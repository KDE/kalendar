// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "colorproxymodel.h"

#include <Akonadi/AgentInstance>
#include <Akonadi/AgentManager>
#include <Akonadi/AttributeFactory>
#include <Akonadi/CollectionColorAttribute>
#include <Akonadi/CollectionUtils>
#include <Akonadi/EntityDisplayAttribute>
#include <CalendarSupport/KCalPrefs>
#include <akonadi_version.h>
#if AKONADI_VERSION < QT_VERSION_CHECK(5, 20, 41)
#include <CalendarSupport/Utils>
#endif
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QRandomGenerator>
#include <kcontacts/addressee.h>
#include <kcontacts/contactgroup.h>

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
                      << KCalendarCore::Journal::journalMimeType();
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

    // Used to get color settings from KOrganizer as fallback
    const auto korganizerrc = KSharedConfig::openConfig(QStringLiteral("korganizerrc"));
    const auto skel = new KCoreConfigSkeleton(korganizerrc);
    mEventViewsPrefs = EventViews::PrefsPtr(new EventViews::Prefs(skel));
    mEventViewsPrefs->readConfig();

    load();
}

QVariant ColorProxyModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    if (role == Qt::DecorationRole) {
#if AKONADI_VERSION < QT_VERSION_CHECK(5, 20, 41)
        const Akonadi::Collection collection = CalendarSupport::collectionFromIndex(index);
#else
        const Akonadi::Collection collection = Akonadi::CollectionUtils::fromIndex(index);
#endif

        if (hasCompatibleMimeTypes(collection)) {
            if (collection.hasAttribute<Akonadi::EntityDisplayAttribute>() && !collection.attribute<Akonadi::EntityDisplayAttribute>()->iconName().isEmpty()) {
                return collection.attribute<Akonadi::EntityDisplayAttribute>()->iconName();
            }
        }
    } else if (role == Qt::FontRole) {
#if AKONADI_VERSION < QT_VERSION_CHECK(5, 20, 41)
        const Akonadi::Collection collection = CalendarSupport::collectionFromIndex(index);
#else
        const Akonadi::Collection collection = Akonadi::CollectionUtils::fromIndex(index);
#endif
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
#if AKONADI_VERSION < QT_VERSION_CHECK(5, 20, 41)
        const Akonadi::Collection collection = CalendarSupport::collectionFromIndex(index);
#else
        const Akonadi::Collection collection = Akonadi::CollectionUtils::fromIndex(index);
#endif
        const Akonadi::Collection::Id colId = collection.id();
        const Akonadi::AgentInstance instance = Akonadi::AgentManager::self()->instance(collection.resource());

        if (!instance.isOnline() && !collection.isVirtual()) {
            return i18nc("@item this is the default calendar", "%1 (Offline)", collection.displayName());
        }
        if (colId == CalendarSupport::KCalPrefs::instance()->defaultCalendarId()) {
            return i18nc("@item this is the default calendar", "%1 (Default)", collection.displayName());
        }
    } else if (role == Qt::BackgroundRole) {
#if AKONADI_VERSION < QT_VERSION_CHECK(5, 20, 41)
        auto color = getCollectionColor(CalendarSupport::collectionFromIndex(index));
#else
        auto color = getCollectionColor(Akonadi::CollectionUtils::fromIndex(index));
#endif
        // Otherwise QML will get black
        if (color.isValid()) {
            return color;
        } else {
            return {};
        }
    } else if (role == isResource) {
#if AKONADI_VERSION < QT_VERSION_CHECK(5, 20, 41)
        return Akonadi::CollectionUtils::isResource(CalendarSupport::collectionFromIndex(index));
#else
        return Akonadi::CollectionUtils::isResource(Akonadi::CollectionUtils::fromIndex(index));
#endif
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
    const QString id = QString::number(collection.id());
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

void ColorProxyModel::load()
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = rColorsConfig.keyList();

    for (const QString &key : colorKeyList) {
        QColor color = rColorsConfig.readEntry(key, QColor("blue"));
        colorCache[key] = color;
    }
}

void ColorProxyModel::save() const
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    for (auto it = colorCache.constBegin(); it != colorCache.constEnd(); ++it) {
        rColorsConfig.writeEntry(it.key(), it.value(), KConfigBase::Notify | KConfigBase::Normal);
    }
    config->sync();
}
