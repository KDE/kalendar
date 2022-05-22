// SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QVariant>

namespace Akonadi
{
class Item;
}

/**
 * @short A helper class for storing contact specific settings.
 */
class ContactMetaData
{
public:
    /**
     * Creates a contact meta data object.
     */
    ContactMetaData();

    /**
     * Destroys the contact meta data object.
     */
    ~ContactMetaData();

    /**
     * Loads the meta data for the given @p contact.
     */
    void load(const Akonadi::Item &contact);

    /**
     * Stores the meta data to the given @p contact.
     */
    void store(Akonadi::Item &contact);

    /**
     * Loads the meta data for the given @p contact.
     */
    void loadMetaData(const QVariantMap &metaData);

    /**
     * Stores the meta data to the given @p contact.
     */
    Q_REQUIRED_RESULT QVariantMap storeMetaData() const;

    /**
     * Sets the mode that is used for the display
     * name of that contact.
     */
    void setDisplayNameMode(int mode);

    /**
     * Returns the mode that is used for the display
     * name of that contact.
     */
    Q_REQUIRED_RESULT int displayNameMode() const;

    /**
     * Sets the @p descriptions of the custom fields of that contact.
     * @param descriptions the descriptions to set
     * The description list contains a QVariantMap for each custom field
     * with the following keys:
     *   - key   (string) The identifier of the field
     *   - title (string) The i18n'ed title of the field
     *   - type  (string) The type description of the field
     *     Possible values for type description are
     *       - text
     *       - numeric
     *       - boolean
     *       - date
     *       - time
     *       - datetime
     */
    void setCustomFieldDescriptions(const QVariantList &descriptions);

    /**
     * Returns the descriptions of the custom fields of the contact.
     */
    Q_REQUIRED_RESULT QVariantList customFieldDescriptions() const;

private:
    int m_displayNameMode = -1;
    QVariantList m_customFieldDescriptions;
};
