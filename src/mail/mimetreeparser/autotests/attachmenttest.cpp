// SPDX-FileCopyrightText: 2015 Volker Krause <vkrause@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "objecttreeparser.h"

#include "setupenv.h"

#include <QDebug>
#include <QTest>

using namespace MimeTreeParser;

class AttachmentTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void initTestCase();
    void testEncryptedAttachment_data();
    void testEncryptedAttachment();
};

QTEST_MAIN(AttachmentTest)

QByteArray readMailFromFile(const QString &mailFile)
{
    QFile file(QLatin1String(MAIL_DATA_DIR) + QLatin1Char('/') + mailFile);
    file.open(QIODevice::ReadOnly);
    Q_ASSERT(file.isOpen());
    return file.readAll();
}

void AttachmentTest::initTestCase()
{
    MimeTreeParser::Test::setupEnv();
}

void AttachmentTest::testEncryptedAttachment_data()
{
    QTest::addColumn<QString>("mbox");
    QTest::newRow("encrypted") << "openpgp-encrypted-two-attachments.mbox";
    QTest::newRow("signed") << "openpgp-signed-two-attachments.mbox";
    QTest::newRow("signed+encrypted") << "openpgp-signed-encrypted-two-attachments.mbox";
    QTest::newRow("encrypted+partial signed") << "openpgp-encrypted-partially-signed-attachments.mbox";
}

void AttachmentTest::testEncryptedAttachment()
{
    QFETCH(QString, mbox);
    ObjectTreeParser otp;
    otp.parseObjectTree(readMailFromFile(mbox));
    otp.decryptParts();
    otp.print();

    auto attachmentParts = otp.collectAttachmentParts();
    QCOMPARE(attachmentParts.size(), 2);
}

#include "attachmenttest.moc"
