// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "componentsplugin.h"

#include <QQmlEngine>
#include <QtQml>

#include "navigation.h"

void ComponentsPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.components"));

    qmlRegisterSingletonType<Navigation>(uri, 1, 0, "Navigation", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Navigation;
    });
}
