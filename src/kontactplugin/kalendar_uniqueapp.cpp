// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendar_uniqueapp.h"

#include <KontactInterface/Core>

#include <KStartupInfo>
#include <KWindowSystem>

#include <QDBusConnection>
#include <QDBusMessage>

void KalendarUniqueAppHandler::loadCommandLineOptions(QCommandLineParser *parser)
{
}

int KalendarUniqueAppHandler::activate(const QStringList &args, const QString &workingDir)
{
    Q_UNUSED(workingDir)

    // Ensure part is loaded
    (void)plugin()->part();

    QDBusMessage message = QDBusMessage::createMethodCall(QStringLiteral("org.kde.kalendar"),
                                                          QStringLiteral("/Kalendar"),
                                                          QStringLiteral("org.kde.kalendar.Kalendar"),
                                                          QStringLiteral("handleCommandLine"));
    message.setArguments(QList<QVariant>() << (args));
    QDBusConnection::sessionBus().send(message);

    // Bring korganizer's plugin to front
    // This bit is duplicated from KUniqueApplication::newInstance()
    QWidget *mWidget = mainWidget();
    if (mWidget) {
        mWidget->show();
        KWindowSystem::forceActiveWindow(mWidget->winId());
        KStartupInfo::appStarted();
    }

    // Then ensure the part appears in kontact.
    // ALWAYS use the korganizer plugin; i.e. never show the todo nor journal
    // plugins when creating a new instance via the command line, even if
    // the command line options are empty; else we'd need to examine the
    // options and then figure out which plugin we should show.
    // kolab/issue3971
    plugin()->core()->selectPlugin(QStringLiteral("kontact_kalendarplugin"));
    return 0;
}
