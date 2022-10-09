/*
    SPDX-FileCopyrightText: 2009 Volker Krause <vkrause@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "resource.h"

#include <Akonadi/AgentConfigurationDialog>
#include <Akonadi/AgentInstanceCreateJob>
#include <Akonadi/AgentManager>
#include <Akonadi/AgentType>
#include <Akonadi/ServerManager>

#include <KLocalizedString>

#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>
#include <QMetaMethod>
#include <QPointer>
#include <QVariant>

using namespace Akonadi;

static QVariant::Type argumentType(const QMetaObject *mo, const QString &method)
{
    QMetaMethod m;
    const int numberOfMethod(mo->methodCount());
    for (int i = 0; i < numberOfMethod; ++i) {
        const QString signature = QLatin1String(mo->method(i).methodSignature());
        if (signature.contains(method + QLatin1Char('('))) {
            m = mo->method(i);
            break;
        }
    }

    if (m.methodSignature().isEmpty()) {
        qWarning() << "Did not find D-Bus method: " << method << " available methods are:";
        for (int i = 0; i < numberOfMethod; ++i) {
            qWarning() << mo->method(i).methodSignature();
        }
        return QVariant::Invalid;
    }

    const QList<QByteArray> argTypes = m.parameterTypes();
    if (argTypes.count() != 1) {
        return QVariant::Invalid;
    }

    return QVariant::nameToType(argTypes.first().constData());
}

Resource::Resource(const QString &type, QObject *parent)
    : SetupObject(parent)
    , m_typeIdentifier(type)
{
}

void Resource::setOption(const QString &key, const QVariant &value)
{
    m_settings.insert(key, value);
}

void Resource::setName(const QString &name)
{
    m_name = name;
}

void Resource::create()
{
    const AgentType type = AgentManager::self()->type(m_typeIdentifier);
    if (!type.isValid()) {
        Q_EMIT error(i18n("Resource type '%1' is not available.", m_typeIdentifier));
        return;
    }

    // check if unique instance already exists
    qDebug() << type.capabilities();
    if (type.capabilities().contains(QLatin1String("Unique"))) {
        const Akonadi::AgentInstance::List lstAgent = AgentManager::self()->instances();
        for (const AgentInstance &instance : lstAgent) {
            qDebug() << instance.type().identifier() << (instance.type() == type);
            if (instance.type() == type) {
                if (m_editMode) {
                    edit();
                }
                Q_EMIT finished(i18n("Resource '%1' is already set up.", type.name()));
                return;
            }
        }
    }

    Q_EMIT info(i18n("Creating resource instance for '%1'...", type.name()));
    auto *job = new AgentInstanceCreateJob(type);
    connect(job, &AgentInstanceCreateJob::result, this, &Resource::instanceCreateResult);
    job->start();
}

void Resource::instanceCreateResult(KJob *job)
{
    if (job->error()) {
        Q_EMIT error(i18n("Failed to create resource instance: %1", job->errorText()));
        return;
    }

    m_instance = qobject_cast<AgentInstanceCreateJob *>(job)->instance();

    if (!m_settings.isEmpty()) {
        Q_EMIT info(i18n("Configuring resource instance..."));
        const auto service = ServerManager::agentServiceName(ServerManager::Resource, m_instance.identifier());
        QDBusInterface iface(service, QStringLiteral("/Settings"));
        if (!iface.isValid()) {
            Q_EMIT error(i18n("Unable to configure resource instance."));
            return;
        }

        // configure resource
        if (!m_name.isEmpty()) {
            m_instance.setName(m_name);
        }
        QMap<QString, QVariant>::const_iterator end(m_settings.constEnd());
        for (QMap<QString, QVariant>::const_iterator it = m_settings.constBegin(); it != end; ++it) {
            qDebug() << "Setting up " << it.key() << " for agent " << m_instance.identifier();
            const QString methodName = QStringLiteral("set%1").arg(it.key());
            QVariant arg = it.value();
            const QVariant::Type targetType = argumentType(iface.metaObject(), methodName);
            if (!arg.canConvert(targetType)) {
                Q_EMIT error(i18n("Could not convert value of setting '%1' to required type %2.", it.key(), QLatin1String(QVariant::typeToName(targetType))));
                qWarning() << "Impossible to convert argument : " << arg;
                return;
            }
            arg.convert(targetType);
            QDBusReply<void> reply = iface.call(methodName, arg);
            if (!reply.isValid()) {
                Q_EMIT error(i18n("Could not set setting '%1': %2", it.key(), reply.error().message()));
                return;
            }
        }
        QDBusReply<void> reply = iface.call(QStringLiteral("save"));
        if (!reply.isValid()) {
            Q_EMIT error(i18n("Could not save settings: %1", reply.error().message()));
            return;
        }
        m_instance.reconfigure();
    }

    if (m_editMode) {
        edit();
    }
    Q_EMIT finished(i18n("Resource setup completed."));
}

void Resource::edit()
{
    if (m_instance.isValid()) {
        QPointer<Akonadi::AgentConfigurationDialog> dlg = new Akonadi::AgentConfigurationDialog(m_instance);
        dlg->exec();
        delete dlg;
    }
}

void Resource::destroy()
{
    if (m_instance.isValid()) {
        AgentManager::self()->removeInstance(m_instance);
        Q_EMIT info(i18n("Removed resource instance for '%1'.", m_instance.type().name()));
    }
}

QString Resource::identifier()
{
    return m_instance.identifier();
}

void Resource::reconfigure()
{
    m_instance.reconfigure();
}

void Resource::setEditMode(const bool editMode)
{
    m_editMode = editMode;
}
