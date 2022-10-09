/*
    SPDX-FileCopyrightText: 2016 Daniel Vrátil <dvratil@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"

#include <QPointer>
#include <QProcess>
#include <gpgme++/key.h>

class KJob;
namespace GpgME
{
class Error;
}

namespace QGpgME
{
}

class Key : public SetupObject
{
    Q_OBJECT

public:
    enum PublishingMethod { NoPublishing, WKS, PKS };

    explicit Key(QObject *parent = nullptr);
    ~Key() override;

    void create() override;
    void destroy() override;

public Q_SLOTS:
    Q_SCRIPTABLE void setKey(const GpgME::Key &key);
    Q_SCRIPTABLE void setPublishingMethod(Key::PublishingMethod method);
    Q_SCRIPTABLE void setMailBox(const QString &mailbox);
    Q_SCRIPTABLE void setTransportId(int transportId);

private:
    void publishWKS();
    void publishPKS();

    void onWKSPublishingCheckDone(const GpgME::Error &error, const QByteArray &returnedData, const QByteArray &returnedError);
    void onWKSPublishingRequestCreated(const GpgME::Error &error, const QByteArray &returnedData, const QByteArray &returnedError);
    void onWKSPublishingRequestSent(KJob *job);

    void onPKSPublishingFinished(int result, QProcess::ExitStatus status);

private:
    int m_transportId = 0;
    GpgME::Key m_key;
    QString m_mailbox;
    QPointer<QObject> mJob;
    PublishingMethod m_publishingMethod = NoPublishing;
};
