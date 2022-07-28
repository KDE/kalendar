// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "errors.h"
#include <QByteArray>
#include <QVariant>

#include <QDateTime>
#include <functional>
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
    bool isUsable = false;
    std::vector<UserId> userIds;
};

struct Error {
    unsigned int error;
    operator bool() const
    {
        return error != 0;
    }
};

struct Signature {
    QByteArray fingerprint;
    Error status;
    QDateTime creationTime;
    enum Result { Ok, NotVerified, Expired, KeyNotFound, Invalid };
    Result result{NotVerified};
    bool isTrusted{false};
};

struct VerificationResult {
    std::vector<Signature> signatures;
    Error error;
};

struct Recipient {
    QByteArray keyId;
    bool secretKeyAvailable{false};
};

struct DecryptionResult {
    std::vector<Recipient> recipients;
    Error error;
    enum Result { NoError, NotEncrypted, PassphraseError, NoSecretKeyError, DecryptionError };
    Result result{NoError};
};

struct KeyListResult {
    std::vector<Key> keys;
    Error error;
};

struct ImportResult {
    int considered;
    int imported;
    int unchanged;
};

#ifndef _WIN32
std::vector<Key> findKeys(const QStringList &filter, bool findPrivate = false, bool remote = false);

Expected<Error, QByteArray> exportPublicKey(const Key &key);

ImportResult importKey(CryptoProtocol protocol, const QByteArray &certData);
ImportResult importKey(CryptoProtocol protocol, const Key &key);

/**
 * Sign the given content and returns the signing data and the algorithm used
 * for integrity check in the "pgp-<algorithm>" format.
 */
Expected<Error, std::pair<QByteArray, QString>> sign(const QByteArray &content, const std::vector<Key> &signingKeys);
Expected<Error, QByteArray> signAndEncrypt(const QByteArray &content, const std::vector<Key> &encryptionKeys, const std::vector<Key> &signingKeys);

std::pair<DecryptionResult, VerificationResult> decryptAndVerify(CryptoProtocol protocol, const QByteArray &ciphertext, QByteArray &outdata);
DecryptionResult decrypt(CryptoProtocol protocol, const QByteArray &ciphertext, QByteArray &outdata);
VerificationResult verifyDetachedSignature(CryptoProtocol protocol, const QByteArray &signature, const QByteArray &outdata);
VerificationResult verifyOpaqueSignature(CryptoProtocol protocol, const QByteArray &signature, QByteArray &outdata);
};
#endif

Q_DECLARE_METATYPE(Crypto::Key);

QDebug operator<<(QDebug d, const Crypto::Key &);
QDebug operator<<(QDebug d, const Crypto::Error &);
