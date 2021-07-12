// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QAbstractItemModel>
#include <QCalendar>
#include <KCalendarCore/Calendar>
#include <QDebug>


class AttachmentsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Event::Ptr eventPtr READ eventPtr WRITE setEventPtr NOTIFY eventPtrChanged)
    Q_PROPERTY(KCalendarCore::Attachment::List attachments READ attachments NOTIFY attachmentsChanged)
    Q_PROPERTY(QVariantMap dataroles READ dataroles CONSTANT)

public:
    enum Roles {
        AttachmentRole = Qt::UserRole + 1,
        LabelRole,
        MimeTypeRole,
        DataRole,
        SizeRole,
        URIRole
    };
    Q_ENUM(Roles);

    explicit AttachmentsModel(QObject *parent = nullptr, KCalendarCore::Event::Ptr eventPtr = nullptr);
    ~AttachmentsModel() = default;

    KCalendarCore::Event::Ptr eventPtr();
    void setEventPtr(KCalendarCore::Event::Ptr event);
    KCalendarCore::Attachment::List attachments();
    QVariantMap dataroles();

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addAttachment(QString uri);
    Q_INVOKABLE void deleteAttachment(QString uri);

Q_SIGNALS:
    void eventPtrChanged();
    void attachmentsChanged();

private:
    KCalendarCore::Event::Ptr m_event;
    QVariantMap m_dataRoles;
};

