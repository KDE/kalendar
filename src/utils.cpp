// SPDX-FileCopyrightText: 2023 Laurent Montel <montel@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later
#include "utils.h"

QString Utils::formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, bool allDay)
{
    if (duration.asSeconds() == 0) {
        return QString();
    } else {
        if (allDay) {
            return format.formatSpelloutDuration(duration.asSeconds() * 1000 + 24 * 60 * 60 * 1000);
        } else {
            return format.formatSpelloutDuration(duration.asSeconds() * 1000);
        }
    }
}
