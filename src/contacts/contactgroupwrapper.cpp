// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactgroupwrapper.h"

#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/Session>
#include <Akonadi/ItemMonitor>
#include <QAbstractListModel>
#include <akonadi/itemmonitor.h>
#include "contactgroupmodel.h"

using namespace Akonadi;

ContactGroupWrapper::ContactGroupWrapper(QObject *parent)
    : QObject(parent)
    , Akonadi::ItemMonitor()
    , m_model(new ContactGroupModel(false, this))
{
    Akonadi::ItemFetchScope scope;
    scope.fetchFullPayload();
    scope.fetchAllAttributes();
    scope.setFetchRelations(true);
    scope.setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
    setFetchScope(scope);

    KContacts::ContactGroup dummyGroup;
    m_model->loadContactGroup(dummyGroup);
}

void ContactGroupWrapper::itemChanged(const Akonadi::Item &item)
{
    const auto group = item.payload<KContacts::ContactGroup>();
    loadContactGroup(group);
}

QString ContactGroupWrapper::name() const
{
    return m_name;
}

QAbstractListModel *ContactGroupWrapper::model() const
{
    return (QAbstractListModel *)m_model;
}

Akonadi::Item ContactGroupWrapper::item() const
{
    return m_item;
}

void ContactGroupWrapper::setItem(const Akonadi::Item &item)
{
    ItemMonitor::setItem(item);
    m_item = item;
    auto job = new ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();
    job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);

    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        itemFetchDone(job);
    });
}

void ContactGroupWrapper::itemFetchDone(KJob *job)
{
    if (job->error()) {
        return;
    }

    auto fetchJob = qobject_cast<ItemFetchJob *>(job);
    if (!fetchJob) {
        return;
    }

    if (fetchJob->items().isEmpty()) {
        return;
    }

    m_item = fetchJob->items().at(0);

    const auto group = m_item.payload<KContacts::ContactGroup>();
    loadContactGroup(group);
}

void ContactGroupWrapper::loadContactGroup(const KContacts::ContactGroup &group)
{
    setName(group.name());
    m_model->loadContactGroup(group);
}

void ContactGroupWrapper::setName(const QString &name)
{
    if (m_name == name) {
        return;
    }
    m_name = name;
    Q_EMIT nameChanged();
}
