/*
    SPDX-FileCopyrightText: 2009 Volker Krause <vkrause@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// this code was taken from kmail-account-wizard

#include "setupmanager.h"
#include "configfile.h"
#include "identity.h"
#include "ldap.h"
#include "resource.h"
#include "setupautoconfigkolabfreebusy.h"
#include "setupautoconfigkolabldap.h"
#include "setupautoconfigkolabmail.h"
#include "setupispdb.h"
#include "transport.h"

#include <KAssistantDialog>
#include <KEMailSettings>
#include <KWallet>

#include <QLocale>

SetupManager::SetupManager(QObject *parent)
    : QObject(parent)
    , m_keyPublishingMethod(Key::NoPublishing)
{
    KEMailSettings e;
    m_name = e.getSetting(KEMailSettings::RealName);
    m_email = e.getSetting(KEMailSettings::EmailAddress);
}

SetupManager::~SetupManager()
{
    delete m_wallet;
}

QObject *SetupManager::createResource(const QString &type)
{
    return connectObject(new Resource(type, this));
}

QObject *SetupManager::createTransport(const QString &type)
{
    return connectObject(new Transport(type, this));
}

QObject *SetupManager::createConfigFile(const QString &fileName)
{
    return connectObject(new ConfigFile(fileName, this));
}

QObject *SetupManager::createLdap()
{
    return connectObject(new Ldap(this));
}

QObject *SetupManager::createIdentity()
{
    auto *identity = new Identity(this);
    identity->setEmail(m_email);
    identity->setRealName(m_name);
    identity->setPgpAutoSign(m_pgpAutoSign);
    identity->setPgpAutoEncrypt(m_pgpAutoEncrypt);
    identity->setKey(m_key.protocol(), m_key.primaryFingerprint());
    return connectObject(identity);
}

QObject *SetupManager::createKey()
{
    Key *key = new Key(this);
    key->setKey(m_key);
    key->setMailBox(m_email);
    key->setPublishingMethod(m_keyPublishingMethod);
    return connectObject(key);
}

QVector<SetupObject *> SetupManager::objectsToSetup() const
{
    return m_objectToSetup;
}

QVector<SetupObject *> SetupManager::setupObjects() const
{
    return m_setupObjects;
}

static bool dependencyCompare(SetupObject *left, SetupObject *right)
{
    if (!left->dependsOn() && right->dependsOn()) {
        return true;
    }
    return false;
}

void SetupManager::execute()
{
    if (m_keyPublishingMethod != Key::NoPublishing) {
        auto key = qobject_cast<Key *>(createKey());
        auto it = std::find_if(m_setupObjects.cbegin(), m_setupObjects.cend(), [](SetupObject *obj) -> bool {
            return qobject_cast<Transport *>(obj);
        });
        if (it != m_setupObjects.cend()) {
            key->setDependsOn(*it);
        }
    }

    // ### FIXME this is a bad over-simplification and would need a real topological sort
    // but for current usage it is good enough
    std::stable_sort(m_objectToSetup.begin(), m_objectToSetup.end(), dependencyCompare);

    while (!m_objectToSetup.isEmpty()) {
        m_currentSetupObject = m_objectToSetup.takeFirst();
        m_currentSetupObject->create();
    }
}

void SetupManager::setupSuccessSlot(const QString &msg)
{
    Q_EMIT setupSucceeded(msg);
    if (m_currentSetupObject) {
        Q_EMIT setupFinished(m_currentSetupObject);
        m_setupObjects.append(m_currentSetupObject);
        m_currentSetupObject = nullptr;
    }
    setupNext();
}

void SetupManager::setupFailedSlot(const QString &msg)
{
    Q_EMIT setupFailed(msg);
    if (m_currentSetupObject) {
        m_setupObjects.append(m_currentSetupObject);
        m_currentSetupObject = nullptr;
    }
    rollback();
}

void SetupManager::setupInfoSlot(const QString &msg)
{
    Q_EMIT setupInfo(msg);
}

void SetupManager::setupNext()
{
    // user canceled during the previous setup step
    if (m_rollbackRequested) {
        rollback();
        return;
    }

    if (!m_objectToSetup.isEmpty()) {
        m_currentSetupObject = m_objectToSetup.takeFirst();
        m_currentSetupObject->create();
    }
}

void SetupManager::rollback()
{
    const auto setupObjectsList = m_setupObjects;
    for (int i = 0; i < setupObjectsList.count(); ++i) {
        auto obj = m_setupObjects.at(i);
        if (obj) {
            obj->destroy();
            m_objectToSetup.prepend(obj);
        }
    }
    m_setupObjects.clear();
    m_rollbackRequested = false;
    Q_EMIT rollbackComplete();
}

SetupObject *SetupManager::connectObject(SetupObject *obj)
{
    connect(obj, &SetupObject::finished, this, &SetupManager::setupSuccessSlot);
    connect(obj, &SetupObject::finished, this, [](const QString &msg) {
        qDebug() << msg;
    });
    connect(obj, &SetupObject::info, this, &SetupManager::setupInfo);
    connect(obj, &SetupObject::info, this, [](const QString &msg) {
        qDebug() << msg;
    });
    connect(obj, &SetupObject::error, this, &SetupManager::setupFailedSlot);
    connect(obj, &SetupObject::error, this, [](const QString &msg) {
        qDebug() << msg;
    });
    m_objectToSetup.append(obj);
    return obj;
}

void SetupManager::setName(const QString &name)
{
    m_name = name;
}

QString SetupManager::name() const
{
    return m_name;
}

void SetupManager::setEmail(const QString &email)
{
    m_email = email;
}

QString SetupManager::email() const
{
    return m_email;
}

void SetupManager::setPassword(const QString &password)
{
    m_password = password;
}

QString SetupManager::password() const
{
    return m_password;
}

QString SetupManager::country() const
{
    return QLocale::countryToString(QLocale().country());
}

void SetupManager::setPgpAutoEncrypt(bool autoencrypt)
{
    m_pgpAutoEncrypt = autoencrypt;
}

void SetupManager::setPgpAutoSign(bool autosign)
{
    m_pgpAutoSign = autosign;
}

void SetupManager::setKey(const GpgME::Key &key)
{
    m_key = key;
}

void SetupManager::setKeyPublishingMethod(Key::PublishingMethod method)
{
    m_keyPublishingMethod = method;
}

void SetupManager::openWallet()
{
    // Remove it we need to update qt5keychain
    using namespace KWallet;
    if (Wallet::isOpen(Wallet::NetworkWallet())) {
        return;
    }

    Q_ASSERT(parent()->isWidgetType());
    m_wallet = Wallet::openWallet(Wallet::NetworkWallet(), qobject_cast<QWidget *>(parent())->effectiveWinId(), Wallet::Asynchronous);
    QEventLoop loop;
    connect(m_wallet, &KWallet::Wallet::walletOpened, &loop, &QEventLoop::quit);
    loop.exec();
}

bool SetupManager::personalDataAvailable() const
{
    return m_personalDataAvailable;
}

void SetupManager::setPersonalDataAvailable(bool available)
{
    m_personalDataAvailable = available;
}

QObject *SetupManager::ispDB(const QString &type)
{
    const QString t = type.toLower();
    if (t == QLatin1String("autoconfigkolabmail")) {
        return new SetupAutoconfigKolabMail(this);
    } else if (t == QLatin1String("autoconfigkolabldap")) {
        return new SetupAutoconfigKolabLdap(this);
    } else if (t == QLatin1String("autoconfigkolabfreebusy")) {
        return new SetupAutoconfigKolabFreebusy(this);
    } else {
        return new SetupIspdb(this);
    }
}

void SetupManager::requestRollback()
{
    if (m_setupObjects.isEmpty()) {
        Q_EMIT rollbackComplete();
    } else {
        m_rollbackRequested = true;
        if (!m_currentSetupObject) {
            rollback();
        }
    }
}
