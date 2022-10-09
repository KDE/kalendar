/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "configfile.h"

#include <KConfig>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KPluginMetaData>
#include <KStringHandler>

#include <QPointer>

ConfigFile::ConfigFile(const QString &configName, QObject *parent)
    : SetupObject(parent)
    , m_config(new KConfig(configName))
{
    m_name = configName;
}

ConfigFile::~ConfigFile()
{
    delete m_config;
}

void ConfigFile::write()
{
    create();
}

void ConfigFile::create()
{
    Q_EMIT info(i18n("Writing config file for %1...", m_name));

    for (const Config &c : std::as_const(m_configData)) {
        KConfigGroup grp = m_config->group(c.group);
        if (c.obscure) {
            grp.writeEntry(c.key, KStringHandler::obscure(c.value));
        } else {
            grp.writeEntry(c.key, c.value);
        }
    }

    m_config->sync();

    if (m_editMode) {
        edit();
    }

    Q_EMIT finished(i18n("Config file for %1 is writing.", m_name));
}

void ConfigFile::destroy()
{
    Q_EMIT info(i18n("Config file for %1 was not changed.", m_name));
}

void ConfigFile::setName(const QString &name)
{
    m_name = name;
}

void ConfigFile::setConfig(const QString &group, const QString &key, const QString &value)
{
    Config conf;
    conf.group = group;
    conf.key = key;
    conf.value = value;
    conf.obscure = false;
    m_configData.append(conf);
}

void ConfigFile::setPassword(const QString &group, const QString &key, const QString &value)
{
    Config conf;
    conf.group = group;
    conf.key = key;
    conf.value = value;
    conf.obscure = true;
    m_configData.append(conf);
}

void ConfigFile::edit()
{
    if (m_editName.isEmpty()) {
        Q_EMIT error(i18n("No given name for the configuration."));
        return;
    }

    if (m_editName == QLatin1String("freebusy")) {
        // QPointer<KCMultiDialog> dialog = new KCMultiDialog();
        // dialog->addModule(KPluginMetaData(QStringLiteral("korganizer_configfreebusy.desktop")));
        // dialog->exec();
        // delete dialog;
        // return;
    }

    Q_EMIT error(i18n("Unknown configuration name '%1'", m_editName));
}

void ConfigFile::setEditName(const QString &name)
{
    m_editName = name;
}

void ConfigFile::setEditMode(const bool editMode)
{
    m_editMode = editMode;
}
