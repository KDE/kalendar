// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarplugin.h"
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

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr);

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

    qmlRegisterType<RemindersModel>(uri, 1, 0, "RemindersModel");
    qmlRegisterModule(uri, 1, 0);
    qRegisterMetaType<KCalendarCore::Incidence::Ptr>();

    qmlRegisterSingletonInstance(uri, 1, 0, "CalendarManager", CalendarManager::instance());
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

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/KalendarUiUtils.qml")), uri, 1, 0, "KalendarUiUtils");

    qRegisterMetaType<Akonadi::ETMCalendar::Ptr>();
}
