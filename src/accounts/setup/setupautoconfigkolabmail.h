/*
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupispdb.h"

class SetupAutoconfigKolabMail : public SetupIspdb
{
    Q_OBJECT
public:
    /** Constructor */
    explicit SetupAutoconfigKolabMail(QObject *parent = nullptr);
};
