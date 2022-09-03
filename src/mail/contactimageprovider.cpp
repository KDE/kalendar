// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-or-later

#include "contactimageprovider.h"

#include <Akonadi/ContactSearchJob>
#include <KIO/TransferJob>
#include <QApplication>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QThread>

#include <KLocalizedString>
#include <kjob.h>

QQuickImageResponse *ContactImageProvider::requestImageResponse(const QString &email, const QSize &requestedSize)
{
    return new ThumbnailResponse(email, requestedSize);
}

ThumbnailResponse::ThumbnailResponse(QString email, QSize size)
    : m_email(std::move(email))
    , requestedSize(size)
    , localFile(QStringLiteral("%1/contact_picture_provider/%2.png").arg(QStandardPaths::writableLocation(QStandardPaths::CacheLocation), m_email))
    , errorStr(QStringLiteral("Image request hasn't started"))
{
    QImage cachedImage;
    if (cachedImage.load(localFile)) {
        m_image = cachedImage;
        errorStr.clear();
        Q_EMIT finished();
        return;
    }

    // Execute a request on the main thread asynchronously
    moveToThread(QApplication::instance()->thread());
    QMetaObject::invokeMethod(this, &ThumbnailResponse::startRequest, Qt::QueuedConnection);
}

void ThumbnailResponse::startRequest()
{
    job = new Akonadi::ContactSearchJob();
    job->setQuery(Akonadi::ContactSearchJob::Email, m_email.toLower(), Akonadi::ContactSearchJob::ExactMatch);

    // Runs in the main thread, not QML thread
    Q_ASSERT(QThread::currentThread() == QApplication::instance()->thread());

    // Connect to any possible outcome including abandonment
    // to make sure the QML thread is not left stuck forever.
    connect(job, &Akonadi::ContactSearchJob::finished, this, &ThumbnailResponse::prepareResult);
}

bool ThumbnailResponse::searchPhoto(const KContacts::AddresseeList &list)
{
    bool foundPhoto = false;
    for (const KContacts::Addressee &addressee : list) {
        const KContacts::Picture photo = addressee.photo();
        if (!photo.isEmpty()) {
            m_photo = photo;
            foundPhoto = true;
            break;
        }
    }
    return foundPhoto;
}

void ThumbnailResponse::prepareResult()
{
    Q_ASSERT(QThread::currentThread() == job->thread());
    auto searchJob = static_cast<Akonadi::ContactSearchJob *>(job);
    {
        QWriteLocker _(&lock);
        if (job->error() == KJob::NoError) {
            bool ok = false;
            const int contactSize(searchJob->contacts().size());
            if (contactSize >= 1) {
                if (contactSize > 1) {
                    qWarning() << " more than 1 contact was found we return first contact";
                }

                const KContacts::Addressee addressee = searchJob->contacts().at(0);
                if (searchPhoto(searchJob->contacts())) {
                    // We have a data raw => we can update message
                    if (m_photo.isIntern()) {
                        m_image = m_photo.data();
                        ok = true;
                    } else {
                        const QUrl url = QUrl::fromUserInput(m_photo.url(), QString(), QUrl::AssumeLocalFile);
                        if (!url.isEmpty()) {
                            if (url.isLocalFile()) {
                                if (m_image.load(url.toLocalFile())) {
                                    ok = true;
                                }
                            } else {
                                QByteArray imageData;
                                KIO::TransferJob *jobTransfert = KIO::get(url, KIO::NoReload);
                                QObject::connect(jobTransfert, &KIO::TransferJob::data, [&imageData](KIO::Job *, const QByteArray &data) {
                                    imageData.append(data);
                                });
                                if (jobTransfert->exec()) {
                                    if (m_image.loadFromData(imageData)) {
                                        ok = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            QString localPath = QFileInfo(localFile).absolutePath();
            QDir dir;
            if (!dir.exists(localPath)) {
                dir.mkpath(localPath);
            }

            m_image.save(localFile);

            if (ok) {
                errorStr.clear();
            } else {
                errorStr = QStringLiteral("No image found");
            }
        } else if (job->error() == Akonadi::Job::UserCanceled) {
            errorStr = i18n("Image request has been cancelled");
        } else {
            errorStr = job->errorString();
            qWarning() << "ThumbnailResponse: no valid image for" << m_email << "-" << errorStr;
        }
        job = nullptr;
    }
    Q_EMIT finished();
}

void ThumbnailResponse::doCancel()
{
    // Runs in the main thread, not QML thread
    if (job) {
        Q_ASSERT(QThread::currentThread() == job->thread());
        job->kill();
    }
}

QQuickTextureFactory *ThumbnailResponse::textureFactory() const
{
    QReadLocker _(&lock);
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

QString ThumbnailResponse::errorString() const
{
    QReadLocker _(&lock);
    return errorStr;
}

void ThumbnailResponse::cancel()
{
    QMetaObject::invokeMethod(this, &ThumbnailResponse::doCancel, Qt::QueuedConnection);
}
