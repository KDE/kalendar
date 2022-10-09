/*
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "setupautoconfigkolabfreebusy.h"
#include "ispdb/autoconfigkolabfreebusy.h"

#include "configfile.h"

#include <QFileInfo>

#include <KLocalizedString>

SetupAutoconfigKolabFreebusy::SetupAutoconfigKolabFreebusy(QObject *parent)
    : SetupObject(parent)
    , mIspdb(new AutoconfigKolabFreebusy(this))
{
    connect(mIspdb, &AutoconfigKolabFreebusy::finished, this, &SetupAutoconfigKolabFreebusy::onIspdbFinished);
}

SetupAutoconfigKolabFreebusy::~SetupAutoconfigKolabFreebusy()
{
    delete mIspdb;
}

int SetupAutoconfigKolabFreebusy::countFreebusyServers() const
{
    return mIspdb->freebusyServers().count();
}

void SetupAutoconfigKolabFreebusy::fillFreebusyServer(int i, QObject *o) const
{
    const freebusy isp = mIspdb->freebusyServers().values().at(i);
    auto *korganizer = qobject_cast<ConfigFile *>(o);
    QFileInfo path(isp.path);
    QString url(QStringLiteral("https://"));

    if (isp.socketType == Ispdb::None) {
        url = QStringLiteral("http://");
    }

    url += isp.hostname;

    if (isp.port != 80) {
        url += QLatin1Char(':');
        url += QString::number(isp.port);
    }

    if (!isp.path.startsWith(QLatin1Char('/'))) {
        url += QLatin1Char('/');
    }

    url += path.path();

    bool fullDomainRetrieval = (path.baseName() == QLatin1String("$EMAIL$"));

    const QString group(QStringLiteral("FreeBusy Retrieve"));

    korganizer->setConfig(group, QStringLiteral("FreeBusyFullDomainRetrieval"), fullDomainRetrieval ? QStringLiteral("true") : QStringLiteral("false"));
    korganizer->setConfig(group, QStringLiteral("FreeBusyRetrieveAuto"), QStringLiteral("true"));
    korganizer->setConfig(group, QStringLiteral("FreeBusyRetrieveUrl"), url);
    korganizer->setConfig(group, QStringLiteral("FreeBusyRetrieverUser"), isp.username);
    korganizer->setConfig(group, QStringLiteral("FreeBusyRetrieverPassword"), isp.password);
    if (!isp.password.isEmpty()) {
        korganizer->setConfig(group, QStringLiteral("FreeBusyRetrieveSavePassword"), QStringLiteral("true"));
    }
}

void SetupAutoconfigKolabFreebusy::start()
{
    mIspdb->start();
    Q_EMIT info(i18n("Searching for autoconfiguration..."));
}

void SetupAutoconfigKolabFreebusy::setEmail(const QString &email)
{
    mIspdb->setEmail(email);
}

void SetupAutoconfigKolabFreebusy::setPassword(const QString &password)
{
    mIspdb->setPassword(password);
}

void SetupAutoconfigKolabFreebusy::create()
{
}

void SetupAutoconfigKolabFreebusy::destroy()
{
}

void SetupAutoconfigKolabFreebusy::onIspdbFinished(bool status)
{
    Q_EMIT ispdbFinished(status);
    if (status) {
        Q_EMIT info(i18n("Autoconfiguration found."));
    } else {
        Q_EMIT info(i18n("Autoconfiguration failed."));
    }
}
