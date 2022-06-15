// SPDX-FileCopyrightText: 2002-2003 Karl-Heinz Zimmer <khz@kde.org>
// SPDX-FileCopyrightText: 2003 Marc Mutz <mutz@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QDateTime>
#include <QStringList>

namespace MimeTreeParser
{

class PartMetaData
{
public:
    bool keyMissing = false;
    bool keyExpired = false;
    bool keyRevoked = false;
    bool sigExpired = false;
    bool crlMissing = false;
    bool crlTooOld = false;
    QString signer;
    QStringList signerMailAddresses;
    QByteArray keyId;
    bool keyIsTrusted = false;
    QString status; // to be used for unknown plug-ins
    QString errorText;
    QDateTime creationTime;
    QString decryptionError;
    QString auditLog;
    bool isSigned = false;
    bool isGoodSignature = false;
    bool isEncrypted = false;
    bool isDecryptable = false;
    bool technicalProblem = false;
    bool isEncapsulatedRfc822Message = false;
};

}
