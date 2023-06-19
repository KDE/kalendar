// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "mailapplication.h"
#include <KAuthorized>
#include <KLocalizedString>
#include <QIcon>

MailApplication::MailApplication(QObject *parent)
    : AbstractApplication(parent)
{
    setupActions();
}

void MailApplication::setupActions()
{
    AbstractApplication::setupActions();

    auto actionName = QLatin1String("create_mail");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &MailApplication::createNewMail);
        action->setText(i18n("New Mail…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("mail-message-new")));
    }

    mCollection->readSettings();
}

QVector<KActionCollection *> MailApplication::actionCollections() const
{
    return {
        mCollection,
    };
}
