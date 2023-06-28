// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailplugin.h"

#include <QQmlEngine>

#include "contactimageprovider.h"
#include "helper.h"
#include "mailmanager.h"
#include "mailmodel.h"
#include "mime/htmlutils.h"
#include "mime/messageparser.h"
#include "mailheadermodel.h"
#include "identitymodel.h"


void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.mail"));

    qmlRegisterSingletonType<MailManager>("org.kde.kalendar.mail", 1, 0, "MailManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailManager;
    });

    qmlRegisterSingletonType<HtmlUtils::HtmlUtils>("org.kde.kalendar.mail", 1, 0, "HtmlUtils", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new HtmlUtils::HtmlUtils;
    });

    qmlRegisterSingletonType<MailCollectionHelper>("org.kde.kalendar.mail", 1, 0, "MailCollectionHelper", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new MailCollectionHelper;
    });

    qmlRegisterType<MailHeaderModel>("org.kde.kalendar.mail", 1, 0, "MailHeaderModel");
    qmlRegisterType<MessageParser>(uri, 1, 0, "MessageParser");
    qmlRegisterType<IdentityModel>(uri, 1, 0, "IdentityModel");

    qRegisterMetaType<MailModel *>("MailModel*");
}

void CalendarPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(uri);
    engine->addImageProvider(QLatin1String("contact"), new ContactImageProvider);
}

#include "moc_mailplugin.cpp"
