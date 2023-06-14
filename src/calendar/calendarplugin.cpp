// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarplugin.h"
#include "calendarapplication.h"
#include "calendarconfig.h"
#include "calendarmanager.h"
#include "filter.h"
#include "incidencewrapper.h"
#include "models/hourlyincidencemodel.h"
#include "models/incidenceoccurrencemodel.h"
#include "models/infinitecalendarviewmodel.h"
#include "models/itemtagsmodel.h"
#include "models/monthmodel.h"
#include "models/multidayincidencemodel.h"
#include "models/timezonelistmodel.h"
#include "models/todosortfilterproxymodel.h"
#include "remindersmodel.h"
#include "utils.h"
#include <Akonadi/AgentFilterProxyModel>

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

#include <Akonadi/FreeBusyManager>
#include <akonadi/calendarsettings.h> //krazy:exclude=camelcase this is a generated file

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.calendar"));

    qmlRegisterSingletonType<Utils>(uri, 1, 0, "Utils", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Utils;
    });
    qmlRegisterSingletonType<Akonadi::CalendarSettings>(uri, 1, 0, "CalendarSettings", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        return Akonadi::CalendarSettings::self();
    });
    qmlRegisterSingletonType<Akonadi::FreeBusyManager>(uri, 1, 0, "FreeBusyManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        return Akonadi::FreeBusyManager::self();
    });
    qmlRegisterType<RemindersModel>(uri, 1, 0, "RemindersModel");
    qmlRegisterModule(uri, 1, 0);
    qRegisterMetaType<KCalendarCore::Incidence::Ptr>();

    qmlRegisterSingletonType<CalendarManager>(uri, 1, 0, "CalendarManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return CalendarManager::instance();
    });
    qmlRegisterSingletonType<CalendarConfig>(uri, 1, 0, "Config", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new CalendarConfig;
    });
    qmlRegisterSingletonType<CalendarApplication>(uri, 1, 0, "CalendarApplication", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new CalendarApplication;
    });

    qmlRegisterSingletonType<Filter>(uri, 1, 0, "Filter", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Filter;
    });

    qmlRegisterType<IncidenceWrapper>(uri, 1, 0, "IncidenceWrapper");
    qmlRegisterType<AttendeesModel>(uri, 1, 0, "AttendeesModel");
    qmlRegisterType<MultiDayIncidenceModel>(uri, 1, 0, "MultiDayIncidenceModel");
    qmlRegisterType<IncidenceOccurrenceModel>(uri, 1, 0, "IncidenceOccurrenceModel");
    qmlRegisterType<TodoSortFilterProxyModel>(uri, 1, 0, "TodoSortFilterProxyModel");
    qmlRegisterType<ItemTagsModel>(uri, 1, 0, "ItemTagsModel");
    qmlRegisterType<HourlyIncidenceModel>(uri, 1, 0, "HourlyIncidenceModel");
    qmlRegisterType<TimeZoneListModel>(uri, 1, 0, "TimeZoneListModel");
    qmlRegisterType<MonthModel>(uri, 1, 0, "MonthModel");
    qmlRegisterType<InfiniteCalendarViewModel>(uri, 1, 0, "InfiniteCalendarViewModel");

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/KalendarUiUtils.qml")), "org.kde.kalendar.utils", 1, 0, "KalendarUiUtils");

    qRegisterMetaType<Akonadi::ETMCalendar::Ptr>();
    qRegisterMetaType<QAbstractProxyModel *>("QAbstractProxyModel*");
    qRegisterMetaType<Akonadi::AgentFilterProxyModel *>();
    qRegisterMetaType<Akonadi::CollectionFilterProxyModel *>();
    qRegisterMetaType<QAction *>();
}
