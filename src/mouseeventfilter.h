// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>

class MouseEventFilter : public QObject
{
    Q_OBJECT

public:
    explicit MouseEventFilter(QObject *parent = nullptr);
};
