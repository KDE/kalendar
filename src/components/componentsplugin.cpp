// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "componentsplugin.h"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

void ComponentsPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.components"));
    qmlRegisterModule(uri, 1, 0);
}
