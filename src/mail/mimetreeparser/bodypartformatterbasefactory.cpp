// SPDX-FileCopyrightText: 2004 Marc Mutz <mutz@kde.org>
// SPDX-FileCopyrightText: 2004 Ingo Kloecker <kloecker@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "bodypartformatterbasefactory.h"
#include "bodypartformatter.h"
#include "bodypartformatterbasefactory_p.h"
#include "mimetreeparser_debug.h"

#include <assert.h>

using namespace MimeTreeParser;

BodyPartFormatterBaseFactoryPrivate::BodyPartFormatterBaseFactoryPrivate(BodyPartFormatterBaseFactory *factory)
    : q(factory)
{
}

BodyPartFormatterBaseFactoryPrivate::~BodyPartFormatterBaseFactoryPrivate()
{
}

void BodyPartFormatterBaseFactoryPrivate::setup()
{
    if (!all) {
        all = std::make_optional<TypeRegistry>();
        messageviewer_create_builtin_bodypart_formatters();
    }
}

void BodyPartFormatterBaseFactoryPrivate::insert(const char *type, const char *subtype, Interface::BodyPartFormatter *formatter)
{
    if (!type || !*type || !subtype || !*subtype || !formatter || !all) {
        return;
    }

    TypeRegistry::iterator type_it = all->find(type);
    if (type_it == all->end()) {
        type_it = all->insert(std::make_pair(type, SubtypeRegistry())).first;
        assert(type_it != all->end());
    }

    SubtypeRegistry &subtype_reg = type_it->second;

    subtype_reg.insert(std::make_pair(subtype, formatter));
}

BodyPartFormatterBaseFactory::BodyPartFormatterBaseFactory()
    : d(std::make_unique<BodyPartFormatterBaseFactoryPrivate>(this))
{
}

BodyPartFormatterBaseFactory::~BodyPartFormatterBaseFactory() = default;

void BodyPartFormatterBaseFactory::insert(const char *type, const char *subtype, Interface::BodyPartFormatter *formatter)
{
    d->insert(type, subtype, formatter);
}

const SubtypeRegistry &BodyPartFormatterBaseFactory::subtypeRegistry(const char *type) const
{
    if (!type || !*type) {
        type = "*"; // krazy:exclude=doublequote_chars
    }

    d->setup();
    assert(d->all);

    static SubtypeRegistry emptyRegistry;
    if (d->all->empty()) {
        return emptyRegistry;
    }

    TypeRegistry::const_iterator type_it = d->all->find(type);
    if (type_it == d->all->end()) {
        type_it = d->all->find("*");
    }
    if (type_it == d->all->end()) {
        return emptyRegistry;
    }

    const SubtypeRegistry &subtype_reg = type_it->second;
    if (subtype_reg.empty()) {
        return emptyRegistry;
    }
    return subtype_reg;
}
