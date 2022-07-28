// SPDX-FileCopyrightText: 2016 Sandro Knauß <knauss@kolabsystems.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <objecttreeparser.h>

#include <QDebug>
#include <QTest>
#include <QTimeZone>

QByteArray readMailFromFile(const QString &mailFile)
{
    QFile file(QLatin1String(MAIL_DATA_DIR) + QLatin1Char('/') + mailFile);
    file.open(QIODevice::ReadOnly);
    Q_ASSERT(file.isOpen());
    return file.readAll();
}

class MimeTreeParserTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testTextMail()
    {
        const auto expectedText = QStringLiteral(
            "If you can see this text it means that your email client couldn't display our newsletter properly.\nPlease visit this link to view the newsletter "
            "on our website: http://www.gog.com/newsletter/");
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("plaintext.mbox")));
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QCOMPARE(part->text(), expectedText);
        QCOMPARE(part->charset(), QStringLiteral("utf-8").toLocal8Bit());

        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);

        QCOMPARE(otp.collectAttachmentParts().size(), 0);

        QCOMPARE(otp.plainTextContent(), expectedText);
        QVERIFY(otp.htmlContent().isEmpty());
    }

    void testAlternative()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("alternative.mbox")));
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->plaintextContent(),
                 QStringLiteral("If you can see this text it means that your email client couldn't display our newsletter properly.\nPlease visit this link to "
                                "view the newsletter on our website: http://www.gog.com/newsletter/\n"));
        QCOMPARE(part->charset(), QStringLiteral("us-ascii").toLocal8Bit());
        QCOMPARE(part->htmlContent(), QStringLiteral("<html><body><p><span>HTML</span> text</p></body></html>\n\n"));
        QCOMPARE(otp.collectAttachmentParts().size(), 0);
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
    }

    void testTextHtml()
    {
        auto expectedText = QStringLiteral("<html><body><p><span>HTML</span> text</p></body></html>");
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("html.mbox")));
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::HtmlMessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->htmlContent(), expectedText);
        QCOMPARE(part->charset(), QStringLiteral("windows-1252").toLocal8Bit());
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
        auto contentAttachmentList = otp.collectAttachmentParts();
        QCOMPARE(contentAttachmentList.size(), 0);

        QCOMPARE(otp.htmlContent(), expectedText);
        QVERIFY(otp.plainTextContent().isEmpty());
    }

    void testSMimeEncrypted()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-encrypted.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("The quick brown fox jumped over the lazy dog."));
        QCOMPARE(part->charset(), QStringLiteral("us-ascii").toLocal8Bit());
        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->signatures().size(), 0);
        auto contentAttachmentList = otp.collectAttachmentParts();
        QCOMPARE(contentAttachmentList.size(), 0);
    }

    void testOpenPGPEncryptedAttachment()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted-attachment-and-non-encrypted-attachment.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("test text"));
        QCOMPARE(part->charset(), QStringLiteral("us-ascii").toLocal8Bit());
        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(part->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(part->signatureState(), MimeTreeParser::KMMsgFullySigned);
        auto contentAttachmentList = otp.collectAttachmentParts();
        QCOMPARE(contentAttachmentList.size(), 2);
        //     QCOMPARE(contentAttachmentList[0]->availableContents(), QVector<QByteArray>() << "text/plain");
        // QCOMPARE(contentAttachmentList[0]->content().size(), 1);
        QCOMPARE(contentAttachmentList[0]->encryptions().size(), 1);
        QCOMPARE(contentAttachmentList[0]->signatures().size(), 1);
        QCOMPARE(contentAttachmentList[0]->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(contentAttachmentList[0]->signatureState(), MimeTreeParser::KMMsgFullySigned);
        //     QCOMPARE(contentAttachmentList[1]->availableContents(), QVector<QByteArray>() << "image/png");
        //     QCOMPARE(contentAttachmentList[1]->content().size(), 1);
        QCOMPARE(contentAttachmentList[1]->encryptions().size(), 0);
        QCOMPARE(contentAttachmentList[1]->signatures().size(), 0);
        QCOMPARE(contentAttachmentList[1]->encryptionState(), MimeTreeParser::KMMsgNotEncrypted);
        QCOMPARE(contentAttachmentList[1]->signatureState(), MimeTreeParser::KMMsgNotSigned);
    }

    void testOpenPGPInline()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-inline-charset-encrypted.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->charset(), QStringLiteral("ISO-8859-15").toLocal8Bit());
        QCOMPARE(part->text(), QString::fromUtf8("asdasd asd asd asdf sadf sdaf sadf öäü"));

        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(otp.collectAttachmentParts().size(), 0);
    }

    void testOpenPPGInlineWithNonEncText()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-inline-encrypted+nonenc.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part1 = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part1));
        QCOMPARE(part1->text(), QStringLiteral("Not encrypted not signed :(\n\nsome random text"));
        // TODO test if we get the proper subparts with the appropriate encryptions
        QCOMPARE(part1->charset(), QStringLiteral("us-ascii").toLocal8Bit());

        QCOMPARE(part1->encryptionState(), MimeTreeParser::KMMsgPartiallyEncrypted);
        QCOMPARE(part1->signatureState(), MimeTreeParser::KMMsgNotSigned);

        // QCOMPARE(part1->text(), QStringLiteral("Not encrypted not signed :(\n\n"));
        // QCOMPARE(part1->charset(), QStringLiteral("us-ascii").toLocal8Bit());
        // QCOMPARE(contentList[1]->content(), QStringLiteral("some random text").toLocal8Bit());
        // QCOMPARE(contentList[1]->charset(), QStringLiteral("us-ascii").toLocal8Bit());
        // QCOMPARE(contentList[1]->encryptions().size(), 1);
        // QCOMPARE(contentList[1]->signatures().size(), 0);
        QCOMPARE(otp.collectAttachmentParts().size(), 0);
    }

    void testEncryptionBlock()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted-attachment-and-non-encrypted-attachment.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part1 = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part1));
        QCOMPARE(part1->encryptions().size(), 1);
        //     auto enc = contentList[0]->encryptions()[0];
        //     QCOMPARE((int) enc->recipients().size(), 2);

        //     auto r = enc->recipients()[0];
        //     QCOMPARE(r->keyid(),QStringLiteral("14B79E26050467AA"));
        //     QCOMPARE(r->name(),QStringLiteral("kdetest"));
        //     QCOMPARE(r->email(),QStringLiteral("you@you.com"));
        //     QCOMPARE(r->comment(),QStringLiteral(""));

        //     r = enc->recipients()[1];
        //     QCOMPARE(r->keyid(),QStringLiteral("8D9860C58F246DE6"));
        //     QCOMPARE(r->name(),QStringLiteral("unittest key"));
        //     QCOMPARE(r->email(),QStringLiteral("test@kolab.org"));
        //     QCOMPARE(r->comment(),QStringLiteral("no password"));
        auto attachmentList = otp.collectAttachmentParts();
        QCOMPARE(attachmentList.size(), 2);
        auto attachment1 = attachmentList[0];
        QVERIFY(attachment1->node());
        QCOMPARE(attachment1->filename(), QStringLiteral("file.txt"));
        auto attachment2 = attachmentList[1];
        QVERIFY(attachment2->node());
        QCOMPARE(attachment2->filename(), QStringLiteral("image.png"));
    }

    void testSignatureBlock()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted-attachment-and-non-encrypted-attachment.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));

        // QCOMPARE(contentList[0]->signatures().size(), 1);
        // auto sig = contentList[0]->signatures()[0];
        // QCOMPARE(sig->creationDateTime(), QDateTime(QDate(2015,05,01),QTime(15,12,47)));
        // QCOMPARE(sig->expirationDateTime(), QDateTime());
        // QCOMPARE(sig->neverExpires(), true);

        // auto key = sig->key();
        // QCOMPARE(key->keyid(),QStringLiteral("8D9860C58F246DE6"));
        // QCOMPARE(key->name(),QStringLiteral("unittest key"));
        // QCOMPARE(key->email(),QStringLiteral("test@kolab.org"));
        // QCOMPARE(key->comment(),QStringLiteral("no password"));
    }

    void testRelatedAlternative()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("cid-links.mbox")));
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
        QCOMPARE(otp.collectAttachmentParts().size(), 1);
    }

    void testAttachmentPart()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("attachment.mbox")));
        otp.print();
        auto partList = otp.collectAttachmentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->mimeType(), "image/jpeg");
        QCOMPARE(part->filename(), QStringLiteral("aqnaozisxya.jpeg"));
    }

    void testAttachment2Part()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("attachment2.mbox")));
        otp.print();
        auto partList = otp.collectAttachmentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->mimeType(), "image/jpeg");
        QCOMPARE(part->filename(), QStringLiteral("aqnaozisxya.jpeg"));
    }

    void testCidLink()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("cid-links.mbox")));
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(bool(part));
        auto resolvedContent = otp.resolveCidLinks(part->htmlContent());
        QVERIFY(!resolvedContent.contains(QLatin1String("cid:")));
    }

    void testCidLinkInForwardedInline()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("cid-links-forwarded-inline.mbox")));
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(bool(part));
        auto resolvedContent = otp.resolveCidLinks(part->htmlContent());
        QVERIFY(!resolvedContent.contains(QLatin1String("cid:")));
    }

    void testOpenPGPInlineError()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("inlinepgpgencrypted-error.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::EncryptedMessagePart>();
        QVERIFY(bool(part));
        QVERIFY(part->error());
    }

    void testEncapsulated()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("encapsulated-with-attachment.mbox")));
        otp.decryptParts();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 2);
        auto part = partList[1].dynamicCast<MimeTreeParser::EncapsulatedRfc822MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->from(), QLatin1String("Thomas McGuire <dontspamme@gmx.net>"));
        QCOMPARE(part->date().toString(), QLatin1String("Wed Aug 5 10:57:58 2009 GMT+0200"));
        auto subPartList = otp.collectContentParts(part);
        QCOMPARE(subPartList.size(), 1);
        qWarning() << subPartList[0]->metaObject()->className();
        auto subPart = subPartList[0].dynamicCast<MimeTreeParser::TextMessagePart>();
        QVERIFY(bool(subPart));
    }

    void test8bitEncodedInPlaintext()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("8bitencoded.mbox")));
        QVERIFY(otp.plainTextContent().contains(QString::fromUtf8("Why Pisa’s Tower")));
        QVERIFY(otp.htmlContent().contains(QString::fromUtf8("Why Pisa’s Tower")));
    }

    void testInlineSigned()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-inline-signed.mbox")));
        otp.decryptParts();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(part->encryptionState(), MimeTreeParser::KMMsgNotEncrypted);
        QCOMPARE(part->signatureState(), MimeTreeParser::KMMsgFullySigned);
        QCOMPARE(part->text(), QString::fromUtf8("ohno öäü\n"));

        QVERIFY(otp.plainTextContent().contains(QString::fromUtf8("ohno öäü")));

        auto signaturePart = part->signatures().first();
        QCOMPARE(signaturePart->partMetaData()->isGoodSignature, true);
        QCOMPARE(signaturePart->partMetaData()->keyIsTrusted, true);
        QCOMPARE(signaturePart->partMetaData()->keyMissing, false);
        QCOMPARE(signaturePart->partMetaData()->keyExpired, false);
        QCOMPARE(signaturePart->partMetaData()->keyRevoked, false);
        QCOMPARE(signaturePart->partMetaData()->sigExpired, false);
        QCOMPARE(signaturePart->partMetaData()->crlMissing, false);
        QCOMPARE(signaturePart->partMetaData()->crlTooOld, false);
        QCOMPARE(signaturePart->partMetaData()->keyId, QByteArray{"8D9860C58F246DE6"});
        QCOMPARE(signaturePart->partMetaData()->signer, QLatin1String{"unittest key (no password) <test@kolab.org>"});
        QCOMPARE(signaturePart->partMetaData()->signerMailAddresses, QStringList{{QStringLiteral("test@kolab.org")}});
    }

    void testEncryptedAndSigned()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted+signed.mbox")));
        otp.decryptParts();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(part->signatureState(), MimeTreeParser::KMMsgFullySigned);
        QVERIFY(otp.plainTextContent().contains(QString::fromUtf8("encrypted message text")));

        auto signaturePart = part->signatures().first();
        QCOMPARE(signaturePart->partMetaData()->keyId, QByteArray{"8D9860C58F246DE6"});
        QCOMPARE(signaturePart->partMetaData()->isGoodSignature, true);
    }

    void testOpenpgpMultipartEmbedded()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-multipart-embedded.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(otp.plainTextContent(), QString::fromUtf8("sdflskjsdf\n\n-- \nThis is a HTML signature.\n"));
    }

    void testOpenpgpMultipartEmbeddedSigned()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-multipart-embedded-signed.mbox")));
        otp.decryptParts();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(part->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(part->signatureState(), MimeTreeParser::KMMsgFullySigned);
        QCOMPARE(otp.plainTextContent(), QString::fromUtf8("test\n\n-- \nThis is a HTML signature.\n"));

        auto signaturePart = part->signatures().first();
        QVERIFY(signaturePart->partMetaData()->keyId.endsWith(QByteArray{"2E3B7787B1B75920"}));
        // We lack the public key for this message
        QCOMPARE(signaturePart->partMetaData()->isGoodSignature, false);
        QCOMPARE(signaturePart->partMetaData()->keyMissing, true);
    }

    void testAppleHtmlWithAttachments()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("applehtmlwithattachments.mbox")));
        otp.decryptParts();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(part);
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
        QVERIFY(part->isHtml());
        QCOMPARE(otp.plainTextContent(), QString::fromUtf8("Hi,\n\nThis is an HTML message with attachments.\n\nCheers,\nChristian"));
        QCOMPARE(otp.htmlContent(),
                 QString::fromUtf8(
                     "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=us-ascii\"></head><body style=\"word-wrap: break-word; "
                     "-webkit-nbsp-mode: space; line-break: after-white-space;\" class=\"\"><meta http-equiv=\"Content-Type\" content=\"text/html; "
                     "charset=us-ascii\" class=\"\"><div style=\"word-wrap: break-word; -webkit-nbsp-mode: space; line-break: after-white-space;\" "
                     "class=\"\">Hi,<div class=\"\"><br class=\"\"></div><blockquote style=\"margin: 0 0 0 40px; border: none; padding: 0px;\" class=\"\"><div "
                     "class=\"\">This is an <b class=\"\">HTML</b> message with attachments.</div></blockquote><div class=\"\"><br class=\"\"></div><div "
                     "class=\"\">Cheers,</div><div class=\"\">Christian<img apple-inline=\"yes\" id=\"B9EE68A9-83CA-41CD-A3E4-E5BA301F797A\" class=\"\" "
                     "src=\"cid:F5B62D1D-E4EC-4C59-AA5A-708525C2AC3C\"></div></div></body></html>"));

        auto attachments = otp.collectAttachmentParts();
        QCOMPARE(attachments.size(), 1);
    }

    void testAppleHtmlWithAttachmentsMixed()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("applehtmlwithattachmentsmixed.mbox")));
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(part);
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
        QVERIFY(part->isHtml());
        QCOMPARE(otp.plainTextContent(), QString::fromUtf8("Hello\n\n\n\nRegards\n\nFsdfsdf"));
        QCOMPARE(otp.htmlContent(),
                 QString::fromUtf8(
                     "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=us-ascii\"></head><body style=\"word-wrap: break-word; "
                     "-webkit-nbsp-mode: space; line-break: after-white-space;\" class=\"\"><strike class=\"\">Hello</strike><div class=\"\"><br "
                     "class=\"\"></div><div class=\"\"></div></body></html><html><head><meta http-equiv=\"Content-Type\" content=\"text/html; "
                     "charset=us-ascii\"></head><body style=\"word-wrap: break-word; -webkit-nbsp-mode: space; line-break: after-white-space;\" "
                     "class=\"\"><div class=\"\"></div><div class=\"\"><br class=\"\"></div><div class=\"\"><b class=\"\">Regards</b></div><div class=\"\"><b "
                     "class=\"\"><br class=\"\"></b></div><div class=\"\">Fsdfsdf</div></body></html>"));

        auto attachments = otp.collectAttachmentParts();
        QCOMPARE(attachments.size(), 1);
    }

    void testInvitation()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("invitation.mbox")));
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(part);
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
        QVERIFY(!part->isHtml());
        QVERIFY(part->availableModes().contains(MimeTreeParser::AlternativeMessagePart::MultipartIcal));

        auto attachments = otp.collectAttachmentParts();
        QCOMPARE(attachments.size(), 0);
    }

    void testGmailInvitation()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("gmail-invitation.mbox")));
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
        QVERIFY(part);
        QCOMPARE(part->encryptions().size(), 0);
        QCOMPARE(part->signatures().size(), 0);
        QVERIFY(part->isHtml());
        QVERIFY(part->availableModes().contains(MimeTreeParser::AlternativeMessagePart::MultipartIcal));

        auto attachments = otp.collectAttachmentParts();
        QCOMPARE(attachments.size(), 1);
    }

    void testMemoryHole()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted-memoryhole.mbox")));
        otp.decryptParts();
        otp.print();

        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));

        QCOMPARE(part->text(), QStringLiteral("very secret mesage\n"));

        QCOMPARE(part->header("subject")->asUnicodeString(), QStringLiteral("hidden subject"));
        QCOMPARE(part->header("from")->asUnicodeString(), QStringLiteral("you@example.com"));
        QCOMPARE(part->header("to")->asUnicodeString(), QStringLiteral("me@example.com"));
        QCOMPARE(part->header("cc")->asUnicodeString(), QStringLiteral("cc@example.com"));
        QCOMPARE(part->header("message-id")->asUnicodeString(), QStringLiteral("<myhiddenreference@me>"));
        QCOMPARE(part->header("references")->asUnicodeString(), QStringLiteral("<hiddenreference@hidden>"));
        QCOMPARE(part->header("in-reply-to")->asUnicodeString(), QStringLiteral("<hiddenreference@hidden>"));
        QCOMPARE(static_cast<const KMime::Headers::Date *>(part->header("date"))->dateTime(), QDateTime(QDate(2018, 1, 2), QTime(3, 4, 5), QTimeZone::utc()));
    }

    /**
     * Required special handling because the list replaces the toplevel part.
     */
    void testMemoryHoleWithList()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("cid-links-forwarded-inline.mbox")));
        auto part = otp.collectContentParts()[0];
        QVERIFY(part->header("references"));
        QCOMPARE(part->header("references")->asUnicodeString(), QStringLiteral("<a1777ec781546ccc5dcd4918a5e4e03d@info>"));
    }

    void testMemoryHoleMultipartMixed()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted-memoryhole2.mbox")));
        otp.decryptParts();
        otp.print();

        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));

        QCOMPARE(part->text(),
                 QStringLiteral("\n\n  Fsdflkjdslfj\n\n\nHappy Monday!\n\nBelow you will find a quick overview of the current on-goings. Remember\n"));

        QCOMPARE(part->header("subject")->asUnicodeString(), QStringLiteral("This is the subject"));
    }

    void testMIMESignature()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("text+html-maillinglist.mbox")));
        otp.decryptParts();
        otp.print();

        auto partList = otp.collectContentParts();
        for (const auto &part : partList) {
            qWarning() << "found part " << part->metaObject()->className();
        }
        QCOMPARE(partList.size(), 2);
        // The actual content
        {
            auto part = partList[0].dynamicCast<MimeTreeParser::AlternativeMessagePart>();
            QVERIFY(bool(part));
        }

        // The signature
        {
            auto part = partList[1].dynamicCast<MimeTreeParser::TextMessagePart>();
            QVERIFY(bool(part));
            QVERIFY(part->text().contains(QStringLiteral("bugzilla mailing list")));
        }
    }

    void testCRLFEncryptedWithSignature()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("crlf-encrypted-with-signature.mbox")));
        otp.decryptParts();
        otp.print();

        QCOMPARE(otp.plainTextContent(), QStringLiteral("CRLF file\n\n-- \nThis is a signature\nWith two lines\n\nAand another line\n"));
    }

    void testCRLFEncryptedWithSignatureMultipart()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("crlf-encrypted-with-signature-multipart.mbox")));
        otp.decryptParts();
        otp.print();

        // QEXPECT_FAIL("", "because MessagePart::parseInternal uses \n\n to detect encapsulated messages (so 'CRLF file' ends up as header)", Continue);
        // QCOMPARE(otp.plainTextContent(), QStringLiteral("CRLF file\n\n-- \nThis is a signature\nWith two lines\n\nAand another line\n"));
        // QVERIFY(!otp.htmlContent().contains(QStringLiteral("\r\n")));
    }

    void testCRLFOutlook()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("outlook.mbox")));
        otp.decryptParts();
        otp.print();

        qWarning() << otp.plainTextContent();
        QVERIFY(otp.plainTextContent().startsWith(QStringLiteral("Hi Christian,\n\nhabs gerade getestet:\n\n«This is a test")));
        QVERIFY(!otp.htmlContent().contains(QLatin1String("\r\n")));
    }

    void testOpenPGPEncryptedSignedThunderbird()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("openpgp-encrypted-signed-thunderbird.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("sdfsdf\n"));
        QCOMPARE(part->charset(), QStringLiteral("utf-8").toLocal8Bit());
        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(part->signatures()[0]->partMetaData()->isGoodSignature, true);
        QCOMPARE(part->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(part->signatureState(), MimeTreeParser::KMMsgFullySigned);
        auto contentAttachmentList = otp.collectAttachmentParts();
        QCOMPARE(contentAttachmentList.size(), 1);
        // QCOMPARE(contentAttachmentList[0]->content().size(), 1);
        QCOMPARE(contentAttachmentList[0]->encryptions().size(), 1);
        QCOMPARE(contentAttachmentList[0]->signatures().size(), 1);
        QCOMPARE(contentAttachmentList[0]->encryptionState(), MimeTreeParser::KMMsgFullyEncrypted);
        QCOMPARE(contentAttachmentList[0]->signatureState(), MimeTreeParser::KMMsgFullySigned);
    }

    void testSignedForwardOpenpgpSignedEncrypted()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("signed-forward-openpgp-signed-encrypted.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 2);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("bla bla bla"));

        part = partList[1].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral(""));
        QCOMPARE(part->charset(), QStringLiteral("ISO-8859-1").toLocal8Bit());
        QCOMPARE(part->signatures().size(), 1);
        QCOMPARE(part->signatures()[0]->partMetaData()->isGoodSignature, true);
        auto contentAttachmentList = otp.collectAttachmentParts();
        QCOMPARE(contentAttachmentList.size(), 1);
    }

    void testSmimeOpaqueSign()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-opaque-sign.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("A simple signed only test."));
    }

    void testSmimeEncrypted()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-encrypted.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("The quick brown fox jumped over the lazy dog."));
    }

    void testSmimeSignedApple()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-signed-apple.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        // QCOMPARE(part->text(), QStringLiteral("A simple signed only test."));
    }

    void testSmimeEncryptedOctetStream()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-encrypted-octet-stream.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("The quick brown fox jumped over the lazy dog."));
    }

    void testSmimeOpaqueSignedEncryptedAttachment()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-opaque-signed-encrypted-attachment.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("This is an Opaque S/MIME encrypted and signed message with attachment"));
    }

    void testSmimeOpaqueEncSign()
    {
        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QLatin1String("smime-opaque-enc+sign.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));
        QCOMPARE(part->text(), QStringLiteral("Encrypted and signed mail."));
    }
};

QTEST_GUILESS_MAIN(MimeTreeParserTest)
#include "mimetreeparsertest.moc"
