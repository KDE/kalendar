// SPDX-FileCopyrightText: 2016 Sandro Knauß <knauss@kolabsystems.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <objecttreeparser.h>

#include <gpgme.h>

#include <QDebug>
#include <QDir>
#include <QProcess>
#include <QTest>
#include <QtGlobal>
#include <qobjectdefs.h>

QByteArray readMailFromFile(const QString &mailFile)
{
    QFile file(QLatin1String(MAIL_DATA_DIR) + QLatin1Char('/') + mailFile);
    file.open(QIODevice::ReadOnly);
    Q_ASSERT(file.isOpen());
    return file.readAll();
}

void killAgent(const QString &dir)
{
    QProcess proc;
    proc.setProgram(QStringLiteral("gpg-connect-agent"));
    QStringList arguments;
    arguments << QStringLiteral("-S ") << dir + QStringLiteral("/S.gpg-agent");
    proc.start();
    proc.waitForStarted();
    proc.write("KILLAGENT\n");
    proc.write("BYE\n");
    proc.closeWriteChannel();
    proc.waitForFinished();
}

class GpgErrorTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void testGpgConfiguredCorrectly()
    {
        setEnv("GNUPGHOME", GNUPGHOME);

        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(QStringLiteral("openpgp-inline-charset-encrypted.mbox")));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0];
        QVERIFY(bool(part));

        QVERIFY(part->text().startsWith(QStringLiteral("asdasd")));
        QCOMPARE(part->encryptions().size(), 1);
        auto enc = part->encryptions()[0];
        QCOMPARE(enc->error(), MimeTreeParser::MessagePart::NoError);
        // QCOMPARE((int) enc->recipients().size(), 2);
    }

    void testNoGPGInstalled_data()
    {
        QTest::addColumn<QString>("mailFileName");

        QTest::newRow("openpgp-inline-charset-encrypted") << "openpgp-inline-charset-encrypted.mbox";
        QTest::newRow("openpgp-encrypted-attachment-and-non-encrypted-attachment") << "openpgp-encrypted-attachment-and-non-encrypted-attachment.mbox";
        QTest::newRow("smime-encrypted") << "smime-encrypted.mbox";
    }

    void testNoGPGInstalled()
    {
        QFETCH(QString, mailFileName);

        setEnv("PATH", "/nonexististing");
        setGpgMEfname("/nonexisting/gpg", "");

        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(mailFileName));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));

        QCOMPARE(part->encryptions().size(), 1);
        QVERIFY(part->text().isEmpty());
        auto enc = part->encryptions()[0];
        QCOMPARE(enc->error(), MimeTreeParser::MessagePart::NoKeyError);
    }

    void testGpgIncorrectGPGHOME_data()
    {
        QTest::addColumn<QString>("mailFileName");

        QTest::newRow("openpgp-inline-charset-encrypted") << "openpgp-inline-charset-encrypted.mbox";
        QTest::newRow("openpgp-encrypted-attachment-and-non-encrypted-attachment") << "openpgp-encrypted-attachment-and-non-encrypted-attachment.mbox";
        QTest::newRow("smime-encrypted") << "smime-encrypted.mbox";
    }

    void testGpgIncorrectGPGHOME()
    {
        QFETCH(QString, mailFileName);
        setEnv("GNUPGHOME", QByteArray(GNUPGHOME) + QByteArray("noexist"));

        MimeTreeParser::ObjectTreeParser otp;
        otp.parseObjectTree(readMailFromFile(mailFileName));
        otp.print();
        otp.decryptParts();
        otp.print();
        auto partList = otp.collectContentParts();
        QCOMPARE(partList.size(), 1);
        auto part = partList[0].dynamicCast<MimeTreeParser::MessagePart>();
        QVERIFY(bool(part));

        QCOMPARE(part->encryptions().size(), 1);
        QCOMPARE(part->signatures().size(), 0);
        QVERIFY(part->text().isEmpty());
        auto enc = part->encryptions()[0];
        QCOMPARE(enc->error(), MimeTreeParser::MessagePart::NoKeyError);
        // QCOMPARE((int) enc->recipients().size(), 2);
    }

public Q_SLOTS:
    void init()
    {
        mResetGpgmeEngine = false;
        mModifiedEnv.clear();
        {
            gpgme_check_version(nullptr);
            gpgme_ctx_t ctx = nullptr;
            gpgme_new(&ctx);
            gpgme_set_protocol(ctx, GPGME_PROTOCOL_OpenPGP);
            gpgme_engine_info_t info = gpgme_ctx_get_engine_info(ctx);
            mGpgmeEngine_fname = info->file_name;
            gpgme_release(ctx);
        }
        mEnv = QProcessEnvironment::systemEnvironment();
        unsetEnv("GNUPGHOME");
    }

    void cleanup()
    {
        QCoreApplication::sendPostedEvents();

        const QString &gnupghome = QString::fromUtf8(qgetenv("GNUPGHOME"));
        if (!gnupghome.isEmpty()) {
            killAgent(gnupghome);
        }

        resetGpgMfname();
        resetEnv();
    }

private:
    void unsetEnv(const QByteArray &name)
    {
        mModifiedEnv << name;
        qunsetenv(name.data());
    }

    void setEnv(const QByteArray &name, const QByteArray &value)
    {
        mModifiedEnv << name;
        qputenv(name.data(), value);
    }

    void resetEnv()
    {
        for (const auto &i : std::as_const(mModifiedEnv)) {
            const auto env = i.data();
            if (mEnv.contains(QString::fromUtf8(i))) {
                qputenv(env, mEnv.value(QString::fromUtf8(i)).toUtf8());
            } else {
                qunsetenv(env);
            }
        }
    }

    void resetGpgMfname()
    {
        if (mResetGpgmeEngine) {
            gpgme_set_engine_info(GPGME_PROTOCOL_OpenPGP, mGpgmeEngine_fname.data(), nullptr);
        }
    }

    void setGpgMEfname(const QByteArray &fname, const QByteArray &homedir)
    {
        mResetGpgmeEngine = true;
        gpgme_set_engine_info(GPGME_PROTOCOL_OpenPGP, fname.data(), homedir.data());
    }

    QSet<QByteArray> mModifiedEnv;
    QProcessEnvironment mEnv;
    bool mResetGpgmeEngine;
    QByteArray mGpgmeEngine_fname;
};

QTEST_GUILESS_MAIN(GpgErrorTest)
#include "gpgerrortest.moc"
