/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QDialog>
namespace FollowUpReminder
{
class FollowUpReminderInfo;
}
class FollowUpReminderInfoWidget;
class FollowUpReminderNoAnswerDialog : public QDialog
{
    Q_OBJECT
public:
    explicit FollowUpReminderNoAnswerDialog(QWidget *parent = nullptr);
    ~FollowUpReminderNoAnswerDialog() override;

    void setInfo(const QList<FollowUpReminder::FollowUpReminderInfo *> &info);

    void wakeUp();

public Q_SLOTS:
    void reject() override;

Q_SIGNALS:
    void needToReparseConfiguration();

protected:
    void closeEvent(QCloseEvent *) override;

private:
    void slotDBusNotificationsPropertiesChanged(const QString &interface, const QVariantMap &changedProperties, const QStringList &invalidatedProperties);
    void slotSave();
    void readConfig();
    void writeConfig();
    FollowUpReminderInfoWidget *const mWidget;
};
