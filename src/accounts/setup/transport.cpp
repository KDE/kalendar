/*
    SPDX-FileCopyrightText: 2009 Volker Krause <vkrause@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "transport.h"

#include <MailTransport/TransportManager>

#include <KLocalizedString>

#define TABLE_SIZE x

template<typename T>
struct StringValueTable {
    const char *name;
    typename T::type value;
    using value_type = typename T::type;
};

static const StringValueTable<MailTransport::Transport::EnumEncryption> encryptionEnum[] = {{"none", MailTransport::Transport::EnumEncryption::None},
                                                                                            {"ssl", MailTransport::Transport::EnumEncryption::SSL},
                                                                                            {"tls", MailTransport::Transport::EnumEncryption::TLS}};
static const int encryptionEnumSize = sizeof(encryptionEnum) / sizeof(*encryptionEnum);

static const StringValueTable<MailTransport::Transport::EnumAuthenticationType> authenticationTypeEnum[] = {
    {"login", MailTransport::Transport::EnumAuthenticationType::LOGIN},
    {"plain", MailTransport::Transport::EnumAuthenticationType::PLAIN},
    {"cram-md5", MailTransport::Transport::EnumAuthenticationType::CRAM_MD5},
    {"digest-md5", MailTransport::Transport::EnumAuthenticationType::DIGEST_MD5},
    {"gssapi", MailTransport::Transport::EnumAuthenticationType::GSSAPI},
    {"ntlm", MailTransport::Transport::EnumAuthenticationType::NTLM},
    {"apop", MailTransport::Transport::EnumAuthenticationType::APOP},
    {"clear", MailTransport::Transport::EnumAuthenticationType::CLEAR},
    {"oauth2", MailTransport::Transport::EnumAuthenticationType::XOAUTH2},
    {"anonymous", MailTransport::Transport::EnumAuthenticationType::ANONYMOUS}};
static const int authenticationTypeEnumSize = sizeof(authenticationTypeEnum) / sizeof(*authenticationTypeEnum);

template<typename T>
static typename T::value_type stringToValue(const T *table, const int tableSize, const QString &string, bool &valid)
{
    const QString ref = string.toLower();
    for (int i = 0; i < tableSize; ++i) {
        if (ref == QLatin1String(table[i].name)) {
            valid = true;
            return table[i].value;
        }
    }
    valid = false;
    return table[0].value; // TODO: error handling
}

Transport::Transport(const QString &type, QObject *parent)
    : SetupObject(parent)
    , m_encr(MailTransport::Transport::EnumEncryption::TLS)
    , m_auth(MailTransport::Transport::EnumAuthenticationType::PLAIN)
{
    if (type == QLatin1String("smtp")) {
        m_port = 25;
    }
}

void Transport::create()
{
    Q_EMIT info(i18n("Setting up mail transport account..."));
    MailTransport::Transport *mt = MailTransport::TransportManager::self()->createTransport();
    mt->setName(m_name);
    mt->setHost(m_host);
    if (m_port > 0) {
        mt->setPort(m_port);
    }
    if (!m_user.isEmpty()) {
        mt->setUserName(m_user);
        mt->setRequiresAuthentication(true);
    }
    if (!m_password.isEmpty()) {
        mt->setStorePassword(true);
        mt->setPassword(m_password);
    }
    mt->setEncryption(m_encr);
    mt->setAuthenticationType(m_auth);
    m_transportId = mt->id();
    mt->save();
    Q_EMIT info(i18n("Mail transport uses '%1' encryption and '%2' authentication.", m_encrStr, m_authStr));
    MailTransport::TransportManager::self()->addTransport(mt);
    MailTransport::TransportManager::self()->setDefaultTransport(mt->id());
    if (m_editMode) {
        edit();
    }
    Q_EMIT finished(i18n("Mail transport account set up."));
}

void Transport::destroy()
{
    MailTransport::TransportManager::self()->removeTransport(m_transportId);
    Q_EMIT info(i18n("Mail transport account deleted."));
}

void Transport::edit()
{
    MailTransport::Transport *mt = MailTransport::TransportManager::self()->transportById(m_transportId, false);
    if (!mt) {
        Q_EMIT error(i18n("Could not load config dialog for UID '%1'", m_transportId));
    } else {
        MailTransport::TransportManager::self()->configureTransport(mt->identifier(), mt, nullptr);
    }
}

void Transport::setEditMode(const bool editMode)
{
    m_editMode = editMode;
}

void Transport::setName(const QString &name)
{
    m_name = name;
}

void Transport::setHost(const QString &host)
{
    m_host = host;
}

void Transport::setPort(int port)
{
    m_port = port;
}

void Transport::setUsername(const QString &user)
{
    m_user = user;
}

void Transport::setPassword(const QString &password)
{
    m_password = password;
}

void Transport::setEncryption(const QString &encryption)
{
    bool valid;
    m_encr = stringToValue(encryptionEnum, encryptionEnumSize, encryption, valid);
    if (valid) {
        m_encrStr = encryption;
    }
}

void Transport::setAuthenticationType(const QString &authType)
{
    bool valid;
    m_auth = stringToValue(authenticationTypeEnum, authenticationTypeEnumSize, authType, valid);
    if (valid) {
        m_authStr = authType;
    }
}

int Transport::transportId() const
{
    return m_transportId;
}
