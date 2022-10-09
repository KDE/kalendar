/*
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "setupispdb.h"
#include "configfile.h"
#include "identity.h"
#include "ispdb/ispdb.h"
#include "ldap.h"
#include "resource.h"
#include "transport.h"

#include <KLocalizedString>

SetupIspdb::SetupIspdb(QObject *parent)
    : SetupObject(parent)
    , mIspdb(new Ispdb(this))
{
    connect(mIspdb, &Ispdb::finished, this, &SetupIspdb::onIspdbFinished);
}

SetupIspdb::~SetupIspdb()
{
    delete mIspdb;
}

QStringList SetupIspdb::relevantDomains() const
{
    return mIspdb->relevantDomains();
}

QString SetupIspdb::name(int l) const
{
    return mIspdb->name(static_cast<Ispdb::length>(l));
}

int SetupIspdb::defaultIdentity() const
{
    return mIspdb->defaultIdentity();
}

int SetupIspdb::countIdentities() const
{
    return mIspdb->identities().count();
}

void SetupIspdb::fillIdentity(int i, QObject *o) const
{
    identity isp = mIspdb->identities().at(i);

    auto *id = qobject_cast<Identity *>(o);

    id->setIdentityName(isp.name);
    id->setRealName(isp.name);
    id->setEmail(isp.email);
    id->setOrganization(isp.organization);
    id->setSignature(isp.signature);
}

void SetupIspdb::fillImapServer(int i, QObject *o) const
{
    if (mIspdb->imapServers().isEmpty()) {
        return;
    }
    Server isp = mIspdb->imapServers().at(i);
    auto *imapRes = qobject_cast<Resource *>(o);

    imapRes->setName(isp.hostname);
    imapRes->setOption(QStringLiteral("ImapServer"), isp.hostname);
    imapRes->setOption(QStringLiteral("UserName"), isp.username);
    imapRes->setOption(QStringLiteral("ImapPort"), isp.port);
    imapRes->setOption(QStringLiteral("Authentication"), isp.authentication); // TODO: setup with right authentication
    if (isp.socketType == Ispdb::None) {
        imapRes->setOption(QStringLiteral("Safety"), QStringLiteral("NONE"));
    } else if (isp.socketType == Ispdb::SSL) {
        imapRes->setOption(QStringLiteral("Safety"), QStringLiteral("SSL"));
    } else {
        imapRes->setOption(QStringLiteral("Safety"), QStringLiteral("STARTTLS"));
    }
}

int SetupIspdb::countImapServers() const
{
    return mIspdb->imapServers().count();
}

void SetupIspdb::fillSmtpServer(int i, QObject *o) const
{
    Server isp = mIspdb->smtpServers().at(i);
    auto *smtpRes = qobject_cast<Transport *>(o);

    smtpRes->setName(isp.hostname);
    smtpRes->setHost(isp.hostname);
    smtpRes->setPort(isp.port);
    smtpRes->setUsername(isp.username);

    switch (isp.authentication) {
    case Ispdb::Plain:
        smtpRes->setAuthenticationType(QStringLiteral("plain"));
        break;
    case Ispdb::CramMD5:
        smtpRes->setAuthenticationType(QStringLiteral("cram-md5"));
        break;
    case Ispdb::NTLM:
        smtpRes->setAuthenticationType(QStringLiteral("ntlm"));
        break;
    case Ispdb::GSSAPI:
        smtpRes->setAuthenticationType(QStringLiteral("gssapi"));
        break;
    case Ispdb::ClientIP:
    case Ispdb::NoAuth:
    default:
        break;
    }
    switch (isp.socketType) {
    case Ispdb::None:
        smtpRes->setEncryption(QStringLiteral("none"));
        break;
    case Ispdb::SSL:
        smtpRes->setEncryption(QStringLiteral("ssl"));
        break;
    case Ispdb::StartTLS:
        smtpRes->setEncryption(QStringLiteral("tls"));
        break;
    }
}

int SetupIspdb::countSmtpServers() const
{
    return mIspdb->smtpServers().count();
}

void SetupIspdb::start()
{
    mIspdb->start();
    Q_EMIT info(i18n("Searching for autoconfiguration..."));
}

void SetupIspdb::setEmail(const QString &email)
{
    mIspdb->setEmail(email);
}

void SetupIspdb::setPassword(const QString &password)
{
    mIspdb->setPassword(password);
}

void SetupIspdb::create()
{
}

void SetupIspdb::destroy()
{
}

void SetupIspdb::onIspdbFinished(bool status)
{
    Q_EMIT ispdbFinished(status);
    if (status) {
        Q_EMIT info(i18n("Autoconfiguration found."));
    } else {
        Q_EMIT info(i18n("Autoconfiguration failed."));
    }
}
