// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <KMime/Content>

#include <memory>

#include "../crypto.h"
#include "../errors.h"

namespace MailCrypto
{

Expected<Crypto::Error, std::unique_ptr<KMime::Content>>
processCrypto(std::unique_ptr<KMime::Content> content, const std::vector<Crypto::Key> &signingKeys, const std::vector<Crypto::Key> &encryptionKeys);

};
