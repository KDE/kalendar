// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
//  SPDX-FileCopyrightText: 2003, 2004 Cornelius Schumacher <schumacher@kde.org>
//  SPDX-FileCopyrightText: 2003-2004 Reinhold Kainhofer <reinhold@kainhofer.com>
//  SPDX-FileCopyrightText: 2009 Sebastian Sauer <sebsauer@kdab.net>
//  SPDX-FileCopyrightText: 2010-2021 Laurent Montel <montel@kde.org>
//  SPDX-FileCopyrightText: 2012 Sérgio Martins <iamsergio@gmail.com>
//
//  SPDX-License-Identifier: GPL-2.0-or-later WITH Qt-Commercial-exception-1.0


#include "calendarmanager.h"

// Akonadi
#include <control.h>
#include <etmcalendar.h>
#include <CollectionFilterProxyModel>
#include <Monitor>
#include <KLocalizedString>
#include <EntityTreeModel>
#include <QApplication>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <AkonadiCore/EntityDisplayAttribute>
#include <AkonadiCore/AgentManager>
#include <AkonadiCore/AgentInstanceModel>
#include <Akonadi/Calendar/IncidenceChanger>
#include <AkonadiCore/CollectionIdentificationAttribute>
#include <KCheckableProxyModel>
#include <KDescendantsProxyModel>
#include <QTimer>

using namespace Akonadi;

static Akonadi::EntityTreeModel *findEtm(QAbstractItemModel *model)
{
    QAbstractProxyModel *proxyModel = nullptr;
    while (model) {
        proxyModel = qobject_cast<QAbstractProxyModel *>(model);
        if (proxyModel && proxyModel->sourceModel()) {
            model = proxyModel->sourceModel();
        } else {
            break;
        }
    }
    return qobject_cast<Akonadi::EntityTreeModel *>(model);
}


bool isStandardCalendar(Akonadi::Collection::Id id)
{
    return id == CalendarSupport::KCalPrefs::instance()->defaultCalendarId();
}


static bool hasCompatibleMimeTypes(const Akonadi::Collection &collection)
{
    static QStringList goodMimeTypes;

    if (goodMimeTypes.isEmpty()) {
        goodMimeTypes << QStringLiteral("text/calendar") << KCalendarCore::Event::eventMimeType() << KCalendarCore::Todo::todoMimeType()
                      << KCalendarCore::Journal::journalMimeType();
    }

    for (int i = 0; i < goodMimeTypes.count(); ++i) {
        if (collection.contentMimeTypes().contains(goodMimeTypes.at(i))) {
            return true;
        }
    }

    return false;
}

/**
 * Automatically checks new calendar entries
 */
class NewCalendarChecker : public QObject
{
    Q_OBJECT
public:
    NewCalendarChecker(QAbstractItemModel *model)
        : QObject(model)
        , mCheckableProxy(model)
    {
        connect(model, &QAbstractItemModel::rowsInserted, this, &NewCalendarChecker::onSourceRowsInserted);
        qRegisterMetaType<QPersistentModelIndex>("QPersistentModelIndex");
    }

private Q_SLOTS:
    void onSourceRowsInserted(const QModelIndex &parent, int start, int end)
    {
        Akonadi::EntityTreeModel *etm = findEtm(mCheckableProxy);
        // Only check new collections and not during initial population
        if (!etm || !etm->isCollectionTreeFetched()) {
            return;
        }
        for (int i = start; i <= end; ++i) {
            //qCDebug(KORGANIZER_LOG) << "checking " << i << parent << mCheckableProxy->index(i, 0, parent).data().toString();
            const QModelIndex index = mCheckableProxy->index(i, 0, parent);
            QMetaObject::invokeMethod(this, "setCheckState", Qt::QueuedConnection, QGenericReturnArgument(), Q_ARG(QPersistentModelIndex, index));
        }
    }

    void setCheckState(const QPersistentModelIndex &index)
    {
        mCheckableProxy->setData(index, Qt::Checked, Qt::CheckStateRole);
        if (mCheckableProxy->hasChildren(index)) {
            onSourceRowsInserted(index, 0, mCheckableProxy->rowCount(index) - 1);
        }
    }

private:
    QAbstractItemModel *const mCheckableProxy;
};

class CollectionFilter : public QSortFilterProxyModel
{
public:
    explicit CollectionFilter(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        setDynamicSortFilter(true);
    }

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override
    {
        const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
        Q_ASSERT(sourceIndex.isValid());

        const Akonadi::Collection &col = sourceIndex.data(Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        const auto attr = col.attribute<Akonadi::CollectionIdentificationAttribute>();

        // We filter the user folders because we insert person nodes for user folders.
        if ((attr && attr->collectionNamespace().startsWith("usertoplevel")) || col.name().contains(QLatin1String("Other Users"))) {
            return false;
        }
        return true;
    }

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override
    {
        if (role == Qt::ToolTipRole) {
            const Akonadi::Collection col = CalendarSupport::collectionFromIndex(index);
            return CalendarSupport::toolTipString(col);
        }

        return QSortFilterProxyModel::data(index, role);
    };
};

class ColorProxyModel : public QSortFilterProxyModel
{
public:
    explicit ColorProxyModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
        , mInitDefaultCalendar(false)
    {
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid()) {
            return QVariant();
        }
        if (role == Qt::DecorationRole) {
            const Akonadi::Collection collection = CalendarSupport::collectionFromIndex(index);

            if (hasCompatibleMimeTypes(collection)) {
                if (collection.hasAttribute<Akonadi::EntityDisplayAttribute>()
                    && !collection.attribute<Akonadi::EntityDisplayAttribute>()->iconName().isEmpty()) {
                    return collection.attribute<Akonadi::EntityDisplayAttribute>()->iconName();
                }
            }
        } else if (role == Qt::FontRole) {
            const Akonadi::Collection collection = CalendarSupport::collectionFromIndex(index);
            if (!collection.contentMimeTypes().isEmpty() && isStandardCalendar(collection.id())
                && collection.rights() & Akonadi::Collection::CanCreateItem) {
                auto font = qvariant_cast<QFont>(QSortFilterProxyModel::data(index, Qt::FontRole));
                font.setBold(true);
                if (!mInitDefaultCalendar) {
                    mInitDefaultCalendar = true;
                    CalendarSupport::KCalPrefs::instance()->setDefaultCalendarId(collection.id());
                }
                return font;
            }
        } else if (role == Qt::DisplayRole) {
            const Akonadi::Collection collection = CalendarSupport::collectionFromIndex(index);
            const Akonadi::Collection::Id colId = collection.id();
            const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());
            if (!instance.isOnline() && !collection.isVirtual()) {
                return i18nc("@item this is the default calendar", "%1 (Offline)", collection.displayName());
            }
            if (colId == CalendarSupport::KCalPrefs::instance()->defaultCalendarId()) {
                return i18nc("@item this is the default calendar", "%1 (Default)", collection.displayName());
            }
        }

        return QSortFilterProxyModel::data(index, role);
    }

    Qt::ItemFlags flags(const QModelIndex &index) const override
    {
        return Qt::ItemIsSelectable | QSortFilterProxyModel::flags(index);
    }

private:
    mutable bool mInitDefaultCalendar;
};



CalendarManager::CalendarManager(QObject *parent)
    : QObject(parent)
    , m_calendar(nullptr)
{
    auto currentDate = QDate::currentDate();
    if (!Akonadi::Control::start() ) {
        qApp->exit(-1);
        return;
    }

    auto colorProxy = new ColorProxyModel(this);
    colorProxy->setObjectName(QStringLiteral("Show calendar colors"));
    colorProxy->setDynamicSortFilter(true);
    m_baseModel = colorProxy;

    // Hide collections that are not required
    auto collectionFilter = new CollectionFilter(this);
    collectionFilter->setSourceModel(colorProxy);

    m_treeModel = new KDescendantsProxyModel(this);
    m_treeModel->setSourceModel(collectionFilter);
    m_treeModel->setExpandsByDefault(true);

    m_calendar = new Akonadi::ETMCalendar(this);
    setCollectionSelectionProxyModel(m_calendar->checkableProxyModel());

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    mCollectionSelectionModelStateSaver = new Akonadi::ETMViewStateSaver(); // not a leak
    KConfigGroup selectionGroup = config->group("GlobalCollectionSelection");
    mCollectionSelectionModelStateSaver->setView(nullptr);
    mCollectionSelectionModelStateSaver->setSelectionModel(m_calendar->checkableProxyModel()->selectionModel());
    mCollectionSelectionModelStateSaver->restoreState(selectionGroup);

    // Below reimplements part of Akonadi::CollectionComboBox

    // Flatten the tree, e.g.
    // Kolab
    // Kolab / Inbox
    // Kolab / Inbox / Calendar
    auto proxyModel = new KDescendantsProxyModel(this);
    proxyModel->setDisplayAncestorData(true);
    proxyModel->setSourceModel(collectionFilter);

    // Filter it by mimetype again, to only keep
    // Kolab / Inbox / Calendar
    m_mimeTypeFilterModel = new Akonadi::CollectionFilterProxyModel(this);
    m_mimeTypeFilterModel->setSourceModel(proxyModel);
    m_mimeTypeFilterModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.event"));
    // text/calendar mimetype includes todo cals

    // Filter by access rights
    m_rightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_rightsFilterModel->setAccessRights( Collection::CanCreateItem );
    m_rightsFilterModel->setSourceModel(m_mimeTypeFilterModel);
    m_rightsFilterModel->sort(0);

    connect(m_rightsFilterModel, &Akonadi::EntityRightsFilterModel::rowsInserted,
            this, &CalendarManager::updateDefaultCalendarSelectableIndex);

    Q_EMIT entityTreeModelChanged();
    Q_EMIT loadingChanged();
}

CalendarManager::~CalendarManager()
{
    save();
    delete mCollectionSelectionModelStateSaver;
}

void CalendarManager::save()
{
    Akonadi::ETMViewStateSaver treeStateSaver;
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup group = config->group("GlobalCollectionSelection");
    treeStateSaver.setView(nullptr);
    treeStateSaver.setSelectionModel(m_calendar->checkableProxyModel()->selectionModel());
    treeStateSaver.saveState(group);

    config->sync();
}


void CalendarManager::delayedInit()
{
    Q_EMIT entityTreeModelChanged();
    Q_EMIT loadingChanged();
}

QAbstractProxyModel *CalendarManager::collections()
{
    return m_treeModel;
}


bool CalendarManager::loading() const
{
    return !m_calendar->isLoaded();
}

void CalendarManager::setCollectionSelectionProxyModel(KCheckableProxyModel *m)
{
    if (m_selectionProxyModel == m) {
        return;
    }

    m_selectionProxyModel = m;
    if (!m_selectionProxyModel) {
        return;
    }

    new NewCalendarChecker(m);
    m_baseModel->setSourceModel(m_selectionProxyModel);
}

KCheckableProxyModel *CalendarManager::collectionSelectionProxyModel() const
{
    return m_selectionProxyModel;
}

Akonadi::ETMCalendar *CalendarManager::calendar() const
{
    return m_calendar;
}

Akonadi::EntityRightsFilterModel * CalendarManager::selectableCalendars() const
{
    return m_rightsFilterModel;
}

qint64 CalendarManager::defaultCalendarId()
{
    return CalendarSupport::KCalPrefs::instance()->defaultCalendarId();
}

int CalendarManager::getCalendarSelectableIndex(qint64 collectionId)
{
    //auto index = m_rightsFilterModel->match(m_rightsFilterModel->index(0,0), Akonadi::EntityTreeModel::Roles::CollectionRole, cal, -1, Qt::MatchRecursive);

    for(int i = 0; i < m_rightsFilterModel->rowCount(); i++)
    {
        QModelIndex idx = m_rightsFilterModel->index(i, 0);
        QVariant data = idx.data(Akonadi::EntityTreeModel::Roles::CollectionIdRole);

        if(data == collectionId)
            return i;
    }
    return -1;
}

int CalendarManager::defaultCalendarSelectableIndex()
{
    return m_defaultCalendarSelectableIndex;
}

void CalendarManager::updateDefaultCalendarSelectableIndex()
{
    qint64 calId = defaultCalendarId();
    m_defaultCalendarSelectableIndex = getCalendarSelectableIndex(calId);
    Q_EMIT defaultCalendarSelectableIndexChanged();
}

void CalendarManager::addEvent(qint64 collectionId, KCalendarCore::Event::Ptr event)
{
    Akonadi::Collection::Id collId = collectionId;
    Akonadi::Collection collection(collId);

    Akonadi::IncidenceChanger *changer = m_calendar->incidenceChanger();
    qDebug() << changer->createIncidence(event, collection); // This will fritz if you don't choose a valid *calendar*
}

#include "calendarmanager.moc"
