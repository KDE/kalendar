/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"
#include <KLDAP/LdapServer>

class LdapTest;
class KConfig;

namespace KLDAP
{
class LdapClientSearchConfig;
}

class Ldap : public SetupObject
{
    Q_OBJECT
public:
    explicit Ldap(QObject *parent = nullptr);
    ~Ldap() override;
    void create() override;
    void destroy() override;
    void edit();
public Q_SLOTS:
    Q_SCRIPTABLE void setUser(const QString &name);
    Q_SCRIPTABLE void setServer(const QString &server);
    Q_SCRIPTABLE void setAuthenticationMethod(const QString &meth);
    Q_SCRIPTABLE void setBindDn(const QString &bindDn);
    Q_SCRIPTABLE void setBaseDn(const QString &baseDn);
    Q_SCRIPTABLE void setPassword(const QString &password);
    Q_SCRIPTABLE void setPort(const int port);
    Q_SCRIPTABLE void setSecurity(const KLDAP::LdapServer::Security security);
    Q_SCRIPTABLE void setSaslMech(const QString &saslmech);
    Q_SCRIPTABLE void setRealm(const QString &realm);
    Q_SCRIPTABLE void setVersion(const int version);
    Q_SCRIPTABLE void setPageSize(const int pageSize);
    Q_SCRIPTABLE void setTimeLimit(const int timeLimit);
    Q_SCRIPTABLE void setSizeLimit(const int sizeLimit);
    Q_SCRIPTABLE void setEditMode(const bool editMode);

protected:
    virtual KConfig *config() const;

    KLDAP::LdapClientSearchConfig *const m_clientSearchConfig;

private:
    friend class LdapTest;
    void slotRestoreDone();
    QString securityString();

    QString m_user;
    QString m_server;
    QString m_bindDn;
    QString m_authMethod;
    QString m_password;
    QString m_mech;
    QString m_realm;
    QString m_baseDn;
    int m_port = 389;
    KLDAP::LdapServer::Security m_security = KLDAP::LdapServer::None;
    int m_version = 3;
    int m_pageSize = 0;
    int m_timeLimit = 0;
    int m_sizeLimit = 0;
    int m_entry = -1;
    bool m_editMode = false;
};
