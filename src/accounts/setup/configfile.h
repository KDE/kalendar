/*
    SPDX-FileCopyrightText: 2010-2022 Laurent Montel <montel@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#pragma once

#include "setupobject.h"
#include <QVector>
class KConfig;

struct Config {
    QString group;
    QString key;
    QString value;
    bool obscure;
};

class ConfigFile : public SetupObject
{
    Q_OBJECT
public:
    explicit ConfigFile(const QString &configName, QObject *parent = nullptr);
    ~ConfigFile() override;
    void create() override;
    void destroy() override;
    void edit();
public Q_SLOTS:
    Q_SCRIPTABLE void write();
    Q_SCRIPTABLE void setName(const QString &name);
    Q_SCRIPTABLE void setConfig(const QString &group, const QString &key, const QString &value);
    Q_SCRIPTABLE void setPassword(const QString &group, const QString &key, const QString &value);
    Q_SCRIPTABLE void setEditMode(const bool editMode);
    Q_SCRIPTABLE void setEditName(const QString &name);

private:
    QVector<Config> m_configData;
    QString m_name;
    KConfig *const m_config;
    QString m_editName;
    bool m_editMode = false;
};
