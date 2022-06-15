// SPDX-FileCopyrightText: 2004 Marc Mutz <mutz@kde.org>
// SPDX-FileCopyrightText: 2004 Ingo Kloecker <kloecker@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

namespace MimeTreeParser
{
class BodyPartFormatterBaseFactory;
class ObjectTreeParser;

class BodyPartFormatterBaseFactoryPrivate
{
public:
    BodyPartFormatterBaseFactoryPrivate(BodyPartFormatterBaseFactory *factory);
    ~BodyPartFormatterBaseFactoryPrivate();

    void setup();
    void messageviewer_create_builtin_bodypart_formatters(); // defined in bodypartformatter.cpp
    void insert(const char *type, const char *subtype, Interface::BodyPartFormatter *formatter);

    BodyPartFormatterBaseFactory *q;
    TypeRegistry *all;
    ObjectTreeParser *mOtp;
};

}
