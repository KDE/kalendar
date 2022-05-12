// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactplugin.h"
#include "addresseewrapper.h"
#include "addressmodel.h"
#include "contactcollectionmodel.h"
#include "contactmanager.h"
#include "emailmodel.h"
#include "globalcontactmodel.h"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.contact"));

    qmlRegisterSingletonType<ContactManager>("org.kde.kalendar.contact", 1, 0, "ContactManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new ContactManager;
    });

    qmlRegisterType<AddresseeWrapper>("org.kde.kalendar.contact", 1, 0, "AddresseeWrapper");
    qRegisterMetaType<KContacts::Picture>("KContacts::Picture");
    qRegisterMetaType<KContacts::PhoneNumber::List>("KContacts::PhoneNumber::List");
    qRegisterMetaType<KContacts::PhoneNumber>("KContacts::PhoneNumber");
}
