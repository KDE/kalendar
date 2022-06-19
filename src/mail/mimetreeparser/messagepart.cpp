// SPDX-FileCopyrightText: 2015 Sandro Knauß <knauss@kolabsys.com>
// SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "messagepart.h"
#include "cryptohelper.h"
#include "mimetreeparser_debug.h"
#include "objecttreeparser.h"

#include "utils.h"

#include <KLocalizedString>
#include <KMime/Content>

#include <QTextCodec>

using namespace MimeTreeParser;
using namespace Crypto;

//------MessagePart-----------------------
MessagePart::MessagePart(ObjectTreeParser *otp, const QString &text, KMime::Content *node)
    : mText(text)
    , mOtp(otp)
    , mParentPart(nullptr)
    , mNode(node) // only null for messagepartlist
    , mError(NoError)
    , mRoot(false)
{
}

MessagePart::~MessagePart()
{
    for (auto n : mNodesToDelete) {
        delete n;
    }
}

MessagePart::Disposition MessagePart::disposition() const
{
    if (!mNode) {
        return Invalid;
    }
    const auto cd = mNode->contentDisposition(false);
    if (!cd) {
        return Invalid;
    }
    switch (cd->disposition()) {
    case KMime::Headers::CDinline:
        return Inline;
    case KMime::Headers::CDattachment:
        return Attachment;
    default:
        return Invalid;
    }
}

QString MessagePart::filename() const
{
    if (!mNode) {
        return {};
    }

    if (const auto cd = mNode->contentDisposition(false)) {
        const auto name = cd->filename();
        // Allow for a fallback for mails that have a ContentDisposition header, but don't set the filename anyways.
        // Not the recommended way, but exists.
        if (!name.isEmpty()) {
            return name;
        }
    }
    if (const auto ct = mNode->contentType(false)) {
        return ct->name();
    }
    return {};
}

static KMime::Headers::ContentType *contentType(KMime::Content *node)
{
    if (node) {
        return node->contentType(false);
    }
    return nullptr;
}

QByteArray MessagePart::charset() const
{
    if (!mNode) {
        return "us-ascii";
    }
    if (auto ct = contentType(mNode)) {
        return ct->charset();
    }
    // Per rfc2045 us-ascii is the default
    return "us-ascii";
}

QByteArray MessagePart::mimeType() const
{
    if (auto ct = contentType(mNode)) {
        return ct->mimeType();
    }
    return {};
}

bool MessagePart::isText() const
{
    if (auto ct = contentType(mNode)) {
        return ct->isText();
    }
    return false;
}

MessagePart::Error MessagePart::error() const
{
    return mError;
}

QString MessagePart::errorString() const
{
    return mMetaData.errorText;
}

PartMetaData *MessagePart::partMetaData()
{
    return &mMetaData;
}

bool MessagePart::isAttachment() const
{
    if (mNode) {
        return KMime::isAttachment(mNode);
    }
    return false;
}

KMime::Content *MessagePart::node() const
{
    return mNode;
}

void MessagePart::setIsRoot(bool root)
{
    mRoot = root;
}

bool MessagePart::isRoot() const
{
    return mRoot;
}

QString MessagePart::text() const
{
    return mText;
}

void MessagePart::setText(const QString &text)
{
    mText = text;
}

bool MessagePart::isHtml() const
{
    return false;
}

MessagePart *MessagePart::parentPart() const
{
    return mParentPart;
}

void MessagePart::setParentPart(MessagePart *parentPart)
{
    mParentPart = parentPart;
}

QString MessagePart::htmlContent() const
{
    return text();
}

QString MessagePart::plaintextContent() const
{
    return text();
}

void MessagePart::parseInternal(KMime::Content *node, bool onlyOneMimePart)
{
    auto subMessagePart = mOtp->parseObjectTreeInternal(node, onlyOneMimePart);
    mRoot = subMessagePart->isRoot();
    for (const auto &part : std::as_const(subMessagePart->subParts())) {
        appendSubPart(part);
    }
}

void MessagePart::parseInternal(const QByteArray &data)
{
    auto tempNode = new KMime::Content();

    const auto lfData = KMime::CRLFtoLF(data);
    // We have to deal with both bodies and full parts. In inline encrypted/signed parts we can have nested parts,
    // or just plain-text, and both ends up here. setContent defaults to setting only the header, so we have to avoid this.
    if (lfData.contains("\n\n")) {
        tempNode->setContent(lfData);
    } else {
        tempNode->setBody(lfData);
    }
    tempNode->parse();
    tempNode->contentType()->setCharset(charset());
    bindLifetime(tempNode);

    if (!tempNode->head().isEmpty()) {
        tempNode->contentDescription()->from7BitString("temporary node");
    }

    parseInternal(tempNode);
}

QString MessagePart::renderInternalText() const
{
    QString text;
    for (const auto &mp : subParts()) {
        text += mp->text();
    }
    return text;
}

void MessagePart::appendSubPart(const MessagePart::Ptr &messagePart)
{
    messagePart->setParentPart(this);
    mBlocks.append(messagePart);
}

const QVector<MessagePart::Ptr> &MessagePart::subParts() const
{
    return mBlocks;
}

bool MessagePart::hasSubParts() const
{
    return !mBlocks.isEmpty();
}

QVector<SignedMessagePart *> MessagePart::signatures() const
{
    QVector<SignedMessagePart *> list;
    if (auto sig = dynamic_cast<SignedMessagePart *>(const_cast<MessagePart *>(this))) {
        list << sig;
    }
    auto parent = parentPart();
    while (parent) {
        if (auto sig = dynamic_cast<SignedMessagePart *>(parent)) {
            list << sig;
        }
        parent = parent->parentPart();
    }
    return list;
}

QVector<EncryptedMessagePart *> MessagePart::encryptions() const
{
    QVector<EncryptedMessagePart *> list;
    if (auto sig = dynamic_cast<EncryptedMessagePart *>(const_cast<MessagePart *>(this))) {
        list << sig;
    }
    auto parent = parentPart();
    while (parent) {
        if (auto sig = dynamic_cast<EncryptedMessagePart *>(parent)) {
            list << sig;
        }
        parent = parent->parentPart();
    }
    return list;
}

KMMsgEncryptionState MessagePart::encryptionState() const
{
    if (!encryptions().isEmpty()) {
        return KMMsgFullyEncrypted;
    }
    return KMMsgNotEncrypted;
}

KMMsgSignatureState MessagePart::signatureState() const
{
    if (!signatures().isEmpty()) {
        return KMMsgFullySigned;
    }
    return KMMsgNotSigned;
}

void MessagePart::bindLifetime(KMime::Content *node)
{
    mNodesToDelete << node;
}

KMime::Headers::Base *MimeTreeParser::MessagePart::header(const char *header) const
{
    if (node() && node()->hasHeader(header)) {
        return node()->headerByType(header);
    }
    if (auto parent = parentPart()) {
        return parent->header(header);
    }

    return nullptr;
}

//-----MessagePartList----------------------
MessagePartList::MessagePartList(ObjectTreeParser *otp, KMime::Content *node)
    : MessagePart(otp, QString(), node)
{
}

QString MessagePartList::text() const
{
    return renderInternalText();
}

QString MessagePartList::plaintextContent() const
{
    return QString();
}

QString MessagePartList::htmlContent() const
{
    return QString();
}

//-----TextMessageBlock----------------------

TextMessagePart::TextMessagePart(ObjectTreeParser *otp, KMime::Content *node)
    : MessagePartList(otp, node)
    , mSignatureState(KMMsgSignatureStateUnknown)
    , mEncryptionState(KMMsgEncryptionStateUnknown)
{
    if (!mNode) {
        qCWarning(MIMETREEPARSER_LOG) << "not a valid node";
        return;
    }

    parseContent();
}

void TextMessagePart::parseContent()
{
    mSignatureState = KMMsgNotSigned;
    mEncryptionState = KMMsgNotEncrypted;
    const auto blocks = prepareMessageForDecryption(mNode->decodedContent());
    // We also get blocks for unencrypted messages
    if (!blocks.isEmpty()) {
        const auto aCodec = mOtp->codecFor(mNode);
        const auto cryptProto = OpenPGP;

        /* The (overall) signature/encrypted status is broken
         * if one unencrypted part is at the beginning or in the middle
         * because mailmain adds an unencrypted part at the end this should not break the overall status
         *
         * That's why we first set the tmp status and if one crypted/signed block comes afterwards, than
         * the status is set to unencryped
         */
        bool fullySignedOrEncrypted = true;
        bool fullySignedOrEncryptedTmp = true;

        for (const auto &block : blocks) {
            if (!fullySignedOrEncryptedTmp) {
                fullySignedOrEncrypted = false;
            }

            if (block.type() == NoPgpBlock && !block.text().trimmed().isEmpty()) {
                fullySignedOrEncryptedTmp = false;
                appendSubPart(MessagePart::Ptr(new MessagePart(mOtp, aCodec->toUnicode(KMime::CRLFtoLF(block.text())))));
            } else if (block.type() == PgpMessageBlock) {
                KMime::Content *content = new KMime::Content;
                content->setBody(block.text());
                content->parse();
                content->contentType()->setCharset(charset());
                EncryptedMessagePart::Ptr mp(new EncryptedMessagePart(mOtp, QString(), cryptProto, content, content, false));
                mp->bindLifetime(content);
                mp->setIsEncrypted(true);
                appendSubPart(mp);
            } else if (block.type() == ClearsignedBlock) {
                KMime::Content *content = new KMime::Content;
                content->setBody(block.text());
                content->parse();
                content->contentType()->setCharset(charset());
                SignedMessagePart::Ptr mp(new SignedMessagePart(mOtp, cryptProto, nullptr, content, false));
                mp->bindLifetime(content);
                mp->setIsSigned(true);
                appendSubPart(mp);
            } else {
                continue;
            }

            const auto mp = subParts().last().staticCast<MessagePart>();
            const PartMetaData *messagePart(mp->partMetaData());

            if (!messagePart->isEncrypted && !messagePart->isSigned && !block.text().trimmed().isEmpty()) {
                mp->setText(aCodec->toUnicode(KMime::CRLFtoLF(block.text())));
            }

            if (messagePart->isEncrypted) {
                mEncryptionState = KMMsgPartiallyEncrypted;
            }

            if (messagePart->isSigned) {
                mSignatureState = KMMsgPartiallySigned;
            }
        }

        // Do we have an fully Signed/Encrypted Message?
        if (fullySignedOrEncrypted) {
            if (mSignatureState == KMMsgPartiallySigned) {
                mSignatureState = KMMsgFullySigned;
            }
            if (mEncryptionState == KMMsgPartiallyEncrypted) {
                mEncryptionState = KMMsgFullyEncrypted;
            }
        }
    }
}

KMMsgEncryptionState TextMessagePart::encryptionState() const
{
    if (mEncryptionState == KMMsgNotEncrypted) {
        return MessagePart::encryptionState();
    }
    return mEncryptionState;
}

KMMsgSignatureState TextMessagePart::signatureState() const
{
    if (mSignatureState == KMMsgNotSigned) {
        return MessagePart::signatureState();
    }
    return mSignatureState;
}

//-----AttachmentMessageBlock----------------------

AttachmentMessagePart::AttachmentMessagePart(ObjectTreeParser *otp, KMime::Content *node)
    : TextMessagePart(otp, node)
{
}

//-----HtmlMessageBlock----------------------

HtmlMessagePart::HtmlMessagePart(ObjectTreeParser *otp, KMime::Content *node)
    : MessagePart(otp, QString(), node)
{
    if (!mNode) {
        qCWarning(MIMETREEPARSER_LOG) << "not a valid node";
        return;
    }

    setText(mOtp->codecFor(mNode)->toUnicode(KMime::CRLFtoLF(mNode->decodedContent())));
}

//-----MimeMessageBlock----------------------

MimeMessagePart::MimeMessagePart(ObjectTreeParser *otp, KMime::Content *node, bool onlyOneMimePart)
    : MessagePart(otp, QString(), node)
{
    if (!mNode) {
        qCWarning(MIMETREEPARSER_LOG) << "not a valid node";
        return;
    }

    parseInternal(mNode, onlyOneMimePart);
}

MimeMessagePart::~MimeMessagePart()
{
}

QString MimeMessagePart::text() const
{
    return renderInternalText();
}

QString MimeMessagePart::plaintextContent() const
{
    return QString();
}

QString MimeMessagePart::htmlContent() const
{
    return QString();
}

//-----AlternativeMessagePart----------------------

AlternativeMessagePart::AlternativeMessagePart(ObjectTreeParser *otp, KMime::Content *node)
    : MessagePart(otp, QString(), node)
{
    if (auto dataIcal = findTypeInDirectChildren(mNode, "text/calendar")) {
        mChildParts[MultipartIcal] = MimeMessagePart::Ptr(new MimeMessagePart(mOtp, dataIcal, true));
    }

    if (auto dataText = findTypeInDirectChildren(mNode, "text/plain")) {
        mChildParts[MultipartPlain] = MimeMessagePart::Ptr(new MimeMessagePart(mOtp, dataText, true));
    }

    if (auto dataHtml = findTypeInDirectChildren(mNode, "text/html")) {
        mChildParts[MultipartHtml] = MimeMessagePart::Ptr(new MimeMessagePart(mOtp, dataHtml, true));
    } else {
        // If we didn't find the HTML part as the first child of the multipart/alternative, it might
        // be that this is a HTML message with images, and text/plain and multipart/related are the
        // immediate children of this multipart/alternative node.
        // In this case, the HTML node is a child of multipart/related.
        // In the case of multipart/related we don't expect multiple html parts, it is usually used to group attachments
        // with html content.
        //
        // In any case, this is not a complete implementation of MIME, but an approximation for the kind of mails we actually see in the wild.
        auto data = [&] {
            if (auto d = findTypeInDirectChildren(mNode, "multipart/related")) {
                return d;
            }
            return findTypeInDirectChildren(mNode, "multipart/mixed");
        }();
        if (data) {
            QString htmlContent;
            const auto parts = data->contents();
            for (auto p : data->contents()) {
                if ((!p->contentType()->isEmpty()) && (p->contentType()->mimeType() == "text/html")) {
                    htmlContent += MimeMessagePart(mOtp, p, true).text();
                } else if (KMime::isAttachment(p)) {
                    appendSubPart(MimeMessagePart::Ptr(new MimeMessagePart(otp, p, true)));
                }
            }
            mChildParts[MultipartHtml] = MessagePart::Ptr(new MessagePart(mOtp, htmlContent, nullptr));
        }
    }
}

AlternativeMessagePart::~AlternativeMessagePart()
{
}

QList<AlternativeMessagePart::HtmlMode> AlternativeMessagePart::availableModes()
{
    return mChildParts.keys();
}

QString AlternativeMessagePart::text() const
{
    if (mChildParts.contains(MultipartPlain)) {
        return mChildParts[MultipartPlain]->text();
    }
    return QString();
}

bool AlternativeMessagePart::isHtml() const
{
    return mChildParts.contains(MultipartHtml);
}

QString AlternativeMessagePart::plaintextContent() const
{
    return text();
}

QString AlternativeMessagePart::htmlContent() const
{
    if (mChildParts.contains(MultipartHtml)) {
        return mChildParts[MultipartHtml]->text();
    } else {
        return plaintextContent();
    }
}

QString AlternativeMessagePart::icalContent() const
{
    if (mChildParts.contains(MultipartIcal)) {
        return mChildParts[MultipartIcal]->text();
    }
    return {};
}

//-----CertMessageBlock----------------------

CertMessagePart::CertMessagePart(ObjectTreeParser *otp, KMime::Content *node, const CryptoProtocol cryptoProto)
    : MessagePart(otp, QString(), node)
    , mProtocol(cryptoProto)
{
    if (!mNode) {
        qCWarning(MIMETREEPARSER_LOG) << "not a valid node";
        return;
    }
}

CertMessagePart::~CertMessagePart()
{
}

void CertMessagePart::import()
{
    importKey(mProtocol, mNode->decodedContent());
}

QString CertMessagePart::text() const
{
    return QString();
}

//-----SignedMessageBlock---------------------
SignedMessagePart::SignedMessagePart(ObjectTreeParser *otp,
                                     const CryptoProtocol cryptoProto,
                                     KMime::Content *node,
                                     KMime::Content *signedData,
                                     bool parseAfterDecryption)
    : MessagePart(otp, {}, node)
    , mParseAfterDecryption(parseAfterDecryption)
    , mProtocol(cryptoProto)
    , mSignedData(signedData)
{
    mMetaData.isSigned = true;
    mMetaData.isGoodSignature = false;
    mMetaData.status = i18n("Wrong Crypto Plug-In.");
}

SignedMessagePart::~SignedMessagePart()
{
}

void SignedMessagePart::setIsSigned(bool isSigned)
{
    mMetaData.isSigned = isSigned;
}

bool SignedMessagePart::isSigned() const
{
    return mMetaData.isSigned;
}

static QString prettifyDN(const char *uid)
{
    // We used to use QGpgME::DN::prettyDN here. But I'm not sure what we actually need it for.
    return QString::fromUtf8(uid);
}

static void sigStatusToMetaData(PartMetaData &mMetaData, const Signature &signature)
{
    mMetaData.isGoodSignature = signature.status.errorCode() == GPG_ERR_NO_ERROR;
    if (!mMetaData.isGoodSignature) {
        if (signature.status.errorCode() == GPG_ERR_NO_PUBKEY) {
            qWarning() << "No public key to verify signature.";
        } else {
            qWarning() << "Is no good signature" << signature.status;
        }
    }
    // save extended signature status flags
    auto summary = signature.summary;
    mMetaData.keyMissing = summary & GPGME_SIGSUM_KEY_MISSING;
    mMetaData.keyExpired = summary & GPGME_SIGSUM_KEY_EXPIRED;
    mMetaData.keyRevoked = summary & GPGME_SIGSUM_KEY_REVOKED;
    mMetaData.sigExpired = summary & GPGME_SIGSUM_SIG_EXPIRED;
    mMetaData.crlMissing = summary & GPGME_SIGSUM_CRL_MISSING;
    mMetaData.crlTooOld = summary & GPGME_SIGSUM_CRL_TOO_OLD;

    Key key;
    if (mMetaData.isGoodSignature) {
        // Search for the key by its fingerprint so that we can check for trust etc.
        const auto keys = findKeys({QString::fromUtf8(signature.fingerprint)});
        if (keys.size() > 1) {
            // Should not happen
            qCDebug(MIMETREEPARSER_LOG) << "Oops: Found more then one Key for Fingerprint: " << signature.fingerprint;
        }
        if (keys.empty()) {
            // Should not happen at this point
            qCWarning(MIMETREEPARSER_LOG) << "Oops: Found no Key for Fingerprint: " << signature.fingerprint;
        } else {
            key = keys[0];
        }
    }

    mMetaData.keyId = key.keyId;
    if (mMetaData.keyId.isEmpty()) {
        mMetaData.keyId = signature.fingerprint;
    }
    mMetaData.keyIsTrusted = signature.validity == GPGME_VALIDITY_FULL || signature.validity == GPGME_VALIDITY_ULTIMATE;
    if (!key.userIds.empty()) {
        mMetaData.signer = prettifyDN(key.userIds[0].id.data());
    }
    for (const auto &userId : key.userIds) {
        QString email = QString::fromUtf8(userId.email);
        // Work around cryptplug bug where email addresses are specified as angle-addr ( <person@example.org> ),
        // not addr-spec ( person@example.org ):
        if (email.startsWith(QLatin1Char('<')) && email.endsWith(QLatin1Char('>'))) {
            email = email.mid(1, email.length() - 2);
        }
        if (!email.isEmpty()) {
            mMetaData.signerMailAddresses.append(email);
        }
    }

    mMetaData.creationTime = signature.creationTime;
    if (mMetaData.signer.isEmpty()) {
        if (!key.userIds.empty()) {
            mMetaData.signer = prettifyDN(key.userIds[0].name.data());
        }
        if (!mMetaData.signerMailAddresses.empty()) {
            if (mMetaData.signer.isEmpty()) {
                mMetaData.signer = mMetaData.signerMailAddresses.front();
            } else {
                mMetaData.signer += QLatin1String(" <") + mMetaData.signerMailAddresses.front() + QLatin1Char('>');
            }
        }
    }
}

void SignedMessagePart::startVerification()
{
    if (!mSignedData) {
        return;
    }

    mMetaData.isSigned = false;
    mMetaData.status = i18n("Wrong Crypto Plug-In.");
    mMetaData.isEncrypted = false;
    mMetaData.isDecryptable = false;

    const auto codec = mOtp->codecFor(mSignedData);

    // If we have a mNode, this is a detached signature
    if (mNode) {
        const auto signature = mNode->decodedContent();

        // This is necessary in case the original data contained CRLF's. Otherwise the signature will not match the data (since KMIME normalizes to LF)
        const QByteArray signedData = KMime::LFtoCRLF(mSignedData->encodedContent());

        setVerificationResult(verifyDetachedSignature(mProtocol, signature, signedData), signedData);
        setText(codec->toUnicode(KMime::CRLFtoLF(signedData)));
    } else {
        QByteArray outdata;
        setVerificationResult(verifyOpaqueSignature(mProtocol, mSignedData->decodedContent(), outdata), outdata);
        setText(codec->toUnicode(KMime::CRLFtoLF(outdata)));
    }

    if (!mMetaData.isSigned) {
        mMetaData.creationTime = QDateTime();
    }
}

void SignedMessagePart::setVerificationResult(const VerificationResult &result, const QByteArray &signedData)
{
    const auto signatures = result.signatures;
    // FIXME
    // mMetaData.auditLogError = result.error;
    if (!signatures.empty()) {
        mMetaData.isSigned = true;
        sigStatusToMetaData(mMetaData, signatures.front());
        if (!signedData.isEmpty() && mParseAfterDecryption) {
            parseInternal(signedData);
        }
    }
}

QString SignedMessagePart::plaintextContent() const
{
    if (!mNode) {
        return MessagePart::text();
    } else {
        return QString();
    }
}

QString SignedMessagePart::htmlContent() const
{
    if (!mNode) {
        return MessagePart::text();
    } else {
        return QString();
    }
}

//-----CryptMessageBlock---------------------
EncryptedMessagePart::EncryptedMessagePart(ObjectTreeParser *otp,
                                           const QString &text,
                                           const CryptoProtocol cryptoProto,
                                           KMime::Content *node,
                                           KMime::Content *encryptedNode,
                                           bool parseAfterDecryption)
    : MessagePart(otp, text, node)
    , mParseAfterDecryption(parseAfterDecryption)
    , mProtocol(cryptoProto)
    , mEncryptedNode(encryptedNode)
{
    mMetaData.isSigned = false;
    mMetaData.isGoodSignature = false;
    mMetaData.isEncrypted = false;
    mMetaData.isDecryptable = false;
    mMetaData.status = i18n("Wrong Crypto Plug-In.");
}

void EncryptedMessagePart::setIsEncrypted(bool encrypted)
{
    mMetaData.isEncrypted = encrypted;
}

bool EncryptedMessagePart::isEncrypted() const
{
    return mMetaData.isEncrypted;
}

bool EncryptedMessagePart::isDecryptable() const
{
    return mMetaData.isDecryptable;
}

bool EncryptedMessagePart::decrypt(KMime::Content &data)
{
    mError = NoError;
    mMetaData.errorText.clear();
    // FIXME
    //  mMetaData.auditLogError = GpgME::Error();
    mMetaData.auditLog.clear();

    const QByteArray ciphertext = data.decodedContent();
    QByteArray plainText;
    DecryptionResult decryptResult;
    VerificationResult verifyResult;
    std::tie(decryptResult, verifyResult) = decryptAndVerify(mProtocol, ciphertext, plainText);
    mMetaData.isSigned = verifyResult.signatures.size() > 0;

    // Normalize CRLF's
    plainText = KMime::CRLFtoLF(plainText);
    const auto codec = mOtp->codecFor(&data);
    const auto decoded = codec->toUnicode(plainText);

    if (verifyResult.signatures.size() > 0) {
        // We simply attach a signed message part to indicate that this content is also signed
        // We're forwarding mNode to not loose the encoding information
        auto subPart = SignedMessagePart::Ptr(new SignedMessagePart(mOtp, mProtocol, mNode, nullptr));
        subPart->setText(decoded);
        subPart->setVerificationResult(verifyResult, plainText);
        appendSubPart(subPart);
    }

    if (decryptResult.error && mMetaData.isSigned) {
        // Only a signed part
        mMetaData.isEncrypted = false;
        mDecryptedData = plainText;
        return true;
    }

    if (mMetaData.isEncrypted) {
        mMetaData.keyId = [&] {
            for (const auto &recipient : std::as_const(decryptResult.recipients)) {
                if (recipient.status.errorCode() != GPG_ERR_NO_SECKEY) {
                    return recipient.keyId;
                }
            }
            return QByteArray{};
        }();
    }

    if (!decryptResult.error) {
        mDecryptedData = plainText;
        setText(decoded);
    } else {
        const auto errorCode = decryptResult.error.errorCode();
        mMetaData.isEncrypted = errorCode != GPG_ERR_NO_DATA;
        qWarning() << "Failed to decrypt : " << decryptResult.error;

        const bool noSecretKeyAvilable = mMetaData.keyId.isEmpty();
        bool passphraseError = errorCode == GPG_ERR_CANCELED || errorCode == GPG_ERR_NO_SECKEY;
        // We only get a decryption failed error when we enter the wrong passphrase....
        if (!passphraseError && !noSecretKeyAvilable) {
            passphraseError = true;
        }

        if (noSecretKeyAvilable) {
            mError = NoKeyError;
            mMetaData.errorText = i18n("Could not decrypt the data: no key found for recipients.");
        } else if (passphraseError) {
            mError = PassphraseError;
            mMetaData.errorText = QString::fromLocal8Bit(decryptResult.error.errorMessage());
        } else {
            mError = UnknownError;
            mMetaData.errorText = i18n("Could not decrypt the data. Error: %1", QString::fromLocal8Bit(decryptResult.error.errorMessage()));
        }
        setText(QString::fromUtf8(mDecryptedData.constData()));
        return false;
    }

    return true;
}

void EncryptedMessagePart::startDecryption(KMime::Content *data)
{
    mMetaData.isEncrypted = true;
    mMetaData.isDecryptable = decrypt(*data);

    if (mParseAfterDecryption && !mMetaData.isSigned) {
        parseInternal(mDecryptedData);
    }
}

void EncryptedMessagePart::startDecryption()
{
    if (mEncryptedNode) {
        startDecryption(mEncryptedNode);
    } else {
        startDecryption(mNode);
    }
}

QString EncryptedMessagePart::plaintextContent() const
{
    if (!mNode) {
        return MessagePart::text();
    } else {
        return QString();
    }
}

QString EncryptedMessagePart::htmlContent() const
{
    if (!mNode) {
        return MessagePart::text();
    } else {
        return QString();
    }
}

QString EncryptedMessagePart::text() const
{
    if (hasSubParts()) {
        auto _mp = (subParts()[0]).dynamicCast<SignedMessagePart>();
        if (_mp) {
            return _mp->text();
        } else {
            return MessagePart::text();
        }
    } else {
        return MessagePart::text();
    }
}

EncapsulatedRfc822MessagePart::EncapsulatedRfc822MessagePart(ObjectTreeParser *otp, KMime::Content *node, const KMime::Message::Ptr &message)
    : MessagePart(otp, QString(), node)
    , mMessage(message)
{
    mMetaData.isEncrypted = false;
    mMetaData.isSigned = false;
    mMetaData.isEncapsulatedRfc822Message = true;

    if (!mMessage) {
        qCWarning(MIMETREEPARSER_LOG) << "Node is of type message/rfc822 but doesn't have a message!";
        return;
    }

    parseInternal(message.data());
}

QString EncapsulatedRfc822MessagePart::text() const
{
    return renderInternalText();
}

QString EncapsulatedRfc822MessagePart::from() const
{
    if (auto from = mMessage->from(false)) {
        return from->asUnicodeString();
    }
    return {};
}

QDateTime EncapsulatedRfc822MessagePart::date() const
{
    if (auto date = mMessage->date(false)) {
        return date->dateTime();
    }
    return {};
}

HeadersPart::HeadersPart(ObjectTreeParser *otp, KMime::Content *node)
    : MessagePart(otp, QString(), node)
{
}
