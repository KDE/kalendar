// This file is part of KAddressBook.
//  SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>
//  SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

namespace Akonadi
{
class ChangeRecorder;
class ContactsTreeModel;
class Monitor;
class Session;
}

/**
 * @short Provides the global model for all contacts
 *
 * This model provides the EntityTreeModel for all contacts.
 * The model is accessible via the static instance() method.
 */
class GlobalContactModel
{
public:
    /**
     * Destroys the global contact model.
     */
    ~GlobalContactModel();

    /**
     * Returns the global contact model instance.
     */
    static GlobalContactModel *instance();

    /**
     * Returns the item model of the global instance.
     */
    Akonadi::ContactsTreeModel *model() const;

private:
    GlobalContactModel();

    static GlobalContactModel *mInstance;

    Akonadi::Session *const mSession;
    Akonadi::ChangeRecorder *const mMonitor;
    Akonadi::ContactsTreeModel *mModel = nullptr;
};
