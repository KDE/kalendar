/*
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"

class AutoconfigKolabLdap;

class SetupAutoconfigKolabLdap : public SetupObject
{
    Q_OBJECT
public:
    /** Constructor */
    explicit SetupAutoconfigKolabLdap(QObject *parent = nullptr);
    ~SetupAutoconfigKolabLdap() override;

    void create() override;
    void destroy() override;

public Q_SLOTS:
    Q_SCRIPTABLE void fillLdapServer(int i, QObject *) const;
    Q_SCRIPTABLE int countLdapServers() const;

    Q_SCRIPTABLE void start();

    Q_SCRIPTABLE void setEmail(const QString &);
    Q_SCRIPTABLE void setPassword(const QString &);

Q_SIGNALS:
    void ispdbFinished(bool);

private Q_SLOTS:
    void onIspdbFinished(bool);

private:
    AutoconfigKolabLdap *const mIspdb;
};
