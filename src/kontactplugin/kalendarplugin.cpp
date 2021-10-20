// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendarplugin.h"
#include "kalendar_uniqueapp.h"
#include "partinterface.h"

#include <KontactInterface/Core>

#include <KActionCollection>
#include <KLocalizedString>
#include <QAction>
#include <QIcon>

#include <QDBusConnection>
#include <QDropEvent>
#include <QStandardPaths>

EXPORT_KONTACT_PLUGIN_WITH_JSON(KalendarPlugin, "kalendarplugin.json")

KalendarPlugin::KalendarPlugin(KontactInterface::Core *core, const QVariantList &)
    : KontactInterface::Plugin(core, core, "kalendar", "kalendar")
{
    setComponentName(QStringLiteral("kalendar"), i18n("Kalendar"));

    auto action = new QAction(QIcon::fromTheme(QStringLiteral("appointment-new")), i18nc("@action:inmenu", "New Event..."), this);
    actionCollection()->addAction(QStringLiteral("new_event"), action);
    actionCollection()->setDefaultShortcut(action, QKeySequence(Qt::CTRL | Qt::SHIFT | Qt::Key_E));
    const QString str = i18nc("@info:status", "Create a new event");
    action->setStatusTip(str);
    action->setToolTip(str);

    action->setWhatsThis(i18nc("@info:whatsthis", "You will be presented with a dialog where you can create a new event item."));
    // connect(action, &QAction::triggered, this, &KalendarPlugin::slotNewEvent);
    insertNewAction(action);

    mUniqueAppWatcher = new KontactInterface::UniqueAppWatcher(new KontactInterface::UniqueAppHandlerFactory<KalendarUniqueAppHandler>(), this);
}

KalendarPlugin::~KalendarPlugin()
{
}

KParts::Part *KalendarPlugin::createPart()
{
    KParts::Part *part = loadPart();

    if (!part) {
        return nullptr;
    }

    mIface = new OrgKdeKalendarPartInterface(QStringLiteral("org.kde.kalendar"), QStringLiteral("/Kalendar"), QDBusConnection::sessionBus(), this);

    return part;
}

QStringList KalendarPlugin::invisibleToolbarActions() const
{
    QStringList invisible;
    invisible += QStringLiteral("new_event");
    invisible += QStringLiteral("new_todo");
    invisible += QStringLiteral("new_journal");

    invisible += QStringLiteral("view_todo");
    invisible += QStringLiteral("view_journal");
    return invisible;
}

OrgKdeKalendarPartInterface *KalendarPlugin::interface()
{
    if (!mIface) {
        (void)part();
    }
    Q_ASSERT(mIface);
    return mIface;
}

/*void KalendarPlugin::slotNewEvent()
{
    interface()->openEventEditor(QString());
}*/

bool KalendarPlugin::isRunningStandalone() const
{
    return mUniqueAppWatcher->isRunningStandalone();
}

#include "kalendarplugin.moc"
