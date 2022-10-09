/*
    SPDX-FileCopyrightText: 2009 Volker Krause <vkrause@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// this code was taken from kmail-account-wizard

#pragma once

#include "key.h"

#include <QObject>
#include <QVector>

#include <gpgme++/key.h>

namespace KWallet
{
class Wallet;
}

class SetupManager : public QObject
{
    Q_OBJECT
public:
    explicit SetupManager(QObject *parent);
    ~SetupManager() override;

    void setName(const QString &);
    void setEmail(const QString &);
    void setPassword(const QString &);
    void setPersonalDataAvailable(bool available);
    void setPgpAutoSign(bool autosign);
    void setPgpAutoEncrypt(bool autoencrypt);
    void setKey(const GpgME::Key &key);
    void setKeyPublishingMethod(Key::PublishingMethod method);

    QVector<SetupObject *> objectsToSetup() const;
    QVector<SetupObject *> setupObjects() const;

public Q_SLOTS:
    Q_SCRIPTABLE bool personalDataAvailable() const;
    Q_SCRIPTABLE QString name() const;
    Q_SCRIPTABLE QString email() const;
    Q_SCRIPTABLE QString password() const;
    Q_SCRIPTABLE QString country() const;
    /** Ensures the wallet is open for subsequent sync wallet access in the resources. */
    Q_SCRIPTABLE void openWallet();
    Q_SCRIPTABLE QObject *createResource(const QString &type);
    Q_SCRIPTABLE QObject *createTransport(const QString &type);
    Q_SCRIPTABLE QObject *createConfigFile(const QString &configName);
    Q_SCRIPTABLE QObject *createLdap();
    Q_SCRIPTABLE QObject *createIdentity();
    Q_SCRIPTABLE QObject *createKey();
    Q_SCRIPTABLE void execute();
    Q_SCRIPTABLE void setupInfoSlot(const QString &msg);
    Q_SCRIPTABLE QObject *ispDB(const QString &type);

    void requestRollback();

Q_SIGNALS:
    void rollbackComplete();
    void setupFinished(SetupObject *obj);
    void setupSucceeded(const QString &msg);
    void setupFailed(const QString &msg);
    void setupInfo(const QString &msg);

private:
    void setupNext();
    void rollback();
    SetupObject *connectObject(SetupObject *obj);

private Q_SLOTS:
    void setupSuccessSlot(const QString &msg);
    void setupFailedSlot(const QString &msg);

private:
    QString m_name, m_email, m_password;
    QVector<SetupObject *> m_objectToSetup;
    QVector<SetupObject *> m_setupObjects;
    SetupObject *m_currentSetupObject = nullptr;
    KWallet::Wallet *m_wallet = nullptr;
    GpgME::Key m_key;
    Key::PublishingMethod m_keyPublishingMethod;
    bool m_personalDataAvailable = false;
    bool m_rollbackRequested = false;
    bool m_pgpAutoSign = false;
    bool m_pgpAutoEncrypt = false;
};
