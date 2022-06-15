// SPDX-FileCopyrightText: 2004 Marc Mutz <mutz@kde.org>
// SPDX-FileCopyrightText: 2004 Ingo Kloecker <kloecker@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include "messagepart.h"

namespace KMime
{
class Content;
}

namespace MimeTreeParser
{
class ObjectTreeParser;

namespace Interface
{

class BodyPart;

class BodyPartFormatter
{
public:
    virtual ~BodyPartFormatter()
    {
    }

    virtual MessagePart::Ptr process(ObjectTreeParser *otp, KMime::Content *node) const;
    virtual QVector<MessagePart::Ptr> processList(ObjectTreeParser *otp, KMime::Content *node) const;
};

} // namespace Interface

}
