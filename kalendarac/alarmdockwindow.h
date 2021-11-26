// SPDX-FileCopyrightText: 2003 Cornelius Schumacher <schumacher@kde.org>
// SPDX-FileCopyrightText: 2008-2009 Allen Winter <winter@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later WITH LicenseRef-Qt-Commercial-exception-1.0

#pragma once

#include <KStatusNotifierItem>

#include <QAction>
#include <QIcon>

class AlarmDockWindow : public KStatusNotifierItem
{
    Q_OBJECT
public:
    AlarmDockWindow();
    ~AlarmDockWindow() override;

    void enableAutostart(bool enabled);

public Q_SLOTS:
    void toggleAlarmsEnabled(bool checked);
    void toggleAutostart(bool checked);
    void toggleGrabFocus(bool checked);
    void slotUpdate(int reminders);

Q_SIGNALS:
    void quitSignal();
    void suspendAllSignal();
    void dismissAllSignal();
    void showReminderSignal();

protected Q_SLOTS:
    void activate(const QPoint &pos) override;
    void slotQuit();
    void slotSuspendAll();
    void slotDismissAll();

private:
    void changeSystrayIcon(bool alarmsEnabled);

    QIcon mIconDisabled;
    QString mName;

    QAction *mAlarmsEnabled = nullptr;
    QAction *mAutostart = nullptr;
    QAction *mShow = nullptr;

    bool mAutostartSet = false;
};
