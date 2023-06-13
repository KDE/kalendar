// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "contactapplication.h"
#include "contactconfig.h"
#include <KAuthorized>
#include <KLocalizedString>
#include <KShortcutsDialog>
#include <QIcon>

ContactApplication::ContactApplication(QObject *parent)
    : AbstractApplication(parent)
    , mContactCollection(new KActionCollection(parent, i18n("Contact")))
{
    mContactCollection->setComponentDisplayName(i18n("Contact"));
    setupActions();
}

QVector<KActionCollection *> ContactApplication::actionCollections() const
{
    return {
        mCollection,
        mContactCollection,
    };
}

void ContactApplication::setupActions()
{
    AbstractApplication::setupActions();

    auto actionName = QLatin1String("create_contact");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mContactCollection->addAction(actionName, this, &ContactApplication::createNewContact);
        action->setText(i18n("New Contact…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("contact-new-symbolic")));
    }

    actionName = QLatin1String("refresh_all");
    if (KAuthorized::authorizeAction(actionName)) {
        auto refreshAllAction = mContactCollection->addAction(actionName, this, &ContactApplication::refreshAll);
        refreshAllAction->setText(i18n("Refresh All Address Books"));
        refreshAllAction->setIcon(QIcon::fromTheme(QStringLiteral("view-refresh")));

        mContactCollection->addAction(refreshAllAction->objectName(), refreshAllAction);
        mContactCollection->setDefaultShortcut(refreshAllAction, QKeySequence(QKeySequence::Refresh));
    }

    actionName = QLatin1String("create_contact_group");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mContactCollection->addAction(actionName, this, &ContactApplication::createNewContactGroup);
        action->setText(i18n("New Contact Group…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("contact-new-symbolic")));
    }

    mCollection->readSettings();
    mContactCollection->readSettings();
}

void ContactApplication::toggleMenubar()
{
    ContactConfig config;
    config.setShowMenubar(!config.showMenubar());
    config.save();
}

bool ContactApplication::showMenubar() const
{
    ContactConfig config;
    return config.showMenubar();
}
