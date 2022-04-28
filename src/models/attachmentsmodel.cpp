// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "attachmentsmodel.h"
#include "kalendar_debug.h"
#include <QDebug>
#include <QMetaEnum>

AttachmentsModel::AttachmentsModel(QObject *parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
{
    for (int i = 0; i < QMetaEnum::fromType<AttachmentsModel::Roles>().keyCount(); i++) {
        const int value = QMetaEnum::fromType<AttachmentsModel::Roles>().value(i);
        const QString key = QLatin1String(roleNames().value(value));
        m_dataRoles[key] = value;
    }
}

KCalendarCore::Incidence::Ptr AttachmentsModel::incidencePtr()
{
    return m_incidence;
}

void AttachmentsModel::setIncidencePtr(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    m_incidence = incidence;
    Q_EMIT incidencePtrChanged();
    Q_EMIT attachmentsChanged();
    Q_EMIT layoutChanged();
}

KCalendarCore::Attachment::List AttachmentsModel::attachments()
{
    return m_incidence->attachments();
}

QVariantMap AttachmentsModel::dataroles()
{
    return m_dataRoles;
}

QVariant AttachmentsModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    KCalendarCore::Attachment attachment = m_incidence->attachments()[idx.row()];
    switch (role) {
    case AttachmentRole:
        return QVariant::fromValue(attachment);
    case LabelRole:
        return attachment.label();
    case MimeTypeRole:
        return attachment.mimeType();
    case IconNameRole: {
        QMimeType type = m_mimeDb.mimeTypeForUrl(QUrl(attachment.uri()));
        return type.iconName();
    }
    case DataRole:
        return attachment.data(); // This is in bytes
    case SizeRole:
        return attachment.size();
    case URIRole:
        return attachment.uri();
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for attachment:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

QHash<int, QByteArray> AttachmentsModel::roleNames() const
{
    return {
        {AttachmentRole, QByteArrayLiteral("attachment")},
        {LabelRole, QByteArrayLiteral("attachmentLabel")},
        {MimeTypeRole, QByteArrayLiteral("mimetype")},
        {IconNameRole, QByteArrayLiteral("iconName")},
        {DataRole, QByteArrayLiteral("data")},
        {SizeRole, QByteArrayLiteral("size")},
        {URIRole, QByteArrayLiteral("uri")},
    };
}

int AttachmentsModel::rowCount(const QModelIndex &) const
{
    return m_incidence->attachments().size();
}

void AttachmentsModel::addAttachment(const QString &uri)
{
    const QMimeType type = m_mimeDb.mimeTypeForUrl(QUrl(uri));

    KCalendarCore::Attachment attachment(uri);
    attachment.setLabel(QUrl(uri).fileName());
    attachment.setMimeType(type.name());
    m_incidence->addAttachment(attachment);

    Q_EMIT attachmentsChanged();
    Q_EMIT layoutChanged();
}

void AttachmentsModel::deleteAttachment(const QString &uri)
{
    KCalendarCore::Attachment::List attachments = m_incidence->attachments();

    for (const auto &attachment : attachments) {
        if (attachment.uri() == uri) {
            attachments.removeAll(attachment);
            break;
        }
    }

    m_incidence->clearAttachments();

    for (const auto &attachment : attachments) {
        m_incidence->addAttachment(attachment);
    }

    Q_EMIT attachmentsChanged();
    Q_EMIT layoutChanged();
}
