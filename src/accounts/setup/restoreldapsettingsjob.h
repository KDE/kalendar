/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include <KConfigGroup>
#include <KLDAP/LdapServer>
#include <QObject>
class KConfig;
class RestoreLdapSettingsJob : public QObject
{
    Q_OBJECT
public:
    explicit RestoreLdapSettingsJob(QObject *parent = nullptr);
    ~RestoreLdapSettingsJob() override;

    void start();
    KConfig *config() const;
    void setConfig(KConfig *config);
    Q_REQUIRED_RESULT bool canStart() const;
    Q_REQUIRED_RESULT int entry() const;
    void setEntry(int entry);

Q_SIGNALS:
    void restoreDone();

private:
    void slotConfigSelectedHostLoaded(const KLDAP::LdapServer &server);
    void slotConfigHostLoaded(const KLDAP::LdapServer &server);
    void restore();
    void saveLdapSettings();
    void restoreSettingsDone();
    void loadNextSelectHostSettings();
    void loadNextHostSettings();
    void saveNextSelectHostSettings();
    void saveNextHostSettings();
    QVector<KLDAP::LdapServer> mSelHosts;
    QVector<KLDAP::LdapServer> mHosts;
    int mEntry = -1;
    int mNumSelHosts = -1;
    int mNumHosts = -1;
    int mCurrentIndex = 0;
    KConfig *mConfig = nullptr;
    KConfigGroup mCurrentGroup;
};
