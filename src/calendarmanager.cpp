//  SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
//  SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
//  SPDX-FileCopyrightText: 2003, 2004 Cornelius Schumacher <schumacher@kde.org>
//  SPDX-FileCopyrightText: 2003-2004 Reinhold Kainhofer <reinhold@kainhofer.com>
//  SPDX-FileCopyrightText: 2009 Sebastian Sauer <sebsauer@kdab.net>
//  SPDX-FileCopyrightText: 2010-2021 Laurent Montel <montel@kde.org>
//  SPDX-FileCopyrightText: 2012 Sérgio Martins <iamsergio@gmail.com>
//
//  SPDX-License-Identifier: GPL-2.0-or-later WITH LicenseRef-Qt-Commercial-exception-1.0

#include "calendarmanager.h"

// Akonadi
#include <Akonadi/AgentInstanceModel>
#include <Akonadi/AgentManager>
#include <Akonadi/AttributeFactory>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionDeleteJob>
#include <Akonadi/CollectionIdentificationAttribute>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionPropertiesDialog>
#include <Akonadi/CollectionUtils>
#include <Akonadi/Control>
#include <Akonadi/EntityDisplayAttribute>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemModifyJob>
#include <Akonadi/ItemMoveJob>
#include <Akonadi/Monitor>
#include "kalendar_debug.h"
#include <Akonadi/Calendar/History>
#include <EventViews/Prefs>
#include <KCheckableProxyModel>
#include <KLocalizedString>
#include <QApplication>
#include <QDebug>
#include <QPointer>
#include <QRandomGenerator>
#include <etmcalendar.h>

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
            // qCDebug(KORGANIZER_LOG) << "checking " << i << parent << mCheckableProxy->index(i, 0, parent).data().toString();
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

class KalendarCollectionFilterProxyModel : public Akonadi::CollectionFilterProxyModel
{
public:
    explicit KalendarCollectionFilterProxyModel(QObject *parent = nullptr)
        : Akonadi::CollectionFilterProxyModel(parent)
    {
    }

protected:
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override
    {
        const auto leftHasChildren = sourceModel()->hasChildren(source_left);
        const auto rightHasChildren = sourceModel()->hasChildren(source_right);
        if (leftHasChildren && !rightHasChildren) {
            return false;
        } else if (!leftHasChildren && rightHasChildren) {
            return true;
        }

        return Akonadi::CollectionFilterProxyModel::lessThan(source_left, source_right);
    }
};

/// Despite the name, this handles the presentation of collections including display text and icons, not just colors.
class ColorProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    enum Roles {
        isResource = Akonadi::EntityTreeModel::UserRole + 1,
    };
    Q_ENUM(Roles);

    explicit ColorProxyModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
        , mInitDefaultCalendar(false)
    {
        // Needed to read colorattribute of collections for incidence colors
        Akonadi::AttributeFactory::registerAttribute<Akonadi::CollectionColorAttribute>();

        // Used to get color settings from KOrganizer as fallback
        const auto korganizerrc = KSharedConfig::openConfig(QStringLiteral("korganizerrc"));
        const auto skel = new KCoreConfigSkeleton(korganizerrc);
        mEventViewsPrefs = EventViews::PrefsPtr(new EventViews::Prefs(skel));
        mEventViewsPrefs->readConfig();

        load();
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid()) {
            return {};
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
            if (!collection.contentMimeTypes().isEmpty() && isStandardCalendar(collection.id()) && collection.rights() & Akonadi::Collection::CanCreateItem) {
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
        } else if (role == Qt::BackgroundRole) {
            auto color = getCollectionColor(CalendarSupport::collectionFromIndex(index));
            // Otherwise QML will get black
            if (color.isValid()) {
                return color;
            } else {
                return {};
            }
        } else if (role == isResource) {
            return Akonadi::CollectionUtils::isResource(CalendarSupport::collectionFromIndex(index));
        }

        return QSortFilterProxyModel::data(index, role);
    }

    Qt::ItemFlags flags(const QModelIndex &index) const override
    {
        return Qt::ItemIsSelectable | QSortFilterProxyModel::flags(index);
    }

    QHash<int, QByteArray> roleNames() const override
    {
        QHash<int, QByteArray> roleNames = QSortFilterProxyModel::roleNames();
        roleNames[Qt::CheckStateRole] = "checkState";
        roleNames[Qt::BackgroundRole] = "collectionColor";
        roleNames[isResource] = "isResource";
        return roleNames;
    }

    QColor getCollectionColor(Akonadi::Collection collection) const
    {
        const QString id = QString::number(collection.id());
        auto supportsMimeType = collection.contentMimeTypes().contains(QLatin1String("application/x-vnd.akonadi.calendar.event"))
            || collection.contentMimeTypes().contains(QLatin1String("application/x-vnd.akonadi.calendar.todo"))
            || collection.contentMimeTypes().contains(QLatin1String("application/x-vnd.akonadi.calendar.journal"));
        // qDebug() << "Collection id: " << collection.id();

        if (!supportsMimeType) {
            return {};
        }

        if (colorCache.contains(id)) {
            return colorCache[id];
        }

        if (collection.hasAttribute<Akonadi::CollectionColorAttribute>()) {
            const auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>();
            if (colorAttr && colorAttr->color().isValid()) {
                colorCache[id] = colorAttr->color();
                save();
                return colorAttr->color();
            }
        }

        QColor korgColor = mEventViewsPrefs->resourceColorKnown(id);
        if (korgColor.isValid()) {
            colorCache[id] = korgColor;
            save();
            return korgColor;
        }

        QColor color;
        color.setRgb(QRandomGenerator::global()->bounded(256), QRandomGenerator::global()->bounded(256), QRandomGenerator::global()->bounded(256));
        colorCache[id] = color;
        save();

        return color;
    }

    void load()
    {
        KSharedConfig::Ptr config = KSharedConfig::openConfig();
        KConfigGroup rColorsConfig(config, "Resources Colors");
        const QStringList colorKeyList = rColorsConfig.keyList();

        for (const QString &key : colorKeyList) {
            QColor color = rColorsConfig.readEntry(key, QColor("blue"));
            colorCache[key] = color;
        }
    }

    void save() const
    {
        KSharedConfig::Ptr config = KSharedConfig::openConfig();
        KConfigGroup rColorsConfig(config, "Resources Colors");
        for (auto it = colorCache.constBegin(); it != colorCache.constEnd(); ++it) {
            rColorsConfig.writeEntry(it.key(), it.value(), KConfigBase::Notify | KConfigBase::Normal);
        }
        config->sync();
    }

    mutable QHash<QString, QColor> colorCache;

private:
    mutable bool mInitDefaultCalendar;
    EventViews::PrefsPtr mEventViewsPrefs;
};

CalendarManager::CalendarManager(QObject *parent)
    : QObject(parent)
    , m_calendar(nullptr)
{
    if (!Akonadi::Control::start()) {
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

    m_calendar = QSharedPointer<Akonadi::ETMCalendar>::create(); // QSharedPointer
    setCollectionSelectionProxyModel(m_calendar->checkableProxyModel());
    connect(m_calendar->checkableProxyModel(), &KCheckableProxyModel::dataChanged, this, &CalendarManager::refreshEnabledTodoCollections);

    m_changer = m_calendar->incidenceChanger();
    m_changer->setHistoryEnabled(true);
    connect(m_changer->history(), &Akonadi::History::changed, this, &CalendarManager::undoRedoDataChanged);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    mCollectionSelectionModelStateSaver = new Akonadi::ETMViewStateSaver(); // not a leak
    KConfigGroup selectionGroup = config->group("GlobalCollectionSelection");
    mCollectionSelectionModelStateSaver->setView(nullptr);
    mCollectionSelectionModelStateSaver->setSelectionModel(m_calendar->checkableProxyModel()->selectionModel());
    mCollectionSelectionModelStateSaver->restoreState(selectionGroup);

    m_allCalendars = new Akonadi::CollectionFilterProxyModel(this);
    m_allCalendars->setSourceModel(collectionFilter);
    m_allCalendars->setExcludeVirtualCollections(true);

    // Filter it by mimetype again, to only keep
    // Kolab / Inbox / Calendar
    m_eventMimeTypeFilterModel = new Akonadi::CollectionFilterProxyModel(this);
    m_eventMimeTypeFilterModel->setSourceModel(collectionFilter);
    m_eventMimeTypeFilterModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.event"));
    // text/calendar mimetype includes todo cals
    m_todoMimeTypeFilterModel = new Akonadi::CollectionFilterProxyModel(this);
    m_todoMimeTypeFilterModel->setSourceModel(collectionFilter);
    m_todoMimeTypeFilterModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.todo"));
    m_todoMimeTypeFilterModel->setExcludeVirtualCollections(true);

    // Filter by access rights
    m_allCollectionsRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_allCollectionsRightsFilterModel->setAccessRights(Collection::CanCreateItem);
    m_allCollectionsRightsFilterModel->setSourceModel(collectionFilter);

    m_eventRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_eventRightsFilterModel->setAccessRights(Collection::CanCreateItem);
    m_eventRightsFilterModel->setSourceModel(m_eventMimeTypeFilterModel);

    m_todoRightsFilterModel = new Akonadi::EntityRightsFilterModel(this);
    m_todoRightsFilterModel->setAccessRights(Collection::CanCreateItem);
    m_todoRightsFilterModel->setSourceModel(m_todoMimeTypeFilterModel);

    // Use our custom class to order them properly
    m_selectableCollectionsModel = new KalendarCollectionFilterProxyModel(this);
    m_selectableCollectionsModel->setSourceModel(m_allCollectionsRightsFilterModel);
    m_selectableCollectionsModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.event"));
    m_selectableCollectionsModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.todo"));
    m_selectableCollectionsModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_selectableCollectionsModel->sort(0, Qt::AscendingOrder);

    m_selectableEventCollectionsModel = new KalendarCollectionFilterProxyModel(this);
    m_selectableEventCollectionsModel->setSourceModel(m_eventRightsFilterModel);
    m_selectableEventCollectionsModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.event"));
    m_selectableEventCollectionsModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_selectableEventCollectionsModel->sort(0, Qt::AscendingOrder);

    m_selectableTodoCollectionsModel = new KalendarCollectionFilterProxyModel(this);
    m_selectableTodoCollectionsModel->setSourceModel(m_todoRightsFilterModel);
    m_selectableTodoCollectionsModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.todo"));
    m_selectableTodoCollectionsModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_selectableTodoCollectionsModel->sort(0, Qt::AscendingOrder);

    // Model for todo via collection picker
    m_todoViewCollectionModel = new KalendarCollectionFilterProxyModel(this);
    m_todoViewCollectionModel->setSourceModel(collectionFilter);
    m_todoViewCollectionModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.todo"));
    m_todoViewCollectionModel->setExcludeVirtualCollections(true);
    m_todoViewCollectionModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_todoViewCollectionModel->sort(0, Qt::AscendingOrder);

    // Model for the sidebar
    m_viewCollectionModel = new KalendarCollectionFilterProxyModel(this);
    m_viewCollectionModel->setSourceModel(collectionFilter);
    m_viewCollectionModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.event"));
    m_viewCollectionModel->addMimeTypeFilter(QStringLiteral("application/x-vnd.akonadi.calendar.todo"));
    m_viewCollectionModel->setExcludeVirtualCollections(true);
    m_viewCollectionModel->setSortCaseSensitivity(Qt::CaseInsensitive);
    m_viewCollectionModel->sort(0, Qt::AscendingOrder);

    m_flatCollectionTreeModel = new KDescendantsProxyModel(this);
    m_flatCollectionTreeModel->setSourceModel(m_viewCollectionModel);
    m_flatCollectionTreeModel->setExpandsByDefault(true);

    auto refreshColors = [=]() {
        for (auto i = 0; i < m_flatCollectionTreeModel->rowCount(); i++) {
            auto idx = m_flatCollectionTreeModel->index(i, 0, {});
            colorProxy->getCollectionColor(CalendarSupport::collectionFromIndex(idx));
        }
    };
    connect(m_flatCollectionTreeModel, &QSortFilterProxyModel::rowsInserted, this, refreshColors);

    KConfigGroup rColorsConfig(config, "Resources Colors");
    m_colorWatcher = KConfigWatcher::create(config);
    QObject::connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &CalendarManager::collectionColorsChanged);
}

CalendarManager::~CalendarManager()
{
    save();
    // delete mCollectionSelectionModelStateSaver;
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
    return static_cast<QAbstractProxyModel *>(m_flatCollectionTreeModel->sourceModel());
}

QAbstractItemModel *CalendarManager::todoCollections()
{
    return m_todoViewCollectionModel;
}

QAbstractItemModel *CalendarManager::viewCollections()
{
    return m_viewCollectionModel;
}

QVector<qint64> CalendarManager::enabledTodoCollections()
{
    return m_enabledTodoCollections;
}

void CalendarManager::refreshEnabledTodoCollections()
{
    m_enabledTodoCollections.clear();
    const auto selectedIndexes = m_calendar->checkableProxyModel()->selectionModel()->selectedIndexes();
    for (auto selectedIndex : selectedIndexes) {
        auto collection = selectedIndex.data(Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        if (collection.contentMimeTypes().contains(QStringLiteral("application/x-vnd.akonadi.calendar.todo"))) {
            m_enabledTodoCollections.append(collection.id());
        }
    }

    Q_EMIT enabledTodoCollectionsChanged();
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

Akonadi::ETMCalendar::Ptr CalendarManager::calendar() const
{
    return m_calendar;
}

Akonadi::IncidenceChanger *CalendarManager::incidenceChanger() const
{
    return m_changer;
}

Akonadi::CollectionFilterProxyModel *CalendarManager::allCalendars()
{
    return m_allCalendars;
}

Akonadi::CollectionFilterProxyModel *CalendarManager::selectableCalendars() const
{
    return m_selectableCollectionsModel;
}

Akonadi::CollectionFilterProxyModel *CalendarManager::selectableEventCalendars() const
{
    return m_selectableEventCollectionsModel;
}

Akonadi::CollectionFilterProxyModel *CalendarManager::selectableTodoCalendars() const
{
    return m_selectableTodoCollectionsModel;
}

qint64 CalendarManager::defaultCalendarId(IncidenceWrapper *incidenceWrapper)
{
    // Checks if default collection accepts this type of incidence
    auto mimeType = incidenceWrapper->incidencePtr()->mimeType();
    Akonadi::Collection collection = m_calendar->collection(CalendarSupport::KCalPrefs::instance()->defaultCalendarId());
    bool supportsMimeType = collection.contentMimeTypes().contains(mimeType) || mimeType == QLatin1String("");
    bool hasRights = collection.rights() & Akonadi::Collection::CanCreateItem;
    if (collection.isValid() && supportsMimeType && hasRights) {
        return collection.id();
    }

    // Should add last used collection by mimetype somewhere.

    // Searches for first collection that will accept this incidence
    for (int i = 0; i < m_allCalendars->rowCount(); i++) {
        QModelIndex idx = m_allCalendars->index(i, 0);
        collection = idx.data(Akonadi::EntityTreeModel::Roles::CollectionRole).value<Akonadi::Collection>();
        supportsMimeType = collection.contentMimeTypes().contains(mimeType) || mimeType == QLatin1String("");
        hasRights = collection.rights() & Akonadi::Collection::CanCreateItem;
        if (collection.isValid() && supportsMimeType && hasRights) {
            return collection.id();
        }
    }

    return -1;
}

int CalendarManager::getCalendarSelectableIndex(IncidenceWrapper *incidenceWrapper)
{
    auto model = new KDescendantsProxyModel;

    switch (incidenceWrapper->incidencePtr()->type()) {
    default:
    case (KCalendarCore::IncidenceBase::TypeEvent): {
        model->setSourceModel(m_selectableEventCollectionsModel);
        break;
    }
    case (KCalendarCore::IncidenceBase::TypeTodo): {
        model->setSourceModel(m_selectableTodoCollectionsModel);
        break;
    }
    }

    for (int i = 0; i < model->rowCount(); i++) {
        QModelIndex idx = model->index(i, 0);
        QVariant data = idx.data(Akonadi::EntityTreeModel::Roles::CollectionIdRole);

        if (data == incidenceWrapper->collectionId())
            return i;
    }

    return 0;
}

QVariant CalendarManager::getIncidenceSubclassed(KCalendarCore::Incidence::Ptr incidencePtr)
{
    switch (incidencePtr->type()) {
    case (KCalendarCore::IncidenceBase::TypeEvent):
        return QVariant::fromValue(m_calendar->event(incidencePtr->instanceIdentifier()));
        break;
    case (KCalendarCore::IncidenceBase::TypeTodo):
        return QVariant::fromValue(m_calendar->todo(incidencePtr->instanceIdentifier()));
        break;
    case (KCalendarCore::IncidenceBase::TypeJournal):
        return QVariant::fromValue(m_calendar->journal(incidencePtr->instanceIdentifier()));
        break;
    default:
        return QVariant::fromValue(incidencePtr);
        break;
    }
}

QVariantMap CalendarManager::undoRedoData()
{
    return QVariantMap{
        {QStringLiteral("undoAvailable"), m_changer->history()->undoAvailable()},
        {QStringLiteral("redoAvailable"), m_changer->history()->redoAvailable()},
        {QStringLiteral("nextUndoDescription"), m_changer->history()->nextUndoDescription()},
        {QStringLiteral("nextRedoDescription"), m_changer->history()->nextRedoDescription()},
    };
}

Akonadi::Item CalendarManager::incidenceItem(KCalendarCore::Incidence::Ptr incidence)
{
    return m_calendar->item(incidence);
}

void CalendarManager::addIncidence(IncidenceWrapper *incidenceWrapper)
{
    Akonadi::Collection collection(incidenceWrapper->collectionId());

    switch (incidenceWrapper->incidencePtr()->type()) {
    case (KCalendarCore::IncidenceBase::TypeEvent): {
        KCalendarCore::Event::Ptr event = incidenceWrapper->incidencePtr().staticCast<KCalendarCore::Event>();
        m_changer->createIncidence(event, collection);
        break;
    }
    case (KCalendarCore::IncidenceBase::TypeTodo): {
        KCalendarCore::Todo::Ptr todo = incidenceWrapper->incidencePtr().staticCast<KCalendarCore::Todo>();
        m_changer->createIncidence(todo, collection);
        break;
    }
    default:
        m_changer->createIncidence(KCalendarCore::Incidence::Ptr(incidenceWrapper->incidencePtr()->clone()), collection);
        break;
    }
    // This will fritz if you don't choose a valid *calendar*
}

// Replicates IncidenceDialogPrivate::save
void CalendarManager::editIncidence(IncidenceWrapper *incidenceWrapper)
{
    // We need to use the incidenceChanger manually to get the change recorded in the history
    // For undo/redo to work properly we need to change the ownership of the incidence pointers
    KCalendarCore::Incidence::Ptr changedIncidence(incidenceWrapper->incidencePtr()->clone());
    KCalendarCore::Incidence::Ptr originalPayload(incidenceWrapper->originalIncidencePtr()->clone());

    Akonadi::Item modifiedItem = m_calendar->item(changedIncidence->instanceIdentifier());
    modifiedItem.setPayload<KCalendarCore::Incidence::Ptr>(changedIncidence);

    m_changer->modifyIncidence(modifiedItem, originalPayload);

    if (!incidenceWrapper->collectionId() || incidenceWrapper->collectionId() < 0 || modifiedItem.parentCollection().id() == incidenceWrapper->collectionId()) {
        return;
    }

    changeIncidenceCollection(modifiedItem, incidenceWrapper->collectionId());
}

void CalendarManager::updateIncidenceDates(IncidenceWrapper *incidenceWrapper, int startOffset, int endOffset, int occurrences, const QDateTime &occurrenceDate)
{ // start and end offsets are in msecs

    Akonadi::Item item = m_calendar->item(incidenceWrapper->incidencePtr());
    item.setPayload(incidenceWrapper->incidencePtr());

    auto setNewDates = [&](KCalendarCore::Incidence::Ptr incidence) {
        if (incidence->type() == KCalendarCore::Incidence::TypeTodo) {
            // For to-dos endOffset is ignored because it will always be == to startOffset because we only
            // support moving to-dos, not resizing them. There are no multi-day to-dos.
            // Lets just call it offset to reduce confusion.
            const int offset = startOffset;

            KCalendarCore::Todo::Ptr todo = incidence.staticCast<KCalendarCore::Todo>();
            QDateTime due = todo->dtDue();
            QDateTime start = todo->dtStart();
            if (due.isValid()) { // Due has priority over start.
                // We will only move the due date, unlike events where we move both.
                due = due.addMSecs(offset);
                todo->setDtDue(due);

                if (start.isValid() && start > due) {
                    // Start can't be bigger than due.
                    todo->setDtStart(due);
                }
            } else if (start.isValid()) {
                // So we're displaying a to-do that doesn't have due date, only start...
                start = start.addMSecs(offset);
                todo->setDtStart(start);
            } else {
                // This never happens
                // qCWarning(CALENDARVIEW_LOG) << "Move what? uid:" << todo->uid() << "; summary=" << todo->summary();
            }
        } else {
            incidence->setDtStart(incidence->dtStart().addMSecs(startOffset));
            if (incidence->type() == KCalendarCore::Incidence::TypeEvent) {
                KCalendarCore::Event::Ptr event = incidence.staticCast<KCalendarCore::Event>();
                event->setDtEnd(event->dtEnd().addMSecs(endOffset));
            }
        }
    };

    if (incidenceWrapper->incidencePtr()->recurs()) {
        switch (occurrences) {
        case KCalUtils::RecurrenceActions::AllOccurrences: {
            // All occurrences
            KCalendarCore::Incidence::Ptr oldIncidence(incidenceWrapper->incidencePtr()->clone());
            setNewDates(incidenceWrapper->incidencePtr());
            qCDebug(KALENDAR_LOG) << incidenceWrapper->incidenceStart();
            m_changer->modifyIncidence(item, oldIncidence);
            break;
        }
        case KCalUtils::RecurrenceActions::SelectedOccurrence: // Just this occurrence
        case KCalUtils::RecurrenceActions::FutureOccurrences: { // All future occurrences
            const bool thisAndFuture = (occurrences == KCalUtils::RecurrenceActions::FutureOccurrences);
            auto tzedOccurrenceDate = occurrenceDate.toTimeZone(incidenceWrapper->incidenceStart().timeZone());
            KCalendarCore::Incidence::Ptr newIncidence(
                KCalendarCore::Calendar::createException(incidenceWrapper->incidencePtr(), tzedOccurrenceDate, thisAndFuture));

            if (newIncidence) {
                m_changer->startAtomicOperation(i18n("Move occurrence(s)"));
                setNewDates(newIncidence);
                m_changer->createIncidence(newIncidence, m_calendar->collection(incidenceWrapper->collectionId()));
                m_changer->endAtomicOperation();
            } else {
                qCDebug(KALENDAR_LOG) << i18n("Unable to add the exception item to the calendar. No change will be done.");
            }
            break;
        }
        }
    } else { // Doesn't recur
        KCalendarCore::Incidence::Ptr oldIncidence(incidenceWrapper->incidencePtr()->clone());
        setNewDates(incidenceWrapper->incidencePtr());
        m_changer->modifyIncidence(item, oldIncidence);
    }

    Q_EMIT updateIncidenceDatesCompleted();
}

bool CalendarManager::hasChildren(KCalendarCore::Incidence::Ptr incidence)
{
    return !m_calendar->childIncidences(incidence->uid()).isEmpty();
}

void CalendarManager::deleteAllChildren(KCalendarCore::Incidence::Ptr incidence)
{
    const auto allChildren = m_calendar->childIncidences(incidence->uid());

    for (const auto &child : allChildren) {
        if (!m_calendar->childIncidences(child->uid()).isEmpty()) {
            deleteAllChildren(child);
        }
    }

    for (const auto &child : allChildren) {
        m_calendar->deleteIncidence(child);
    }
}

void CalendarManager::deleteIncidence(KCalendarCore::Incidence::Ptr incidence, bool deleteChildren)
{
    const auto directChildren = m_calendar->childIncidences(incidence->uid());

    if (!directChildren.isEmpty()) {
        if (deleteChildren) {
            m_changer->startAtomicOperation(i18n("Delete task and its sub-tasks"));
            deleteAllChildren(incidence);
        } else {
            m_changer->startAtomicOperation(i18n("Delete task and make sub-tasks independent"));
            for (const auto &child : directChildren) {
                const auto instances = m_calendar->instances(child);
                for (const auto &instance : instances) {
                    KCalendarCore::Incidence::Ptr oldInstance(instance->clone());
                    instance->setRelatedTo(QString());
                    m_changer->modifyIncidence(m_calendar->item(instance), oldInstance);
                }

                KCalendarCore::Incidence::Ptr oldInc(child->clone());
                child->setRelatedTo(QString());
                m_changer->modifyIncidence(m_calendar->item(child), oldInc);
            }
        }

        m_calendar->deleteIncidence(incidence);
        m_changer->endAtomicOperation();
        return;
    }

    m_calendar->deleteIncidence(incidence);
}

void CalendarManager::changeIncidenceCollection(KCalendarCore::Incidence::Ptr incidence, qint64 collectionId)
{
    KCalendarCore::Incidence::Ptr incidenceClone(incidence->clone());
    Akonadi::Item modifiedItem = m_calendar->item(incidence->instanceIdentifier());
    modifiedItem.setPayload<KCalendarCore::Incidence::Ptr>(incidenceClone);

    if (modifiedItem.parentCollection().id() != collectionId) {
        changeIncidenceCollection(modifiedItem, collectionId);
    }
}

void CalendarManager::changeIncidenceCollection(Akonadi::Item item, qint64 collectionId)
{
    if (item.parentCollection().id() == collectionId) {
        return;
    }

    Q_ASSERT(item.hasPayload<KCalendarCore::Incidence::Ptr>());

    Akonadi::Collection newCollection(collectionId);
    item.setParentCollection(newCollection);

    auto job = new Akonadi::ItemMoveJob(item, newCollection);
    // Add some type of check here?
    connect(job, &KJob::result, job, [=]() {
        qCDebug(KALENDAR_LOG) << job->error();

        if (!job->error()) {
            const auto allChildren = m_calendar->childIncidences(item.id());
            for (const auto &child : allChildren) {
                changeIncidenceCollection(m_calendar->item(child), collectionId);
            }

            auto parent = item.payload<KCalendarCore::Incidence::Ptr>()->relatedTo();
            if (!parent.isEmpty()) {
                changeIncidenceCollection(m_calendar->item(parent), collectionId);
            }
        }
    });
}

QVariantMap CalendarManager::getCollectionDetails(QVariant collectionId)
{
    QVariantMap collectionDetails;
    Akonadi::Collection collection = m_calendar->collection(collectionId.toInt());
    bool isFiltered = false;
    int allCalendarsRow = 0;

    for (int i = 0; i < m_allCalendars->rowCount(); i++) {
        if (m_allCalendars->data(m_allCalendars->index(i, 0), Akonadi::EntityTreeModel::CollectionIdRole).toInt() == collectionId) {
            isFiltered = !m_allCalendars->data(m_allCalendars->index(i, 0), Qt::CheckStateRole).toBool();
            allCalendarsRow = i;
            break;
        }
    }

    collectionDetails[QLatin1String("id")] = collection.id();
    collectionDetails[QLatin1String("name")] = collection.name();
    collectionDetails[QLatin1String("displayName")] = collection.displayName();
    collectionDetails[QLatin1String("color")] = m_baseModel->colorCache[QString::number(collection.id())];
    collectionDetails[QLatin1String("count")] = collection.statistics().count();
    collectionDetails[QLatin1String("isResource")] = Akonadi::CollectionUtils::isResource(collection);
    collectionDetails[QLatin1String("readOnly")] = collection.rights().testFlag(Collection::ReadOnly);
    collectionDetails[QLatin1String("canChange")] = collection.rights().testFlag(Collection::CanChangeCollection);
    collectionDetails[QLatin1String("canCreate")] = collection.rights().testFlag(Collection::CanCreateCollection);
    collectionDetails[QLatin1String("canDelete")] = collection.rights().testFlag(Collection::CanDeleteCollection);
    collectionDetails[QLatin1String("isFiltered")] = isFiltered;
    collectionDetails[QLatin1String("allCalendarsRow")] = allCalendarsRow;

    return collectionDetails;
}

void CalendarManager::setCollectionColor(qint64 collectionId, QColor color)
{
    auto collection = m_calendar->collection(collectionId);
    auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>(Akonadi::Collection::AddIfMissing);
    colorAttr->setColor(color);
    auto modifyJob = new Akonadi::CollectionModifyJob(collection);
    connect(modifyJob, &Akonadi::CollectionModifyJob::result, this, [this, collectionId, color](KJob *job) {
        if (job->error()) {
            qCWarning(KALENDAR_LOG) << "Error occurred modifying collection color: " << job->errorString();
        } else {
            m_baseModel->colorCache[QString::number(collectionId)] = color;
            m_baseModel->save();
        }
    });
}

void CalendarManager::undoAction()
{
    m_changer->history()->undo();
}

void CalendarManager::redoAction()
{
    m_changer->history()->redo();
}

void CalendarManager::updateAllCollections()
{
    for (int i = 0; i < collections()->rowCount(); i++) {
        auto collection = collections()->data(collections()->index(i, 0), Akonadi::EntityTreeModel::CollectionRole).value<Akonadi::Collection>();
        Akonadi::AgentManager::self()->synchronizeCollection(collection, true);
    }
}

void CalendarManager::updateCollection(qint64 collectionId)
{
    auto collection = m_calendar->collection(collectionId);
    Akonadi::AgentManager::self()->synchronizeCollection(collection, false);
}

void CalendarManager::deleteCollection(qint64 collectionId)
{
    auto collection = m_calendar->collection(collectionId);
    const bool isTopLevel = collection.parentCollection() == Akonadi::Collection::root();

    if (!isTopLevel) {
        // deletes contents
        auto job = new Akonadi::CollectionDeleteJob(collection, this);
        connect(job, &Akonadi::CollectionDeleteJob::result, this, [](KJob *job) {
            if (job->error()) {
                qCWarning(KALENDAR_LOG) << "Error occurred deleting collection: " << job->errorString();
            }
        });
        return;
    }
    // deletes the agent, not the contents
    const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());
    if (instance.isValid()) {
        Akonadi::AgentManager::self()->removeInstance(instance);
    }
}

void CalendarManager::editCollection(qint64 collectionId)
{ // TODO: Reimplement this dialog in QML
    auto collection = m_calendar->collection(collectionId);
    QPointer<Akonadi::CollectionPropertiesDialog> dlg = new Akonadi::CollectionPropertiesDialog(collection);
    dlg->setWindowTitle(i18nc("@title:window", "Properties of Calendar %1", collection.name()));
    dlg->show();
}

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr);

#include "calendarmanager.moc"
