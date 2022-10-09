/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "restoreldapsettingsjob.h"

#include <KConfig>
#include <KLDAP/LdapClientSearchConfig>
#include <KLDAP/LdapClientSearchConfigReadConfigJob>
#include <KLDAP/LdapClientSearchConfigWriteConfigJob>

#include <QDebug>

RestoreLdapSettingsJob::RestoreLdapSettingsJob(QObject *parent)
    : QObject(parent)
{
}

RestoreLdapSettingsJob::~RestoreLdapSettingsJob() = default;

void RestoreLdapSettingsJob::start()
{
    if (!canStart()) {
        deleteLater();
        qWarning() << "Impossible to start RestoreLdapSettingsJob";
        Q_EMIT restoreDone();
        return;
    }
    restore();
}

void RestoreLdapSettingsJob::slotConfigSelectedHostLoaded(const KLDAP::LdapServer &server)
{
    mSelHosts.append(server);
    mCurrentIndex++;
    loadNextSelectHostSettings();
}

void RestoreLdapSettingsJob::loadNextSelectHostSettings()
{
    if (mCurrentIndex < mNumSelHosts) {
        if (mCurrentIndex != mEntry) {
            auto job = new KLDAP::LdapClientSearchConfigReadConfigJob(this);
            connect(job, &KLDAP::LdapClientSearchConfigReadConfigJob::configLoaded, this, &RestoreLdapSettingsJob::slotConfigSelectedHostLoaded);
            job->setActive(true);
            job->setConfig(mCurrentGroup);
            job->setServerIndex(mCurrentIndex);
            job->start();
        } else {
            mCurrentIndex++;
            loadNextSelectHostSettings();
        }
    } else {
        // Reset index;
        mCurrentIndex = 0;
        loadNextHostSettings();
    }
}

void RestoreLdapSettingsJob::slotConfigHostLoaded(const KLDAP::LdapServer &server)
{
    mHosts.append(server);
    mCurrentIndex++;
    loadNextHostSettings();
}

void RestoreLdapSettingsJob::loadNextHostSettings()
{
    if (mCurrentIndex < mNumHosts) {
        auto job = new KLDAP::LdapClientSearchConfigReadConfigJob(this);
        connect(job, &KLDAP::LdapClientSearchConfigReadConfigJob::configLoaded, this, &RestoreLdapSettingsJob::slotConfigHostLoaded);
        job->setActive(false);
        job->setConfig(mCurrentGroup);
        job->setServerIndex(mCurrentIndex);
        job->start();
    } else {
        saveLdapSettings();
    }
}

void RestoreLdapSettingsJob::restore()
{
    if (mEntry >= 0) {
        mCurrentGroup = mConfig->group(QStringLiteral("LDAP"));
        mNumSelHosts = mCurrentGroup.readEntry(QStringLiteral("NumSelectedHosts"), 0);
        mNumHosts = mCurrentGroup.readEntry(QStringLiteral("NumHosts"), 0);
        loadNextSelectHostSettings();
    } else {
        restoreSettingsDone();
    }
}

void RestoreLdapSettingsJob::restoreSettingsDone()
{
    Q_EMIT restoreDone();
    deleteLater();
}

void RestoreLdapSettingsJob::saveNextSelectHostSettings()
{
    if (mCurrentIndex < mNumSelHosts - 1) {
        auto job = new KLDAP::LdapClientSearchConfigWriteConfigJob(this);
        connect(job, &KLDAP::LdapClientSearchConfigWriteConfigJob::configSaved, this, &RestoreLdapSettingsJob::saveNextSelectHostSettings);
        job->setActive(true);
        job->setConfig(mCurrentGroup);
        job->setServer(mSelHosts.at(mCurrentIndex));
        job->setServerIndex(mCurrentIndex);
        job->start();
    } else {
        mCurrentIndex = 0;
        saveNextHostSettings();
    }
}

void RestoreLdapSettingsJob::saveNextHostSettings()
{
    if (mCurrentIndex < mNumHosts) {
        auto job = new KLDAP::LdapClientSearchConfigWriteConfigJob(this);
        connect(job, &KLDAP::LdapClientSearchConfigWriteConfigJob::configSaved, this, &RestoreLdapSettingsJob::saveNextHostSettings);
        job->setActive(false);
        job->setConfig(mCurrentGroup);
        job->setServer(mHosts.at(mCurrentIndex));
        job->setServerIndex(mCurrentIndex);
        job->start();
    } else {
        mCurrentGroup.writeEntry(QStringLiteral("NumSelectedHosts"), mNumSelHosts - 1);
        mCurrentGroup.writeEntry(QStringLiteral("NumHosts"), mNumHosts);
        mConfig->sync();
        restoreSettingsDone();
    }
}

void RestoreLdapSettingsJob::saveLdapSettings()
{
    mConfig->deleteGroup(QStringLiteral("LDAP"));
    mCurrentGroup = KConfigGroup(mConfig, QStringLiteral("LDAP"));

    mCurrentIndex = 0;
    saveNextSelectHostSettings();
}

int RestoreLdapSettingsJob::entry() const
{
    return mEntry;
}

void RestoreLdapSettingsJob::setEntry(int entry)
{
    mEntry = entry;
}

KConfig *RestoreLdapSettingsJob::config() const
{
    return mConfig;
}

void RestoreLdapSettingsJob::setConfig(KConfig *config)
{
    mConfig = config;
}

bool RestoreLdapSettingsJob::canStart() const
{
    return (mConfig != nullptr) && (mEntry != -1);
}
