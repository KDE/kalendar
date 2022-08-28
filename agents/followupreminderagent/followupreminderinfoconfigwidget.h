/*
   SPDX-FileCopyrightText: 2018-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <Akonadi/AgentConfigurationBase>
#include <Akonadi/Item>
#include <QVariantList>
#include <QWidget>
class FollowUpReminderInfoWidget;
class FollowUpReminderInfoConfigWidget : public Akonadi::AgentConfigurationBase
{
    Q_OBJECT
public:
    explicit FollowUpReminderInfoConfigWidget(const KSharedConfigPtr &config, QWidget *parentWidget, const QVariantList &args);
    ~FollowUpReminderInfoConfigWidget() override;

    bool save() const override;
    void load() override;
    QSize restoreDialogSize() const override;
    void saveDialogSize(const QSize &size) override;

private:
    FollowUpReminderInfoWidget *const mWidget;
};
AKONADI_AGENTCONFIG_FACTORY(FollowUpReminderInfoAgentConfigFactory, "followupreminderagentconfig.json", FollowUpReminderInfoConfigWidget)
