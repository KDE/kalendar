// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>

class KJob;
class QAbstractListModel;
class ContactGroupModel;

#include <Akonadi/Item>
#include <Akonadi/ItemMonitor>
#include <KContacts/ContactGroup>

class ContactGroupWrapper : public QObject, public Akonadi::ItemMonitor {
    Q_OBJECT
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(Akonadi::Item item READ item WRITE setItem NOTIFY akonadiItemChanged)
    Q_PROPERTY(QAbstractListModel *model READ model CONSTANT)

public:
    ContactGroupWrapper(QObject *parent = nullptr);
    QString name() const;
    void setName(const QString &name);
    Akonadi::Item item() const;
    void setItem(const Akonadi::Item &item);
    QAbstractListModel *model() const;

protected:
    virtual void itemChanged(const Akonadi::Item &item) override;

Q_SIGNALS:
    void nameChanged();
    void akonadiItemChanged();

private:
    void itemFetchDone(KJob *job);
    void loadContactGroup(const KContacts::ContactGroup &contactGroup);

    QString m_name;
    ContactGroupModel *m_model;
    Akonadi::Item m_item;
};