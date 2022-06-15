// SPDX-FileCopyrightText: 2016 Sandro Knauß <sknauss@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "bodypartformatter.h"

using namespace MimeTreeParser::Interface;

namespace MimeTreeParser
{
namespace Interface
{

MessagePart::Ptr BodyPartFormatter::process(ObjectTreeParser *otp, KMime::Content *node) const
{
    return {};
}

QVector<MessagePart::Ptr> BodyPartFormatter::processList(ObjectTreeParser *otp, KMime::Content *node) const
{
    if (auto p = process(otp, node)) {
        return {p};
    }
    return {};
}

}
}
