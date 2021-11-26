// SPDX-FileCopyrightText: 2003 Cornelius Schumacher <schumacher@kde.org>
// SPDX-FileCopyrightText: 2008-2009 Allen Winter <winter@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later WITH LicenseRef-Qt-Commercial-exception-1.0

#include "alarmdockwindow.h"

#include <KConfigGroup>
#include <KIconEffect>
#include <KIconLoader>
#include <KLocalizedString>
#include <KMessageBox>
#include <KSharedConfig>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDebug>
#include <QMenu>

AlarmDockWindow::AlarmDockWindow()
    : KStatusNotifierItem(nullptr)
{
    // Read the autostart status from the config file
    KConfigGroup config(KSharedConfig::openConfig(), "General");
    const bool autostartSet = config.hasKey("Autostart");
    const bool autostart = config.readEntry("Autostart", true);
    // const bool grabFocus = config.readEntry("GrabFocus", false);
    const bool alarmsEnabled = config.readEntry("Enabled", true);

    // Don't mention Daemon here since it's a technical
    // term the user doesn't care about
    mName = i18nc("@title:window", "Kalendar Reminders");
    setToolTipTitle(mName);
    setToolTipIconByName(QStringLiteral("kalendarac"));
    setTitle(mName);

    // Set up icons
    const QIcon iconEnabled = QIcon::fromTheme(QStringLiteral("org.kde.kalendar"));

    KIconLoader loader;
    QImage iconDisabled = iconEnabled.pixmap(loader.currentSize(KIconLoader::Panel)).toImage();
    KIconEffect::toGray(iconDisabled, 1.0);
    mIconDisabled = QIcon(QPixmap::fromImage(iconDisabled));

    changeSystrayIcon(alarmsEnabled);

    // Set up the context menu
    mAlarmsEnabled = contextMenu()->addAction(i18nc("@action:inmenu", "Enable Reminders"));
    connect(mAlarmsEnabled, &QAction::toggled, this, &AlarmDockWindow::toggleAlarmsEnabled);
    mAlarmsEnabled->setCheckable(true);

    mAutostart = contextMenu()->addAction(i18nc("@action:inmenu", "Start Reminder Daemon at Login"));
    connect(mAutostart, &QAction::toggled, this, &AlarmDockWindow::toggleAutostart);
    mAutostart->setCheckable(true);

    mAlarmsEnabled->setChecked(alarmsEnabled);
    mAutostart->setChecked(autostart);

    // Disable standard quit behaviour. We have to intercept the quit even,
    // if the main window is hidden.
    QAction *act = action(QStringLiteral("quit"));
    if (act) {
        disconnect(act, SIGNAL(triggered(bool)), this, SLOT(maybeQuit()));
        connect(act, &QAction::triggered, this, &AlarmDockWindow::slotQuit);
    } else {
        qDebug() << "No Quit standard action.";
    }
    mAutostartSet = autostartSet;
}

AlarmDockWindow::~AlarmDockWindow()
{
}

void AlarmDockWindow::slotUpdate(int reminders)
{
    const bool actif = (reminders > 0);
    if (actif) {
        setToolTip(QStringLiteral("kalendarac"), mName, i18ncp("@info:status", "There is 1 active reminder.", "There are %1 active reminders.", reminders));
    } else {
        setToolTip(QStringLiteral("kalendarac"), mName, i18nc("@info:status", "No active reminders."));
    }
}

void AlarmDockWindow::toggleAlarmsEnabled(bool checked)
{
    changeSystrayIcon(checked);

    KConfigGroup config(KSharedConfig::openConfig(), "General");
    config.writeEntry("Enabled", checked);
    config.sync();
}

void AlarmDockWindow::toggleAutostart(bool checked)
{
    // qCDebug(KOALARMCLIENT_LOG);
    mAutostartSet = true;
    enableAutostart(checked);
}

void AlarmDockWindow::toggleGrabFocus(bool checked)
{
    KConfigGroup config(KSharedConfig::openConfig(), "General");
    config.writeEntry("GrabFocus", checked);
}

void AlarmDockWindow::slotSuspendAll()
{
    Q_EMIT suspendAllSignal();
}

void AlarmDockWindow::slotDismissAll()
{
    Q_EMIT dismissAllSignal();
}

void AlarmDockWindow::enableAutostart(bool enable)
{
    KConfigGroup config(KSharedConfig::openConfig(), "General");
    config.writeEntry("Autostart", enable);
    config.sync();
}

void AlarmDockWindow::activate(const QPoint &pos)
{
    Q_UNUSED(pos)
    QDBusConnection::sessionBus().interface()->startService(QStringLiteral("org.kde.kalendar"));
}

void AlarmDockWindow::slotQuit()
{
    if (mAutostartSet == true) {
        const int result = KMessageBox::warningContinueCancel(associatedWidget(),
                                                              xi18nc("@info",
                                                                     "Do you want to quit the Kalendar reminder daemon?<nl/>"
                                                                     "<note> you will not get calendar reminders unless the daemon is running.</note>"),
                                                              i18nc("@title:window", "Close Kalendar Reminder Daemon"),
                                                              KStandardGuiItem::quit());

        if (result == KMessageBox::Continue) {
            Q_EMIT quitSignal();
        }
    } else {
        const int result = KMessageBox::questionYesNoCancel(associatedWidget(),
                                                            xi18nc("@info",
                                                                   "Do you want to start the Kalendar reminder daemon at login?<nl/>"
                                                                   "<note> you will not get calendar reminders unless the daemon is running.</note>"),
                                                            i18nc("@title:window", "Close Kalendar Reminder Daemon"),
                                                            KGuiItem(i18nc("@action:button start the reminder daemon", "Start")),
                                                            KGuiItem(i18nc("@action:button do not start the reminder daemon", "Do Not Start")),
                                                            KStandardGuiItem::cancel(),
                                                            QStringLiteral("AskForStartAtLogin"));

        bool autostart = true;
        if (result == KMessageBox::No) {
            autostart = false;
        }
        enableAutostart(autostart);

        if (result != KMessageBox::Cancel) {
            Q_EMIT quitSignal();
        }
    }
}

void AlarmDockWindow::changeSystrayIcon(bool alarmsEnabled)
{
    if (alarmsEnabled) {
        setIconByName(QStringLiteral("org.kde.kalendar"));
    } else {
        setIconByPixmap(mIconDisabled.pixmap(22, 22));
    }
}
