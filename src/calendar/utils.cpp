// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "utils.h"
#include <KLocalizedString>
#include <QtMath>
#include <chrono>

using namespace std::chrono_literals;

namespace
{
QString numAndUnit(const qint64 seconds)
{
    std::chrono::seconds secs{seconds};
    if (secs >= 24h * 2) {
        // 2 days +
        return i18nc("%1 is 2 or more", "%1 days", std::chrono::round<std::chrono::days>(secs).count());
    } else if (secs >= 24h) {
        return i18n("1 day");
    } else if (secs >= (2h)) {
        return i18nc("%1 is 2 or mores", "%1 hours", std::chrono::round<std::chrono::hours>(secs).count()); // 2 hours +
    } else if (secs >= (1h)) {
        return i18n("1 hour");
    } else {
        return i18n("%1 minutes", std::chrono::round<std::chrono::minutes>(secs).count());
    }
};
}

Utils::Utils(QObject *parent)
    : QObject(parent)
{
}

QString Utils::secondsToReminderLabel(const qint64 seconds) const
{
    if (seconds < 0) {
        return i18n("%1 before start of event", numAndUnit(seconds * -1));
    } else if (seconds > 0) {
        return i18n("%1 after start of event", numAndUnit(seconds));
    } else {
        return i18n("On event start");
    }
}
