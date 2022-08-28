/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/
#include "followupreminderinfowidget.h"
#include "followupreminderagent_debug.h"
#include "followupreminderinfo.h"
#include "followupreminderutil.h"
#include "jobs/followupremindershowmessagejob.h"

#include <KLocalizedString>
#include <KMessageBox>
#include <KSharedConfig>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QIcon>
#include <QKeyEvent>
#include <QLocale>
#include <QMenu>
#include <QTreeWidget>

// #define DEBUG_MESSAGE_ID
namespace
{
inline QString followUpItemPattern()
{
    return QStringLiteral("FollowupReminderItem \\d+");
}
}

FollowUpReminderInfoItem::FollowUpReminderInfoItem(QTreeWidget *parent)
    : QTreeWidgetItem(parent)
{
}

FollowUpReminderInfoItem::~FollowUpReminderInfoItem()
{
    delete mInfo;
}

void FollowUpReminderInfoItem::setInfo(FollowUpReminder::FollowUpReminderInfo *info)
{
    mInfo = info;
}

FollowUpReminder::FollowUpReminderInfo *FollowUpReminderInfoItem::info() const
{
    return mInfo;
}

FollowUpReminderInfoWidget::FollowUpReminderInfoWidget(QWidget *parent)
    : QWidget(parent)
    , mTreeWidget(new QTreeWidget(this))
{
    setObjectName(QStringLiteral("FollowUpReminderInfoWidget"));
    auto hbox = new QHBoxLayout(this);
    hbox->setContentsMargins({});
    mTreeWidget->setObjectName(QStringLiteral("treewidget"));
    QStringList headers;
    headers << i18n("To") << i18n("Subject") << i18n("Deadline") << i18n("Answer")
#ifdef DEBUG_MESSAGE_ID
            << QStringLiteral("Message Id") << QStringLiteral("Answer Message Id")
#endif
        ;

    mTreeWidget->setHeaderLabels(headers);
    mTreeWidget->setSortingEnabled(true);
    mTreeWidget->setRootIsDecorated(false);
    mTreeWidget->setSelectionMode(QAbstractItemView::ExtendedSelection);
    mTreeWidget->setContextMenuPolicy(Qt::CustomContextMenu);
    mTreeWidget->installEventFilter(this);

    connect(mTreeWidget, &QTreeWidget::customContextMenuRequested, this, &FollowUpReminderInfoWidget::slotCustomContextMenuRequested);
    connect(mTreeWidget, &QTreeWidget::itemDoubleClicked, this, &FollowUpReminderInfoWidget::slotItemDoubleClicked);

    hbox->addWidget(mTreeWidget);
}

FollowUpReminderInfoWidget::~FollowUpReminderInfoWidget() = default;

bool FollowUpReminderInfoWidget::eventFilter(QObject *object, QEvent *event)
{
    if (object == mTreeWidget) {
        if (event->type() == QEvent::KeyPress) {
            auto keyEvent = static_cast<QKeyEvent *>(event);
            if (keyEvent->key() == Qt::Key_Delete) {
                const auto listItems = mTreeWidget->selectedItems();
                deleteItems(listItems);
            }
        }
    }

    return false;
}

void FollowUpReminderInfoWidget::setInfo(const QList<FollowUpReminder::FollowUpReminderInfo *> &infoList)
{
    mTreeWidget->clear();
    for (FollowUpReminder::FollowUpReminderInfo *info : infoList) {
        if (info->isValid()) {
            createOrUpdateItem(info);
        } else {
            delete info;
        }
    }
}

void FollowUpReminderInfoWidget::load()
{
    auto config = FollowUpReminder::FollowUpReminderUtil::defaultConfig();
    const QStringList filterGroups = config->groupList().filter(QRegularExpression(followUpItemPattern()));
    const int numberOfItem = filterGroups.count();
    for (int i = 0; i < numberOfItem; ++i) {
        KConfigGroup group = config->group(filterGroups.at(i));

        auto info = new FollowUpReminder::FollowUpReminderInfo(group);
        if (info->isValid()) {
            createOrUpdateItem(info);
        } else {
            delete info;
        }
    }
}

QList<qint32> FollowUpReminderInfoWidget::listRemoveId() const
{
    return mListRemoveId;
}

void FollowUpReminderInfoWidget::createOrUpdateItem(FollowUpReminder::FollowUpReminderInfo *info, FollowUpReminderInfoItem *item)
{
    if (!item) {
        item = new FollowUpReminderInfoItem(mTreeWidget);
    }
    item->setInfo(info);
    item->setText(To, info->to());
    item->setToolTip(To, info->to());
    item->setText(Subject, info->subject());
    item->setToolTip(Subject, info->subject());
    const QString date = QLocale().toString(info->followUpReminderDate());
    item->setText(DeadLine, date);
    item->setToolTip(DeadLine, date);
    const bool answerWasReceived = info->answerWasReceived();
    item->setText(AnswerWasReceived, answerWasReceived ? i18n("Received") : i18n("On hold"));
    item->setData(0, AnswerItemFound, answerWasReceived);
    if (answerWasReceived) {
        item->setBackground(DeadLine, Qt::green);
    } else {
        if (info->followUpReminderDate() < QDate::currentDate()) {
            item->setBackground(DeadLine, Qt::red);
        }
    }
#ifdef DEBUG_MESSAGE_ID
    item->setText(MessageId, QString::number(info->originalMessageItemId()));
    item->setText(AnswerMessageId, QString::number(info->answerMessageItemId()));
#endif
}

bool FollowUpReminderInfoWidget::save() const
{
    if (!mChanged) {
        return false;
    }
    KSharedConfig::Ptr config = KSharedConfig::openConfig();

    // first, delete all filter groups:
    const QStringList filterGroups = config->groupList().filter(QRegularExpression(followUpItemPattern()));

    for (const QString &group : filterGroups) {
        config->deleteGroup(group);
    }

    const int numberOfItem(mTreeWidget->topLevelItemCount());
    int i = 0;
    for (; i < numberOfItem; ++i) {
        auto mailItem = static_cast<FollowUpReminderInfoItem *>(mTreeWidget->topLevelItem(i));
        if (mailItem->info()) {
            KConfigGroup group = config->group(FollowUpReminder::FollowUpReminderUtil::followUpReminderPattern().arg(i));
            mailItem->info()->writeConfig(group, i);
        }
    }
    ++i;
    KConfigGroup general = config->group(QStringLiteral("General"));
    general.writeEntry("Number", i);
    config->sync();
    return true;
}

void FollowUpReminderInfoWidget::slotItemDoubleClicked(QTreeWidgetItem *item)
{
    if (!item)
        return;

    const auto mailItem = static_cast<FollowUpReminderInfoItem *>(item);
    const auto answerMessageItemId = mailItem->info()->answerMessageItemId();
    if (answerMessageItemId >= 0) {
        openShowMessage(answerMessageItemId);
    } else {
        openShowMessage(mailItem->info()->originalMessageItemId());
    }
}

void FollowUpReminderInfoWidget::slotCustomContextMenuRequested(const QPoint &pos)
{
    Q_UNUSED(pos)
    const QList<QTreeWidgetItem *> listItems = mTreeWidget->selectedItems();
    const int nbElementSelected = listItems.count();
    if (nbElementSelected > 0) {
        QMenu menu(this);
        QAction *showMessage = nullptr;
        QAction *showOriginalMessage = nullptr;
        FollowUpReminderInfoItem *mailItem = nullptr;
        if ((nbElementSelected == 1)) {
            mailItem = static_cast<FollowUpReminderInfoItem *>(listItems.at(0));
            if (mailItem->data(0, AnswerItemFound).toBool()) {
                showMessage = menu.addAction(i18n("Show Message"));
                menu.addSeparator();
            }
            showOriginalMessage = menu.addAction(QIcon::fromTheme(QStringLiteral("mail-message")), i18n("Show Original Message"));
            menu.addSeparator();
        }
        QAction *deleteItem = menu.addAction(QIcon::fromTheme(QStringLiteral("edit-delete")), i18n("Delete"));
        QAction *result = menu.exec(QCursor::pos());
        if (result) {
            if (result == showMessage) {
                openShowMessage(mailItem->info()->answerMessageItemId());
            } else if (result == deleteItem) {
                deleteItems(listItems);
            } else if (result == showOriginalMessage) {
                openShowMessage(mailItem->info()->originalMessageItemId());
            }
        }
    }
}

void FollowUpReminderInfoWidget::openShowMessage(Akonadi::Item::Id id)
{
    auto job = new FollowUpReminderShowMessageJob(id);
    job->start();
}

void FollowUpReminderInfoWidget::deleteItems(const QList<QTreeWidgetItem *> &mailItemLst)
{
    if (mailItemLst.isEmpty()) {
        qCDebug(FOLLOWUPREMINDERAGENT_LOG) << "Not item selected";
    } else {
        const auto answer = KMessageBox::warningContinueCancel(
            this,
            i18np("Do you want to delete this selected item?", "Do you want to delete these %1 selected items?", mailItemLst.count()),
            i18nc("@title:window", "Delete Items"),
            KStandardGuiItem::del());
        if (answer == KMessageBox::Continue) {
            for (QTreeWidgetItem *item : mailItemLst) {
                auto mailItem = static_cast<FollowUpReminderInfoItem *>(item);
                mListRemoveId << mailItem->info()->uniqueIdentifier();
                delete mailItem;
            }
            mChanged = true;
        }
    }
}

void FollowUpReminderInfoWidget::restoreTreeWidgetHeader(const QByteArray &data)
{
    mTreeWidget->header()->restoreState(data);
}

void FollowUpReminderInfoWidget::saveTreeWidgetHeader(KConfigGroup &group)
{
    group.writeEntry("HeaderState", mTreeWidget->header()->saveState());
}
