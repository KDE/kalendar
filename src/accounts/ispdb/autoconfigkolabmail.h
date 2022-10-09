/*
 * SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

// This code was taken from kmail-account-wizard

#pragma once

#include "ispdb.h"

class AutoconfigKolabMail : public Ispdb
{
    Q_OBJECT
public:
    /** Constructor */
    explicit AutoconfigKolabMail(QObject *parent = nullptr);

    void startJob(const QUrl &url) override;

private:
    void slotResult(KJob *);
};
