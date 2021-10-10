// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>

#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#else
#include <AkonadiCore/ItemFetchJob>
#include <AkonadiCore/ItemFetchScope>
#endif
#include <KCalendarCore/Incidence>
#include <itemtagsmodel.h>

ItemTagsModel::ItemTagsModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

Akonadi::Item ItemTagsModel::item() const
{
    return m_item;
}

void ItemTagsModel::setItem(Akonadi::Item item)
{
    Q_EMIT layoutAboutToBeChanged();
    m_item = item;
    Q_EMIT itemChanged();
    Q_EMIT layoutChanged();
}

int ItemTagsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_item.tags().count();
}

QVariant ItemTagsModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    const auto tag = m_item.tags().at(idx.row());

    switch (role) {
    case NameRole:
        return tag.name();
    case IdRole:
        return tag.id();
    default:
        qWarning() << "Unknown role for item tag:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

QHash<int, QByteArray> ItemTagsModel::roleNames() const
{
    return {
        {NameRole, QByteArrayLiteral("name")},
        {IdRole, QByteArrayLiteral("id")},
    };
}
