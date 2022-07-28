// SPDX-FileCopyrightText: 2009 Constantin Berzan <exit3219@gmail.com>
// SPDX-FileCopyrightText: 2010 Klarälvdalens Datakonsult AB, a KDAB Group company, info@kdab.com
// SPDX-FileCopyrightText: 2010 Leo Franchi <lfranchi@kde.org>
// SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "crypto.h"

#ifndef _WIN32
#include <gpgme.h>
#endif

#include <QDateTime>
#include <QDebug>
#include <QFile>

#include <future>
#include <utility>

using namespace Crypto;

QDebug operator<<(QDebug d, const Key &key)
{
    d << key.fingerprint;
    return d;
}

QDebug operator<<(QDebug d, const Error &error)
{
    d << error.error;
    return d;
}

#ifndef _WIN32
namespace Crypto
{
struct Data {
    Data(const QByteArray &buffer)
    {
        const bool copy = false;
        const gpgme_error_t e = gpgme_data_new_from_mem(&data, buffer.constData(), buffer.size(), int(copy));
        if (e) {
            qWarning() << "Failed to copy data?" << e;
        }
    }

    ~Data()
    {
        gpgme_data_release(data);
    }
    gpgme_data_t data;
};
}

static gpgme_error_t checkEngine(CryptoProtocol protocol)
{
    gpgme_check_version(nullptr);
    const gpgme_protocol_t p = protocol == CMS ? GPGME_PROTOCOL_CMS : GPGME_PROTOCOL_OpenPGP;
    return gpgme_engine_check_version(p);
}

static std::pair<gpgme_error_t, gpgme_ctx_t> createForProtocol(CryptoProtocol proto)
{
    if (auto e = checkEngine(proto)) {
        qWarning() << "GPG Engine check failed." << e;
        return std::make_pair(e, nullptr);
    }
    gpgme_ctx_t ctx = nullptr;
    if (auto e = gpgme_new(&ctx)) {
        return std::make_pair(e, nullptr);
    }

    switch (proto) {
    case OpenPGP:
        if (auto e = gpgme_set_protocol(ctx, GPGME_PROTOCOL_OpenPGP)) {
            gpgme_release(ctx);
            return std::make_pair(e, nullptr);
        }
        break;
    case CMS:
        if (auto e = gpgme_set_protocol(ctx, GPGME_PROTOCOL_CMS)) {
            gpgme_release(ctx);
            return std::make_pair(e, nullptr);
        }
        break;
    default:
        Q_ASSERT(false);
        return std::make_pair(1, nullptr);
    }
    // We want the output to always be ASCII armored
    gpgme_set_armor(ctx, 1);

    // Trust new keys
    if (auto e = gpgme_set_ctx_flag(ctx, "trust-model", "tofu+pgp")) {
        gpgme_release(ctx);
        return std::make_pair(e, nullptr);
    }

    // That's a great way to bring signature verification to a crawl
    if (auto e = gpgme_set_ctx_flag(ctx, "auto-key-retrieve", "0")) {
        gpgme_release(ctx);
        return std::make_pair(e, nullptr);
    }

    return std::make_pair(GPG_ERR_NO_ERROR, ctx);
}

gpgme_error_t gpgme_passphrase(void *hook, const char *uid_hint, const char *passphrase_info, int prev_was_bad, int fd)
{
    Q_UNUSED(hook);
    Q_UNUSED(prev_was_bad);
    // uid_hint will be something like "CAA5183608F0FB50 Test1 Kolab <test1@kolab.org>" (CAA518... is the key)
    // pahhphrase_info will be something like "CAA5183608F0FB50 2E3B7787B1B75920 1 0"
    qInfo() << "Requested passphrase for " << (uid_hint ? QByteArray{uid_hint} : QByteArray{})
            << (passphrase_info ? QByteArray{passphrase_info} : QByteArray{});

    QFile file;
    file.open(fd, QIODevice::WriteOnly);
    // FIXME hardcoded as a test
    auto passphrase = QByteArray{"test1"} + QByteArray{"\n"};
    file.write(passphrase);
    file.close();

    return 0;
}

namespace Crypto
{
struct Context {
    Context(CryptoProtocol protocol = OpenPGP)
    {
        gpgme_error_t code;
        std::tie(code, context) = createForProtocol(protocol);
        error = Error{code};
    }

    ~Context()
    {
        gpgme_release(context);
    }

    operator bool() const
    {
        return !error;
    }
    Error error;
    gpgme_ctx_t context;
};
}

static QByteArray toBA(gpgme_data_t out)
{
    size_t length = 0;
    auto data = gpgme_data_release_and_get_mem(out, &length);
    auto outdata = QByteArray{data, static_cast<int>(length)};
    gpgme_free(data);
    return outdata;
}

static std::vector<Recipient> copyRecipients(gpgme_decrypt_result_t result)
{
    std::vector<Recipient> recipients;
    for (gpgme_recipient_t r = result->recipients; r; r = r->next) {
        recipients.push_back({QByteArray{r->keyid}, r->status != GPG_ERR_NO_SECKEY});
    }
    return recipients;
}

static std::vector<Signature> copySignatures(gpgme_verify_result_t result)
{
    std::vector<Signature> signatures;
    for (gpgme_signature_t is = result->signatures; is; is = is->next) {
        Signature sig;
        sig.fingerprint = QByteArray{is->fpr};
        sig.creationTime.setSecsSinceEpoch(is->timestamp);
        if (is->summary & GPGME_SIGSUM_VALID) {
            sig.result = Signature::Ok;
        } else {
            sig.result = Signature::Invalid;
            if (is->summary & GPGME_SIGSUM_KEY_EXPIRED) {
                sig.result = Signature::Expired;
            }
            if (is->summary & GPGME_SIGSUM_KEY_MISSING) {
                sig.result = Signature::KeyNotFound;
            }
        }
        sig.status = {is->status};
        sig.isTrusted = is->validity == GPGME_VALIDITY_FULL || is->validity == GPGME_VALIDITY_ULTIMATE;
        signatures.push_back(sig);
    }
    return signatures;
}

VerificationResult Crypto::verifyDetachedSignature(CryptoProtocol protocol, const QByteArray &signature, const QByteArray &text)
{
    Context context{protocol};
    if (!context) {
        qWarning() << "Failed to create context " << context.error;
        return {{}, context.error};
    }
    auto ctx = context.context;

    auto err = gpgme_op_verify(ctx, Data{signature}.data, Data{text}.data, nullptr);
    gpgme_verify_result_t res = gpgme_op_verify_result(ctx);
    return {copySignatures(res), {err}};
}

static DecryptionResult::Result toResult(gpgme_error_t err)
{
    if (err == GPG_ERR_NO_DATA) {
        return DecryptionResult::NotEncrypted;
    } else if (err == GPG_ERR_NO_SECKEY) {
        return DecryptionResult::NoSecretKeyError;
    } else if (err == GPG_ERR_CANCELED || err == GPG_ERR_INV_PASSPHRASE) {
        return DecryptionResult::PassphraseError;
    }
    qWarning() << "unknown error" << err << gpgme_strerror(err);
    return DecryptionResult::NoSecretKeyError;
}

VerificationResult Crypto::verifyOpaqueSignature(CryptoProtocol protocol, const QByteArray &signature, QByteArray &outdata)
{
    Context context{protocol};
    if (!context) {
        qWarning() << "Failed to create context " << context.error;
        return VerificationResult{{}, context.error};
    }
    auto ctx = context.context;

    gpgme_data_t out;
    const gpgme_error_t e = gpgme_data_new(&out);
    Q_ASSERT(!e);
    auto err = gpgme_op_verify(ctx, Data{signature}.data, nullptr, out);

    VerificationResult result{{}, {err}};
    if (gpgme_verify_result_t res = gpgme_op_verify_result(ctx)) {
        result.signatures = copySignatures(res);
    }

    outdata = toBA(out);
    return result;
}

std::pair<DecryptionResult, VerificationResult> Crypto::decryptAndVerify(CryptoProtocol protocol, const QByteArray &ciphertext, QByteArray &outdata)
{
    Context context{protocol};
    if (!context) {
        qWarning() << "Failed to create context " << gpgme_strerror(context.error);
        qWarning() << "returning early";
        return std::make_pair(DecryptionResult{{}, {context.error}, DecryptionResult::NoSecretKeyError}, VerificationResult{{}, context.error});
    }
    auto ctx = context.context;

    gpgme_data_t out;
    if (gpgme_error_t e = gpgme_data_new(&out)) {
        qWarning() << "Failed to allocated data" << e;
    }
    auto err = gpgme_op_decrypt_verify(ctx, Data{ciphertext}.data, out);
    if (err) {
        qWarning() << "Failed to decrypt and verify" << Error{err};
        // We make sure we don't return any plain-text if the decryption failed to prevent EFAIL
        if (err == GPG_ERR_DECRYPT_FAILED) {
            return std::make_pair(DecryptionResult{{}, {err}, DecryptionResult::DecryptionError}, VerificationResult{{}, {err}});
        }
    }

    VerificationResult verificationResult{{}, {err}};
    if (gpgme_verify_result_t res = gpgme_op_verify_result(ctx)) {
        verificationResult.signatures = copySignatures(res);
    }

    DecryptionResult decryptionResult{{}, {err}};
    if (gpgme_decrypt_result_t res = gpgme_op_decrypt_result(ctx)) {
        decryptionResult.recipients = copyRecipients(res);
    }
    decryptionResult.result = toResult(err);

    outdata = toBA(out);
    return std::make_pair(decryptionResult, verificationResult);
}

static DecryptionResult decryptGPGME(CryptoProtocol protocol, const QByteArray &ciphertext, QByteArray &outdata)
{
    Context context{protocol};
    if (!context) {
        qWarning() << "Failed to create context " << context.error;
        return DecryptionResult{{}, context.error};
    }
    auto ctx = context.context;

    gpgme_data_t out;
    if (gpgme_error_t e = gpgme_data_new(&out)) {
        qWarning() << "Failed to allocated data" << e;
    }
    auto err = gpgme_op_decrypt(ctx, Data{ciphertext}.data, out);
    if (err) {
        qWarning() << "Failed to decrypt" << gpgme_strerror(err);
        // We make sure we don't return any plain-text if the decryption failed to prevent EFAIL
        if (err == GPG_ERR_DECRYPT_FAILED) {
            return DecryptionResult{{}, {err}};
        }
    }

    DecryptionResult decryptionResult{{}, {err}};
    if (gpgme_decrypt_result_t res = gpgme_op_decrypt_result(ctx)) {
        decryptionResult.recipients = copyRecipients(res);
    }

    decryptionResult.result = toResult(err);

    outdata = toBA(out);
    return decryptionResult;
}

DecryptionResult Crypto::decrypt(CryptoProtocol protocol, const QByteArray &ciphertext, QByteArray &outdata)
{
    return decryptGPGME(protocol, ciphertext, outdata);
}

ImportResult Crypto::importKey(CryptoProtocol protocol, const QByteArray &certData)
{
    Context context{protocol};
    if (!context) {
        qWarning() << "Failed to create context " << context.error;
        return {0, 0, 0};
    }
    if (gpgme_op_import(context.context, Data{certData}.data)) {
        qWarning() << "Import failed";
        return {0, 0, 0};
    }
    if (auto result = gpgme_op_import_result(context.context)) {
        return {result->considered, result->imported, result->unchanged};
    } else {
        return {0, 0, 0};
    }
}

static bool validateKey(const gpgme_key_t key)
{
    if (key->revoked) {
        qWarning() << "Key is revoked " << key->fpr;
        return false;
    }
    if (key->expired) {
        qWarning() << "Key is expired " << key->fpr;
        return false;
    }
    if (key->disabled) {
        qWarning() << "Key is disabled " << key->fpr;
        return false;
    }
    if (key->invalid) {
        qWarning() << "Key is invalid " << key->fpr;
        return false;
    }
    return true;
}

static KeyListResult listKeys(CryptoProtocol protocol, const std::vector<const char *> &patterns, bool secretOnly, int keyListMode, bool importKeys)
{
    Context context{protocol};
    if (!context) {
        qWarning() << "Failed to create context " << context.error;
        return {{}, context.error};
    }
    auto ctx = context.context;

    gpgme_set_keylist_mode(ctx, keyListMode);

    KeyListResult result;
    result.error = {GPG_ERR_NO_ERROR};
    auto zeroTerminatedPatterns = patterns;
    zeroTerminatedPatterns.push_back(nullptr);
    if (patterns.size() > 1) {
        if (auto err = gpgme_op_keylist_ext_start(ctx, const_cast<const char **>(zeroTerminatedPatterns.data()), int(secretOnly), 0)) {
            result.error = {err};
            qWarning() << "Error while listing keys:" << result.error;
        }
    } else if (patterns.size() == 1) {
        if (auto err = gpgme_op_keylist_start(ctx, zeroTerminatedPatterns[0], int(secretOnly))) {
            result.error = {err};
            qWarning() << "Error while listing keys:" << result.error;
        }
    } else {
        if (auto err = gpgme_op_keylist_start(ctx, nullptr, int(secretOnly))) {
            result.error = {err};
            qWarning() << "Error while listing keys:" << result.error;
        }
    }

    std::vector<gpgme_key_t> listedKeys;
    while (true) {
        gpgme_key_t key;
        if (auto err = gpgme_op_keylist_next(ctx, &key)) {
            if (gpgme_err_code(err) != GPG_ERR_EOF) {
                qWarning() << "Error after listing keys" << result.error << gpgme_strerror(err);
            }
            break;
        }

        listedKeys.push_back(key);

        Key k;
        if (key->subkeys) {
            k.keyId = QByteArray{key->subkeys->keyid};
            k.shortKeyId = k.keyId.right(8);
            k.fingerprint = QByteArray{key->subkeys->fpr};
        }
        for (gpgme_user_id_t uid = key->uids; uid; uid = uid->next) {
            k.userIds.push_back(UserId{QByteArray{uid->name}, QByteArray{uid->email}, QByteArray{uid->uid}});
        }
        k.isUsable = validateKey(key);
        result.keys.push_back(k);
    }
    gpgme_op_keylist_end(ctx);

    if (importKeys && !listedKeys.empty()) {
        listedKeys.push_back(nullptr);
        if (auto err = gpgme_op_import_keys(ctx, const_cast<gpgme_key_t *>(listedKeys.data()))) {
            qWarning() << "Error while importing keys" << gpgme_strerror(err);
        }
    }
    return result;
}

/**
 * Get the given `key` in the armor format.
 */
Expected<Error, QByteArray> Crypto::exportPublicKey(const Key &key)
{
    Context context;
    if (!context) {
        return makeUnexpected(Error{context.error});
    }

    gpgme_data_t out;
    const gpgme_error_t e = gpgme_data_new(&out);
    Q_ASSERT(!e);

    qDebug() << "Exporting public key:" << key.keyId;
    if (auto err = gpgme_op_export(context.context, key.keyId.data(), 0, out)) {
        return makeUnexpected(Error{err});
    }

    return toBA(out);
}

Expected<Error, QByteArray> Crypto::signAndEncrypt(const QByteArray &content, const std::vector<Key> &encryptionKeys, const std::vector<Key> &signingKeys)
{
    Context context;
    if (!context) {
        return makeUnexpected(Error{context.error});
    }

    for (const auto &signingKey : signingKeys) {
        qDebug() << "Signing with " << signingKey;
        // TODO do we have to free those again?
        gpgme_key_t key;
        if (auto e = gpgme_get_key(context.context, signingKey.fingerprint.data(), &key, /*secret*/ false)) {
            qWarning() << "Failed to retrieve signing key " << signingKey.fingerprint << Error{e};
            return makeUnexpected(Error{e});
        } else {
            gpgme_signers_add(context.context, key);
        }
    }

    gpgme_key_t *const keys = new gpgme_key_t[encryptionKeys.size() + 1];
    gpgme_key_t *keys_it = keys;
    for (const auto &k : encryptionKeys) {
        qDebug() << "Encrypting to " << k;
        gpgme_key_t key;
        if (auto e = gpgme_get_key(context.context, k.fingerprint.data(), &key, /*secret*/ false)) {
            delete[] keys;
            qWarning() << "Failed to retrieve key " << k.fingerprint << Error{e};
            return makeUnexpected(Error{e});
        } else {
            if (!key->can_encrypt || !validateKey(key)) {
                qWarning() << "Key cannot be used for encryption " << k.fingerprint;
                delete[] keys;
                return makeUnexpected(Error{e});
            }
            *keys_it++ = key;
        }
    }
    *keys_it++ = nullptr;

    gpgme_data_t out;
    if (auto e = gpgme_data_new(&out)) {
        qWarning() << "Failed to allocate output buffer";
        delete[] keys;
        return makeUnexpected(Error{e});
    }

    gpgme_error_t err = !signingKeys.empty() ? gpgme_op_encrypt_sign(context.context, keys, GPGME_ENCRYPT_ALWAYS_TRUST, Data{content}.data, out)
                                             : gpgme_op_encrypt(context.context, keys, GPGME_ENCRYPT_ALWAYS_TRUST, Data{content}.data, out);
    delete[] keys;
    if (err) {
        qWarning() << "Encryption failed:" << gpgme_err_code(err);
        switch (gpgme_err_code(err)) {
        case GPG_ERR_UNUSABLE_PUBKEY:
            for (const auto &k : encryptionKeys) {
                qWarning() << "Encryption key:" << k;
            }
            break;
        case GPG_ERR_UNUSABLE_SECKEY:
            for (const auto &k : signingKeys) {
                qWarning() << "Signing key:" << k;
            }
            break;
        default:
            break;
        }
        return makeUnexpected(Error{err});
    }

    return toBA(out);
}

Expected<Error, std::pair<QByteArray, QString>> Crypto::sign(const QByteArray &content, const std::vector<Key> &signingKeys)
{
    Context context;
    if (!context) {
        return makeUnexpected(Error{context.error});
    }

    for (const auto &signingKey : signingKeys) {
        // TODO do we have to free those again?
        gpgme_key_t key;
        if (auto e = gpgme_get_key(context.context, signingKey.fingerprint.data(), &key, /*secret*/ false)) {
            qWarning() << "Failed to retrieve signing key " << signingKey.fingerprint << Error{e};
            return makeUnexpected(Error{e});
        } else {
            gpgme_signers_add(context.context, key);
        }
    }

    gpgme_data_t out;
    const gpgme_error_t e = gpgme_data_new(&out);
    Q_ASSERT(!e);

    if (auto err = gpgme_op_sign(context.context, Data{content}.data, out, GPGME_SIG_MODE_DETACH)) {
        qWarning() << "Signing failed:" << Error{err};
        return makeUnexpected(Error{err});
    }

    const QByteArray algo = [&] {
        if (gpgme_sign_result_t res = gpgme_op_sign_result(context.context)) {
            if (gpgme_new_signature_t is = res->signatures) {
                return QByteArray{gpgme_hash_algo_name(is->hash_algo)};
            }
        }
        return QByteArray{};
    }();
    // RFC 3156 Section 5:
    // Hash-symbols are constructed [...] by converting the text name to lower
    // case and prefixing it with the four characters "pgp-".
    const auto micAlg = (QStringLiteral("pgp-") + QString::fromUtf8(algo)).toLower();

    return std::pair<QByteArray, QString>{toBA(out), micAlg};
}

std::vector<Key> Crypto::findKeys(const QStringList &patterns, bool findPrivate, bool remote)
{
    QByteArrayList list;
    std::transform(patterns.constBegin(), patterns.constEnd(), std::back_inserter(list), [](const QString &s) {
        return s.toUtf8();
    });
    std::vector<char const *> pattern;
    std::transform(list.constBegin(), list.constEnd(), std::back_inserter(pattern), [](const QByteArray &s) {
        return s.constData();
    });

    const KeyListResult res = listKeys(OpenPGP, pattern, findPrivate, remote ? GPGME_KEYLIST_MODE_EXTERN : GPGME_KEYLIST_MODE_LOCAL, remote);
    if (res.error) {
        qWarning() << "Failed to lookup keys: " << res.error;
        return {};
    }
    qDebug() << "Found " << res.keys.size() << " keys for the patterns: " << patterns;

    std::vector<Key> usableKeys;
    for (const auto &key : res.keys) {
        if (!key.isUsable) {
            qWarning() << "Key is not usable: " << key.fingerprint;
            continue;
        }

        qDebug() << "Key:" << key.fingerprint;
        for (const auto &userId : key.userIds) {
            qDebug() << "  userID:" << userId.email;
        }
        usableKeys.push_back(key);
    }
    return usableKeys;
}

#endif
