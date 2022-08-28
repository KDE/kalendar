/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupremindernoanswerdialog.h"
#include "followupreminderagent_debug.h"
#include "followupreminderinfo.h"
#include "followupreminderinfowidget.h"

#include <KLocalizedString>
#include <KSharedConfig>

#include <KConfigGroup>
#include <QDialogButtonBox>
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>

#include "dbusproperties.h" // DBUS-generated
#include "notifications_interface.h" // DBUS-generated

namespace
{
static constexpr const char s_fdo_notifications_service[] = "org.freedesktop.Notifications";
static constexpr const char s_fdo_notifications_path[] = "/org/freedesktop/Notifications";
static constexpr const char DialogGroup[] = "FollowUpReminderNoAnswerDialog";
}

FollowUpReminderNoAnswerDialog::FollowUpReminderNoAnswerDialog(QWidget *parent)
    : QDialog(parent)
    , mWidget(new FollowUpReminderInfoWidget(this))
{
    setWindowTitle(i18nc("@title:window", "Follow Up Reminder"));
    setWindowIcon(QIcon::fromTheme(QStringLiteral("kmail")));
    setAttribute(Qt::WA_DeleteOnClose);

    auto mainLayout = new QVBoxLayout(this);

    auto lab = new QLabel(i18n("You still wait an answer about this mail:"), this);
    mainLayout->addWidget(lab);
    mWidget->setObjectName(QStringLiteral("FollowUpReminderInfoWidget"));
    mainLayout->addWidget(mWidget);

    auto buttonBox = new QDialogButtonBox(QDialogButtonBox::Close, this);
    QPushButton *closeButton = buttonBox->button(QDialogButtonBox::Close);
    closeButton->setDefault(true);
    closeButton->setShortcut(Qt::CTRL | Qt::Key_Return);
    connect(buttonBox, &QDialogButtonBox::rejected, this, &FollowUpReminderNoAnswerDialog::reject);

    mainLayout->addWidget(buttonBox);

    readConfig();
    QDBusConnection dbusConn = QDBusConnection::sessionBus();
    if (dbusConn.interface()->isServiceRegistered(QString::fromLatin1(s_fdo_notifications_service))) {
        auto propsIface = new OrgFreedesktopDBusPropertiesInterface(QString::fromLatin1(s_fdo_notifications_service),
                                                                    QString::fromLatin1(s_fdo_notifications_path),
                                                                    dbusConn,
                                                                    this);
        connect(propsIface,
                &OrgFreedesktopDBusPropertiesInterface::PropertiesChanged,
                this,
                &FollowUpReminderNoAnswerDialog::slotDBusNotificationsPropertiesChanged);
    }
}

FollowUpReminderNoAnswerDialog::~FollowUpReminderNoAnswerDialog()
{
    writeConfig();
}

void FollowUpReminderNoAnswerDialog::wakeUp()
{
    // Check if notifications are inhibited (e.x. plasma "do not disturb" mode.
    // In that case, we'll wait until they are allowed again (see slotDBusNotificationsPropertiesChanged)
    QDBusConnection dbusConn = QDBusConnection::sessionBus();
    if (dbusConn.interface()->isServiceRegistered(QString::fromLatin1(s_fdo_notifications_service))) {
        OrgFreedesktopNotificationsInterface iface(QString::fromLatin1(s_fdo_notifications_service), QString::fromLatin1(s_fdo_notifications_path), dbusConn);
        if (iface.inhibited()) {
            return;
        }
    }
    show();
}

void FollowUpReminderNoAnswerDialog::slotDBusNotificationsPropertiesChanged(const QString &interface,
                                                                            const QVariantMap &changedProperties,
                                                                            const QStringList &invalidatedProperties)
{
    Q_UNUSED(interface) // always "org.freedesktop.Notifications"
    Q_UNUSED(invalidatedProperties)
    const auto it = changedProperties.find(QStringLiteral("Inhibited"));
    if (it != changedProperties.end()) {
        const bool inhibited = it.value().toBool();
        qCDebug(FOLLOWUPREMINDERAGENT_LOG) << "Notifications inhibited:" << inhibited;
        if (!inhibited) {
            wakeUp();
        }
    }
}

void FollowUpReminderNoAnswerDialog::setInfo(const QList<FollowUpReminder::FollowUpReminderInfo *> &info)
{
    mWidget->setInfo(info);
}

void FollowUpReminderNoAnswerDialog::readConfig()
{
    KConfigGroup group(KSharedConfig::openStateConfig(), DialogGroup);
    const QSize sizeDialog = group.readEntry("Size", QSize(800, 600));
    if (sizeDialog.isValid()) {
        resize(sizeDialog);
    }
    mWidget->restoreTreeWidgetHeader(group.readEntry("HeaderState", QByteArray()));
}

void FollowUpReminderNoAnswerDialog::writeConfig()
{
    KConfigGroup group(KSharedConfig::openStateConfig(), DialogGroup);
    group.writeEntry("Size", size());
    mWidget->saveTreeWidgetHeader(group);
}

void FollowUpReminderNoAnswerDialog::slotSave()
{
    if (mWidget->save()) {
        Q_EMIT needToReparseConfiguration();
    }
}

void FollowUpReminderNoAnswerDialog::reject()
{
    slotSave();
    QDialog::reject();
}

void FollowUpReminderNoAnswerDialog::closeEvent(QCloseEvent *event)
{
    slotSave();
    QDialog::closeEvent(event);
}
