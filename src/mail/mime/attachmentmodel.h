// SPDX-FileCopyrightText: 2016 Sandro Knauß <knauss@kolabsys.com>
// SPDX-FileCopyCopyright: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>

#include <QAbstractItemModel>
#include <QModelIndex>

#include <memory>

namespace MimeTreeParser
{
class ObjectTreeParser;
}
class AttachmentModelPrivate;

class AttachmentModel : public QAbstractItemModel
{
    Q_OBJECT
public:
    AttachmentModel(std::shared_ptr<MimeTreeParser::ObjectTreeParser> parser);
    ~AttachmentModel();

public:
    enum Roles { TypeRole = Qt::UserRole + 1, IconRole, NameRole, SizeRole, IsEncryptedRole, IsSignedRole };

    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    QModelIndex parent(const QModelIndex &index) const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    int columnCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;

    Q_INVOKABLE bool saveAttachmentToDisk(const QModelIndex &parent);
    Q_INVOKABLE bool openAttachment(const QModelIndex &index);

    Q_INVOKABLE bool importPublicKey(const QModelIndex &index);

private:
    std::unique_ptr<AttachmentModelPrivate> d;
};
