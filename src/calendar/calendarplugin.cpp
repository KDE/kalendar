// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarplugin.h"
#include "calendarmanager.h"
#include "config.h"
#include "filter.h"
#include "importers/icalimporter.h"
#include "incidencewrapper.h"
#include "models/hourlyincidencemodel.h"
#include "models/incidenceoccurrencemodel.h"
#include "models/infinitecalendarviewmodel.h"
#include "models/itemtagsmodel.h"
#include "models/monthmodel.h"
#include "models/multidayincidencemodel.h"
#include "models/remindersmodel.h"
#include "models/timezonelistmodel.h"
#include "models/todosortfilterproxymodel.h"
#include "utils.h"

#include <QAbstractListModel>
#include <QAction>
#include <QQmlEngine>
#include <QtQml>

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.calendar"));

    qmlRegisterSingletonType<Utils>(uri, 1, 0, "Utils", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Utils;
    });

    qmlRegisterSingletonType<Filter>(uri, 1, 0, "Filter", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Filter;
    });

    qmlRegisterSingletonType<Config>(uri, 1, 0, "Config", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return Config::self();
    });

    qmlRegisterSingletonType<CalendarManager>(uri, 1, 0, "CalendarManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return CalendarManager::instance();
    });

    qmlRegisterType<RemindersModel>(uri, 1, 0, "RemindersModel");
    qmlRegisterModule(uri, 1, 0);
    qRegisterMetaType<KCalendarCore::Incidence::Ptr>();

    qmlRegisterType<IncidenceWrapper>(uri, 1, 0, "IncidenceWrapper");
    qmlRegisterType<ICalImporter>(uri, 1, 0, "ICalImporter");
    qmlRegisterType<AttendeesModel>(uri, 1, 0, "AttendeesModel");
    qmlRegisterType<MultiDayIncidenceModel>(uri, 1, 0, "MultiDayIncidenceModel");
    qmlRegisterType<IncidenceOccurrenceModel>(uri, 1, 0, "IncidenceOccurrenceModel");
    qmlRegisterType<TodoSortFilterProxyModel>(uri, 1, 0, "TodoSortFilterProxyModel");
    qmlRegisterType<ItemTagsModel>(uri, 1, 0, "ItemTagsModel");
    qmlRegisterType<HourlyIncidenceModel>(uri, 1, 0, "HourlyIncidenceModel");
    qmlRegisterType<TimeZoneListModel>(uri, 1, 0, "TimeZoneListModel");
    qmlRegisterType<MonthModel>(uri, 1, 0, "MonthModel");
    qmlRegisterType<InfiniteCalendarViewModel>(uri, 1, 0, "InfiniteCalendarViewModel");

    qRegisterMetaType<Akonadi::ETMCalendar::Ptr>();
    qRegisterMetaType<QAction *>();
}
