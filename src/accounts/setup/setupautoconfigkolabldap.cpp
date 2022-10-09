/*
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "setupautoconfigkolabldap.h"
#include "configfile.h"
#include "ispdb/autoconfigkolabldap.h"
#include "ldap.h"

#include <KLocalizedString>

SetupAutoconfigKolabLdap::SetupAutoconfigKolabLdap(QObject *parent)
    : SetupObject(parent)
    , mIspdb(new AutoconfigKolabLdap(this))
{
    connect(mIspdb, &AutoconfigKolabLdap::finished, this, &SetupAutoconfigKolabLdap::onIspdbFinished);
}

SetupAutoconfigKolabLdap::~SetupAutoconfigKolabLdap()
{
    delete mIspdb;
}

void SetupAutoconfigKolabLdap::fillLdapServer(int i, QObject *o) const
{
    const ldapServer isp = mIspdb->ldapServers().values().at(i);
    Ldap *ldapRes = qobject_cast<Ldap *>(o);

    // TODO: setting filter

    ldapRes->setServer(isp.hostname);
    ldapRes->setPort(isp.port);
    ldapRes->setBaseDn(isp.dn);
    ldapRes->setSecurity(isp.socketType);
    ldapRes->setVersion(isp.ldapVersion);
    ldapRes->setUser(isp.username);
    ldapRes->setPassword(isp.password);
    ldapRes->setBindDn(isp.bindDn);

    ldapRes->setRealm(isp.realm);
    ldapRes->setSaslMech(isp.saslMech);

    if (isp.pageSize != -1) {
        ldapRes->setPageSize(isp.pageSize);
    }

    if (isp.timeLimit != -1) {
        ldapRes->setPageSize(isp.timeLimit);
    }

    if (isp.sizeLimit != -1) {
        ldapRes->setPageSize(isp.sizeLimit);
    }

    // Anonymous is set by not setting the AuthenticationMethod
    if (isp.authentication == KLDAP::LdapServer::SASL) {
        ldapRes->setAuthenticationMethod(QStringLiteral("SASL"));
    } else if (isp.authentication == KLDAP::LdapServer::Simple) {
        ldapRes->setAuthenticationMethod(QStringLiteral("Simple"));
    }
}

int SetupAutoconfigKolabLdap::countLdapServers() const
{
    return mIspdb->ldapServers().count();
}

void SetupAutoconfigKolabLdap::start()
{
    mIspdb->start();
    Q_EMIT info(i18n("Searching for autoconfiguration..."));
}

void SetupAutoconfigKolabLdap::setEmail(const QString &email)
{
    mIspdb->setEmail(email);
}

void SetupAutoconfigKolabLdap::setPassword(const QString &password)
{
    mIspdb->setPassword(password);
}

void SetupAutoconfigKolabLdap::create()
{
}

void SetupAutoconfigKolabLdap::destroy()
{
}

void SetupAutoconfigKolabLdap::onIspdbFinished(bool status)
{
    Q_EMIT ispdbFinished(status);
    if (status) {
        Q_EMIT info(i18n("Autoconfiguration found."));
    } else {
        Q_EMIT info(i18n("Autoconfiguration failed."));
    }
}
