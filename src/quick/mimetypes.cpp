// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mimetypes.h"

#include <KContacts/Addressee>
#include <KContacts/ContactGroup>

using namespace Akonadi::Quick;

MimeTypes::MimeTypes(QObject *parent)
    : QObject(parent)
{
}

QString MimeTypes::calendar() const
{
    return QStringLiteral("application/x-vnd.akonadi.calendar.event");
}

QString MimeTypes::todo() const
{
    return QStringLiteral("application/x-vnd.akonadi.calendar.todo");
}

QString MimeTypes::address() const
{
    return KContacts::Addressee::mimeType();
}

QString MimeTypes::contactGroup() const
{
    return KContacts::ContactGroup::mimeType();
}

QString MimeTypes::mail() const
{
    return QStringLiteral("message/rfc822");
}
