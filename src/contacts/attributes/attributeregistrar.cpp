/*
    This file is part of Akonadi Contact.

    SPDX-FileCopyrightText: 2009 Constantin Berzan <exit3219@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "attributes/contactmetadataattribute_p.h"

#include <Akonadi/AttributeFactory>

namespace
{
// Anonymous namespace; function is invisible outside this file.
bool dummy()
{
    using namespace Akonadi;
    AttributeFactory::registerAttribute<ContactMetaDataAttribute>();
    return true;
}

// Called when this library is loaded.
const bool registered = dummy();
} // namespace
