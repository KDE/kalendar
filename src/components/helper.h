// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once

#include <QObject>

class Helper : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE QString iconName(const QIcon &icon) const;
};
