/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "identity.h"
#include "transport.h"

#include <KIdentityManagement/IdentityManager>
#include <kidentitymanagement/identity.h>

#include <KLocalizedString>

Identity::Identity(QObject *parent)
    : SetupObject(parent)
{
    m_identity = &KIdentityManagement::IdentityManager::self()->newFromScratch(QString());
    Q_ASSERT(m_identity != nullptr);
}

Identity::~Identity() = default;

void Identity::create()
{
    Q_EMIT info(i18n("Setting up identity..."));

    // store identity information
    m_identityName = identityName();
    m_identity->setIdentityName(m_identityName);
    auto manager = KIdentityManagement::IdentityManager::self();
    manager->commit();
    if (!manager->setAsDefault(m_identity->uoid())) {
        qWarning() << "Impossible to find identity";
    }

    Q_EMIT finished(i18n("Identity set up."));
}

QString Identity::identityName() const
{
    // create identity name
    QString name(m_identityName);
    if (name.isEmpty()) {
        name = i18nc("Default name for new email accounts/identities.", "Unnamed");

        const QString idName = m_identity->primaryEmailAddress();
        int pos = idName.indexOf(QLatin1Char('@'));
        if (pos != -1) {
            name = idName.mid(0, pos);
        }

        // Make the name a bit more human friendly
        name.replace(QLatin1Char('.'), QLatin1Char(' '));
        pos = name.indexOf(QLatin1Char(' '));
        if (pos != 0) {
            name[pos + 1] = name[pos + 1].toUpper();
        }
        name[0] = name[0].toUpper();
    }

    auto manager = KIdentityManagement::IdentityManager::self();
    if (!manager->isUnique(name)) {
        name = manager->makeUnique(name);
    }
    return name;
}

void Identity::destroy()
{
    auto manager = KIdentityManagement::IdentityManager::self();
    if (!manager->removeIdentityForced(m_identityName)) {
        qWarning() << " impossible to remove identity " << m_identityName;
    }
    manager->commit();
    m_identity = nullptr;
    Q_EMIT info(i18n("Identity removed."));
}

void Identity::setIdentityName(const QString &name)
{
    m_identityName = name;
}

void Identity::setRealName(const QString &name)
{
    m_identity->setFullName(name);
}

void Identity::setOrganization(const QString &org)
{
    m_identity->setOrganization(org);
}

void Identity::setEmail(const QString &email)
{
    m_identity->setPrimaryEmailAddress(email);
}

uint Identity::uoid() const
{
    return m_identity->uoid();
}

void Identity::setTransport(QObject *transport)
{
    if (transport) {
        m_identity->setTransport(QString::number(qobject_cast<Transport *>(transport)->transportId()));
    } else {
        m_identity->setTransport(QString());
    }
    setDependsOn(qobject_cast<SetupObject *>(transport));
}

void Identity::setSignature(const QString &sig)
{
    if (!sig.isEmpty()) {
        const KIdentityManagement::Signature signature(sig);
        m_identity->setSignature(signature);
    } else {
        m_identity->setSignature(KIdentityManagement::Signature());
    }
}

void Identity::setPreferredCryptoMessageFormat(const QString &format)
{
    m_identity->setPreferredCryptoMessageFormat(format);
}

void Identity::setXFace(const QString &xface)
{
    m_identity->setXFaceEnabled(!xface.isEmpty());
    m_identity->setXFace(xface);
}

void Identity::setPgpAutoEncrypt(bool autoencrypt)
{
    m_identity->setPgpAutoEncrypt(autoencrypt);
}

void Identity::setPgpAutoSign(bool autosign)
{
    m_identity->setPgpAutoSign(autosign);
}

void Identity::setKey(GpgME::Protocol protocol, const QByteArray &fingerprint)
{
    if (fingerprint.isEmpty()) {
        m_identity->setPGPEncryptionKey(QByteArray());
        m_identity->setPGPSigningKey(QByteArray());
        m_identity->setSMIMEEncryptionKey(QByteArray());
        m_identity->setSMIMESigningKey(QByteArray());
    } else if (protocol == GpgME::OpenPGP) {
        m_identity->setPGPSigningKey(fingerprint);
        m_identity->setPGPEncryptionKey(fingerprint);
    } else if (protocol == GpgME::CMS) {
        m_identity->setSMIMESigningKey(fingerprint);
        m_identity->setSMIMEEncryptionKey(fingerprint);
    }
}
