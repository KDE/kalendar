// SPDX-FileCopyrightText: 2023 Laurent Montel <montel@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later
#pragma once

#include <KCalendarCore/Duration>
#include <KFormat>

namespace Utils
{
Q_REQUIRED_RESULT QString formatSpelloutDuration(const KCalendarCore::Duration &duration, const KFormat &format, bool allDay);
};
