// SPDX-FileCopyrightText: 2023 Aakarsh MJ <mj.akarsh@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

#include "mailheadermodel.h"
#include <QAbstractListModel>
#include <QList>

MailHeaderModel:: MailHeaderModel(QObject* parent)
    : QAbstractListModel(parent)
{
    HeaderItem newItem{Header::To, QString{}};
    m_headers.append(newItem);
}

QVariant MailHeaderModel::data(const QModelIndex &index, int role) const 
{
    Q_ASSERT(checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid));

    const auto &item = m_headers[index.row()];
    switch (role) {
        case Qt::DisplayRole:
        case NameRole:
            return item.header;
        case ValueRole:
            return item.value;
    } 
    return {};
}

int MailHeaderModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    return m_headers.size();
}

void MailHeaderModel::updateModel(const int row, const QString &value)
{
   Q_ASSERT(row >= 0 && row < m_headers.count());

    const auto text = value.trimmed();
    if (text.length() == 0 && row > 0 && row != rowCount() - 1) {
        // Delete row if it's empty and not the first nor the last one
        beginRemoveRows({}, row, row);
        m_headers.removeAt(row);
        endRemoveRows();
        return;
    }

    auto &header = m_headers[row];
    header.value = text;
    Q_EMIT dataChanged(index(row, 0), index(row, 0), { ValueRole });

    if (row == rowCount() - 1) {
        beginInsertRows({}, row + 1, row + 1);
        m_headers.append(HeaderItem { Header::CC, QString{} });
        endInsertRows();
    } 
}

void MailHeaderModel::updateHeaderType(const int row, const Header headerName)
{
    Q_ASSERT(row >= 0 && row < m_headers.count());

    auto &header = m_headers[row];
    header.header = headerName;
    Q_EMIT dataChanged(index(row, 0), index(row, 0), { NameRole });
}
