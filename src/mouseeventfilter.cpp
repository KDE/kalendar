// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "mouseventfilter.h"

#include <QEvent>

MouseEventFilter::MouseEventFilter(QObject *parent)
    : QObject{parent}
{
}
