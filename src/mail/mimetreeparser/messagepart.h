/*
   Copyright (c) 2015 Sandro Knauß <sknauss@kde.org>

   This library is free software; you can redistribute it and/or modify it
   under the terms of the GNU Library General Public License as published by
   the Free Software Foundation; either version 2 of the License, or (at your
   option) any later version.

   This library is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
   License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to the
   Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301, USA.
*/
#pragma once

#include "../crypto.h"
#include "partmetadata.h"

#include <KMime/Message>

#include <QSharedPointer>
#include <QString>

class QTextCodec;

namespace KMime
{
class Content;
}

namespace MimeTreeParser
{

/** Flags for the encryption state. */
typedef enum { KMMsgEncryptionStateUnknown, KMMsgNotEncrypted, KMMsgPartiallyEncrypted, KMMsgFullyEncrypted, KMMsgEncryptionProblematic } KMMsgEncryptionState;

/** Flags for the signature state. */
typedef enum { KMMsgSignatureStateUnknown, KMMsgNotSigned, KMMsgPartiallySigned, KMMsgFullySigned, KMMsgSignatureProblematic } KMMsgSignatureState;

class ObjectTreeParser;
class MultiPartAlternativeBodyPartFormatter;

class SignedMessagePart;
class EncryptedMessagePart;

using Crypto::CryptoProtocol;
using Crypto::CryptoProtocol::CMS;
using Crypto::CryptoProtocol::OpenPGP;
using Crypto::CryptoProtocol::UnknownProtocol;

class MessagePart : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool attachment READ isAttachment)
    Q_PROPERTY(bool root READ isRoot)
    Q_PROPERTY(bool isHtml READ isHtml)
    Q_PROPERTY(QString plaintextContent READ plaintextContent)
    Q_PROPERTY(QString htmlContent READ htmlContent)
public:
    enum Disposition { Inline, Attachment, Invalid };
    typedef QSharedPointer<MessagePart> Ptr;
    MessagePart(ObjectTreeParser *otp, const QString &text, KMime::Content *node = nullptr);

    virtual ~MessagePart();

    virtual QString text() const;
    void setText(const QString &text);
    virtual bool isAttachment() const;

    void setIsRoot(bool root);
    bool isRoot() const;

    void setParentPart(MessagePart *parentPart);
    MessagePart *parentPart() const;

    virtual QString plaintextContent() const;
    virtual QString htmlContent() const;

    virtual bool isHtml() const;

    QByteArray mimeType() const;
    QByteArray charset() const;
    QString filename() const;
    Disposition disposition() const;
    bool isText() const;

    enum Error { NoError = 0, PassphraseError, NoKeyError, UnknownError };

    Error error() const;
    QString errorString() const;

    PartMetaData *partMetaData();

    void appendSubPart(const MessagePart::Ptr &messagePart);
    const QVector<MessagePart::Ptr> &subParts() const;
    bool hasSubParts() const;

    KMime::Content *node() const;

    virtual KMMsgSignatureState signatureState() const;
    virtual KMMsgEncryptionState encryptionState() const;

    QVector<SignedMessagePart *> signatures() const;
    QVector<EncryptedMessagePart *> encryptions() const;

    /**
     * Retrieve the header @header in this part or any parent parent.
     *
     * Useful for MemoryHole support.
     */
    KMime::Headers::Base *header(const char *header) const;

    void bindLifetime(KMime::Content *);

protected:
    void parseInternal(KMime::Content *node, bool onlyOneMimePart = false);
    void parseInternal(const QByteArray &data);
    QString renderInternalText() const;

    QString mText;
    ObjectTreeParser *mOtp;
    PartMetaData mMetaData;
    MessagePart *mParentPart;
    KMime::Content *mNode;
    QVector<KMime::Content *> mNodesToDelete;
    Error mError;

private:
    QVector<MessagePart::Ptr> mBlocks;
    bool mRoot;
};

class MimeMessagePart : public MessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<MimeMessagePart> Ptr;
    MimeMessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node, bool onlyOneMimePart = false);
    virtual ~MimeMessagePart();

    QString text() const Q_DECL_OVERRIDE;

    QString plaintextContent() const Q_DECL_OVERRIDE;
    QString htmlContent() const Q_DECL_OVERRIDE;

private:
    friend class AlternativeMessagePart;
};

class MessagePartList : public MessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<MessagePartList> Ptr;
    MessagePartList(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node);
    virtual ~MessagePartList() = default;

    QString text() const Q_DECL_OVERRIDE;

    QString plaintextContent() const Q_DECL_OVERRIDE;
    QString htmlContent() const Q_DECL_OVERRIDE;
};

class TextMessagePart : public MessagePartList
{
    Q_OBJECT
public:
    typedef QSharedPointer<TextMessagePart> Ptr;
    TextMessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node);
    virtual ~TextMessagePart() = default;

    KMMsgSignatureState signatureState() const Q_DECL_OVERRIDE;
    KMMsgEncryptionState encryptionState() const Q_DECL_OVERRIDE;

private:
    void parseContent();

    KMMsgSignatureState mSignatureState;
    KMMsgEncryptionState mEncryptionState;

    friend class ObjectTreeParser;
};

class AttachmentMessagePart : public TextMessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<AttachmentMessagePart> Ptr;
    AttachmentMessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node);
    virtual ~AttachmentMessagePart() = default;
    virtual bool isAttachment() const Q_DECL_OVERRIDE
    {
        return true;
    }
};

class HtmlMessagePart : public MessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<HtmlMessagePart> Ptr;
    HtmlMessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node);
    virtual ~HtmlMessagePart() = default;
    bool isHtml() const Q_DECL_OVERRIDE
    {
        return true;
    };
};

class AlternativeMessagePart : public MessagePart
{
    Q_OBJECT
public:
    enum HtmlMode {
        Normal, ///< A normal plaintext message, non-multipart
        Html, ///< A HTML message, non-multipart
        MultipartPlain, ///< A multipart/alternative message, the plain text part is currently displayed
        MultipartHtml, ///< A multipart/altervative message, the HTML part is currently displayed
        MultipartIcal ///< A multipart/altervative message, the ICal part is currently displayed
    };

    typedef QSharedPointer<AlternativeMessagePart> Ptr;
    AlternativeMessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node);
    virtual ~AlternativeMessagePart();

    QString text() const Q_DECL_OVERRIDE;

    bool isHtml() const Q_DECL_OVERRIDE;

    QString plaintextContent() const Q_DECL_OVERRIDE;
    QString htmlContent() const Q_DECL_OVERRIDE;
    QString icalContent() const;

    QList<HtmlMode> availableModes();

private:
    QMap<HtmlMode, MessagePart::Ptr> mChildParts;

    friend class ObjectTreeParser;
    friend class MultiPartAlternativeBodyPartFormatter;
};

class CertMessagePart : public MessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<CertMessagePart> Ptr;
    CertMessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node, const CryptoProtocol cryptoProto);
    virtual ~CertMessagePart();

    QString text() const Q_DECL_OVERRIDE;
    void import();

private:
    const CryptoProtocol mProtocol;
};

class EncapsulatedRfc822MessagePart : public MessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<EncapsulatedRfc822MessagePart> Ptr;
    EncapsulatedRfc822MessagePart(MimeTreeParser::ObjectTreeParser *otp, KMime::Content *node, const KMime::Message::Ptr &message);
    virtual ~EncapsulatedRfc822MessagePart() = default;

    QString text() const Q_DECL_OVERRIDE;
    QString from() const;
    QDateTime date() const;

private:
    const KMime::Message::Ptr mMessage;
};

class EncryptedMessagePart : public MessagePart
{
    Q_OBJECT
    Q_PROPERTY(bool isEncrypted READ isEncrypted)
public:
    typedef QSharedPointer<EncryptedMessagePart> Ptr;
    EncryptedMessagePart(ObjectTreeParser *otp,
                         const QString &text,
                         const CryptoProtocol protocol,
                         KMime::Content *node,
                         KMime::Content *encryptedNode = nullptr,
                         bool parseAfterDecryption = true);

    virtual ~EncryptedMessagePart() = default;

    QString text() const Q_DECL_OVERRIDE;

    void setIsEncrypted(bool encrypted);
    bool isEncrypted() const;

    bool isDecryptable() const;

    void startDecryption(KMime::Content *data);
    void startDecryption();

    QByteArray mDecryptedData;

    QString plaintextContent() const Q_DECL_OVERRIDE;
    QString htmlContent() const Q_DECL_OVERRIDE;

private:
    bool decrypt(KMime::Content &data);
    bool mParseAfterDecryption{true};

protected:
    const CryptoProtocol mProtocol;
    QByteArray mVerifiedText;
    KMime::Content *mEncryptedNode;
};

class SignedMessagePart : public MessagePart
{
    Q_OBJECT
    Q_PROPERTY(bool isSigned READ isSigned)
public:
    typedef QSharedPointer<SignedMessagePart> Ptr;
    SignedMessagePart(ObjectTreeParser *otp, const CryptoProtocol protocol, KMime::Content *node, KMime::Content *signedData, bool parseAfterDecryption = true);

    virtual ~SignedMessagePart();

    void setIsSigned(bool isSigned);
    bool isSigned() const;

    void startVerification();

    QString plaintextContent() const Q_DECL_OVERRIDE;
    QString htmlContent() const Q_DECL_OVERRIDE;

private:
    void verifySignature(const QByteArray &text, const QByteArray &signature);
    void setVerificationResult(const Crypto::VerificationResult &result, const QByteArray &signedData);
    bool mParseAfterDecryption{true};

protected:
    CryptoProtocol mProtocol;
    KMime::Content *mSignedData;

    friend EncryptedMessagePart;
};

class HeadersPart : public MessagePart
{
    Q_OBJECT
public:
    typedef QSharedPointer<HeadersPart> Ptr;
    HeadersPart(ObjectTreeParser *otp, KMime::Content *node);
    virtual ~HeadersPart() = default;
};

}
