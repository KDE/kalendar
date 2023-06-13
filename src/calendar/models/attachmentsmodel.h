// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KCalendarCore/Calendar>
#include <QAbstractListModel>
#include <QMimeDatabase>

class AttachmentsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(KCalendarCore::Incidence::Ptr incidencePtr READ incidencePtr WRITE setIncidencePtr NOTIFY incidencePtrChanged)
    Q_PROPERTY(KCalendarCore::Attachment::List attachments READ attachments NOTIFY attachmentsChanged)
    Q_PROPERTY(QVariantMap dataroles READ dataroles CONSTANT)

public:
    enum Roles {
        AttachmentRole = Qt::UserRole + 1,
        LabelRole,
        MimeTypeRole,
        IconNameRole,
        DataRole,
        SizeRole,
        URIRole,
    };
    Q_ENUM(Roles)

    explicit AttachmentsModel(QObject *parent = nullptr, KCalendarCore::Incidence::Ptr incidencePtr = nullptr);
    ~AttachmentsModel() override = default;

    KCalendarCore::Incidence::Ptr incidencePtr();
    void setIncidencePtr(KCalendarCore::Incidence::Ptr incidence);
    KCalendarCore::Attachment::List attachments();
    QVariantMap dataroles();

    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addAttachment(const QString &uri);
    Q_INVOKABLE void deleteAttachment(const QString &uri);

Q_SIGNALS:
    void incidencePtrChanged();
    void attachmentsChanged();

private:
    KCalendarCore::Incidence::Ptr m_incidence;
    QVariantMap m_dataRoles;
    QMimeDatabase m_mimeDb;
};
