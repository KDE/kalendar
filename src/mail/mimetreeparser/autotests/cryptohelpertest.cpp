// Copyright 2015 Sandro Knauß <knauss@kolabsys.com>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#include "cryptohelpertest.h"

#include "cryptohelper.h"

#include <QTest>

using namespace MimeTreeParser;

void CryptoHelperTest::testPMFDEmpty()
{
    QCOMPARE(prepareMessageForDecryption("").count(), 0);
}

void CryptoHelperTest::testPMFDWithNoPGPBlock()
{
    const QByteArray text = "testblabla";
    const QList<Block> blocks = prepareMessageForDecryption(text);
    QCOMPARE(blocks.count(), 1);
    QCOMPARE(blocks[0].text(), text);
    QCOMPARE(blocks[0].type(), NoPgpBlock);
}

void CryptoHelperTest::testPGPBlockType()
{
    const QString blockText = QStringLiteral("text");
    const QString preString = QStringLiteral("before\n");
    for (int i = 1; i <= PrivateKeyBlock; ++i) {
        QString name;
        switch (i) {
        case PgpMessageBlock:
            name = QStringLiteral("MESSAGE");
            break;
        case MultiPgpMessageBlock:
            name = QStringLiteral("MESSAGE PART");
            break;
        case SignatureBlock:
            name = QStringLiteral("SIGNATURE");
            break;
        case ClearsignedBlock:
            name = QStringLiteral("SIGNED MESSAGE");
            break;
        case PublicKeyBlock:
            name = QStringLiteral("PUBLIC KEY BLOCK");
            break;
        case PrivateKeyBlock:
            name = QStringLiteral("PRIVATE KEY BLOCK");
            break;
        }
        QString text = QLatin1String("-----BEGIN PGP ") + name + QLatin1String("\n") + blockText;
        QList<Block> blocks = prepareMessageForDecryption(preString.toLatin1() + text.toLatin1());
        QCOMPARE(blocks.count(), 1);
        QCOMPARE(blocks[0].type(), UnknownBlock);

        text += QLatin1String("\n-----END PGP ") + name + QLatin1String("\n");
        blocks = prepareMessageForDecryption(preString.toLatin1() + text.toLatin1());
        QCOMPARE(blocks.count(), 2);
        QCOMPARE(blocks[1].text(), text.toLatin1());
        QCOMPARE(blocks[1].type(), static_cast<PGPBlockType>(i));
    }
}

void CryptoHelperTest::testDeterminePGPBlockType()
{
    const QString blockText = QStringLiteral("text");
    for (int i = 1; i <= PrivateKeyBlock; ++i) {
        QString name;
        switch (i) {
        case PgpMessageBlock:
            name = QStringLiteral("MESSAGE");
            break;
        case MultiPgpMessageBlock:
            name = QStringLiteral("MESSAGE PART");
            break;
        case SignatureBlock:
            name = QStringLiteral("SIGNATURE");
            break;
        case ClearsignedBlock:
            name = QStringLiteral("SIGNED MESSAGE");
            break;
        case PublicKeyBlock:
            name = QStringLiteral("PUBLIC KEY BLOCK");
            break;
        case PrivateKeyBlock:
            name = QStringLiteral("PRIVATE KEY BLOCK");
            break;
        }
        const QString text = QLatin1String("-----BEGIN PGP ") + name + QLatin1String("\n") + blockText + QLatin1String("\n");
        const Block block = Block(text.toLatin1());
        QCOMPARE(block.text(), text.toLatin1());
        QCOMPARE(block.type(), static_cast<PGPBlockType>(i));
    }
}

void CryptoHelperTest::testEmbededPGPBlock()
{
    const QByteArray text = QByteArray("before\n-----BEGIN PGP MESSAGE-----\ncrypted - you see :)\n-----END PGP MESSAGE-----\nafter");
    const QList<Block> blocks = prepareMessageForDecryption(text);
    QCOMPARE(blocks.count(), 3);
    QCOMPARE(blocks[0].text(), QByteArray("before\n"));
    QCOMPARE(blocks[1].text(), QByteArray("-----BEGIN PGP MESSAGE-----\ncrypted - you see :)\n-----END PGP MESSAGE-----\n"));
    QCOMPARE(blocks[2].text(), QByteArray("after"));
}

void CryptoHelperTest::testClearSignedMessage()
{
    const QByteArray text = QByteArray(
        "before\n-----BEGIN PGP SIGNED MESSAGE-----\nsigned content\n-----BEGIN PGP SIGNATURE-----\nfancy signature\n-----END PGP SIGNATURE-----\nafter");
    const QList<Block> blocks = prepareMessageForDecryption(text);
    QCOMPARE(blocks.count(), 3);
    QCOMPARE(blocks[0].text(), QByteArray("before\n"));
    QCOMPARE(blocks[1].text(),
             QByteArray("-----BEGIN PGP SIGNED MESSAGE-----\nsigned content\n-----BEGIN PGP SIGNATURE-----\nfancy signature\n-----END PGP SIGNATURE-----\n"));
    QCOMPARE(blocks[2].text(), QByteArray("after"));
}

void CryptoHelperTest::testMultipleBlockMessage()
{
    const QByteArray text = QByteArray(
        "before\n-----BEGIN PGP SIGNED MESSAGE-----\nsigned content\n-----BEGIN PGP SIGNATURE-----\nfancy signature\n-----END PGP "
        "SIGNATURE-----\nafter\n-----BEGIN PGP MESSAGE-----\ncrypted - you see :)\n-----END PGP MESSAGE-----\n");
    const QList<Block> blocks = prepareMessageForDecryption(text);
    QCOMPARE(blocks.count(), 4);
    QCOMPARE(blocks[0].text(), QByteArray("before\n"));
    QCOMPARE(blocks[1].text(),
             QByteArray("-----BEGIN PGP SIGNED MESSAGE-----\nsigned content\n-----BEGIN PGP SIGNATURE-----\nfancy signature\n-----END PGP SIGNATURE-----\n"));
    QCOMPARE(blocks[2].text(), QByteArray("after\n"));
    QCOMPARE(blocks[3].text(), QByteArray("-----BEGIN PGP MESSAGE-----\ncrypted - you see :)\n-----END PGP MESSAGE-----\n"));
}

QTEST_APPLESS_MAIN(CryptoHelperTest)
