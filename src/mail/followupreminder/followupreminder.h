/*
   SPDX-FileCopyrightText: 2020 Daniel Vrátil <dvratil@kde.org>
   SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QObject>
#include <QtGlobal>

class FollowUpReminder : public QObject
{
    Q_OBJECT
public:
    Q_REQUIRED_RESULT Q_INVOKABLE bool isAvailableAndEnabled();
};
