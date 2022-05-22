/*
    This file is part of Akonadi Contact.

    SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

#include <Akonadi/Attribute>

#include <QVariant>

#include <memory>

class ContactMetaDataAttributePrivate;

/**
 * @short Attribute to store contact specific meta data.
 *
 * @author Tobias Koenig <tokoe@kde.org>
 */
class ContactMetaDataAttribute : public Akonadi::Attribute
{
public:
    /**
     * Creates a new contact meta data attribute.
     */
    ContactMetaDataAttribute();

    /**
     * Destroys the contact meta data attribute.
     */
    ~ContactMetaDataAttribute() override;

    /**
     * Sets the meta @p data.
     */
    void setMetaData(const QVariantMap &data);

    /**
     * Returns the meta data.
     */
    QVariantMap metaData() const;

    QByteArray type() const override;
    Akonadi::Attribute *clone() const override;
    QByteArray serialized() const override;
    void deserialize(const QByteArray &data) override;

private:
    //@cond PRIVATE
    std::unique_ptr<ContactMetaDataAttributePrivate> const d;
    //@endcond
};
