// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include "attachmentsmodel.h"

AttachmentsModel::AttachmentsModel(QObject* parent, KCalendarCore::Event::Ptr eventPtr)
    : QAbstractListModel(parent)
    , m_event(eventPtr)
{
    for(int i = 0; i < QMetaEnum::fromType<AttachmentsModel::Roles>().keyCount(); i++) {
        int value = QMetaEnum::fromType<AttachmentsModel::Roles>().value(i);
        QString key = QLatin1String(roleNames()[value]);
        m_dataRoles[key] = value;
    }

}

KCalendarCore::Event::Ptr AttachmentsModel::eventPtr()
{
    return m_event;
}

void AttachmentsModel::setEventPtr(KCalendarCore::Event::Ptr event)
{
    if (m_event == event) {
        return;
    }
    m_event = event;
    Q_EMIT eventPtrChanged();
    Q_EMIT attachmentsChanged();
    Q_EMIT layoutChanged();
}

KCalendarCore::Attachment::List AttachmentsModel::attachments()
{
    return m_event->attachments();
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

    KCalendarCore::Attachment attachment = m_event->attachments()[idx.row()];
    switch (role) {
        case AttachmentRole:
            return QVariant::fromValue(attachment);
        case LabelRole:
            return attachment.label();
        case MimeTypeRole:
            return attachment.mimeType();
        case IconNameRole:
        {
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
            qWarning() << "Unknown role for event:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

QHash<int, QByteArray> AttachmentsModel::roleNames() const
{
    return {
        { AttachmentRole, QByteArrayLiteral("attachment") },
        { LabelRole, QByteArrayLiteral("attachmentLabel") },
        { MimeTypeRole, QByteArrayLiteral("mimetype") },
        { IconNameRole, QByteArrayLiteral("iconName") },
        { DataRole, QByteArrayLiteral("data") },
        { SizeRole, QByteArrayLiteral("size") },
        { URIRole, QByteArrayLiteral("uri") }
    };
}

int AttachmentsModel::rowCount(const QModelIndex &) const
{
    return m_event->attachments().size();
}

void AttachmentsModel::addAttachment(QString uri)
{
    QMimeType type = m_mimeDb.mimeTypeForUrl(QUrl(uri));

    KCalendarCore::Attachment attachment(uri);
    attachment.setLabel(QUrl(uri).fileName());
    attachment.setMimeType(type.name());
    m_event->addAttachment(attachment);

    Q_EMIT attachmentsChanged();
    Q_EMIT layoutChanged();
}

void AttachmentsModel::deleteAttachment(QString uri)
{
    KCalendarCore::Attachment::List attachments = m_event->attachments();

    for(auto attachment : attachments) {
        if(attachment.uri() == uri) {
            attachments.removeAll(attachment);
            break;
        }
    }

    m_event->clearAttachments();

    for(auto attachment : attachments) {
        m_event->addAttachment(attachment);
    }

    Q_EMIT attachmentsChanged();
    Q_EMIT layoutChanged();
}
