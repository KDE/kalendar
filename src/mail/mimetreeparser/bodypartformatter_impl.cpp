/*  -*- c++ -*-
    bodypartformatter.cpp

    This file is part of KMail, the KDE mail client.
    Copyright (c) 2003 Marc Mutz <mutz@kde.org>

    KMail is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License, version 2, as
    published by the Free Software Foundation.

    KMail is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    In addition, as a special exception, the copyright holders give
    permission to link the code of this program with any edition of
    the Qt library by Trolltech AS, Norway (or with modified versions
    of Qt that use the same license as Qt), and distribute linked
    combinations including the two.  You must obey the GNU General
    Public License in all respects for all of the code used other than
    Qt.  If you modify this file, you may extend this exception to
    your version of the file, but you are not obligated to do so.  If
    you do not wish to do so, delete this exception statement from
    your version.
*/

#include "mimetreeparser_debug.h"

#include "bodypartformatter.h"

#include "bodypartformatterbasefactory.h"
#include "bodypartformatterbasefactory_p.h"

#include "messagepart.h"
#include "objecttreeparser.h"
#include "utils.h"

#include <KMime/Content>

using namespace MimeTreeParser;
using namespace MimeTreeParser::Interface;

namespace MimeTreeParser
{
class AnyTypeBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
};

class MessageRfc822BodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        return MessagePart::Ptr(new EncapsulatedRfc822MessagePart(objectTreeParser, node, node->bodyAsMessage()));
    }
};

class HeadersBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        return MessagePart::Ptr(new HeadersPart(objectTreeParser, node));
    }
};

class MultiPartRelatedBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    QVector<MessagePart::Ptr> processList(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->contents().isEmpty()) {
            return {};
        }
        // We rely on the order of the parts.
        // Theoretically there could also be a Start parameter which would break this..
        // https://tools.ietf.org/html/rfc2387#section-4

        // We want to display attachments even if displayed inline.
        QVector<MessagePart::Ptr> list;
        list.append(MimeMessagePart::Ptr(new MimeMessagePart(objectTreeParser, node->contents().at(0), true)));
        for (int i = 1; i < node->contents().size(); i++) {
            auto p = node->contents().at(i);
            if (KMime::isAttachment(p)) {
                list.append(MimeMessagePart::Ptr(new MimeMessagePart(objectTreeParser, p, true)));
            }
        }
        return list;
    }
};

class MultiPartMixedBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->contents().isEmpty()) {
            return {};
        }
        // we need the intermediate part to preserve the headers (necessary for with protected headers using multipart mixed)
        auto part = MessagePart::Ptr(new MessagePart(objectTreeParser, {}, node));
        part->appendSubPart(MimeMessagePart::Ptr(new MimeMessagePart(objectTreeParser, node->contents().at(0), false)));
        return part;
    }
};

class ApplicationPGPEncryptedBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->decodedContent().trimmed() != "Version: 1") {
            qCWarning(MIMETREEPARSER_LOG) << "Unknown PGP Version String:" << node->decodedContent().trimmed();
        }

        if (!node->parent()) {
            return MessagePart::Ptr();
        }

        KMime::Content *data = findTypeInDirectChildren(node->parent(), "application/octet-stream");

        if (!data) {
            return MessagePart::Ptr(); // new MimeMessagePart(objectTreeParser, node));
        }

        EncryptedMessagePart::Ptr mp(new EncryptedMessagePart(objectTreeParser, data->decodedText(), OpenPGP, node, data));
        mp->setIsEncrypted(true);
        return mp;
    }
};

class ApplicationPkcs7MimeBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->head().isEmpty()) {
            return MessagePart::Ptr();
        }

        const QString smimeType = node->contentType()->parameter(QStringLiteral("smime-type")).toLower();

        if (smimeType == QLatin1String("certs-only")) {
            return CertMessagePart::Ptr(new CertMessagePart(objectTreeParser, node, CMS));
        }

        bool isSigned = (smimeType == QLatin1String("signed-data"));
        bool isEncrypted = (smimeType == QLatin1String("enveloped-data"));

        // Analyze "signTestNode" node to find/verify a signature.
        // If zero part.objectTreeParser verification was successfully done after
        // decrypting via recursion by insertAndParseNewChildNode().
        KMime::Content *signTestNode = isEncrypted ? nullptr : node;

        // We try decrypting the content
        // if we either *know* that it is an encrypted message part
        // or there is neither signed nor encrypted parameter.
        MessagePart::Ptr mp;
        if (!isSigned) {
            if (isEncrypted) {
                qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime     ==      S/MIME TYPE: enveloped (encrypted) data";
            } else {
                qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime  -  type unknown  -  enveloped (encrypted) data ?";
            }

            auto _mp = EncryptedMessagePart::Ptr(new EncryptedMessagePart(objectTreeParser, node->decodedText(), CMS, node));
            mp = _mp;
            _mp->setIsEncrypted(true);
            // PartMetaData *messagePart(_mp->partMetaData());
            // if (!part.source()->decryptMessage()) {
            isEncrypted = true;
            signTestNode = nullptr; // PENDING(marc) to be abs. sure, we'd need to have to look at the content
            // } else {
            //     _mp->startDecryption();
            //     if (messagePart->isDecryptable) {
            //         qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime  -  encryption found  -  enveloped (encrypted) data !";
            //         isEncrypted = true;
            //         part.nodeHelper()->setEncryptionState(node, KMMsgFullyEncrypted);
            //         signTestNode = nullptr;

            //     } else {
            //         // decryption failed, which could be because the part was encrypted but
            //         // decryption failed, or because we didn't know if it was encrypted, tried,
            //         // and failed. If the message was not actually encrypted, we continue
            //         // assuming it's signed
            //         if (_mp->passphraseError() || (smimeType.isEmpty() && messagePart->isEncrypted)) {
            //             isEncrypted = true;
            //             signTestNode = nullptr;
            //         }

            //         if (isEncrypted) {
            //             qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime  -  ERROR: COULD NOT DECRYPT enveloped data !";
            //         } else {
            //             qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime  -  NO encryption found";
            //         }
            //     }
            // }
        }

        // We now try signature verification if necessarry.
        if (signTestNode) {
            if (isSigned) {
                qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime     ==      S/MIME TYPE: opaque signed data";
            } else {
                qCDebug(MIMETREEPARSER_LOG) << "pkcs7 mime  -  type unknown  -  opaque signed data ?";
            }

            return SignedMessagePart::Ptr(new SignedMessagePart(objectTreeParser, CMS, nullptr, signTestNode));
        }
        return mp;
    }
};

class MultiPartAlternativeBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->contents().isEmpty()) {
            return MessagePart::Ptr();
        }

        AlternativeMessagePart::Ptr mp(new AlternativeMessagePart(objectTreeParser, node));
        if (mp->mChildParts.isEmpty()) {
            return MimeMessagePart::Ptr(new MimeMessagePart(objectTreeParser, node->contents().at(0)));
        }
        return mp;
    }
};

class MultiPartEncryptedBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->contents().isEmpty()) {
            Q_ASSERT(false);
            return MessagePart::Ptr();
        }

        CryptoProtocol useThisCryptProto = UnknownProtocol;

        /*
        ATTENTION: This code is to be replaced by the new 'auto-detect' feature. --------------------------------------
        */
        KMime::Content *data = findTypeInDirectChildren(node, "application/octet-stream");
        if (data) {
            useThisCryptProto = OpenPGP;
        } else {
            data = findTypeInDirectChildren(node, "application/pkcs7-mime");
            if (data) {
                useThisCryptProto = CMS;
            }
        }
        /*
        ---------------------------------------------------------------------------------------------------------------
        */

        if (!data) {
            return MessagePart::Ptr(new MimeMessagePart(objectTreeParser, node->contents().at(0)));
        }

        EncryptedMessagePart::Ptr mp(new EncryptedMessagePart(objectTreeParser, data->decodedText(), useThisCryptProto, node, data));
        mp->setIsEncrypted(true);
        return mp;
    }
};

class MultiPartSignedBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    static CryptoProtocol detectProtocol(const QString &protocolContentType_, const QString &signatureContentType)
    {
        auto protocolContentType = protocolContentType_;
        if (protocolContentType.isEmpty()) {
            qCWarning(MIMETREEPARSER_LOG) << "Message doesn't set the protocol for the multipart/signed content-type, "
                                             "using content-type of the signature:"
                                          << signatureContentType;
            protocolContentType = signatureContentType;
        }

        CryptoProtocol protocol = UnknownProtocol;
        if (protocolContentType == QLatin1String("application/pkcs7-signature") || protocolContentType == QLatin1String("application/x-pkcs7-signature")) {
            protocol = CMS;
        } else if (protocolContentType == QLatin1String("application/pgp-signature") || protocolContentType == QLatin1String("application/x-pgp-signature")) {
            protocol = OpenPGP;
        }
        return protocol;
    }

    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (node->contents().size() != 2) {
            qCDebug(MIMETREEPARSER_LOG) << "mulitpart/signed must have exactly two child parts!" << Qt::endl << "processing as multipart/mixed";
            if (!node->contents().isEmpty()) {
                return MessagePart::Ptr(new MimeMessagePart(objectTreeParser, node->contents().at(0)));
            } else {
                return MessagePart::Ptr();
            }
        }

        KMime::Content *signedData = node->contents().at(0);
        KMime::Content *signature = node->contents().at(1);
        Q_ASSERT(signedData);
        Q_ASSERT(signature);

        auto protocol =
            detectProtocol(node->contentType()->parameter(QStringLiteral("protocol")).toLower(), QLatin1String(signature->contentType()->mimeType().toLower()));

        if (protocol == UnknownProtocol) {
            return MessagePart::Ptr(new MimeMessagePart(objectTreeParser, signedData));
        }

        return SignedMessagePart::Ptr(new SignedMessagePart(objectTreeParser, protocol, signature, signedData));
    }
};

class TextHtmlBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        return HtmlMessagePart::Ptr(new HtmlMessagePart(objectTreeParser, node));
    }
};

class TextPlainBodyPartFormatter : public MimeTreeParser::Interface::BodyPartFormatter
{
public:
    MessagePart::Ptr process(ObjectTreeParser *objectTreeParser, KMime::Content *node) const Q_DECL_OVERRIDE
    {
        if (KMime::isAttachment(node)) {
            return AttachmentMessagePart::Ptr(new AttachmentMessagePart(objectTreeParser, node));
        }
        return TextMessagePart::Ptr(new TextMessagePart(objectTreeParser, node));
    }
};

} // anon namespace

void BodyPartFormatterBaseFactoryPrivate::messageviewer_create_builtin_bodypart_formatters()
{
    auto any = new AnyTypeBodyPartFormatter;
    auto textPlain = new TextPlainBodyPartFormatter;
    auto pkcs7 = new ApplicationPkcs7MimeBodyPartFormatter;
    auto pgp = new ApplicationPGPEncryptedBodyPartFormatter;
    auto html = new TextHtmlBodyPartFormatter;
    auto headers = new HeadersBodyPartFormatter;
    auto multipartAlternative = new MultiPartAlternativeBodyPartFormatter;
    auto multipartMixed = new MultiPartMixedBodyPartFormatter;
    auto multipartSigned = new MultiPartSignedBodyPartFormatter;
    auto multipartEncrypted = new MultiPartEncryptedBodyPartFormatter;
    auto message = new MessageRfc822BodyPartFormatter;
    auto multipartRelated = new MultiPartRelatedBodyPartFormatter;

    insert("application", "octet-stream", any);
    insert("application", "pgp", textPlain);
    insert("application", "pkcs7-mime", pkcs7);
    insert("application", "x-pkcs7-mime", pkcs7);
    insert("application", "pgp-encrypted", pgp);
    insert("application", "*", any);

    insert("text", "html", html);
    insert("text", "rtf", any);
    insert("text", "plain", textPlain);
    insert("text", "rfc822-headers", headers);
    insert("text", "*", textPlain);

    insert("image", "*", any);

    insert("message", "rfc822", message);
    insert("message", "*", any);

    insert("multipart", "alternative", multipartAlternative);
    insert("multipart", "encrypted", multipartEncrypted);
    insert("multipart", "signed", multipartSigned);
    insert("multipart", "related", multipartRelated);
    insert("multipart", "*", multipartMixed);
    insert("*", "*", any);
}
