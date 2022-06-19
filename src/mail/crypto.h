// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "errors.h"
#include <QByteArray>
#include <QVariant>

#include <QDateTime>
#include <functional>
#include <gpgme.h>
#include <memory>

namespace Crypto
{

enum CryptoProtocol { UnknownProtocol, OpenPGP, CMS };

struct UserId {
    QByteArray name;
    QByteArray email;
    QByteArray id;
};

struct Key {
    QByteArray keyId;
    QByteArray shortKeyId;
    QByteArray fingerprint;
    bool isExpired = false;
    std::vector<UserId> userIds;
};

struct Error {
    gpgme_error_t error;
    gpgme_err_code_t errorCode() const
    {
        return gpgme_err_code(error);
    }
    const char *errorMessage() const
    {
        return gpgme_strerror(error);
    }
    operator bool() const
    {
        return error != GPG_ERR_NO_ERROR;
    }
};

struct Signature {
    QByteArray fingerprint;
    gpgme_sigsum_t summary;
    Error status;
    gpgme_validity_t validity;
    gpgme_error_t validity_reason;
    QDateTime creationTime;
};

struct VerificationResult {
    std::vector<Signature> signatures;
    Error error;
};

struct Recipient {
    QByteArray keyId;
    Error status;
};

struct DecryptionResult {
    std::vector<Recipient> recipients;
    Error error;
};

struct KeyListResult {
    std::vector<Key> keys;
    Error error;
};

std::vector<Key> findKeys(const QStringList &filter, bool findPrivate = false, bool remote = false);

Expected<Error, QByteArray> exportPublicKey(const Key &key);

struct ImportResult {
    int considered;
    int imported;
    int unchanged;
};
ImportResult importKey(CryptoProtocol protocol, const QByteArray &certData);
ImportResult importKey(CryptoProtocol protocol, const Key &key);

/**
 * Sign the given content and returns the signing data and the algorithm used
 * for integrity check in the "pgp-<algorithm>" format.
 */
Expected<Error, std::pair<QByteArray, QString>> sign(const QByteArray &content, const std::vector<Key> &signingKeys);
Expected<Error, QByteArray> signAndEncrypt(const QByteArray &content, const std::vector<Key> &encryptionKeys, const std::vector<Key> &signingKeys);

std::pair<DecryptionResult, VerificationResult> decryptAndVerify(CryptoProtocol protocol, const QByteArray &ciphertext, QByteArray &outdata);
VerificationResult verifyDetachedSignature(CryptoProtocol protocol, const QByteArray &signature, const QByteArray &outdata);
VerificationResult verifyOpaqueSignature(CryptoProtocol protocol, const QByteArray &signature, QByteArray &outdata);
};

Q_DECLARE_METATYPE(Crypto::Key);

QDebug operator<<(QDebug d, const Crypto::Key &);
QDebug operator<<(QDebug d, const Crypto::Error &);
