// This file is part of KMail, the KDE mail client.
// SPDX-FileCopyrightText: 2003      Marc Mutz <mutz@kde.org>
// SPDX-FileCopyrightText: 2002-2004 Klarälvdalens Datakonsult AB, a KDAB Group company, info@kdab.net
// SPDX-FileCopyrightText: 2009 Andras Mantia <andras@kdab.net>
// SPDX-FileCopyrightText: 2015 Sandro Knauß <sknauss@kde.org>
// SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsystems.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "objecttreeparser.h"

#include "bodypartformatterbasefactory.h"

#include "mimetreeparser_debug.h"

#include "bodypartformatter.h"
#include "utils.h"

#include <KMime/Message>

#include <KCharsets>
#include <QByteArray>
#include <QMimeDatabase>
#include <QRegularExpression>
#include <QTextCodec>
#include <QTextStream>
#include <QUrl>

using namespace MimeTreeParser;

/*
 * Collect message parts bottom up.
 * Filter to avoid evaluating a subtree.
 * Select parts to include it in the result set. Selecting a part in a branch will keep any parent parts from being selected.
 */
static QVector<MessagePart::Ptr>
collect(MessagePart::Ptr start, const std::function<bool(const MessagePartPtr &)> &evaluateSubtree, const std::function<bool(const MessagePartPtr &)> &select)
{
    MessagePartPtr ptr = start.dynamicCast<MessagePart>();
    Q_ASSERT(ptr);
    QVector<MessagePart::Ptr> list;
    if (evaluateSubtree(ptr)) {
        for (const auto &p : ptr->subParts()) {
            list << ::collect(p, evaluateSubtree, select);
        }
    }

    // Don't consider this part if we already selected a subpart
    if (list.isEmpty()) {
        if (select(ptr)) {
            list << start;
        }
    }
    return list;
}

QString ObjectTreeParser::plainTextContent()
{
    QString content;
    if (mParsedPart) {
        auto plainParts = ::collect(
            mParsedPart,
            [](const MessagePartPtr &) {
                return true;
            },
            [](const MessagePartPtr &part) {
                if (part->isAttachment()) {
                    return false;
                }
                if (dynamic_cast<MimeTreeParser::TextMessagePart *>(part.data())) {
                    return true;
                }
                if (dynamic_cast<MimeTreeParser::AlternativeMessagePart *>(part.data())) {
                    return true;
                }
                return false;
            });
        for (const auto &part : plainParts) {
            content += part->text();
        }
    }
    return content;
}

QString ObjectTreeParser::htmlContent()
{
    QString content;
    if (mParsedPart) {
        QVector<MessagePart::Ptr> contentParts = ::collect(
            mParsedPart,
            [](const MessagePartPtr &) {
                return true;
            },
            [](const MessagePartPtr &part) {
                if (dynamic_cast<MimeTreeParser::HtmlMessagePart *>(part.data())) {
                    return true;
                }
                if (dynamic_cast<MimeTreeParser::AlternativeMessagePart *>(part.data())) {
                    return true;
                }
                return false;
            });
        for (const auto &part : contentParts) {
            if (auto p = dynamic_cast<MimeTreeParser::AlternativeMessagePart *>(part.data())) {
                content += p->htmlContent();
            } else {
                content += part->text();
            }
        }
    }
    return content;
}

static void print(QTextStream &stream, KMime::Content *node, const QString prefix = {})
{
    QByteArray mediaType("text");
    QByteArray subType("plain");
    if (node->contentType(false) && !node->contentType()->mediaType().isEmpty() && !node->contentType()->subType().isEmpty()) {
        mediaType = node->contentType()->mediaType();
        subType = node->contentType()->subType();
    }
    stream << prefix << "! " << mediaType << subType << " isAttachment: " << KMime::isAttachment(node) << "\n";
    for (const auto nodeContent : node->contents()) {
        print(stream, nodeContent, prefix + QLatin1String(" "));
    }
}

static void print(QTextStream &stream, const MessagePart &messagePart, const QByteArray pre = {})
{
    stream << pre << "# " << messagePart.metaObject()->className() << " isAttachment: " << messagePart.isAttachment() << "\n";
    for (const auto &subPart : messagePart.subParts()) {
        print(stream, *subPart, pre + " ");
    }
}

QString ObjectTreeParser::structureAsString() const
{
    QString string;
    QTextStream stream{&string};

    if (mTopLevelContent) {
        ::print(stream, mTopLevelContent);
    }
    if (mParsedPart) {
        ::print(stream, *mParsedPart);
    }
    return string;
}

void ObjectTreeParser::print()
{
    qInfo().noquote() << structureAsString();
}

static KMime::Content *find(KMime::Content *node, const std::function<bool(KMime::Content *)> &select)
{
    QByteArray mediaType("text");
    QByteArray subType("plain");
    if (node->contentType(false) && !node->contentType()->mediaType().isEmpty() && !node->contentType()->subType().isEmpty()) {
        mediaType = node->contentType()->mediaType();
        subType = node->contentType()->subType();
    }
    if (select(node)) {
        return node;
    }
    for (const auto nodeContent : node->contents()) {
        if (const auto content = find(nodeContent, select)) {
            return content;
        }
    }
    return nullptr;
}

KMime::Content *ObjectTreeParser::find(const std::function<bool(KMime::Content *)> &select)
{
    return ::find(mTopLevelContent, select);
}

QVector<MessagePartPtr> ObjectTreeParser::collectContentParts()
{
    return collectContentParts(mParsedPart);
}

QVector<MessagePart::Ptr> ObjectTreeParser::collectContentParts(MessagePart::Ptr start)
{
    return ::collect(
        start,
        [start](const MessagePartPtr &part) {
            // Ignore the top-level
            if (start.data() == part.data()) {
                return true;
            }
            if (auto encapsulatedPart = part.dynamicCast<MimeTreeParser::EncapsulatedRfc822MessagePart>()) {
                return false;
            }
            return true;
        },
        [start](const MessagePartPtr &part) {
            if (const auto attachment = dynamic_cast<MimeTreeParser::AttachmentMessagePart *>(part.data())) {
                return attachment->mimeType() == "text/calendar";
            } else if (const auto text = dynamic_cast<MimeTreeParser::TextMessagePart *>(part.data())) {
                auto enc = dynamic_cast<MimeTreeParser::EncryptedMessagePart *>(text->parentPart());
                if (enc && enc->error()) {
                    return false;
                }
                return true;
            } else if (dynamic_cast<MimeTreeParser::AlternativeMessagePart *>(part.data())) {
                return true;
            } else if (dynamic_cast<MimeTreeParser::HtmlMessagePart *>(part.data())) {
                // Don't if we have an alternative part as parent
                return true;
            } else if (dynamic_cast<MimeTreeParser::EncapsulatedRfc822MessagePart *>(part.data())) {
                if (start.data() == part.data()) {
                    return false;
                }
                return true;
            } else if (const auto enc = dynamic_cast<MimeTreeParser::EncryptedMessagePart *>(part.data())) {
                if (enc->error()) {
                    return true;
                }
                // If we have a textpart with encrypted and unencrypted subparts we want to return the textpart
                if (dynamic_cast<MimeTreeParser::TextMessagePart *>(enc->parentPart())) {
                    return false;
                }
            } else if (const auto sig = dynamic_cast<MimeTreeParser::SignedMessagePart *>(part.data())) {
                // Signatures without subparts already contain the text
                return !sig->hasSubParts();
            }
            return false;
        });
}

QVector<MessagePart::Ptr> ObjectTreeParser::collectAttachmentParts()
{
    QVector<MessagePart::Ptr> contentParts = ::collect(
        mParsedPart,
        [](const MessagePartPtr &) {
            return true;
        },
        [](const MessagePartPtr &part) {
            return part->isAttachment();
        });
    return contentParts;
}

void ObjectTreeParser::decryptParts()
{
    decryptAndVerify();
}

/*
 * This naive implementation assumes that there is an encrypted part wrapping a signature.
 * For other cases we would have to process both recursively (I think?)
 */
void ObjectTreeParser::decryptAndVerify()
{
    // We first decrypt
    ::collect(
        mParsedPart,
        [](const MessagePartPtr &) {
            return true;
        },
        [](const MessagePartPtr &part) {
            if (const auto enc = dynamic_cast<MimeTreeParser::EncryptedMessagePart *>(part.data())) {
                enc->startDecryption();
            }
            return false;
        });
    // And then verify the available signatures
    ::collect(
        mParsedPart,
        [](const MessagePartPtr &) {
            return true;
        },
        [](const MessagePartPtr &part) {
            if (const auto enc = dynamic_cast<MimeTreeParser::SignedMessagePart *>(part.data())) {
                enc->startVerification();
            }
            return false;
        });
}

void ObjectTreeParser::importCertificates()
{
    QVector<MessagePart::Ptr> contentParts = ::collect(
        mParsedPart,
        [](const MessagePartPtr &) {
            return true;
        },
        [](const MessagePartPtr &part) {
            if (const auto cert = dynamic_cast<MimeTreeParser::CertMessagePart *>(part.data())) {
                cert->import();
            }
            return false;
        });
}

QString ObjectTreeParser::resolveCidLinks(const QString &html)
{
    auto text = html;
    static const auto regex = QRegularExpression(QLatin1String("(src)\\s*=\\s*(\"|')(cid:[^\"']+)\\2"));
    auto it = regex.globalMatch(text);
    while (it.hasNext()) {
        const auto match = it.next();
        const auto link = QUrl(match.captured(3));
        auto cid = link.path();
        auto mailMime = const_cast<KMime::Content *>(find([=](KMime::Content *content) {
            if (!content || !content->contentID(false)) {
                return false;
            }
            return QString::fromLatin1(content->contentID(false)->identifier()) == cid;
        }));
        if (mailMime) {
            const auto contentType = mailMime->contentType(false);
            if (!contentType) {
                qWarning() << "No content type, skipping";
                continue;
            }
            QMimeDatabase mimeDb;
            const auto mimetype = mimeDb.mimeTypeForName(QString::fromLatin1(contentType->mimeType())).name();
            if (mimetype.startsWith(QLatin1String("image/"))) {
                // We reencode to base64 below.
                const auto data = mailMime->decodedContent();
                if (data.isEmpty()) {
                    qWarning() << "Attachment is empty.";
                    continue;
                }
                text.replace(match.captured(0), QString::fromLatin1("src=\"data:%1;base64,%2\"").arg(mimetype, QString::fromLatin1(data.toBase64())));
            }
        } else {
            qWarning() << "Failed to find referenced attachment: " << cid;
        }
    }
    return text;
}

//-----------------------------------------------------------------------------

void ObjectTreeParser::parseObjectTree(const QByteArray &mimeMessage)
{
    const auto mailData = KMime::CRLFtoLF(mimeMessage);
    mMsg = KMime::Message::Ptr(new KMime::Message);
    mMsg->setContent(mailData);
    mMsg->parse();
    // We avoid using mMsg->contentType()->charset(), because that will just return kmime's defaultCharset(), ISO-8859-1
    const auto charset = mMsg->contentType()->parameter(QStringLiteral("charset")).toLatin1();
    if (charset.isEmpty()) {
        mMsg->contentType()->setCharset("us-ascii");
    }
    parseObjectTree(mMsg.data());
}

void ObjectTreeParser::parseObjectTree(KMime::Content *node)
{
    mTopLevelContent = node;
    mParsedPart = parseObjectTreeInternal(node, false);
}

MessagePartPtr ObjectTreeParser::parsedPart() const
{
    return mParsedPart;
}

/*
 * This will lookup suitable formatters based on the type,
 * and let them generate a list of parts.
 * If the formatter generated a list of parts, then those are taken, otherwise we move on to the next match.
 */
QVector<MessagePartPtr> ObjectTreeParser::processType(KMime::Content *node, const QByteArray &mediaType, const QByteArray &subType)
{
    static MimeTreeParser::BodyPartFormatterBaseFactory factory;
    const auto sub = factory.subtypeRegistry(mediaType.constData());
    const auto range = sub.equal_range(subType.constData());
    for (auto it = range.first; it != range.second; ++it) {
        const auto formatter = it->second;
        if (!formatter) {
            continue;
        }
        const auto list = formatter->processList(this, node);
        if (!list.isEmpty()) {
            return list;
        }
    }
    return {};
}

MessagePart::Ptr ObjectTreeParser::parseObjectTreeInternal(KMime::Content *node, bool onlyOneMimePart)
{
    if (!node) {
        return MessagePart::Ptr();
    }

    auto parsedPart = MessagePart::Ptr(new MessagePartList(this, node));
    parsedPart->setIsRoot(node->isTopLevel());
    const auto contents = node->parent() ? node->parent()->contents() : KMime::Content::List{node};
    for (int i = contents.indexOf(node); i < contents.size(); ++i) {
        node = contents.at(i);

        QByteArray mediaType("text");
        QByteArray subType("plain");
        if (node->contentType(false) && !node->contentType()->mediaType().isEmpty() && !node->contentType()->subType().isEmpty()) {
            mediaType = node->contentType()->mediaType();
            subType = node->contentType()->subType();
        }

        auto messageParts = [&] {
            // Try the specific type handler
            {
                auto list = processType(node, mediaType, subType);
                if (!list.isEmpty()) {
                    return list;
                }
            }
            // Fallback to the generic handler
            {
                auto list = processType(node, mediaType, "*");
                if (!list.isEmpty()) {
                    return list;
                }
            }
            // Fallback to the default handler
            return defaultHandling(node);
        }();

        for (const auto &part : messageParts) {
            parsedPart->appendSubPart(part);
        }

        if (onlyOneMimePart) {
            break;
        }
    }

    return parsedPart;
}

QVector<MessagePart::Ptr> ObjectTreeParser::defaultHandling(KMime::Content *node)
{
    if (node->contentType()->mimeType() == QByteArrayLiteral("application/octet-stream")
        && (node->contentType()->name().endsWith(QLatin1String("p7m")) || node->contentType()->name().endsWith(QLatin1String("p7s"))
            || node->contentType()->name().endsWith(QLatin1String("p7c")))) {
        auto list = processType(node, "application", "pkcs7-mime");
        if (!list.isEmpty()) {
            return list;
        }
    }

    return {AttachmentMessagePart::Ptr(new AttachmentMessagePart(this, node))};
}

static QTextCodec *getLocalCodec()
{
    auto codec = QTextCodec::codecForLocale();

    // In the case of Japan. Japanese locale name is "eucjp" but
    // The Japanese mail systems normally used "iso-2022-jp" of locale name.
    // We want to change locale name from eucjp to iso-2022-jp at KMail only.

    // (Introduction to i18n, 6.6 Limit of Locale technology):
    // EUC-JP is the de-facto standard for UNIX systems, ISO 2022-JP
    // is the standard for Internet, and Shift-JIS is the encoding
    // for Windows and Macintosh.
    if (codec) {
        const QByteArray codecNameLower = codec->name().toLower();
        if (codecNameLower == "eucjp"
#if defined Q_OS_WIN || defined Q_OS_MACX
            || codecNameLower == "shift-jis" // OK?
#endif
        ) {
            codec = QTextCodec::codecForName("jis7");
            // QTextCodec *cdc = QTextCodec::codecForName("jis7");
            // QTextCodec::setCodecForLocale(cdc);
            // KLocale::global()->setEncoding(cdc->mibEnum());
        }
    }
    return codec;
}

const QTextCodec *ObjectTreeParser::codecFor(KMime::Content *node) const
{
    static auto localCodec = getLocalCodec();
    if (!node) {
        return localCodec;
    }

    QByteArray charset = node->contentType()->charset().toLower();

    // utf-8 is a superset of us-ascii, so we don't lose anything if we use it instead
    // utf-8 is used so widely nowadays that it is a good idea to use it to fix issues with broken clients.
    if (charset == "us-ascii") {
        charset = "utf-8";
    }
    if (!charset.isEmpty()) {
        if (auto c = KCharsets::charsets()->codecForName(QLatin1String(charset))) {
            return c;
        };
    }
    // no charset means us-ascii (RFC 2045), so using local encoding should
    // be okay
    return localCodec;
}
