// SPDX-FileCopyrightText: 2022 Devin Lin <devin@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>

#include <MailTransport/Transport>

#include "ispdb/ispdb.h"
#include "setup/setupmanager.h"

/**
 * Object that is created in QML to facilitate the creation of a new email account.
 */

class NewAccount : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(bool ispdbIsSearching READ ispdbIsSearching NOTIFY ispdbIsSearchingChanged)

    // email server form
    Q_PROPERTY(ReceivingMailProtocol receivingMailProtocol READ receivingMailProtocol WRITE setReceivingMailProtocol NOTIFY receivingMailProtocolChanged)

    // imap
    Q_PROPERTY(QString imapHost READ imapHost WRITE setImapHost NOTIFY imapHostChanged)
    Q_PROPERTY(int imapPort READ imapPort WRITE setImapPort NOTIFY imapPortChanged)
    Q_PROPERTY(QString imapUsername READ imapUsername WRITE setImapUsername NOTIFY imapUsernameChanged)
    Q_PROPERTY(QString imapPassword READ imapPassword WRITE setImapPassword NOTIFY imapPasswordChanged)
    Q_PROPERTY(AuthenticationType imapAuthenticationType READ imapAuthenticationType WRITE setImapAuthenticationType NOTIFY imapAuthenticationTypeChanged)
    Q_PROPERTY(SocketType imapSocketType READ imapSocketType WRITE setImapSocketType NOTIFY imapSocketTypeChanged)

    // pop3
    Q_PROPERTY(QString pop3Host READ pop3Host WRITE setPop3Host NOTIFY pop3HostChanged)
    Q_PROPERTY(int pop3Port READ pop3Port WRITE setPop3Port NOTIFY pop3PortChanged)
    Q_PROPERTY(QString pop3Username READ pop3Username WRITE setPop3Username NOTIFY pop3UsernameChanged)
    Q_PROPERTY(QString pop3Password READ pop3Password WRITE setPop3Password NOTIFY pop3PasswordChanged)
    Q_PROPERTY(AuthenticationType pop3AuthenticationType READ pop3AuthenticationType WRITE setPop3AuthenticationType NOTIFY pop3AuthenticationTypeChanged)
    Q_PROPERTY(SocketType pop3SocketType READ pop3SocketType WRITE setPop3SocketType NOTIFY pop3SocketTypeChanged)

    // smtp
    Q_PROPERTY(QString smtpHost READ smtpHost WRITE setSmtpHost NOTIFY smtpHostChanged)
    Q_PROPERTY(int smtpPort READ smtpPort WRITE setSmtpPort NOTIFY smtpPortChanged)
    Q_PROPERTY(QString smtpUsername READ smtpUsername WRITE setSmtpUsername NOTIFY smtpUsernameChanged)
    Q_PROPERTY(QString smtpPassword READ smtpPassword WRITE setSmtpPassword NOTIFY smtpPasswordChanged)
    Q_PROPERTY(AuthenticationType smtpAuthenticationType READ smtpAuthenticationType WRITE setSmtpAuthenticationType NOTIFY smtpAuthenticationTypeChanged)
    Q_PROPERTY(SocketType smtpSocketType READ smtpSocketType WRITE setSmtpSocketType NOTIFY smtpSocketTypeChanged)

public:
    NewAccount(QObject *parent = nullptr);
    virtual ~NewAccount() noexcept;

    enum ReceivingMailProtocol { Pop3, Imap };
    Q_ENUM(ReceivingMailProtocol)

    enum SocketType { SSL, StartTLS, None };
    Q_ENUM(SocketType)

    enum AuthenticationType { Plain, CramMD5, NTLM, GSSAPI, OAuth2, NoAuth };
    Q_ENUM(AuthenticationType)

    QString &email();
    void setEmail(const QString &email);

    QString &name();
    void setName(const QString &name);

    QString &password();
    void setPassword(const QString &password);

    bool ispdbIsSearching();

    ReceivingMailProtocol receivingMailProtocol();
    void setReceivingMailProtocol(ReceivingMailProtocol receivingMailProtocol);

    // imap form
    QString &imapHost();
    void setImapHost(QString host);

    int imapPort();
    void setImapPort(int port);

    QString &imapUsername();
    void setImapUsername(QString username);

    QString &imapPassword();
    void setImapPassword(QString password);

    AuthenticationType imapAuthenticationType();
    void setImapAuthenticationType(AuthenticationType authenticationType);

    SocketType imapSocketType();
    void setImapSocketType(SocketType socketType);

    // pop3 form
    QString &pop3Host();
    void setPop3Host(QString host);

    int pop3Port();
    void setPop3Port(int port);

    QString &pop3Username();
    void setPop3Username(QString username);

    QString &pop3Password();
    void setPop3Password(QString password);

    AuthenticationType pop3AuthenticationType();
    void setPop3AuthenticationType(AuthenticationType authenticationType);

    SocketType pop3SocketType();
    void setPop3SocketType(SocketType pop3SocketType);

    // smtp form
    QString &smtpHost();
    void setSmtpHost(QString host);

    int smtpPort();
    void setSmtpPort(int port);

    QString &smtpUsername();
    void setSmtpUsername(QString username);

    QString &smtpPassword();
    void setSmtpPassword(QString password);

    AuthenticationType smtpAuthenticationType();
    void setSmtpAuthenticationType(AuthenticationType authenticationType);

    SocketType smtpSocketType();
    void setSmtpSocketType(SocketType socketType);

    // search online (mozilla db) for SMTP/IMAP/POP3 settings for the given email
    Q_INVOKABLE void searchIspdbForConfig();

    // add account with the current settings
    Q_INVOKABLE void addAccount();

    void configureImap(QString host, int port, QString username, QString password, AuthenticationType authentication, SocketType socket);
    void configurePop3(QString host, int port, QString username, QString password, AuthenticationType authentication, SocketType socket);
    void configureSmtp(QString host, int port, QString username, QString password, AuthenticationType authentication, SocketType socket);

public Q_SLOTS:
    void ispdbFinishedSearchingSlot();

Q_SIGNALS:
    void emailChanged();
    void nameChanged();
    void passwordChanged();
    void ispdbIsSearchingChanged();
    void receivingMailProtocolChanged();

    void imapHostChanged();
    void imapPortChanged();
    void imapUsernameChanged();
    void imapPasswordChanged();
    void imapAuthenticationTypeChanged();
    void imapSocketTypeChanged();
    void pop3HostChanged();
    void pop3PortChanged();
    void pop3UsernameChanged();
    void pop3PasswordChanged();
    void pop3AuthenticationTypeChanged();
    void pop3SocketTypeChanged();
    void smtpHostChanged();
    void smtpPortChanged();
    void smtpUsernameChanged();
    void smtpPasswordChanged();
    void smtpAuthenticationTypeChanged();
    void smtpSocketTypeChanged();

    void setupSucceeded(const QString &msg);
    void setupFailed(const QString &msg);
    void setupInfo(const QString &msg);

private:
    AuthenticationType ispdbTypeToAuth(Ispdb::authType authType);
    SocketType ispdbTypeToSocket(Ispdb::socketType socketType);

    QString m_email;
    QString m_name;
    QString m_password;

    bool m_ispdbIsSearching;
    Ispdb *m_ispdb;

    SetupManager *m_setupManager;

    ReceivingMailProtocol m_receivingMailProtocol;

    QString m_imapHost;
    int m_imapPort;
    QString m_imapUsername;
    QString m_imapPassword;
    AuthenticationType m_imapAuthenticationType;
    SocketType m_imapSocketType;

    QString m_pop3Host;
    int m_pop3Port;
    QString m_pop3Username;
    QString m_pop3Password;
    AuthenticationType m_pop3AuthenticationType;
    SocketType m_pop3SocketType;

    QString m_smtpHost;
    int m_smtpPort;
    QString m_smtpUsername;
    QString m_smtpPassword;
    AuthenticationType m_smtpAuthenticationType;
    SocketType m_smtpSocketType;
};
