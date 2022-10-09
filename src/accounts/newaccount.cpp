// SPDX-FileCopyrightText: 2009 Volker Krause <vkrause@kde.org>
// SPDX-FileCopyrightText: 2010 Tom Albers <toma@kde.org>
// SPDX-FileCopyrightText: 2012-2022 Laurent Montel <montel@kde.org>
// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "newaccount.h"

#include "setup/resource.h"
#include "setup/transport.h"

NewAccount::NewAccount(QObject *parent)
    : QObject(parent)
    , m_ispdb{nullptr}
    , m_setupManager{new SetupManager{this}}
    , m_receivingMailProtocol{ReceivingMailProtocol::Imap}
    , m_imapPort{993}
    , m_imapAuthenticationType{AuthenticationType::Plain}
    , m_pop3Port{995}
    , m_pop3AuthenticationType{AuthenticationType::Plain}
    , m_smtpPort{587}
    , m_smtpAuthenticationType{AuthenticationType::Plain}
{
    connect(m_setupManager, &SetupManager::setupSucceeded, this, [this](const QString &msg) {
        Q_EMIT setupSucceeded(msg);
    });
    connect(m_setupManager, &SetupManager::setupFailed, this, [this](const QString &msg) {
        Q_EMIT setupFailed(msg);
    });
    connect(m_setupManager, &SetupManager::setupInfo, this, [this](const QString &msg) {
        Q_EMIT setupInfo(msg);
    });
}

NewAccount::~NewAccount() noexcept
{
}

QString &NewAccount::email()
{
    return m_email;
}

void NewAccount::setEmail(const QString &email)
{
    if (m_email != email) {
        m_email = email;
        Q_EMIT emailChanged();
    }
}

QString &NewAccount::name()
{
    return m_name;
}

void NewAccount::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        Q_EMIT nameChanged();
    }
}

QString &NewAccount::password()
{
    return m_password;
}

void NewAccount::setPassword(const QString &password)
{
    if (m_password != password) {
        m_password = password;
        Q_EMIT passwordChanged();
    }
}

bool NewAccount::ispdbIsSearching()
{
    return m_ispdbIsSearching;
}

NewAccount::ReceivingMailProtocol NewAccount::receivingMailProtocol()
{
    return m_receivingMailProtocol;
}

void NewAccount::setReceivingMailProtocol(NewAccount::ReceivingMailProtocol receivingMailProtocol)
{
    if (m_receivingMailProtocol != receivingMailProtocol) {
        m_receivingMailProtocol = receivingMailProtocol;
        Q_EMIT receivingMailProtocolChanged();
    }
}

QString &NewAccount::imapHost()
{
    return m_imapHost;
}

void NewAccount::setImapHost(QString host)
{
    if (m_imapHost != host) {
        m_imapHost = host;
        Q_EMIT imapHostChanged();
    }
}

int NewAccount::imapPort()
{
    return m_imapPort;
}

void NewAccount::setImapPort(int port)
{
    if (m_imapPort != port) {
        m_imapPort = port;
        Q_EMIT imapPortChanged();
    }
}

QString &NewAccount::imapUsername()
{
    return m_imapUsername;
}

void NewAccount::setImapUsername(QString username)
{
    if (m_imapUsername != username) {
        m_imapUsername = username;
        Q_EMIT imapUsernameChanged();
    }
}

QString &NewAccount::imapPassword()
{
    return m_imapPassword;
}

void NewAccount::setImapPassword(QString password)
{
    if (m_imapPassword != password) {
        m_imapPassword = password;
        Q_EMIT imapPasswordChanged();
    }
}

NewAccount::AuthenticationType NewAccount::imapAuthenticationType()
{
    return m_imapAuthenticationType;
}

void NewAccount::setImapAuthenticationType(AuthenticationType authenticationType)
{
    if (m_imapAuthenticationType != authenticationType) {
        m_imapAuthenticationType = authenticationType;
        Q_EMIT imapAuthenticationTypeChanged();
    }
}

NewAccount::SocketType NewAccount::imapSocketType()
{
    return m_imapSocketType;
}

void NewAccount::setImapSocketType(SocketType socketType)
{
    if (m_imapSocketType != socketType) {
        m_imapSocketType = socketType;
        Q_EMIT imapSocketTypeChanged();
    }
}

QString &NewAccount::pop3Host()
{
    return m_pop3Host;
}

void NewAccount::setPop3Host(QString host)
{
    if (m_pop3Host != host) {
        m_pop3Host = host;
        Q_EMIT pop3HostChanged();
    }
}

int NewAccount::pop3Port()
{
    return m_pop3Port;
}

void NewAccount::setPop3Port(int port)
{
    if (m_pop3Port != port) {
        m_pop3Port = port;
        Q_EMIT pop3PortChanged();
    }
}

QString &NewAccount::pop3Username()
{
    return m_pop3Username;
}

void NewAccount::setPop3Username(QString username)
{
    if (m_pop3Username != username) {
        m_pop3Username = username;
        Q_EMIT pop3UsernameChanged();
    }
}

QString &NewAccount::pop3Password()
{
    return m_pop3Password;
}

void NewAccount::setPop3Password(QString password)
{
    if (m_pop3Password != password) {
        m_pop3Password = password;
        Q_EMIT pop3PasswordChanged();
    }
}

NewAccount::AuthenticationType NewAccount::pop3AuthenticationType()
{
    return m_pop3AuthenticationType;
}

void NewAccount::setPop3AuthenticationType(AuthenticationType authenticationType)
{
    if (m_pop3AuthenticationType != authenticationType) {
        m_pop3AuthenticationType = authenticationType;
        Q_EMIT pop3AuthenticationTypeChanged();
    }
}

NewAccount::SocketType NewAccount::pop3SocketType()
{
    return m_pop3SocketType;
}

void NewAccount::setPop3SocketType(SocketType socketType)
{
    if (m_pop3SocketType != socketType) {
        m_pop3SocketType = socketType;
        Q_EMIT pop3SocketTypeChanged();
    }
}

QString &NewAccount::smtpHost()
{
    return m_smtpHost;
}

void NewAccount::setSmtpHost(QString host)
{
    if (m_smtpHost != host) {
        m_smtpHost = host;
        Q_EMIT smtpHostChanged();
    }
}

int NewAccount::smtpPort()
{
    return m_smtpPort;
}

void NewAccount::setSmtpPort(int port)
{
    if (m_smtpPort != port) {
        m_smtpPort = port;
        Q_EMIT smtpPortChanged();
    }
}

QString &NewAccount::smtpUsername()
{
    return m_smtpUsername;
}

void NewAccount::setSmtpUsername(QString username)
{
    if (m_smtpUsername != username) {
        m_smtpUsername = username;
        Q_EMIT smtpUsernameChanged();
    }
}

QString &NewAccount::smtpPassword()
{
    return m_smtpPassword;
}

void NewAccount::setSmtpPassword(QString password)
{
    if (m_smtpPassword != password) {
        m_smtpPassword = password;
        Q_EMIT smtpPasswordChanged();
    }
}

NewAccount::AuthenticationType NewAccount::smtpAuthenticationType()
{
    return m_smtpAuthenticationType;
}

void NewAccount::setSmtpAuthenticationType(AuthenticationType authenticationType)
{
    if (m_smtpAuthenticationType != authenticationType) {
        m_smtpAuthenticationType = authenticationType;
        Q_EMIT smtpAuthenticationTypeChanged();
    }
}

NewAccount::SocketType NewAccount::smtpSocketType()
{
    return m_smtpSocketType;
}

void NewAccount::setSmtpSocketType(SocketType socketType)
{
    if (m_smtpSocketType != socketType) {
        m_smtpSocketType = socketType;
        Q_EMIT smtpSocketTypeChanged();
    }
}

void NewAccount::searchIspdbForConfig()
{
    delete m_ispdb;
    m_ispdb = new Ispdb(this);

    m_ispdb->setEmail(m_email);
    m_ispdb->start();

    connect(m_ispdb, &Ispdb::finished, this, &NewAccount::ispdbFinishedSearchingSlot);

    m_ispdbIsSearching = true;
    Q_EMIT ispdbIsSearchingChanged();
}

void NewAccount::addAccount()
{
    if (m_receivingMailProtocol == ReceivingMailProtocol::Imap) {
        configureImap(m_imapHost, m_imapPort, m_imapUsername, m_imapPassword, m_imapAuthenticationType, m_imapSocketType);
    } else if (m_receivingMailProtocol == ReceivingMailProtocol::Pop3) {
        configurePop3(m_pop3Host, m_pop3Port, m_pop3Username, m_pop3Password, m_pop3AuthenticationType, m_pop3SocketType);
    }

    configureSmtp(m_smtpHost, m_smtpPort, m_smtpUsername, m_smtpPassword, m_smtpAuthenticationType, m_smtpSocketType);

    m_setupManager->execute();
}

void NewAccount::configureImap(QString host, int port, QString username, QString password, AuthenticationType authentication, SocketType socket)
{
    QObject *object = m_setupManager->createResource(QStringLiteral("akonadi_imap_resource"));
    auto *t = qobject_cast<Resource *>(object);

    t->setName(username);
    t->setOption(QStringLiteral("ImapServer"), host);
    t->setOption(QStringLiteral("ImapPort"), port);
    t->setOption(QStringLiteral("UserName"), username);
    t->setOption(QStringLiteral("Password"), password);

    switch (authentication) {
    case AuthenticationType::Plain:
        t->setOption(QStringLiteral("Authentication"), MailTransport::Transport::EnumAuthenticationType::CLEAR);
        break;
    case AuthenticationType::CramMD5:
        t->setOption(QStringLiteral("Authentication"), MailTransport::Transport::EnumAuthenticationType::CRAM_MD5);
        break;
    case AuthenticationType::NTLM:
        t->setOption(QStringLiteral("Authentication"), MailTransport::Transport::EnumAuthenticationType::NTLM);
        break;
    case AuthenticationType::GSSAPI:
        t->setOption(QStringLiteral("Authentication"), MailTransport::Transport::EnumAuthenticationType::GSSAPI);
        break;
    case AuthenticationType::OAuth2:
        t->setOption(QStringLiteral("Authentication"), MailTransport::Transport::EnumAuthenticationType::XOAUTH2);
        break;
    case AuthenticationType::NoAuth:
        break;
    default:
        break;
    }

    switch (socket) {
    case SocketType::None:
        t->setOption(QStringLiteral("Safety"), QStringLiteral("None"));
        break;
    case SocketType::SSL:
        t->setOption(QStringLiteral("Safety"), QStringLiteral("SSL"));
        break;
    case SocketType::StartTLS:
        t->setOption(QStringLiteral("Safety"), QStringLiteral("STARTTLS"));
        break;
    default:
        break;
    }
}

void NewAccount::configurePop3(QString host, int port, QString username, QString password, AuthenticationType authentication, SocketType socket)
{
    QObject *object = m_setupManager->createResource(QStringLiteral("akonadi_pop3_resource"));
    auto *t = qobject_cast<Resource *>(object);

    t->setName(username);
    t->setOption(QStringLiteral("Host"), host);
    t->setOption(QStringLiteral("Port"), port);
    t->setOption(QStringLiteral("Login"), username);
    t->setOption(QStringLiteral("Password"), password);

    switch (authentication) {
    case AuthenticationType::Plain:
        t->setOption(QStringLiteral("AuthenticationMethod"), MailTransport::Transport::EnumAuthenticationType::PLAIN);
        break;
    case AuthenticationType::CramMD5:
        t->setOption(QStringLiteral("AuthenticationMethod"), MailTransport::Transport::EnumAuthenticationType::CRAM_MD5);
        break;
    case AuthenticationType::NTLM:
        t->setOption(QStringLiteral("AuthenticationMethod"), MailTransport::Transport::EnumAuthenticationType::NTLM);
        break;
    case AuthenticationType::GSSAPI:
        t->setOption(QStringLiteral("AuthenticationMethod"), MailTransport::Transport::EnumAuthenticationType::GSSAPI);
        break;
    case AuthenticationType::NoAuth:
    default:
        t->setOption(QStringLiteral("AuthenticationMethod"), MailTransport::Transport::EnumAuthenticationType::CLEAR);
        break;
    }

    switch (socket) {
    case SocketType::SSL:
        t->setOption(QStringLiteral("UseSSL"), 1);
        break;
    case SocketType::StartTLS:
        t->setOption(QStringLiteral("UseTLS"), 1);
        break;
    case SocketType::None:
    default:
        t->setOption(QStringLiteral("UseTLS"), 1); // TODO is this correct?
        break;
    }
}

void NewAccount::configureSmtp(QString host, int port, QString username, QString password, AuthenticationType authentication, SocketType socket)
{
    QObject *object = m_setupManager->createTransport(QStringLiteral("smtp"));
    auto *t = qobject_cast<Transport *>(object);

    t->setName(username);
    t->setHost(host);
    t->setPort(port);
    t->setUsername(username);
    t->setPassword(password);

    switch (authentication) {
    case AuthenticationType::Plain:
        t->setAuthenticationType(QStringLiteral("plain"));
        break;
    case AuthenticationType::CramMD5:
        t->setAuthenticationType(QStringLiteral("cram-md5"));
        break;
    case AuthenticationType::NTLM:
        t->setAuthenticationType(QStringLiteral("ntlm"));
        break;
    case AuthenticationType::GSSAPI:
        t->setAuthenticationType(QStringLiteral("gssapi"));
        break;
    case AuthenticationType::OAuth2:
        t->setAuthenticationType(QStringLiteral("oauth2"));
        break;
    case AuthenticationType::NoAuth:
        break;
    default:
        break;
    }

    switch (socket) {
    case SocketType::None:
        t->setEncryption(QStringLiteral("none"));
        break;
    case SocketType::SSL:
        t->setEncryption(QStringLiteral("ssl"));
        break;
    case SocketType::StartTLS:
        t->setEncryption(QStringLiteral("tls"));
        break;
    default:
        break;
    }
}

void NewAccount::ispdbFinishedSearchingSlot()
{
    if (!m_ispdb) {
        return;
    }

    m_ispdbIsSearching = false;
    Q_EMIT ispdbIsSearchingChanged();

    // add smtp settings
    if (!m_ispdb->smtpServers().isEmpty()) {
        const Server s = m_ispdb->smtpServers().at(0);
        setSmtpHost(s.hostname);
        setSmtpPort(s.port);
        setSmtpUsername(s.username);
        setSmtpPassword(m_password);
        setSmtpAuthenticationType(ispdbTypeToAuth(s.authentication));
        setSmtpSocketType(ispdbTypeToSocket(s.socketType));
    }

    // add imap settings
    if (!m_ispdb->imapServers().isEmpty()) {
        const Server s = m_ispdb->imapServers().at(0);
        setImapHost(s.hostname);
        setImapPort(s.port);
        setImapUsername(s.username);
        setImapPassword(m_password);
        setImapAuthenticationType(ispdbTypeToAuth(s.authentication));
        setImapSocketType(ispdbTypeToSocket(s.socketType));
    }

    // add pop3 settings
    if (!m_ispdb->pop3Servers().isEmpty()) {
        const Server s = m_ispdb->pop3Servers().at(0);
        setPop3Host(s.hostname);
        setPop3Port(s.port);
        setPop3Username(s.username);
        setPop3Password(m_password);
        setPop3AuthenticationType(ispdbTypeToAuth(s.authentication));
        setPop3SocketType(ispdbTypeToSocket(s.socketType));
    }
}

NewAccount::AuthenticationType NewAccount::ispdbTypeToAuth(Ispdb::authType authType)
{
    switch (authType) {
    case Ispdb::Plain:
        return AuthenticationType::Plain;
    case Ispdb::CramMD5:
        return AuthenticationType::CramMD5;
    case Ispdb::NTLM:
        return AuthenticationType::NTLM;
    case Ispdb::GSSAPI:
        return AuthenticationType::GSSAPI;
    case Ispdb::OAuth2:
        return AuthenticationType::OAuth2;
    case Ispdb::ClientIP:
    case Ispdb::NoAuth:
    default:
        return AuthenticationType::NoAuth;
    }
}

NewAccount::SocketType NewAccount::ispdbTypeToSocket(Ispdb::socketType socketType)
{
    switch (socketType) {
    case Ispdb::SSL:
        return SocketType::SSL;
    case Ispdb::StartTLS:
        return SocketType::StartTLS;
    case Ispdb::None:
    default:
        return SocketType::None;
    }
}
