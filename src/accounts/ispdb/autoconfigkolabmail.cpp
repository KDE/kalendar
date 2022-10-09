/*
 * SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

// This code was taken from kmail-account-wizard

#include "autoconfigkolabmail.h"
#include <QDomDocument>

AutoconfigKolabMail::AutoconfigKolabMail(QObject *parent)
    : Ispdb(parent)
{
}

void AutoconfigKolabMail::startJob(const QUrl &url)
{
    mData.clear();
    QMap<QString, QVariant> map;
    map[QStringLiteral("errorPage")] = false;
    map[QStringLiteral("no-auth-prompt")] = true;
    map[QStringLiteral("no-www-auth")] = true;

    KIO::TransferJob *job = KIO::get(url, KIO::NoReload, KIO::HideProgressInfo);
    job->setMetaData(map);
    connect(job, &KIO::TransferJob::result, this, &AutoconfigKolabMail::slotResult);
    connect(job, &KIO::TransferJob::data, this, &AutoconfigKolabMail::dataArrived);
}

void AutoconfigKolabMail::slotResult(KJob *job)
{
    if (job->error()) {
        if (job->error() == KIO::ERR_INTERNAL_SERVER // error 500
            || job->error() == KIO::ERR_UNKNOWN_HOST // unknown host
            || job->error() == KIO::ERR_CANNOT_CONNECT || job->error() == KIO::ERR_DOES_NOT_EXIST) { // error 404
            if (serverType() == DataBase) {
                setServerType(IspAutoConfig);
                lookupInDb(false, false);
            } else if (serverType() == IspAutoConfig) {
                setServerType(IspWellKnow);
                lookupInDb(false, false);
            } else {
                Q_EMIT finished(false);
            }
        } else {
            // qCDebug(ACCOUNTWIZARD_LOG) << "Fetching failed" << job->error() << job->errorString();
            Q_EMIT finished(false);
        }
        return;
    }

    auto *tjob = qobject_cast<KIO::TransferJob *>(job);

    int responsecode = tjob->queryMetaData(QStringLiteral("responsecode")).toInt();

    if (responsecode == 401) {
        lookupInDb(true, true);
        return;
    } else if (responsecode != 200 && responsecode != 0 && responsecode != 304) {
        // qCDebug(ACCOUNTWIZARD_LOG) << "Fetching failed with" << responsecode;
        Q_EMIT finished(false);
        return;
    }

    QDomDocument document;
    bool ok = document.setContent(mData);
    if (!ok) {
        // qCDebug(ACCOUNTWIZARD_LOG) << "Could not parse xml" << mData;
        Q_EMIT finished(false);
        return;
    }
    parseResult(document);
}
