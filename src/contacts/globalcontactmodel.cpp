/*
  This file is part of KAddressBook.

  SPDX-FileCopyrightText: 2009 Tobias Koenig <tokoe@kde.org>

  SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "globalcontactmodel.h"

#include <Akonadi/ChangeRecorder>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/EntityDisplayAttribute>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Session>

#include <KContacts/Addressee>
#include <KContacts/ContactGroup>

GlobalContactModel *GlobalContactModel::mInstance = nullptr;

GlobalContactModel::GlobalContactModel()
    : mSession(new Akonadi::Session("KAddressBook::GlobalContactSession"))
    , mMonitor(new Akonadi::ChangeRecorder)
{
    Akonadi::ItemFetchScope scope;
    scope.fetchFullPayload(true);
    scope.fetchAttribute<Akonadi::EntityDisplayAttribute>();

    mMonitor->setSession(mSession);
    mMonitor->fetchCollection(true);
    mMonitor->setItemFetchScope(scope);
    mMonitor->setCollectionMonitored(Akonadi::Collection::root());
    mMonitor->setMimeTypeMonitored(KContacts::Addressee::mimeType(), true);
    mMonitor->setMimeTypeMonitored(KContacts::ContactGroup::mimeType(), true);

    mModel = new Akonadi::ContactsTreeModel(mMonitor);
}

GlobalContactModel::~GlobalContactModel()
{
    delete mModel;
    delete mMonitor;
    delete mSession;
}

GlobalContactModel *GlobalContactModel::instance()
{
    if (!mInstance) {
        mInstance = new GlobalContactModel();
    }
    return mInstance;
}

Akonadi::ContactsTreeModel *GlobalContactModel::model() const
{
    return mModel;
}
