/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"

#include <gpgme++/global.h>

class Transport;

namespace KIdentityManagement
{
class Identity;
}

class Identity : public SetupObject
{
    Q_OBJECT
public:
    explicit Identity(QObject *parent = nullptr);
    ~Identity() override;
    void create() override;
    void destroy() override;

public Q_SLOTS:
    Q_SCRIPTABLE void setIdentityName(const QString &name);
    Q_SCRIPTABLE void setRealName(const QString &name);
    Q_SCRIPTABLE void setEmail(const QString &email);
    Q_SCRIPTABLE void setOrganization(const QString &org);
    Q_SCRIPTABLE void setSignature(const QString &sig);
    Q_SCRIPTABLE uint uoid() const;
    Q_SCRIPTABLE void setTransport(QObject *transport);
    Q_SCRIPTABLE void setPreferredCryptoMessageFormat(const QString &format);
    Q_SCRIPTABLE void setXFace(const QString &xface);
    Q_SCRIPTABLE void setPgpAutoSign(bool autosign);
    Q_SCRIPTABLE void setPgpAutoEncrypt(bool autoencrypt);
    Q_SCRIPTABLE void setKey(GpgME::Protocol protocol, const QByteArray &fingerprint);

private:
    Q_REQUIRED_RESULT QString identityName() const;
    QString m_identityName;
    KIdentityManagement::Identity *m_identity = nullptr;
};
