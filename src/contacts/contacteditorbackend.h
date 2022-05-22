// This file is part of Akonadi Contact.
// SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "contactmetadata.h"
#include <Akonadi/Collection>
#include <Akonadi/Item>
#include <QObject>

namespace KContacts
{
class Addressee;
}

namespace Akonadi
{
class Monitor;
}

class AddresseeWrapper;

/**
 * @short An object to edit contacts in Akonadi.
 *
 * This object provides a way to create a new contact or edit
 * an existing contact in Akonadi from QML.
 *
 * Example for creating a new contact:
 *
 * @code{.qml}
 * ContactEditor {
 *     id: contactEditor
 *     mode: ContactEditor.CreateMode
 * }
 *
 * TextField {
 *     id: nameField
 *     onTextChanged. contactEditor.addressee.name = text
 * }
 *
 * Button {
 *     onClicked: contactEditor.saveContactInAddressBook()
 * }
 * @endcode
 *
 * Example for editing an existing contact:
 *
 * @code
 *
 * ContactEditor {
 *     id: contactEditor
 *     mode: ContactEditor.EditMode
 *     item: myExistingItem
 * }
 *
 * TextField {
 *     id: nameField
 *     onTextChanged. contactEditor.addressee.name = text
 * }
 *
 * Button {
 *     onClicked: contactEditor.saveContactInAddressBook()
 * }
 *
 * @endcode
 *
 * @author Tobias Koenig <tokoe@kde.org>
 * @author Carl Schwan <carl@carlschwan.eu>
 */
class ContactEditorBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Mode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(AddresseeWrapper *contact READ contact NOTIFY addresseeChanged NOTIFY modeChanged)

public:
    /**
     * Describes the mode of the editor.
     */
    enum Mode {
        CreateMode, ///< Creates a new contact
        EditMode ///< Edits an existing contact
    };
    Q_ENUM(Mode);

    /**
     * Creates a new contact editor backend.
     *
     * @param parent The parent object of the editor.
     */
    explicit ContactEditorBackend(QObject *parent = nullptr);

    /**
     * Destroys the contact editor.
     */
    ~ContactEditorBackend() override;

    /**
     * Sets the @p addressbook which shall be used to store new
     * contacts.
     */
    void setDefaultAddressBook(const Akonadi::Collection &addressbook);

    [[nodiscard]] bool hasNoSavedData() const;

    [[nodiscard]] AddresseeWrapper *contact();
    [[nodiscard]] Mode mode() const;
    void setMode(Mode mode);

    /**
     * Loads the @p contact into the editor.
     */
    Q_INVOKABLE void loadContact(const Akonadi::Item &contact);

    /**
     * Save the contact from the editor back to the storage. And return error.
     * Need to connect to finished() signal, to keep time to Q_EMIT signal.
     */
    Q_INVOKABLE void saveContactInAddressBook();

Q_SIGNALS:
    /**
     * This signal is emitted when the @p contact has been saved back
     * to the storage.
     */
    void contactStored(const Akonadi::Item &contact);

    /**
     * This signal is emitted when an error occurred during the save.
     * @param errorMsg The error message.
     * @since 4.11
     */
    void error(const QString &errorMsg);

    /**
     * @brief finished
     * @since 4.11
     */
    void finished();

    void addresseeChanged();
    void modeChanged();

private:
    void itemFetchDone(KJob *job);
    void parentCollectionFetchDone(KJob *job);
    void storeDone(KJob *job);
    void loadContact(const KContacts::Addressee &contact, const ContactMetaData &metaData);
    void setupMonitor();
    void itemChanged(const Akonadi::Item &item, const QSet<QByteArray> &);
    void storeContact(KContacts::Addressee &contact, ContactMetaData &metaData) const;

    Akonadi::Item m_item;
    Akonadi::Collection m_defaltAddressBook;
    AddresseeWrapper *m_addressee = nullptr;
    Mode m_mode;
    bool m_readOnly;
    ContactMetaData m_contactMetaData;
    Akonadi::Monitor *m_monitor = nullptr;
};
