// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QQuickAsyncImageProvider>

#include <KContacts/Addressee>
#include <QAtomicPointer>
#include <QReadWriteLock>

namespace Akonadi
{
class ContactSearchJob;
}

class ThumbnailResponse : public QQuickImageResponse
{
    Q_OBJECT
public:
    ThumbnailResponse(QString mediaId, QSize requestedSize);
    ~ThumbnailResponse() override = default;

private Q_SLOTS:
    void startRequest();
    void prepareResult();
    void doCancel();

private:
    bool searchPhoto(const KContacts::AddresseeList &list);
    const QString m_email;
    QSize requestedSize;
    const QString localFile;

    QImage m_image;
    KContacts::Picture m_photo;
    QString errorStr;
    Akonadi::ContactSearchJob *job = nullptr;
    mutable QReadWriteLock lock; // Guards ONLY these two members above

    QQuickTextureFactory *textureFactory() const override;
    QString errorString() const override;
    void cancel() override;
};

class ContactImageProvider : public QQuickAsyncImageProvider
{
public:
    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;
};
