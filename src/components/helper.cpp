// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "helper.h"
#include <QIcon>

QString Helper::iconName(const QIcon &icon) const
{
    return icon.name();
}
