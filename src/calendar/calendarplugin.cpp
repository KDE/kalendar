// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarplugin.h"
#include "remindersmodel.h"
#include "utils.h"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

#include <Akonadi/FreeBusyManager>
#include <akonadi/calendarsettings.h> //krazy:exclude=camelcase this is a generated file

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr);

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
}

#include "moc_calendarplugin.cpp"
