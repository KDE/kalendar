// SPDX-FileCopyrightText: 2016 Sandro Knauß <sknauss@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KMime/Content>

namespace MimeTreeParser
{
KMime::Content *findTypeInDirectChildren(KMime::Content *content, const QByteArray &mimeType);
}
