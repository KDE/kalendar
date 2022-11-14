// SPDX-FileCopyrightText: 2016 Sandro Knauß <sknauss@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "utils.h"

using namespace MimeTreeParser;

KMime::Content *MimeTreeParser::findTypeInDirectChildren(KMime::Content *content, const QByteArray &mimeType)
{
    const auto contents = content->contents();
    for (const auto child : contents) {
        if ((!child->contentType()->isEmpty()) && (mimeType == child->contentType()->mimeType())) {
            return child;
        }
    }
    return nullptr;
}
