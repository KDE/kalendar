/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <Akonadi/Collection>

#include <QDialog>
#include <QPushButton>

#include <memory>

class QAbstractItemModel;

namespace MessageComposer
{
class FollowUpReminderSelectDateDialogPrivate;
/**
 * @brief The FollowUpReminderSelectDateDialog class
 * @author Laurent Montel <montel@kde.org>
 */
class FollowUpReminderSelectDateDialog : public QDialog
{
    Q_OBJECT
public:
    explicit FollowUpReminderSelectDateDialog(QWidget *parent = nullptr, QAbstractItemModel *model = nullptr);
    ~FollowUpReminderSelectDateDialog() override;

    Q_REQUIRED_RESULT QDate selectedDate() const;

    void accept() override;

    Akonadi::Collection collection() const;

private Q_SLOTS:
    void slotDateChanged();
    void updateOkButton();

private:
    std::unique_ptr<FollowUpReminderSelectDateDialogPrivate> const d;
};
}
