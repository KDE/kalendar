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
class ContactGroupEditorPrivate;
class QAbstractItemModel;

/**
 * @short An object to edit contact groups in Akonadi.
 *
 * This object provides a way to create a new contact group or edit
 * an existing contact group in Akonadi from QML.
 *
 * Example for creating a new contact:
 *
 * @code{.qml}
 * ContactGroupEditor {
 *     id: contactGroupEditor
 *     mode: ContactGroupEditor.CreateMode
 * }
 *
 * TextField {
 *     id: nameField
 *     onTextChanged. contactEditor.addressee.name = text
 * }
 *
 * Button {
 *     onClicked: contactEditor.saveContactGroup()
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
class ContactGroupEditor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Mode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(qint64 collectionId READ collectionId NOTIFY collectionChanged)
    Q_PROPERTY(bool isReadOnly READ isReadOnly NOTIFY isReadOnlyChanged)
    Q_PROPERTY(QAbstractItemModel *groupModel READ groupModel CONSTANT)
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
     * Creates a new contact group editor backend.
     *
     * @param parent The parent object of the editor.
     */
    explicit ContactGroupEditor(QObject *parent = nullptr);

    /**
     * Destroys the contact editor.
     */
    ~ContactGroupEditor() override;

    /**
     * Sets the @p addressbook which shall be used to store new
     * contacts.
     */
    Q_INVOKABLE void setDefaultAddressBook(const Akonadi::Collection &addressbook);

    Q_INVOKABLE void loadContactGroup(const Akonadi::Item &item);
    /**
     * Save the contact group from the editor back to the storage. And return error.
     * Need to connect to finished() signal, to keep time to Q_EMIT signal.
     */
    Q_INVOKABLE bool saveContactGroup();

    [[nodiscard]] bool hasNoSavedData() const;

    [[nodiscard]] qint64 collectionId() const;
    [[nodiscard]] Mode mode() const;
    void setMode(Mode mode);
    [[nodiscard]] bool isReadOnly() const;
    void setReadOnly(bool isReadOnly);

    QString name() const;
    void setName(const QString &name);
    QAbstractItemModel *groupModel() const;

    Q_INVOKABLE void fetchItem();

Q_SIGNALS:
    /**
     * This signal is emitted when the @p contact has been saved back
     * to the storage.
     */
    void contactGroupStored(const Akonadi::Item &contact);

    /**
     * This signal is emitted when an error occurred during the save.
     * @param errorMsg The error message.
     */
    void errorOccured(const QString &errorMsg);

    /**
     * @brief finished
     */
    void finished();

    void modeChanged();
    void isReadOnlyChanged();
    void nameChanged();
    void itemChanged();
    void collectionChanged();
    void itemChangedExternally();

private:
    std::unique_ptr<ContactGroupEditorPrivate> d;
};
