// SPDX-FileCopyrightText: 2004 Marc Mutz <mutz@kde.org>,
// SPDX-FileCopyrightText: 2004 Ingo Kloecker <kloecker@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QByteArray>
#include <map>
#include <memory>

namespace MimeTreeParser
{

namespace Interface
{
class BodyPartFormatter;
}

struct ltstr {
    bool operator()(const char *s1, const char *s2) const
    {
        return qstricmp(s1, s2) < 0;
    }
};

typedef std::multimap<const char *, std::unique_ptr<Interface::BodyPartFormatter>, ltstr> SubtypeRegistry;
typedef std::map<const char *, MimeTreeParser::SubtypeRegistry, MimeTreeParser::ltstr> TypeRegistry;

class BodyPartFormatterBaseFactoryPrivate;

class BodyPartFormatterBaseFactory
{
public:
    BodyPartFormatterBaseFactory();
    ~BodyPartFormatterBaseFactory();

    const SubtypeRegistry &subtypeRegistry(const char *type) const;

protected:
    void insert(const char *type, const char *subtype, std::unique_ptr<Interface::BodyPartFormatter> formatter);

private:
    static BodyPartFormatterBaseFactory *mSelf;

    std::unique_ptr<BodyPartFormatterBaseFactoryPrivate> d;
    friend class BodyPartFormatterBaseFactoryPrivate;

private:
    // disabled
    const BodyPartFormatterBaseFactory &operator=(const BodyPartFormatterBaseFactory &);
    BodyPartFormatterBaseFactory(const BodyPartFormatterBaseFactory &);
};

}
