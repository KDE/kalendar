/*
    SPDX-FileCopyrightText: 2009 Volker Krause <vkrause@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"
#include <MailTransport/Transport>

class Transport : public SetupObject
{
    Q_OBJECT
public:
    explicit Transport(const QString &type, QObject *parent = nullptr);
    void create() override;
    void destroy() override;
    void edit();

    int transportId() const;

public Q_SLOTS:
    Q_SCRIPTABLE void setName(const QString &name);
    Q_SCRIPTABLE void setHost(const QString &host);
    Q_SCRIPTABLE void setPort(int port);
    Q_SCRIPTABLE void setUsername(const QString &user);
    Q_SCRIPTABLE void setPassword(const QString &password);
    Q_SCRIPTABLE void setEncryption(const QString &encryption);
    Q_SCRIPTABLE void setAuthenticationType(const QString &authType);
    Q_SCRIPTABLE void setEditMode(const bool editMode);

private:
    int m_transportId = -1;
    QString m_name;
    QString m_host;
    int m_port = -1;
    QString m_user;
    QString m_password;
    MailTransport::Transport::EnumEncryption::type m_encr;
    MailTransport::Transport::EnumAuthenticationType::type m_auth;
    QString m_encrStr;
    QString m_authStr;

    bool m_editMode = false;
};
