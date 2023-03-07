// SPDX-FileCopyrightText: 2022 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactsmodel.h"
#include <akonadi/entitytreemodel.h>

#include <Akonadi/ContactsFilterProxyModel>
#include <Akonadi/ContactsTreeModel>
#include <Akonadi/EmailAddressSelectionModel>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <KContacts/Addressee>
#include <KDescendantsProxyModel>

ContactsModel::ContactsModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    auto sourceModel = new Akonadi::EmailAddressSelectionModel(this);
    auto filterModel = new Akonadi::ContactsFilterProxyModel(this);
    filterModel->setSourceModel(sourceModel->model());
    filterModel->setFilterFlags(Akonadi::ContactsFilterProxyModel::HasEmail);

    auto flatModel = new KDescendantsProxyModel(this);
    flatModel->setSourceModel(filterModel);

    auto addresseeOnlyModel = new Akonadi::EntityMimeTypeFilterModel(this);
    addresseeOnlyModel->setSourceModel(flatModel);
    addresseeOnlyModel->addMimeTypeInclusionFilter(KContacts::Addressee::mimeType());

    setSourceModel(addresseeOnlyModel);
    setDynamicSortFilter(true);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    sort(0);
}

bool ContactsModel::filterAcceptsRow(int row, const QModelIndex &sourceParent) const
{
    // Eliminate duplicate Akonadi items
    const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
    Q_ASSERT(sourceIndex.isValid());

    auto data = sourceIndex.data(Akonadi::EntityTreeModel::ItemIdRole);
    auto matches = match(index(0, 0), Akonadi::EntityTreeModel::ItemIdRole, data, 2, Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);

    return matches.length() < 1;
}

QVariant ContactsModel::data(const QModelIndex &idx, int role) const
{
    if (role == AllEmailsRole) {
        const auto item = QSortFilterProxyModel::data(idx, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.mimeType() == KContacts::Addressee::mimeType()) {
            if (!item.hasPayload<KContacts::Addressee>()) {
                return {};
            }
            const auto contact = item.payload<KContacts::Addressee>();
            return contact.emails();
        }
        return {};
    }
    if (role == EmailRole) {
        const auto item = QSortFilterProxyModel::data(idx, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.mimeType() == KContacts::Addressee::mimeType()) {
            if (!item.hasPayload<KContacts::Addressee>()) {
                return {};
            }
            const auto contact = item.payload<KContacts::Addressee>();
            return contact.preferredEmail();
        }
        return {};
    }

    if (role == GidRole) {
        const auto item = QSortFilterProxyModel::data(idx, Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();
        if (item.mimeType() == KContacts::Addressee::mimeType()) {
            if (!item.hasPayload<KContacts::Addressee>()) {
                return {};
            }
            return item.id();
        }
        return {};
    }

    return QSortFilterProxyModel::data(idx, role);
}

QHash<int, QByteArray> ContactsModel::roleNames() const
{
    auto roles = QSortFilterProxyModel::roleNames();
    roles[EmailRole] = "email";
    roles[GidRole] = "gid";
    return roles;
}
