/*
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"

class Identity;
class Ispdb;

class SetupIspdb : public SetupObject
{
    Q_OBJECT
public:
    /** Constructor */
    explicit SetupIspdb(QObject *parent = nullptr);
    SetupIspdb(QObject *parent, Ispdb *ispdb);
    ~SetupIspdb() override;

    void create() override;
    void destroy() override;

public Q_SLOTS:
    Q_SCRIPTABLE QStringList relevantDomains() const;
    Q_SCRIPTABLE QString name(int l) const;

    Q_SCRIPTABLE void fillImapServer(int i, QObject *) const;
    Q_SCRIPTABLE int countImapServers() const;

    Q_SCRIPTABLE void fillSmtpServer(int i, QObject *) const;
    Q_SCRIPTABLE int countSmtpServers() const;

    Q_SCRIPTABLE void fillIdentity(int i, QObject *) const;
    Q_SCRIPTABLE int countIdentities() const;
    Q_SCRIPTABLE int defaultIdentity() const;

    Q_SCRIPTABLE void start();

    Q_SCRIPTABLE void setEmail(const QString &);
    Q_SCRIPTABLE void setPassword(const QString &);

Q_SIGNALS:
    void ispdbFinished(bool);

protected Q_SLOTS:
    void onIspdbFinished(bool);

protected:
    Ispdb *mIspdb = nullptr;
};
