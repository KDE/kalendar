// SPDX-FileCopyrightText: 2022 Christian Mollekopf <christian@mkpf.ch>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <crypto.h>

#include <QDebug>
#include <QTest>
#include <QtWebEngine>

class CryptoTest : public QObject
{
    Q_OBJECT
private Q_SLOTS:

    void initTestCase()
    {
        QtWebEngine::initialize();
    }

    void testDecrypt()
    {
        QByteArray input =
            "-----BEGIN PGP "
            "MESSAGE-----\n\nhQEMAwzOQ1qnzNo7AQgA3kD1WyRdQawpduoJ3J9h3SpSC7YiNqU7aiyTMUGAdbGO\nBMhIzPdEkai9P486Wpg5h+ywmQrk3KoH/GioRjwvIaeNZY/cmxetT0/"
            "ig5rrnqxM\nj63vFFbCbE6kSeDbvYqF5mL3XH+TqpZRW5ApPSgkr7jMDOK7k1eF5A5ey84LYFny\nKy63LGy5KEQk7E1cMLZOHAZnorcm7Lh3RVWgPj+"
            "DRDowMn3yVdFOpT5bQ66zAIkc\nBs9IWuq0lMxGsdfRv5wlzUqZJGge3oT7tkZhI6D56MLIjqg7SurQMiWrn6wh51Sr\nR7W9N6lHyrKrffP2VjFwPPK1/"
            "Vjd0Am4gTPkf+GcJ4UBDAPKpRg2CPD7UAEIAJuC\n8s2uGAGF9zgoQdrmL6bInA5JCQiZI+B5Jgg9wQ/dW3idJN9esr1Ff7/"
            "d8DVuzf1V\nbFydMBqQk5Zkp5FuDhJsfGWK+NPJBUaOKGlGqRPZX+SjP2k1SuDoxvdxvtWYBVOt\nZhq03zczRWo4dxJ++WYqxu6gMlBCO+z84kfhknWyBNeN7+8mmYGNWDo/"
            "ARWhspO0\nCIOfBCFeqwCpCZLIiCTBjGg98Ed+SGIdjQwq97suh3nANlKFpiNp2+w02H+"
            "rarMj\nIUkaVrKIGqaKw3X7JxuBcD8gzW2nyw6MKrm4q2iTCXYQb8lpUuvITJmNJFIkTmpt\nDjlDEZdJiNhs0IOIepbS6QETyg97HVDWmL4frclu4QAeF28007HHlg805IAjAZ/x\nwU9P3/"
            "VH74zZJinBLmXaIe3XidksWHES3H8ay+UtsUafC+4icSZRwplW9MexBNsl\nmJ4pfrHtAf+t+Tk0/BbuanSbL6OGA1wG7GVEfj39rsc4vYgSS/"
            "NLI5njq55AXFVG\nsyeplNt2FNw3Ii6V3NnEkvlKcmj8sVnGCAIIeaG9yiAJ5qOsHP37sk3TAduKRGSE\nd8Ldty4mBftkTPyOG8eMr28XCldnhqnNWbcP9t2maKAyQ4bjv15Erx+"
            "1AfXXGtVq\n3PsVsUN2YQIib7VLBjOYzW9jysQWFFuE26sE2oH4of34E0jD6GV3d6Ng8gTtpIhO\nBWePihWtHdBGsNNoYrp19IXX594hayaF+"
            "WV8rpaBS0KxVoEHZhFusyvxcDiQnsO7\n3QPVu3btkkte8Hq9KtoFVeFm91M9fii3m3vFBsPu7weMm2zBCxTTRdLd5X+"
            "yEYah\nn8tKnUUFHFIcgdZ3FIoQmIJrrYtcjLnvXeDdB2F6HX7z9KMQ5RzKBZcCMnVViKxl\nPIF3bikUzhtg55BGNyiAu2sz1wLzOoERsb38GN3UK4qinFVXLHxXhcdpEXKocb+"
            "k\nPyRTykAunux+J5+klASl/k85s8gNvMH1CijdNseQEqLlsISERu+zxyFPPit6/"
            "tP6\nwDyvhjHcGV2Jpw5T01n5aJpKklbGb9qUBkzlfayc03ebtqPzBTwG8NEzu9rlZQpr\nldbYUvXYBHSOqk2Z403I0PWR5DlcasFgciHFQw9PODRNK+"
            "OVY46btfyBXABlzYTH\nOMfnHd8HoCOKCp29+ugK2G8y91JNd4M8B2xI1zACFB3hlDoc7K4h85Yi0cCYZahX\nOUWZxSZjfl8X793RT5h+2BE+0bRGLOJIGhAxe+JKUC7O5njXBc3O5/"
            "ocfLif2t4y\neYJmu/w46hJUPxYk4Poe3Oppcim1hKHI7DVSJeJydBRqJgDzRzQ/1u7dD15z69/0\nrbexuTVmwmXN695s/V0=\n=1o3V\n-----END PGP MESSAGE-----\n";

        QByteArray output;
        const auto decryptResult = Crypto::decrypt(Crypto::OpenPGP, input, output);

        const QByteArray expectedOutput =
            "Content-Type: multipart/mixed; boundary=\"HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\";\n protected-headers=\"v1\"\nFrom: test1 <test1@kolab.org>\nTo: "
            "test@kolab.org\nMessage-ID: <a85660b4-6fdf-9d74-ad1c-e6899f57e4b0@kolab.org>\nSubject: "
            "enc+signed\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\nContent-Type: text/rfc822-headers; protected-headers=\"v1\"\nContent-Disposition: "
            "inline\n\nFrom: test1 <test1@kolab.org>\nTo: test@kolab.org\nSubject: enc+signed\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\nContent-Type: "
            "text/plain; charset=utf-8\nContent-Transfer-Encoding: quoted-printable\nContent-Language: en-US\n\ntest\n\n--=20\nThis is a HTML "
            "signature.\n\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ--\n";
        QCOMPARE(output, expectedOutput);
        QCOMPARE(decryptResult.recipients.size(), 2);
        QCOMPARE(decryptResult.recipients[0].keyId, QByteArray{"0CCE435AA7CCDA3B"});
        QCOMPARE(decryptResult.recipients[1].keyId, QByteArray{"CAA5183608F0FB50"});
    }

    void testDecryptAndVerify()
    {
        QByteArray input =
            "-----BEGIN PGP "
            "MESSAGE-----\n\nhQEMAwzOQ1qnzNo7AQgA3kD1WyRdQawpduoJ3J9h3SpSC7YiNqU7aiyTMUGAdbGO\nBMhIzPdEkai9P486Wpg5h+ywmQrk3KoH/GioRjwvIaeNZY/cmxetT0/"
            "ig5rrnqxM\nj63vFFbCbE6kSeDbvYqF5mL3XH+TqpZRW5ApPSgkr7jMDOK7k1eF5A5ey84LYFny\nKy63LGy5KEQk7E1cMLZOHAZnorcm7Lh3RVWgPj+"
            "DRDowMn3yVdFOpT5bQ66zAIkc\nBs9IWuq0lMxGsdfRv5wlzUqZJGge3oT7tkZhI6D56MLIjqg7SurQMiWrn6wh51Sr\nR7W9N6lHyrKrffP2VjFwPPK1/"
            "Vjd0Am4gTPkf+GcJ4UBDAPKpRg2CPD7UAEIAJuC\n8s2uGAGF9zgoQdrmL6bInA5JCQiZI+B5Jgg9wQ/dW3idJN9esr1Ff7/"
            "d8DVuzf1V\nbFydMBqQk5Zkp5FuDhJsfGWK+NPJBUaOKGlGqRPZX+SjP2k1SuDoxvdxvtWYBVOt\nZhq03zczRWo4dxJ++WYqxu6gMlBCO+z84kfhknWyBNeN7+8mmYGNWDo/"
            "ARWhspO0\nCIOfBCFeqwCpCZLIiCTBjGg98Ed+SGIdjQwq97suh3nANlKFpiNp2+w02H+"
            "rarMj\nIUkaVrKIGqaKw3X7JxuBcD8gzW2nyw6MKrm4q2iTCXYQb8lpUuvITJmNJFIkTmpt\nDjlDEZdJiNhs0IOIepbS6QETyg97HVDWmL4frclu4QAeF28007HHlg805IAjAZ/x\nwU9P3/"
            "VH74zZJinBLmXaIe3XidksWHES3H8ay+UtsUafC+4icSZRwplW9MexBNsl\nmJ4pfrHtAf+t+Tk0/BbuanSbL6OGA1wG7GVEfj39rsc4vYgSS/"
            "NLI5njq55AXFVG\nsyeplNt2FNw3Ii6V3NnEkvlKcmj8sVnGCAIIeaG9yiAJ5qOsHP37sk3TAduKRGSE\nd8Ldty4mBftkTPyOG8eMr28XCldnhqnNWbcP9t2maKAyQ4bjv15Erx+"
            "1AfXXGtVq\n3PsVsUN2YQIib7VLBjOYzW9jysQWFFuE26sE2oH4of34E0jD6GV3d6Ng8gTtpIhO\nBWePihWtHdBGsNNoYrp19IXX594hayaF+"
            "WV8rpaBS0KxVoEHZhFusyvxcDiQnsO7\n3QPVu3btkkte8Hq9KtoFVeFm91M9fii3m3vFBsPu7weMm2zBCxTTRdLd5X+"
            "yEYah\nn8tKnUUFHFIcgdZ3FIoQmIJrrYtcjLnvXeDdB2F6HX7z9KMQ5RzKBZcCMnVViKxl\nPIF3bikUzhtg55BGNyiAu2sz1wLzOoERsb38GN3UK4qinFVXLHxXhcdpEXKocb+"
            "k\nPyRTykAunux+J5+klASl/k85s8gNvMH1CijdNseQEqLlsISERu+zxyFPPit6/"
            "tP6\nwDyvhjHcGV2Jpw5T01n5aJpKklbGb9qUBkzlfayc03ebtqPzBTwG8NEzu9rlZQpr\nldbYUvXYBHSOqk2Z403I0PWR5DlcasFgciHFQw9PODRNK+"
            "OVY46btfyBXABlzYTH\nOMfnHd8HoCOKCp29+ugK2G8y91JNd4M8B2xI1zACFB3hlDoc7K4h85Yi0cCYZahX\nOUWZxSZjfl8X793RT5h+2BE+0bRGLOJIGhAxe+JKUC7O5njXBc3O5/"
            "ocfLif2t4y\neYJmu/w46hJUPxYk4Poe3Oppcim1hKHI7DVSJeJydBRqJgDzRzQ/1u7dD15z69/0\nrbexuTVmwmXN695s/V0=\n=1o3V\n-----END PGP MESSAGE-----\n";

        QByteArray output;

        Crypto::DecryptionResult decryptResult;
        Crypto::VerificationResult verifyResult;
        std::tie(decryptResult, verifyResult) = Crypto::decryptAndVerify(Crypto::OpenPGP, input, output);

        const QByteArray expectedOutput =
            "Content-Type: multipart/mixed; boundary=\"HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\";\n protected-headers=\"v1\"\nFrom: test1 <test1@kolab.org>\nTo: "
            "test@kolab.org\nMessage-ID: <a85660b4-6fdf-9d74-ad1c-e6899f57e4b0@kolab.org>\nSubject: "
            "enc+signed\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\nContent-Type: text/rfc822-headers; protected-headers=\"v1\"\nContent-Disposition: "
            "inline\n\nFrom: test1 <test1@kolab.org>\nTo: test@kolab.org\nSubject: enc+signed\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\nContent-Type: "
            "text/plain; charset=utf-8\nContent-Transfer-Encoding: quoted-printable\nContent-Language: en-US\n\ntest\n\n--=20\nThis is a HTML "
            "signature.\n\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ--\n";

        QCOMPARE(output, expectedOutput);
        QCOMPARE(verifyResult.signatures.size(), 1);
        // QCOMPARE(verifyResult.signatures[0].fingerprint, QByteArray{"CBD116485DB9560CA3CD91E02E3B7787B1B75920"});
        QVERIFY(verifyResult.signatures[0].fingerprint.contains(QByteArray{"2E3B7787B1B75920"}));
        QCOMPARE(decryptResult.recipients.size(), 2);
        QCOMPARE(decryptResult.recipients[0].keyId, QByteArray{"0CCE435AA7CCDA3B"});
        QCOMPARE(decryptResult.recipients[1].keyId, QByteArray{"CAA5183608F0FB50"});
    }

    void testDecryptAndVerifyKeyMissing()
    {
        QByteArray input =
            "-----BEGIN PGP "
            "MESSAGE-----\n\nhQEMAwzOQ1qnzNo7AQgA3kD1WyRdQawpduoJ3J9h3SpSC7YiNqU7aiyTMUGAdbGO\nBMhIzPdEkai9P486Wpg5h+ywmQrk3KoH/GioRjwvIaeNZY/cmxetT0/"
            "ig5rrnqxM\nj63vFFbCbE6kSeDbvYqF5mL3XH+TqpZRW5ApPSgkr7jMDOK7k1eF5A5ey84LYFny\nKy63LGy5KEQk7E1cMLZOHAZnorcm7Lh3RVWgPj+"
            "DRDowMn3yVdFOpT5bQ66zAIkc\nBs9IWuq0lMxGsdfRv5wlzUqZJGge3oT7tkZhI6D56MLIjqg7SurQMiWrn6wh51Sr\nR7W9N6lHyrKrffP2VjFwPPK1/"
            "Vjd0Am4gTPkf+GcJ4UBDAPKpRg2CPD7UAEIAJuC\n8s2uGAGF9zgoQdrmL6bInA5JCQiZI+B5Jgg9wQ/dW3idJN9esr1Ff7/"
            "d8DVuzf1V\nbFydMBqQk5Zkp5FuDhJsfGWK+NPJBUaOKGlGqRPZX+SjP2k1SuDoxvdxvtWYBVOt\nZhq03zczRWo4dxJ++WYqxu6gMlBCO+z84kfhknWyBNeN7+8mmYGNWDo/"
            "ARWhspO0\nCIOfBCFeqwCpCZLIiCTBjGg98Ed+SGIdjQwq97suh3nANlKFpiNp2+w02H+"
            "rarMj\nIUkaVrKIGqaKw3X7JxuBcD8gzW2nyw6MKrm4q2iTCXYQb8lpUuvITJmNJFIkTmpt\nDjlDEZdJiNhs0IOIepbS6QETyg97HVDWmL4frclu4QAeF28007HHlg805IAjAZ/x\nwU9P3/"
            "VH74zZJinBLmXaIe3XidksWHES3H8ay+UtsUafC+4icSZRwplW9MexBNsl\nmJ4pfrHtAf+t+Tk0/BbuanSbL6OGA1wG7GVEfj39rsc4vYgSS/"
            "NLI5njq55AXFVG\nsyeplNt2FNw3Ii6V3NnEkvlKcmj8sVnGCAIIeaG9yiAJ5qOsHP37sk3TAduKRGSE\nd8Ldty4mBftkTPyOG8eMr28XCldnhqnNWbcP9t2maKAyQ4bjv15Erx+"
            "1AfXXGtVq\n3PsVsUN2YQIib7VLBjOYzW9jysQWFFuE26sE2oH4of34E0jD6GV3d6Ng8gTtpIhO\nBWePihWtHdBGsNNoYrp19IXX594hayaF+"
            "WV8rpaBS0KxVoEHZhFusyvxcDiQnsO7\n3QPVu3btkkte8Hq9KtoFVeFm91M9fii3m3vFBsPu7weMm2zBCxTTRdLd5X+"
            "yEYah\nn8tKnUUFHFIcgdZ3FIoQmIJrrYtcjLnvXeDdB2F6HX7z9KMQ5RzKBZcCMnVViKxl\nPIF3bikUzhtg55BGNyiAu2sz1wLzOoERsb38GN3UK4qinFVXLHxXhcdpEXKocb+"
            "k\nPyRTykAunux+J5+klASl/k85s8gNvMH1CijdNseQEqLlsISERu+zxyFPPit6/"
            "tP6\nwDyvhjHcGV2Jpw5T01n5aJpKklbGb9qUBkzlfayc03ebtqPzBTwG8NEzu9rlZQpr\nldbYUvXYBHSOqk2Z403I0PWR5DlcasFgciHFQw9PODRNK+"
            "OVY46btfyBXABlzYTH\nOMfnHd8HoCOKCp29+ugK2G8y91JNd4M8B2xI1zACFB3hlDoc7K4h85Yi0cCYZahX\nOUWZxSZjfl8X793RT5h+2BE+0bRGLOJIGhAxe+JKUC7O5njXBc3O5/"
            "ocfLif2t4y\neYJmu/w46hJUPxYk4Poe3Oppcim1hKHI7DVSJeJydBRqJgDzRzQ/1u7dD15z69/0\nrbexuTVmwmXN695s/V0=\n=1o3V\n-----END PGP MESSAGE-----\n";

        QByteArray output;

        Crypto::DecryptionResult decryptResult;
        Crypto::VerificationResult verifyResult;
        std::tie(decryptResult, verifyResult) = Crypto::decryptAndVerify(Crypto::OpenPGP, input, output);

        const QByteArray expectedOutput =
            "Content-Type: multipart/mixed; boundary=\"HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\";\n protected-headers=\"v1\"\nFrom: test1 <test1@kolab.org>\nTo: "
            "test@kolab.org\nMessage-ID: <a85660b4-6fdf-9d74-ad1c-e6899f57e4b0@kolab.org>\nSubject: "
            "enc+signed\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\nContent-Type: text/rfc822-headers; protected-headers=\"v1\"\nContent-Disposition: "
            "inline\n\nFrom: test1 <test1@kolab.org>\nTo: test@kolab.org\nSubject: enc+signed\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ\nContent-Type: "
            "text/plain; charset=utf-8\nContent-Transfer-Encoding: quoted-printable\nContent-Language: en-US\n\ntest\n\n--=20\nThis is a HTML "
            "signature.\n\n\n--HKEnEQX5LVRrGxcPEIzBMsyPh2G25GeZZ--\n";

        QCOMPARE(output, expectedOutput);
        QCOMPARE(verifyResult.signatures.size(), 1);
        QCOMPARE(verifyResult.signatures[0].result, Crypto::Signature::KeyNotFound);
    }

    void testDecryptAndVerifyCRLFEncryptedWithSignature()
    {
        // This was the original input that seems to have some padding issues (which could stem from some crlf "normalization" we're doing.
        //  QByteArray input = "-----BEGIN PGP
        //  MESSAGE-----\n\nhQEMAwzOQ1qnzNo7AQgAgXLGaohf4ZPJVDkpmpNsyXL/nccd+SyY3/deHQ8d8vp9\nYe9Hr30Yz65+CAI7JCHKjIOaXjw1Nf1qqEDSyghKR0c16dLBGK37GlqOLaqScifZ\n/bC5WQu4V1a+dv1qnNOh3JNp5ynVpg22b5XaBggpAGCxCSrUsWWkRxTR+kBuPdn8\nEPMOlN3xKU1LFQfI+a3HMGpWo3PokVb4nrtuuwi261woSgKUSYjG86MJF1E28y+g\nbMC6rmRV+Jp0wpEmr7aogx4gELe17tglD41oLvNL9yZeEh/V8cMnnEDbO/oG+xba\nUjyM73V+TO2kXk0CTqItVbx6Q7kNWR/DfaJqGnzcy9KMAT1B8EpVCK/nN81mF8ia\n4KFKQ1OGHhcQ2tT5ZXs6m1vJ5/sz/6g0n0CMtSsWUSvPzpM5F+LK+B7dzOeJEQee\n3/S0wUFYpbAh1PyMPYobNLsEQCGtQ1PhsUXM7t1ai6jfM4k/lvbnIzUM11Q6vsnR\nLWS77CELfcW9WlQ755sNcwo3a/WySyU1C1gZdLw=Fijx\n-----END
        //  PGP MESSAGE-----\n";

        // This is what I got from reencrypting the output with gpgme.
        QByteArray input =
            "-----BEGIN PGP "
            "MESSAGE-----\n\nhQEMAwzOQ1qnzNo7AQf/e+AvN9SH/nCo8VNWEhw8w9zMFrC+LK0HmXGedmwVDS+p\nX/"
            "4dBFC4ftR0jvzKyiBpjtAisD7zfNIcPd1rkfjtjf1kvksuDej+"
            "rVBZ8Mupa7Rl\ng9tCGSwxNmKU9v3BzSVXV9z4P2PHYpOn68WOnDZZqUVdvbZ6WuowAzBjiECo59cZ\nZmOp5kO4DGEE7vJ3QSR58VUYhM7kUcUYOf68syZiGOO7gC075ZLXIc3l+"
            "rD4fYtJ\nAsGsfVXmbxB58aVuNZllK/CshfjddPbVRladc4xJ1KsnC/M+mOClUM2WJ7Ghw+V6\nkta1xPC3cjc1j7rPm1LH2ESzqvhkhay6ATaBNJ3rd9J/AYU0/"
            "WFF+HQryulNxiCg\nzkN0kfC0lJ8GOKtlwgIcY6AsyStPR13fkXT0xRbB+zvms5nHmbtUvtsjeOsw7BJL\ndLBq5P+0xiCZR+/gBhkx/"
            "OqBFtel3qktopoDRi3rnVMJGMVcKiAFmf3612HU5tYb\n8iolmHNdKSksNbDKYgzLnQ==\n=YzFH\n-----END PGP MESSAGE-----\n";

        QByteArray output;

        Crypto::DecryptionResult decryptResult;
        Crypto::VerificationResult verifyResult;
        std::tie(decryptResult, verifyResult) = Crypto::decryptAndVerify(Crypto::OpenPGP, input, output);

        const QByteArray expectedOutput = "CRLF file\r\n\r\n-- \r\nThis is a signature\r\nWith two lines\r\n\r\nAand another line\r\n";

        // QEXPECT_FAIL("", "either librnp or gpgme fails to handle CRLF properly", Continue);
        QCOMPARE(output, expectedOutput);
        QCOMPARE(verifyResult.signatures.size(), 0);
        QCOMPARE(decryptResult.recipients.size(), 1);

        // qWarning() << decryptResult.recipients[0].keyId;
        // const auto keys = Crypto::findKeys({{decryptResult.recipients[0].keyId}});
        // QCOMPARE(keys.size(), 1);
        // auto result =  Crypto::signAndEncrypt(expectedOutput, keys, {});
        // qWarning() << result.value();
    }

    void testVerifyDetachedSignature()
    {
        QByteArray signature =
            "-----BEGIN PGP SIGNATURE-----\nVersion: GnuPG v2.0.15 "
            "(GNU/Linux)\n\niQEcBAABAgAGBQJMh7F5AAoJEI2YYMWPJG3mOB0IALeHfwg8u7wK0tDKtKqxQSqC\n2Bbk4pTLuLw/VniQNauDG+kc1eUc5RJk/"
            "R31aB1ysiQCV5Q8ucI8c9vCDDMbd+s4\nt2bZUEzMpXrw/"
            "aFiHgYGXFAY+tpqZqDGNVRNHWsPYJKtx8cci9E5DLnBJcVXVqib\n3iiHlr9AQOok3PUmpPk1a61q2L0kk8wqRenC0yZXNw5qFn5WW/"
            "hFeCOfYB+t+s5N\nIuE6ihFCJIlvGborrvl6VgPJTCyUQ3XgI90vS6ABN8TFlCNr3grXOWUePc2a20or\nxFgh38cnSR64WJajU5K1nUL9/RgfIcs+PvyHuJaRf/"
            "iUFkj1jiMEuaSi9jVFco0=\n=bArV\n-----END PGP SIGNATURE-----\n";
        QByteArray signedData =
            "Content-Type: multipart/mixed; boundary=\"nextPart1512490.WQBKYaOrt8\"\r\nContent-Transfer-Encoding: "
            "7Bit\r\n\r\n\r\n--nextPart1512490.WQBKYaOrt8\r\nContent-Transfer-Encoding: 7Bit\r\nContent-Type: text/plain; charset=\"us-ascii\"\r\n\r\nbla bla "
            "bla\r\n--nextPart1512490.WQBKYaOrt8\r\nContent-Type: message/rfc822\r\nContent-Disposition: inline; filename=\"forwarded "
            "message\"\r\nContent-Description: OpenPGP Test <test@kolab.org>: OpenPGP signed and encrypted\r\n\r\nFrom: OpenPGP Test <test@kolab.org>\r\nTo: "
            "test@kolab.org\r\nSubject: OpenPGP signed and encrypted\r\nDate: Tue, 07 Sep 2010 18:08:44 +0200\r\nUser-Agent: KMail/4.6 pre "
            "(Linux/2.6.34-rc2-2-default; KDE/4.5.60; x86_64; ; )\r\nMIME-Version: 1.0\r\nContent-Type: multipart/encrypted; "
            "boundary=\"nextPart25203163.0xtB501Z4V\"; protocol=\"application/pgp-encrypted\"\r\nContent-Transfer-Encoding: "
            "7Bit\r\n\r\n\r\n--nextPart25203163.0xtB501Z4V\r\nContent-Type: application/pgp-encrypted\r\nContent-Disposition: attachment\r\n\r\nVersion: "
            "1\r\n--nextPart25203163.0xtB501Z4V\r\nContent-Type: application/octet-stream\r\nContent-Disposition: inline; "
            "filename=\"msg.asc\"\r\n\r\n-----BEGIN PGP MESSAGE-----\r\nVersion: GnuPG v2.0.15 "
            "(GNU/Linux)\r\n\r\nhQEMAwzOQ1qnzNo7AQf7BFYWaGiCTGtXY59bSh3LCXNnWZejblYALxIUNXOFEXbm\r\ny/YA95FmQsy3U5HRCAJV/"
            "DY1PEaJz1RTm9bcdIpDC3Ab2YzSwmOwV5fcoUOB2df4\r\nKjX19Q+2F3JxpPQ0N1gHf4dKfIu19LH+CKeFzUN13aJs5J4A5wlj+"
            "NjJikxzmxDS\r\nkDtNYndynPmo9DJQcsUFw3gpvx5HaHvx1cT4mAB2M5cd2l+vN1jYbaWb0x5Zq41z\r\nmRNI89aPieC3rcM2289m68fGloNbYvi8mZJu5RrI4Tbi/"
            "D7Rjm1y63lHgVV6AN88\r\nXAzRiedOeF99LoTBulrJdtT8AAgCs8nCetcWpIffdtLpAZiZkzHmYOU7nqGxqpRk\r\nOVeUTrCn9DW2SMmHjaP4IiKnMvzEycu5F4a72+V1LeMIhMSjTRTq+"
            "ZE2PTaqH59z\r\nQsMn7Nb6GlOICbTptRKNNtyJKO7xXlpT7YtvNKnCyEOkH2XrYH7GvpYCiuQ0/o+7\r\nSxV436ZejiYIg6DQDXJCoa2DXimGp0C10Jh0HwX0BixpoNtwEjkGRYcX6P/"
            "JzkH0\r\noBood4Ly+Tiu6iVDisrK3AVGYpIzCrKkE9qULTw4R/"
            "jFKR2tcCqGb7Fxtk2LV7Md\r\n3S+DyOKrvKQ5GNwbp9OE97pwk+Lr1JS3UAvj5f6BR+1PVNcC0i0wWkgwDjPh1eGD\r\nenMQmorE6+N0uHtH2F4fOxo/TbbA3+zhI25kVW3bO03xyUl/"
            "cmQZeb52nvfOvtOo\r\ngSb2j6bPkzljDMPEzrtJjbFtGHJbPfUQYJgZv9OE2EQIqpg6goIw279alBq6GLIX\r\npkO+dRmztzjcDyhcLxMuQ4cTizel/0J/"
            "bU7U6lvwHSyZVbT4Ev+opG5K70Hbqbwr\r\nNZcgdWXbSeesxGM/oQaMeSurOevxVl+/"
            "zrTVAek61aRRd1baAYqgi2pf2V7y4oK3\r\nqkdxzmoFpRdNlfrQW65NZWnHOi9rC9XxANIwnVn3kRcDf+t2K4PrFluI157lXM/"
            "o\r\nwX91j88fazysbJlQ6TjsApO9ETiPOFEBqouxCTtCZzlUgyVG8jpIjdHWFnagHeXH\r\n+"
            "lXNdYjxnTWTjTxMOZC9ySMpXkjWdFI1ecxVwu6Ik6RX51rvBJAAXWP75yUjPKJ4\r\nrRi5oQl/VLl0QznO7lvgMPtUwgDVNWO/r7Kn9B387h9fAJZ/"
            "kWFAEDW2yhAzABqO\r\nrCNKDzBPgfAwCnikCpMoCbOL7SU8BdbzQHD8/Lkv4m0pzliHQ/KkGF710koBzTmF\r\nN7+wk9pwIuvcrEBQj567\r\n=GV0c\r\n-----END PGP "
            "MESSAGE-----\r\n\r\n--nextPart25203163.0xtB501Z4V--\r\n\r\n--nextPart1512490.WQBKYaOrt8--\r\n";

        const auto result = Crypto::verifyDetachedSignature(Crypto::OpenPGP, signature, signedData);
        QCOMPARE(result.signatures.size(), 1);
        QVERIFY(result.signatures[0].fingerprint.contains(QByteArray{"8D9860C58F246DE6"}));
        QCOMPARE(result.signatures[0].result, Crypto::Signature::Ok);
    }

    void testVerifyOpaqueSignature()
    {
        QByteArray signedData =
            "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\nohno \xF6\xE4\xFC\n-----BEGIN PGP SIGNATURE-----\nVersion: GnuPG "
            "v2\n\niQEcBAEBCAAGBQJV3H/vAAoJEI2YYMWPJG3mEZQH/2mbCDa60risTUsomEecasc7\nkIc8Ch+OjZwlEQWKEiFbpLCMVjMwf0oGFcpc/"
            "dqnIyIqeVvF6Em+v7iqKuyAaihu\n7ZxxC816tDDI7UIpmyWu39McqGB/2hoA/"
            "q+"
            "QAMgBiaIuMwYJK9Aw08hXzoCds6O7\nUor2Y6kMSwEiRnTSYvQHdoaZY3F9SFTLPgjvwfSu7scvp7xvH7bAVIqGGfkLjXpP\nOFkDhEqUI7ORwD5cvvzEu57XmbGB7Nj5LRCGcTq6IlaGeN6Pw"
            "5+hOdd6MQ4iISwy\n870msP9NvktURnfXYC3fYnJaK/eUln7LYCBl/k04Z/3Um6dMYyQGh63oGv/2qxQ=\n=4ctb\n-----END PGP SIGNATURE-----";
        QByteArray outdata;
        const auto result = Crypto::verifyOpaqueSignature(Crypto::OpenPGP, signedData, outdata);
        QCOMPARE(result.signatures.size(), 1);
        QVERIFY(result.signatures[0].fingerprint.contains(QByteArray{"8D9860C58F246DE6"}));
        QCOMPARE(result.signatures[0].result, Crypto::Signature::Ok);
        QCOMPARE(outdata, QByteArray{"ohno \xF6\xE4\xFC\n"});
    }
};

QTEST_GUILESS_MAIN(CryptoTest)
#include "cryptotest.moc"
