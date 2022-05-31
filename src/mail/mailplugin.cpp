// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailplugin.h"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

#include "mailmanager.h"
#include "mailmodel.h"

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.mail"));

    qmlRegisterSingletonType<MailManager>("org.kde.kalendar.mail", 1, 0, "MailManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailManager;
    });
    qRegisterMetaType<MailModel*>("MailModel*");
}
