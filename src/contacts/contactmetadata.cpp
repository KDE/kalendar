// SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "contactmetadata.h"

#include "attributes/contactmetadataattribute_p.h"

#include <Akonadi/Item>

using namespace Akonadi;

ContactMetaData::ContactMetaData() = default;

ContactMetaData::~ContactMetaData() = default;

void ContactMetaData::load(const Akonadi::Item &contact)
{
    if (!contact.hasAttribute("contactmetadata")) {
        return;
    }
    const auto attribute = contact.attribute<ContactMetaDataAttribute>();
    const QVariantMap metaData = attribute->metaData();
    loadMetaData(metaData);
}

void ContactMetaData::store(Akonadi::Item &contact)
{
    auto attribute = contact.attribute<ContactMetaDataAttribute>(Item::AddIfMissing);

    attribute->setMetaData(storeMetaData());
}

void ContactMetaData::loadMetaData(const QVariantMap &metaData)
{
    m_displayNameMode = metaData.value(QStringLiteral("DisplayNameMode"), -1).toInt();

    m_customFieldDescriptions = metaData.value(QStringLiteral("CustomFieldDescriptions")).toList();
}

QVariantMap ContactMetaData::storeMetaData() const
{
    QVariantMap metaData;
    if (m_displayNameMode != -1) {
        metaData.insert(QStringLiteral("DisplayNameMode"), QVariant(m_displayNameMode));
    }

    if (m_customFieldDescriptions.isEmpty()) {
        metaData.insert(QStringLiteral("CustomFieldDescriptions"), m_customFieldDescriptions);
    }
    return metaData;
}

void ContactMetaData::setDisplayNameMode(int mode)
{
    m_displayNameMode = mode;
}

int ContactMetaData::displayNameMode() const
{
    return m_displayNameMode;
}

void ContactMetaData::setCustomFieldDescriptions(const QVariantList &descriptions)
{
    m_customFieldDescriptions = descriptions;
}

QVariantList ContactMetaData::customFieldDescriptions() const
{
    return m_customFieldDescriptions;
}
