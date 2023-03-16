// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "calendarplugin.h"
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
    qmlRegisterType<RemindersModel>(uri, 1, 0, "RemindersModel");
    qmlRegisterModule(uri, 1, 0);
    qRegisterMetaType<KCalendarCore::Incidence::Ptr>();
}
