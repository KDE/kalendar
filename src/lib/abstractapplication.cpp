// SPDX-FileCopyrightText: 2023 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "abstractapplication.h"
#include "commandbarfiltermodel.h"
#include <KAboutData>
#include <KAuthorized>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <KShortcutsDialog>
#include <QDebug>
#include <QGuiApplication>
#include <QMenu>

AbstractApplication::AbstractApplication(QObject *parent)
    : QObject(parent)
    , mCollection(new KActionCollection(parent))
{
}

AbstractApplication::~AbstractApplication()
{
    if (m_actionModel) {
        auto lastUsedActions = m_actionModel->lastUsedActions();
        auto cfg = KSharedConfig::openConfig();
        KConfigGroup cg(cfg, "General");
        cg.writeEntry("CommandBarLastUsedActions", lastUsedActions);
    }
}

/**
 * A helper function that takes a list of KActionCollection* and converts it
 * to KCommandBar::ActionGroup
 */
static QVector<KalCommandBarModel::ActionGroup> actionCollectionToActionGroup(const QVector<KActionCollection *> &actionCollections)
{
    using ActionGroup = KalCommandBarModel::ActionGroup;

    QVector<ActionGroup> actionList;
    actionList.reserve(actionCollections.size());

    for (const auto collection : actionCollections) {
        const QList<QAction *> collectionActions = collection->actions();
        const QString componentName = collection->componentDisplayName();

        ActionGroup ag;
        ag.name = componentName;
        ag.actions.reserve(collection->count());
        for (const auto action : collectionActions) {
            /**
             * If this action is a menu, fetch all its child actions
             * and skip the menu action itself
             */
            if (QMenu *menu = action->menu()) {
                const QList<QAction *> menuActions = menu->actions();

                ActionGroup menuActionGroup;
                menuActionGroup.name = KLocalizedString::removeAcceleratorMarker(action->text());
                menuActionGroup.actions.reserve(menuActions.size());
                for (const auto mAct : menuActions) {
                    if (mAct) {
                        menuActionGroup.actions.append(mAct);
                    }
                }

                /**
                 * If there were no actions in the menu, we
                 * add the menu to the list instead because it could
                 * be that the actions are created on demand i.e., aboutToShow()
                 */
                if (!menuActions.isEmpty()) {
                    actionList.append(menuActionGroup);
                    continue;
                }
            }

            if (action && !action->text().isEmpty()) {
                ag.actions.append(action);
            }
        }
        actionList.append(ag);
    }
    return actionList;
}

QSortFilterProxyModel *AbstractApplication::actionsModel()
{
    if (!m_proxyModel) {
        m_actionModel = new KalCommandBarModel(this);
        m_proxyModel = new CommandBarFilterModel(this);
        m_proxyModel->setSortRole(KalCommandBarModel::Score);
        m_proxyModel->setFilterRole(Qt::DisplayRole);
        m_proxyModel->setSourceModel(m_actionModel);
    }

    // setLastUsedActions
    auto cfg = KSharedConfig::openConfig();
    KConfigGroup cg(cfg, "General");

    QStringList actionNames = cg.readEntry(QStringLiteral("CommandBarLastUsedActions"), QStringList());

    m_actionModel->setLastUsedActions(actionNames);
    m_actionModel->refresh(actionCollectionToActionGroup(actionCollections()));
    return m_proxyModel;
}

void AbstractApplication::configureShortcuts()
{
    // TODO replace with QML version
    KShortcutsDialog dlg(KShortcutsEditor::ApplicationAction, KShortcutsEditor::LetterShortcutsAllowed, nullptr);
    dlg.setModal(true);
    const auto collections = actionCollections();
    for (const auto collection : collections) {
        dlg.addCollection(collection);
    }
    dlg.configure();
}

QAction *AbstractApplication::action(const QString &name)
{
    const auto collections = actionCollections();
    for (const auto collection : collections) {
        auto resultAction = collection->action(name);
        if (resultAction) {
            return resultAction;
        }
    }

    qWarning() << "Not found action for name" << name;

    return nullptr;
}

void AbstractApplication::setupActions()
{
    auto actionName = QLatin1String("open_kcommand_bar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openKCommandBarAction = mCollection->addAction(actionName, this, &AbstractApplication::openKCommandBarAction);
        openKCommandBarAction->setText(i18n("Open Command Bar"));
        openKCommandBarAction->setIcon(QIcon::fromTheme(QStringLiteral("new-command-alarm")));

        mCollection->addAction(openKCommandBarAction->objectName(), openKCommandBarAction);
        mCollection->setDefaultShortcut(openKCommandBarAction, QKeySequence(Qt::CTRL | Qt::ALT | Qt::Key_I));
    }

    actionName = QLatin1String("file_quit");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::quit(this, &AbstractApplication::quit, this);
        mCollection->addAction(action->objectName(), action);
    }

    actionName = QLatin1String("switch_application_language");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::switchApplicationLanguage(this, &AbstractApplication::openLanguageSwitcher, this);
        mCollection->addAction(action->objectName(), action);
    }

    actionName = QLatin1String("options_configure_keybinding");
    if (KAuthorized::authorizeAction(actionName)) {
        auto keyBindingsAction = KStandardAction::keyBindings(this, &AbstractApplication::configureShortcuts, this);
        mCollection->addAction(keyBindingsAction->objectName(), keyBindingsAction);
    }

    actionName = QLatin1String("open_about_page");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &AbstractApplication::openAboutPage);
        action->setText(i18n("About %1", KAboutData::applicationData().displayName()));
        action->setIcon(QIcon::fromTheme(QStringLiteral("help-about")));
    }

    actionName = QLatin1String("open_about_kde_page");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &AbstractApplication::openAboutKDEPage);
        action->setText(i18n("About KDE"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("kde")));
    }

    actionName = QLatin1String("options_configure");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::preferences(this, &AbstractApplication::openSettings, this);
        mCollection->addAction(action->objectName(), action);
    }

    actionName = QLatin1String("open_tag_manager");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openTagManagerAction = mCollection->addAction(actionName, this, &AbstractApplication::openTagManager);
        openTagManagerAction->setText(i18n("Manage Tags…"));
        openTagManagerAction->setIcon(QIcon::fromTheme(QStringLiteral("action-rss_tag")));
    }
}

void AbstractApplication::quit()
{
    qGuiApp->exit();
}
