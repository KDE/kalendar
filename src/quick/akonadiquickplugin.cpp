// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "akonadiquickplugin.h"

#include "mimetypes.h"
#include "collection.h"
#include "collectioncomboboxmodel.h"
#include <akonadi_version.h>

#include <Akonadi/Collection>
#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

void AkonadiQuickPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.akonadi"));

    qmlRegisterSingletonType<Akonadi::Quick::MimeTypes>("org.kde.akonadi", 1, 0, "MimeTypes", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new Akonadi::Quick::MimeTypes;
    });

    qmlRegisterType<Akonadi::Quick::CollectionComboBoxModel>("org.kde.akonadi", 1, 0, "CollectionComboBoxModel");

#if AKONADI_VERSION > QT_VERSION_CHECK(5, 20, 41)
    qmlRegisterUncreatableType<Akonadi::Collection>("org.kde.akonadi", 1, 0, "Collection", QStringLiteral("It's just an enum"));
#else
    qmlRegisterUncreatableType<Akonadi::Quick::Collection>("org.kde.akonadi", 1, 0, "Collection", QStringLiteral("It's just an enum"));
#endif
}
