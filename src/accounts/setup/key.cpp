/*
    SPDX-FileCopyrightText: 2016 Daniel Vrátil <dvratil@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "key.h"
#include "setupmanager.h"
#include "transport.h"

#include <QTimer>

#include <QGpgME/CryptoConfig>
#include <QGpgME/Protocol>
#include <QGpgME/WKSPublishJob>

#include <gpgme++/engineinfo.h>

#include <MailTransport/Transport>
#include <MailTransport/TransportManager>
#include <MailTransportAkonadi/MessageQueueJob>

#include <KIdentityManagement/Identity>
#include <KIdentityManagement/IdentityManager>

#include <KMime/Headers>
#include <KMime/Message>
#include <KMime/Util>

#include <KEmailAddress>

#include <KLocalizedString>

// This code was taken from kmail-account-wizard

Key::Key(QObject *parent)
    : SetupObject(parent)
{
}

Key::~Key() = default;

void Key::setKey(const GpgME::Key &key)
{
    m_key = key;
}

void Key::setMailBox(const QString &mailbox)
{
    m_mailbox = KEmailAddress::extractEmailAddress(mailbox);
}

void Key::setTransportId(int transportId)
{
    m_transportId = transportId;
}

void Key::setPublishingMethod(PublishingMethod method)
{
    m_publishingMethod = method;
}

void Key::create()
{
    switch (m_publishingMethod) {
    case NoPublishing:
        QTimer::singleShot(0, this, [this]() {
            Q_EMIT finished(i18n("Skipping key publishing"));
        });
        break;
    case WKS:
        publishWKS();
        break;
    case PKS:
        publishPKS();
        break;
    }
}

void Key::publishWKS()
{
    Q_EMIT info(i18n("Publishing OpenPGP key..."));

    auto job = QGpgME::openpgp()->wksPublishJob();
    mJob = job;
    connect(job, &QGpgME::WKSPublishJob::result, this, &Key::onWKSPublishingCheckDone);
    job->startCheck(m_mailbox);
}

void Key::onWKSPublishingCheckDone(const GpgME::Error &gpgMeError, const QByteArray &, const QByteArray &returnedError)
{
    mJob = nullptr;

    if (gpgMeError) {
        if (gpgMeError.isCanceled()) {
            Q_EMIT error(i18n("Key publishing was canceled."));
            return;
        }

        qWarning() << "Check error:" << returnedError;
        if (gpgMeError.code() == GPG_ERR_NOT_SUPPORTED) {
            Q_EMIT info(i18n("Key publishing failed: not online, or GnuPG too old."));
            Q_EMIT finished(QString());
        } else {
            Q_EMIT info(i18n("Your email provider does not support key publishing."));
            Q_EMIT finished(QString());
        }
        return;
    }

    auto job = QGpgME::openpgp()->wksPublishJob();
    mJob = job;
    connect(job, &QGpgME::WKSPublishJob::result, this, &Key::onWKSPublishingRequestCreated);
    job->startCreate(m_key.primaryFingerprint(), m_mailbox);
}

void Key::onWKSPublishingRequestCreated(const GpgME::Error &gpgMeError, const QByteArray &returnedData, const QByteArray &returnedError)
{
    mJob = nullptr;

    if (gpgMeError) {
        if (gpgMeError.isCanceled()) {
            Q_EMIT error(i18n("Key publishing was canceled."));
            return;
        }

        qWarning() << "Publishing error:" << returnedData << returnedError;
        Q_EMIT error(i18n("An error occurred while creating key publishing request."));
        return;
    }

    if (m_transportId == 0 && qobject_cast<SetupManager *>(parent())) {
        const auto setupManager = qobject_cast<SetupManager *>(parent());
        const auto setupObjects = setupManager->setupObjects();
        auto it = std::find_if(setupObjects.cbegin(), setupObjects.cend(), [](SetupObject *obj) -> bool {
            return qobject_cast<Transport *>(obj);
        });
        if (it != setupObjects.cend()) {
            m_transportId = qobject_cast<Transport *>(*it)->transportId();
        }
    } else if (m_transportId) {
        auto ident = KIdentityManagement::IdentityManager::self()->identityForAddress(m_mailbox);
        if (!ident.transport().isEmpty()) {
            m_transportId = ident.transport().toInt();
        }
    }

    auto transport = MailTransport::TransportManager::self()->transportById(m_transportId, true);
    if (!transport) {
        qWarning() << "No MailTransport::Transport available?!?!?!";
        Q_EMIT error(i18n("Key publishing error: mail transport is not configured"));
        return;
    }

    qDebug() << returnedData;

    // Parse the data so that we can get "To" and "From" headers
    auto msg = KMime::Message::Ptr::create();
    msg->setContent(KMime::CRLFtoLF(returnedData));
    msg->parse();

    if (!msg->from(false) || !msg->to(false)) {
        qWarning() << "No FROM or TO in parsed message, source data were:" << returnedData;
        Q_EMIT error(i18n("Key publishing error: failed to create request email"));
        return;
    }

    auto header = new KMime::Headers::Generic("X-KMail-Transport");
    header->fromUnicodeString(QString::number(m_transportId), "utf-8");
    msg->setHeader(header);

    // Build the message
    msg->assemble();

    // Move to outbox
    auto job = new MailTransport::MessageQueueJob;
    mJob = job;
    job->addressAttribute().setTo({msg->to(false)->asUnicodeString()});
    job->transportAttribute().setTransportId(transport->id());
    job->addressAttribute().setFrom(msg->from(false)->asUnicodeString());
    // Don't leave any evidence :-)
    job->sentBehaviourAttribute().setSentBehaviour(MailTransport::SentBehaviourAttribute::Delete);
    job->sentBehaviourAttribute().setSendSilently(true);
    job->setMessage(msg);
    connect(job, &KJob::result, this, &Key::onWKSPublishingRequestSent);
    job->start();
}

void Key::onWKSPublishingRequestSent(KJob *job)
{
    mJob = nullptr;
    if (job->error() == KJob::KilledJobError) {
        Q_EMIT error(i18n("Key publishing was canceled."));
    } else if (job->error()) {
        Q_EMIT error(i18n("Failed to send key publishing request: %1", job->errorString()));
    } else {
        Q_EMIT finished(i18n("Key publishing request sent."));
    }
}

void Key::publishPKS()
{
    Q_EMIT info(i18n("Publishing OpenPGP key..."));

    // default
    QString keyServer = QStringLiteral("key.gnupg.net");

    const auto config = QGpgME::cryptoConfig();
    if (config) {
        const auto entry = config->entry(QStringLiteral("gpg"), QStringLiteral("Keyserver"), QStringLiteral("keyserver"));
        if (entry && !entry->stringValue().isEmpty()) {
            keyServer = entry->stringValue();
        }
    }

    const char *gpgName = GpgME::engineInfo(GpgME::OpenPGP).fileName();
    auto gpgProcess = new QProcess;
    gpgProcess->setProperty("keyServer", keyServer);
    connect(gpgProcess, &QProcess::finished, this, &Key::onPKSPublishingFinished);
    mJob = gpgProcess;
    gpgProcess->start(QString::fromLatin1(gpgName),
                      {QStringLiteral("--keyserver"), keyServer, QStringLiteral("--send-keys"), QString::fromLatin1(m_key.primaryFingerprint())});
}

void Key::onPKSPublishingFinished(int code, QProcess::ExitStatus status)
{
    auto process = qobject_cast<QProcess *>(mJob);
    mJob = nullptr;
    process->deleteLater();

    if (status != QProcess::NormalExit || code != 0) {
        qWarning() << "PKS Publishing error:" << process->readAll();
        Q_EMIT info(i18n("Failed to publish the key."));
        Q_EMIT finished(QString());
        return;
    }

    const auto keyServer = process->property("keyServer").toString();
    Q_EMIT finished(i18n("Key has been published on %1", keyServer));
}

void Key::destroy()
{
    // This is all we can do, there's no unpublish...
    if (auto job = qobject_cast<QGpgME::Job *>(mJob)) {
        job->slotCancel();
    } else if (auto job = qobject_cast<KJob *>(mJob)) {
        job->kill();
    } else if (auto job = qobject_cast<QProcess *>(mJob)) {
        job->kill();
    }
}
