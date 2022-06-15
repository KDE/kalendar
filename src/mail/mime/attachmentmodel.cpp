// SPDX-FileCopyrightText: 2016 Sandro Knauß <knauss@kolabsys.com>
// SPDX-FileCopyCopyright: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "attachmentmodel.h"

#include "../mimetreeparser/objecttreeparser.h"
#include "mailcrypto.h"
#include <QString>

#include <KLocalizedString>
#include <KMime/Content>
#include <QDebug>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QUrl>

#include <memory>
#include <qstringliteral.h>

QString sizeHuman(float size)
{
    QStringList list;
    list << QStringLiteral("KB") << QStringLiteral("MB") << QStringLiteral("GB") << QStringLiteral("TB");

    QStringListIterator i(list);
    QString unit = QStringLiteral("Bytes");

    while (size >= 1024.0 && i.hasNext()) {
        unit = i.next();
        size /= 1024.0;
    }

    if (unit == QStringLiteral("Bytes")) {
        return QString().setNum(size) + QStringLiteral(" ") + unit;
    } else {
        return QString().setNum(size, 'f', 2) + QStringLiteral(" ") + unit;
    }
}

class AttachmentModelPrivate
{
public:
    AttachmentModelPrivate(AttachmentModel *q_ptr, const std::shared_ptr<MimeTreeParser::ObjectTreeParser> &parser);

    AttachmentModel *q;
    std::shared_ptr<MimeTreeParser::ObjectTreeParser> mParser;
    QVector<MimeTreeParser::MessagePartPtr> mAttachments;
};

AttachmentModelPrivate::AttachmentModelPrivate(AttachmentModel *q_ptr, const std::shared_ptr<MimeTreeParser::ObjectTreeParser> &parser)
    : q(q_ptr)
    , mParser(parser)
{
    mAttachments = mParser->collectAttachmentParts();
}

AttachmentModel::AttachmentModel(std::shared_ptr<MimeTreeParser::ObjectTreeParser> parser)
    : d(std::unique_ptr<AttachmentModelPrivate>(new AttachmentModelPrivate(this, parser)))
{
}

AttachmentModel::~AttachmentModel()
{
}

QHash<int, QByteArray> AttachmentModel::roleNames() const
{
    return {
        {TypeRole, QByteArrayLiteral("type")},
        {NameRole, QByteArrayLiteral("name")},
        {SizeRole, QByteArrayLiteral("size")},
        {IconRole, QByteArrayLiteral("iconName")},
        {IsEncryptedRole, QByteArrayLiteral("encrypted")},
        {IsSignedRole, QByteArrayLiteral("signed")},
    };
}

QModelIndex AttachmentModel::index(int row, int column, const QModelIndex &) const
{
    if (row < 0 || column != 0) {
        return {};
    }

    if (row < d->mAttachments.size()) {
        return createIndex(row, column, d->mAttachments.at(row).data());
    }
    return {};
}

QVariant AttachmentModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        switch (role) {
        case Qt::DisplayRole:
            return QLatin1String("root");
        }
        return {};
    }

    if (index.internalPointer()) {
        const auto part = static_cast<MimeTreeParser::MessagePart *>(index.internalPointer());
        Q_ASSERT(part);
        auto node = part->node();
        if (!node) {
            qWarning() << "no content for attachment";
            return {};
        }
        QMimeDatabase mimeDb;
        const auto mimetype = mimeDb.mimeTypeForName(QString::fromLatin1(part->mimeType()));
        const auto content = node->encodedContent();
        switch (role) {
        case TypeRole:
            return mimetype.name();
        case NameRole:
            return part->filename();
        case IconRole:
            return mimetype.iconName();
        case SizeRole:
            return sizeHuman(content.size());
        case IsEncryptedRole:
            return part->encryptions().size() > 0;
        case IsSignedRole:
            return part->signatures().size() > 0;
        }
    }
    return QVariant();
}

static QString saveAttachmentToDisk(const QModelIndex &index, const QString &path, bool readonly = false)
{
    if (index.internalPointer()) {
        const auto part = static_cast<MimeTreeParser::MessagePart *>(index.internalPointer());
        Q_ASSERT(part);
        auto node = part->node();
        auto data = node->decodedContent();
        // This is necessary to store messages embedded messages (EncapsulatedRfc822MessagePart)
        if (data.isEmpty()) {
            data = node->encodedContent();
        }
        if (part->isText()) {
            // convert CRLF to LF before writing text attachments to disk
            data = KMime::CRLFtoLF(data);
        }
        const auto name = part->filename();
        QString fname = path + name;

        // Fallback name should we end up with an empty name
        if (name.isEmpty()) {
            fname = path + QStringLiteral("unnamed");
            while (QFileInfo{fname}.exists()) {
                fname = fname + QStringLiteral("_1");
            }
        }

        // A file with that name already exists, we assume it's the right file
        if (QFileInfo{fname}.exists()) {
            return fname;
        }
        QFile f(fname);
        if (!f.open(QIODevice::ReadWrite)) {
            qWarning() << "Failed to write attachment to file:" << fname << " Error: " << f.errorString();
            // Kube::Fabric::Fabric{}.postMessage("notification", {{"message", QObject::tr("Failed to save attachment.")}});
            return {};
        }
        f.write(data);
        if (readonly) {
            // make file read-only so that nobody gets the impression that he migh edit attached files
            f.setPermissions(QFileDevice::ReadUser);
        }
        f.close();
        qInfo() << "Wrote attachment to file: " << fname;
        return fname;
    }
    return {};
}

bool AttachmentModel::saveAttachmentToDisk(const QModelIndex &index)
{
    auto downloadDir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (downloadDir.isEmpty()) {
        downloadDir = QStringLiteral("~");
    }
    downloadDir += QStringLiteral("/kalendar/");
    QDir{}.mkpath(downloadDir);

    auto path = ::saveAttachmentToDisk(index, downloadDir);
    if (path.isEmpty()) {
        return false;
    }
    // Kube::Fabric::Fabric{}.postMessage("notification", {{"message", tr("Saved the attachment to disk: %1").arg(path)}});
    return true;
}

bool AttachmentModel::openAttachment(const QModelIndex &index)
{
    auto downloadDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + QStringLiteral("/kalendar/");
    QDir{}.mkpath(downloadDir);
    const auto filePath = ::saveAttachmentToDisk(index, downloadDir, true);
    if (!filePath.isEmpty()) {
        if (!QDesktopServices::openUrl(QUrl(QStringLiteral("file://") + filePath))) {
            // Kube::Fabric::Fabric{}.postMessage("notification", {{"message", tr("Failed to open attachment.")}});
            return false;
        }
        return true;
    }
    // Kube::Fabric::Fabric{}.postMessage("notification", {{"message", tr("Failed to save attachment for opening.")}});
    return false;
}

bool AttachmentModel::importPublicKey(const QModelIndex &index)
{
    Q_ASSERT(index.internalPointer());
    const auto part = static_cast<MimeTreeParser::MessagePart *>(index.internalPointer());
    Q_ASSERT(part);
    auto result = Crypto::importKey(Crypto::OpenPGP, part->node()->decodedContent());

    bool success = true;
    QString message;
    if (result.considered == 0) {
        message = i18n("No keys were found in this attachment");
        success = false;
    } else {
        message = i18np("one key imported", "%1 keys imported", result.imported);
        if (result.unchanged != 0) {
            message += QStringLiteral("\n") + i18np("one key was already imported", "%1 keys were already imported", result.unchanged);
        }
    }

    // Kube::Fabric::Fabric{}.postMessage("notification", {{"message", message}});

    return success;
}

QModelIndex AttachmentModel::parent(const QModelIndex &) const
{
    return {};
}

int AttachmentModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid()) {
        return d->mAttachments.size();
    }
    return 0;
}

int AttachmentModel::columnCount(const QModelIndex &) const
{
    return 1;
}
