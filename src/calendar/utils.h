// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <KCalendarCore/Duration>
#include <KFormat>
#include <QObject>

class Utils : public QObject
{
    Q_OBJECT

public:
    explicit Utils(QObject *parent = nullptr);

    /// Gives prettified time
    Q_INVOKABLE QString secondsToReminderLabel(const qint64 seconds) const;

    Q_REQUIRED_RESULT static QString formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, bool allDay);
};
