/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <Akonadi/Item>
#include <KConfigGroup>
#include <QTreeWidgetItem>
#include <QWidget>
class QTreeWidget;
namespace FollowUpReminder
{
class FollowUpReminderInfo;
}

class FollowUpReminderInfoItem : public QTreeWidgetItem
{
public:
    explicit FollowUpReminderInfoItem(QTreeWidget *parent = nullptr);
    ~FollowUpReminderInfoItem() override;

    void setInfo(FollowUpReminder::FollowUpReminderInfo *info);
    FollowUpReminder::FollowUpReminderInfo *info() const;

private:
    FollowUpReminder::FollowUpReminderInfo *mInfo = nullptr;
};

class FollowUpReminderInfoWidget : public QWidget
{
    Q_OBJECT
public:
    explicit FollowUpReminderInfoWidget(QWidget *parent = nullptr);
    ~FollowUpReminderInfoWidget() override;

    void restoreTreeWidgetHeader(const QByteArray &data);
    void saveTreeWidgetHeader(KConfigGroup &group);

    void setInfo(const QList<FollowUpReminder::FollowUpReminderInfo *> &infoList);

    bool save() const;
    void load();

    Q_REQUIRED_RESULT QList<qint32> listRemoveId() const;

protected:
    bool eventFilter(QObject *object, QEvent *event) override;

private:
    void slotItemDoubleClicked(QTreeWidgetItem *item);
    void slotCustomContextMenuRequested(const QPoint &pos);
    void createOrUpdateItem(FollowUpReminder::FollowUpReminderInfo *info, FollowUpReminderInfoItem *item = nullptr);
    void deleteItems(const QList<QTreeWidgetItem *> &mailItemLst);
    void openShowMessage(Akonadi::Item::Id id);
    enum ItemData {
        AnswerItemId = Qt::UserRole + 1,
        AnswerItemFound = Qt::UserRole + 2,
    };

    enum FollowUpReminderColumn {
        To = 0,
        Subject,
        DeadLine,
        AnswerWasReceived,
        MessageId,
        AnswerMessageId,
    };
    QList<qint32> mListRemoveId;
    QTreeWidget *const mTreeWidget;
    bool mChanged = false;
};
