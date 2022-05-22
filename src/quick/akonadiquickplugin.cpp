// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "akonadiquickplugin.h"

#include "mimetypes.h"
#include "collection.h"
#include "collectioncomboboxmodel.h"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

void AkonadiQuickPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.akonadi.quick"));

    qmlRegisterSingletonType<Akonadi::Quick::MimeTypes>("org.kde.akonadi.quick", 1, 0, "MimeTypes", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Akonadi::Quick::MimeTypes;
    });

    qmlRegisterType<Akonadi::Quick::CollectionComboBoxModel>("org.kde.akonadi.quick", 1, 0, "CollectionComboBoxModel");
    qmlRegisterUncreatableType<Akonadi::Quick::Collection>("org.kde.akonadi.quick", 1, 0, "Collection", QStringLiteral("It's just an enum"));
}
