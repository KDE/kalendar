/*
    This file is part of Akonadi Contact.

    SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "contactmetadataattribute_p.h"

#include <QDataStream>
#include <QIODevice>

class ContactMetaDataAttributePrivate
{
public:
    QVariantMap mData;
};

ContactMetaDataAttribute::ContactMetaDataAttribute()
    : d(new ContactMetaDataAttributePrivate)
{
}

ContactMetaDataAttribute::~ContactMetaDataAttribute() = default;

void ContactMetaDataAttribute::setMetaData(const QVariantMap &data)
{
    d->mData = data;
}

QVariantMap ContactMetaDataAttribute::metaData() const
{
    return d->mData;
}

QByteArray ContactMetaDataAttribute::type() const
{
    static const QByteArray sType("contactmetadata");
    return sType;
}

Akonadi::Attribute *ContactMetaDataAttribute::clone() const
{
    auto copy = new ContactMetaDataAttribute;
    copy->setMetaData(d->mData);

    return copy;
}

QByteArray ContactMetaDataAttribute::serialized() const
{
    QByteArray data;
    QDataStream s(&data, QIODevice::WriteOnly);
    s.setVersion(QDataStream::Qt_4_5);
    s << d->mData;

    return data;
}

void ContactMetaDataAttribute::deserialize(const QByteArray &data)
{
    QDataStream s(data);
    s.setVersion(QDataStream::Qt_4_5);
    s >> d->mData;
}
