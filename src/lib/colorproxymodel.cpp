// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "colorproxymodel.h"

#include <Akonadi/AgentInstance>
#include <Akonadi/AgentManager>
#include <Akonadi/AttributeFactory>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionModifyJob>
#include <Akonadi/CollectionUtils>
#include <Akonadi/EntityDisplayAttribute>
#include <CalendarSupport/KCalPrefs>
#include <KCalendarCore/Event>
#include <KCalendarCore/Journal>
#include <KCalendarCore/Todo>
#include <KConfigGroup>
#include <KContacts/Addressee>
#include <KContacts/ContactGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QRandomGenerator>
#include <qcolor.h>

namespace
{
bool isStandardCalendar(Akonadi::Collection::Id id)
{
    return id == CalendarSupport::KCalPrefs::instance()->defaultCalendarId();
}

static bool hasCompatibleMimeTypes(const Akonadi::Collection &collection)
{
    static QStringList goodMimeTypes;

    if (goodMimeTypes.isEmpty()) {
        goodMimeTypes << QStringLiteral("text/calendar") << KCalendarCore::Event::eventMimeType() << KCalendarCore::Todo::todoMimeType()
                      << KContacts::Addressee::mimeType() << KContacts::ContactGroup::mimeType() << KCalendarCore::Journal::journalMimeType();
    }

    for (int i = 0; i < goodMimeTypes.count(); ++i) {
        if (collection.contentMimeTypes().contains(goodMimeTypes.at(i))) {
            return true;
        }
    }

    return false;
}
}

ColorProxyModel::ColorProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , mInitDefaultCalendar(false)
{
    // Needed to read colorattribute of collections for incidence colors
    Akonadi::AttributeFactory::registerAttribute<Akonadi::CollectionColorAttribute>();
}

QVariant ColorProxyModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    if (role == Qt::DecorationRole) {
        const Akonadi::Collection collection = Akonadi::CollectionUtils::fromIndex(index);

        if (hasCompatibleMimeTypes(collection)) {
            if (collection.hasAttribute<Akonadi::EntityDisplayAttribute>() && !collection.attribute<Akonadi::EntityDisplayAttribute>()->iconName().isEmpty()) {
                return collection.attribute<Akonadi::EntityDisplayAttribute>()->iconName();
            }
        }
    } else if (role == Qt::FontRole) {
        const Akonadi::Collection collection = Akonadi::CollectionUtils::fromIndex(index);
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
        const Akonadi::Collection collection = Akonadi::CollectionUtils::fromIndex(index);
        const Akonadi::Collection::Id colId = collection.id();
        const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());

        if (!instance.isOnline() && !collection.isVirtual()) {
            return i18nc("@item this is the default calendar", "%1 (Offline)", collection.displayName());
        }
        if (colId == CalendarSupport::KCalPrefs::instance()->defaultCalendarId()) {
            return i18nc("@item this is the default calendar", "%1 (Default)", collection.displayName());
        }
    } else if (role == Qt::BackgroundRole) {
        auto color = getCollectionColor(Akonadi::CollectionUtils::fromIndex(index));
        // Otherwise QML will get black
        if (color.isValid()) {
            return color;
        } else {
            return {};
        }
    } else if (role == isResource) {
        return Akonadi::CollectionUtils::isResource(Akonadi::CollectionUtils::fromIndex(index));
    }

    return QSortFilterProxyModel::data(index, role);
}

Qt::ItemFlags ColorProxyModel::flags(const QModelIndex &index) const
{
    return Qt::ItemIsSelectable | QSortFilterProxyModel::flags(index);
}

QHash<int, QByteArray> ColorProxyModel::roleNames() const
{
    QHash<int, QByteArray> roleNames = QSortFilterProxyModel::roleNames();
    roleNames[Qt::CheckStateRole] = "checkState";
    roleNames[Qt::BackgroundRole] = "collectionColor";
    roleNames[isResource] = "isResource";
    return roleNames;
}

QColor ColorProxyModel::getCollectionColor(Akonadi::Collection collection) const
{
    const auto id = collection.id();
    auto supportsMimeType = collection.contentMimeTypes().contains(QLatin1String("application/x-vnd.akonadi.calendar.event"))
        || collection.contentMimeTypes().contains(QLatin1String("application/x-vnd.akonadi.calendar.todo"))
        || collection.contentMimeTypes().contains(QLatin1String("application/x-vnd.akonadi.calendar.journal"))
        || collection.contentMimeTypes().contains(KContacts::Addressee::mimeType())
        || collection.contentMimeTypes().contains(KContacts::ContactGroup::mimeType());

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
            return colorAttr->color();
        }
    }

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup resourcesColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = resourcesColorsConfig.keyList();

    QColor color;
    for (const QString &key : colorKeyList) {
        if (key.toLongLong() == id) {
            color = resourcesColorsConfig.readEntry(key, QColor("blue"));
        }
    }

    if (!color.isValid()) {
        QColor color;
        color.setRgb(QRandomGenerator::global()->bounded(256), QRandomGenerator::global()->bounded(256), QRandomGenerator::global()->bounded(256));
        colorCache[id] = color;
    }

    auto colorAttr = collection.attribute<Akonadi::CollectionColorAttribute>(Akonadi::Collection::AddIfMissing);
    colorAttr->setColor(color);

    auto modifyJob = new Akonadi::CollectionModifyJob(collection);
    connect(modifyJob, &Akonadi::CollectionModifyJob::result, this, [](KJob *job) {
        if (job->error()) {
            qWarning() << "Error occurred modifying collection color: " << job->errorString();
        }
    });

    return color;
}

QColor ColorProxyModel::color(Akonadi::Collection::Id collectionId) const
{
    return colorCache[collectionId];
}

void ColorProxyModel::setColor(Akonadi::Collection::Id collectionId, const QColor &color)
{
    colorCache[collectionId] = color;
}
