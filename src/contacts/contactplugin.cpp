// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactplugin.h"
#include "addresseewrapper.h"
#include "addressmodel.h"
#include "contactcollectionmodel.h"
#include "contacteditorbackend.h"
#include "contactgroupeditor.h"
#include "contactgroupwrapper.h"
#include "contactmanager.h"
#include "contactsmodel.h"
#include "emailmodel.h"
#include "globalcontactmodel.h"
#include "contactconfig.h"

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QtQml>

void CalendarPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QByteArray("org.kde.kalendar.contact"));

    qmlRegisterSingletonType<ContactConfig>("org.kde.kalendar.contact", 1, 0, "ContactConfig", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new ContactConfig;
    });

    qmlRegisterSingletonType<ContactManager>("org.kde.kalendar.contact", 1, 0, "ContactManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return new ContactManager;
    });

    qmlRegisterUncreatableType<EmailModel>("org.kde.kalendar.contact", 1, 0, "EmailModel", QStringLiteral("Enum"));
    qmlRegisterUncreatableType<PhoneModel>("org.kde.kalendar.contact", 1, 0, "PhoneModel", QStringLiteral("Enum"));
    qmlRegisterType<AddresseeWrapper>("org.kde.kalendar.contact", 1, 0, "AddresseeWrapper");
    qmlRegisterType<ContactEditorBackend>("org.kde.kalendar.contact", 1, 0, "ContactEditor");
    qmlRegisterType<ContactGroupWrapper>("org.kde.kalendar.contact", 1, 0, "ContactGroupWrapper");
    qmlRegisterType<ContactGroupEditor>("org.kde.kalendar.contact", 1, 0, "ContactGroupEditor");
    qmlRegisterType<ContactsModel>("org.kde.kalendar.contact", 1, 0, "ContactsModel");
    qRegisterMetaType<KContacts::Picture>("KContacts::Picture");
    qRegisterMetaType<KContacts::PhoneNumber::List>("KContacts::PhoneNumber::List");
    qRegisterMetaType<KContacts::PhoneNumber>("KContacts::PhoneNumber");
}
