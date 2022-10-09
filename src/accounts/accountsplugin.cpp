// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "accountsplugin.h"

#include <QQmlEngine>

#include "mailaccounts.h"
#include "newaccount.h"

void AccountsPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.accounts"));

    qmlRegisterSingletonType<MailAccounts>("org.kde.kalendar.accounts", 1, 0, "MailAccounts", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine)
        return new MailAccounts;
    });

    qmlRegisterType<NewAccount>("org.kde.kalendar.accounts", 1, 0, "NewAccount");
}
