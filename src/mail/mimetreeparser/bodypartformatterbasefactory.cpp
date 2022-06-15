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
    , all(nullptr)
{
}

BodyPartFormatterBaseFactoryPrivate::~BodyPartFormatterBaseFactoryPrivate()
{
    if (all) {
        delete all;
        all = nullptr;
    }
}

void BodyPartFormatterBaseFactoryPrivate::setup()
{
    if (!all) {
        all = new TypeRegistry();
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
    : d(new BodyPartFormatterBaseFactoryPrivate(this))
{
}

BodyPartFormatterBaseFactory::~BodyPartFormatterBaseFactory()
{
    delete d;
}

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

SubtypeRegistry::const_iterator BodyPartFormatterBaseFactory::createForIterator(const char *type, const char *subtype) const
{
    if (!type || !*type) {
        type = "*"; // krazy:exclude=doublequote_chars
    }
    if (!subtype || !*subtype) {
        subtype = "*"; // krazy:exclude=doublequote_chars
    }

    d->setup();
    assert(d->all);

    if (d->all->empty()) {
        return SubtypeRegistry::const_iterator();
    }

    TypeRegistry::const_iterator type_it = d->all->find(type);
    if (type_it == d->all->end()) {
        type_it = d->all->find("*");
    }
    if (type_it == d->all->end()) {
        return SubtypeRegistry::const_iterator();
    }

    const SubtypeRegistry &subtype_reg = type_it->second;
    if (subtype_reg.empty()) {
        return SubtypeRegistry::const_iterator();
    }

    SubtypeRegistry::const_iterator subtype_it = subtype_reg.find(subtype);
    qCWarning(MIMETREEPARSER_LOG) << type << subtype << subtype_reg.size();
    if (subtype_it == subtype_reg.end()) {
        subtype_it = subtype_reg.find("*");
    }
    if (subtype_it == subtype_reg.end()) {
        return SubtypeRegistry::const_iterator();
    }

    if (!(*subtype_it).second) {
        qCWarning(MIMETREEPARSER_LOG) << "BodyPartFormatterBaseFactory: a null bodypart formatter sneaked in for \"" << type << "/" << subtype << "\"!";
    }

    return subtype_it;
}
