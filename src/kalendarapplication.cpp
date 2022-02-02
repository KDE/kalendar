// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2017 Matthieu Gallien <matthieu_gallien@yahoo.fr>
// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "kalendarapplication.h"

#include "calendaradaptor.h"
#include "kalendar_debug.h"
#include "models/commandbarfiltermodel.h"
#include <CalendarSupport/Utils>
#include <KAuthorized>
#include <KConfigGroup>
#include <KFormat>
#include <KLocalizedString>
#include <KSharedConfig>
#include <KWindowConfig>
#include <KWindowSystem>
#include <KXmlGui/KShortcutsDialog>
#include <QGuiApplication>
#include <QMenu>
#include <QQuickWindow>
#include <QSortFilterProxyModel>
#include <QWindow>
#include <vector>

KalendarApplication::KalendarApplication(QObject *parent)
    : QObject(parent)
    , mCollection(parent)
    , mSortCollection(parent, i18n("Sort"))
    , m_viewGroup(new QActionGroup(this))
{
    mSortCollection.setComponentDisplayName(i18n("Sort"));
    setupActions();

    new CalendarAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Calendar"), this);

    KConfig cfg(QStringLiteral("defaultcalendarrc"));
    KConfigGroup grp(&cfg, QStringLiteral("General"));
    grp.writeEntry(QStringLiteral("ApplicationId"), QStringLiteral("org.kde.kalendar"));
}

KalendarApplication::~KalendarApplication()
{
    if (m_actionModel) {
        auto lastUsedActions = m_actionModel->lastUsedActions();
        auto cfg = KSharedConfig::openConfig();
        KConfigGroup cg(cfg, "General");
        cg.writeEntry("CommandBarLastUsedActions", lastUsedActions);
    }
}

QAction *KalendarApplication::action(const QString &name)
{
    auto resultAction = mCollection.action(name);

    if (resultAction) {
        return resultAction;
    }

    resultAction = mSortCollection.action(name);

    if (resultAction) {
        return resultAction;
    }
    return nullptr;
}

void KalendarApplication::setupActions()
{
    auto actionName = QLatin1String("options_configure_keybinding");
    if (KAuthorized::authorizeAction(actionName)) {
        auto keyBindingsAction = KStandardAction::keyBindings(this, &KalendarApplication::configureShortcuts, this);
        mCollection.addAction(keyBindingsAction->objectName(), keyBindingsAction);
    }

    actionName = QLatin1String("open_todo_view");
    QAction *openTodoAction = nullptr;
    if (KAuthorized::authorizeAction(actionName)) {
        openTodoAction = mCollection.addAction(actionName, this, &KalendarApplication::openTodoView);
        openTodoAction->setText(i18n("Tasks View"));
        openTodoAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-tasks")));
        openTodoAction->setCheckable(true);
        openTodoAction->setActionGroup(m_viewGroup);
        connect(openTodoAction, &QAction::toggled, this, [](bool checked) {
            if (checked) {
                KalendarConfig::setLastOpenedView(KalendarConfig::TodoView);
                KalendarConfig::self()->save();
            }
        });
        mCollection.setDefaultShortcut(openTodoAction, QKeySequence(i18n("Ctrl+6")));
    }

    actionName = QLatin1String("open_week_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openWeekAction = mCollection.addAction(actionName, this, &KalendarApplication::openWeekView);
        openWeekAction->setText(i18n("Week View"));
        openWeekAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-week")));
        openWeekAction->setCheckable(true);
        openWeekAction->setActionGroup(m_viewGroup);
        connect(openWeekAction, &QAction::toggled, this, [](bool checked) {
            if (checked) {
                KalendarConfig::setLastOpenedView(KalendarConfig::WeekView);
                KalendarConfig::self()->save();
            }
        });
        mCollection.setDefaultShortcut(openWeekAction, QKeySequence(i18n("Ctrl+2")));
    }

    actionName = QLatin1String("open_threeday_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openThreeDayAction = mCollection.addAction(actionName, this, &KalendarApplication::openThreeDayView);
        openThreeDayAction->setText(i18n("3 Day View"));
        openThreeDayAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-workweek")));
        openThreeDayAction->setCheckable(true);
        openThreeDayAction->setActionGroup(m_viewGroup);
        connect(openThreeDayAction, &QAction::toggled, this, [](bool checked) {
            if (checked) {
                KalendarConfig::setLastOpenedView(KalendarConfig::ThreeDayView);
                KalendarConfig::self()->save();
            }
        });
        mCollection.setDefaultShortcut(openThreeDayAction, QKeySequence(i18n("Ctrl+3")));
    }

    actionName = QLatin1String("open_day_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openDayAction = mCollection.addAction(actionName, this, &KalendarApplication::openDayView);
        openDayAction->setText(i18n("Day View"));
        openDayAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-day")));
        openDayAction->setCheckable(true);
        openDayAction->setActionGroup(m_viewGroup);
        connect(openDayAction, &QAction::toggled, this, [](bool checked) {
            if (checked) {
                KalendarConfig::setLastOpenedView(KalendarConfig::DayView);
                KalendarConfig::self()->save();
            }
        });
        mCollection.setDefaultShortcut(openDayAction, QKeySequence(i18n("Ctrl+4")));
    }

    actionName = QLatin1String("open_schedule_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openScheduleAction = mCollection.addAction(actionName, this, &KalendarApplication::openScheduleView);
        openScheduleAction->setText(i18n("Schedule View"));
        openScheduleAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-list")));
        openScheduleAction->setCheckable(true);
        openScheduleAction->setActionGroup(m_viewGroup);
        connect(openScheduleAction, &QAction::toggled, this, [](bool checked) {
            if (checked) {
                KalendarConfig::setLastOpenedView(KalendarConfig::ScheduleView);
                KalendarConfig::self()->save();
            }
        });
        mCollection.setDefaultShortcut(openScheduleAction, QKeySequence(i18n("Ctrl+5")));
    }

    actionName = QLatin1String("open_month_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openMonthAction = mCollection.addAction(actionName, this, &KalendarApplication::openMonthView);
        openMonthAction->setText(i18n("Month View"));
        openMonthAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-month")));
        openMonthAction->setCheckable(true);
        openMonthAction->setActionGroup(m_viewGroup);
        connect(openMonthAction, &QAction::toggled, this, [](bool checked) {
            if (checked) {
                KalendarConfig::setLastOpenedView(KalendarConfig::MonthView);
                KalendarConfig::self()->save();
            }
        });
        mCollection.setDefaultShortcut(openMonthAction, QKeySequence(i18n("Ctrl+1")));
    }

    actionName = QLatin1String("open_about_page");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &KalendarApplication::openAboutPage);
        action->setText(i18n("About Kalendar"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("help-about")));
    }

    actionName = QLatin1String("move_view_backwards");
    if (KAuthorized::authorizeAction(actionName)) {
        auto moveViewBackwardsAction = mCollection.addAction(actionName, this, &KalendarApplication::moveViewBackwards);
        moveViewBackwardsAction->setText(i18n("Backwards"));
        moveViewBackwardsAction->setIcon(QIcon::fromTheme(QStringLiteral("go-previous")));
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [moveViewBackwardsAction, openTodoAction]() {
                moveViewBackwardsAction->setEnabled(!openTodoAction->isChecked());
            });
            moveViewBackwardsAction->setEnabled(!openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("move_view_forwards");
    if (KAuthorized::authorizeAction(actionName)) {
        auto moveViewForwardsAction = mCollection.addAction(actionName, this, &KalendarApplication::moveViewForwards);
        moveViewForwardsAction->setText(i18n("Forwards"));
        moveViewForwardsAction->setIcon(QIcon::fromTheme(QStringLiteral("go-next")));
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [moveViewForwardsAction, openTodoAction]() {
                moveViewForwardsAction->setEnabled(!openTodoAction->isChecked());
            });
            moveViewForwardsAction->setEnabled(!openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("move_view_to_today");
    if (KAuthorized::authorizeAction(actionName)) {
        auto moveViewToTodayAction = mCollection.addAction(actionName, this, &KalendarApplication::moveViewToToday);
        moveViewToTodayAction->setText(i18n("To Today"));
        moveViewToTodayAction->setIcon(QIcon::fromTheme(QStringLiteral("go-jump-today")));
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [moveViewToTodayAction, openTodoAction]() {
                moveViewToTodayAction->setEnabled(!openTodoAction->isChecked());
            });
            moveViewToTodayAction->setEnabled(!openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("open_date_changer");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openDateChangerAction = mCollection.addAction(actionName, this, &KalendarApplication::openDateChanger);
        openDateChangerAction->setText(i18n("To Date…"));
        openDateChangerAction->setIcon(QIcon::fromTheme(QStringLiteral("change-date-symbolic")));
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [openDateChangerAction, openTodoAction]() {
                openDateChangerAction->setEnabled(!openTodoAction->isChecked());
            });
            openDateChangerAction->setEnabled(!openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("toggle_menubar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &KalendarApplication::toggleMenubar);
        action->setText(i18n("Show Menubar"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("show-menu")));
        action->setCheckable(true);
        action->setChecked(m_config->showMenubar());
        mCollection.setDefaultShortcut(action, QKeySequence(i18n("Ctrl+M")));
    }

    actionName = QLatin1String("create_event");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &KalendarApplication::createNewEvent);
        action->setText(i18n("New Event…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("resource-calendar-insert")));
    }

    actionName = QLatin1String("create_todo");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &KalendarApplication::createNewTodo);
        action->setText(i18n("New Task…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("view-task-add")));
    }

    actionName = QLatin1String("options_configure");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::preferences(this, &KalendarApplication::openSettings, this);
        mCollection.addAction(action->objectName(), action);
    }

    actionName = QLatin1String("open_tag_manager");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openTagManagerAction = mCollection.addAction(actionName, this, &KalendarApplication::openTagManager);
        openTagManagerAction->setText(i18n("Manage Tags…"));
        openTagManagerAction->setIcon(QIcon::fromTheme(QStringLiteral("action-rss_tag")));
    }

    actionName = QLatin1String("switch_application_language");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::switchApplicationLanguage(this, &KalendarApplication::openLanguageSwitcher, this);
        mCollection.addAction(action->objectName(), action);
    }

    actionName = QLatin1String("import_calendar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto importIcalAction = mCollection.addAction(actionName, this, &KalendarApplication::importCalendar);
        importIcalAction->setText(i18n("Import Calendar…"));
        importIcalAction->setIcon(QIcon::fromTheme(QStringLiteral("document-import-ocal")));
        connect(this, &KalendarApplication::importStarted, this, [importIcalAction]() {
            importIcalAction->setEnabled(false);
        });
        connect(this, &KalendarApplication::importFinished, this, [importIcalAction]() {
            importIcalAction->setEnabled(true);
        });
    }

    actionName = QLatin1String("file_quit");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::quit(this, &KalendarApplication::quit, this);
        mCollection.addAction(action->objectName(), action);
    }

    actionName = QLatin1String("edit_undo");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::undo(this, &KalendarApplication::undo, this);
        action->setEnabled(false);
        mCollection.addAction(action->objectName(), action);
    }
    actionName = QLatin1String("edit_redo");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::redo(this, &KalendarApplication::redo, this);
        action->setEnabled(false);
        mCollection.addAction(action->objectName(), action);
    }

    actionName = QLatin1String("todoview_sort_alphabetically");
    if (KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewAlphabeticallyAction = mSortCollection.addAction(actionName, this, &KalendarApplication::todoViewSortAlphabetically);
        sortTodoViewAlphabeticallyAction->setText(i18n("Alphabetically"));
        sortTodoViewAlphabeticallyAction->setIcon(QIcon::fromTheme(QStringLiteral("font")));
        sortTodoViewAlphabeticallyAction->setCheckable(true);
        sortTodoViewAlphabeticallyAction->setActionGroup(m_todoViewSortGroup);
        mSortCollection.addAction(sortTodoViewAlphabeticallyAction->objectName(), sortTodoViewAlphabeticallyAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [sortTodoViewAlphabeticallyAction, openTodoAction]() {
                sortTodoViewAlphabeticallyAction->setEnabled(openTodoAction->isChecked());
            });
            sortTodoViewAlphabeticallyAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_sort_by_due_date");
    if (KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewByDueDateAction = mSortCollection.addAction(actionName, this, &KalendarApplication::todoViewSortByDueDate);
        sortTodoViewByDueDateAction->setText(i18n("By Due Date"));
        sortTodoViewByDueDateAction->setIcon(QIcon::fromTheme(QStringLiteral("change-date-symbolic")));
        sortTodoViewByDueDateAction->setCheckable(true);
        sortTodoViewByDueDateAction->setActionGroup(m_todoViewSortGroup);
        mSortCollection.addAction(sortTodoViewByDueDateAction->objectName(), sortTodoViewByDueDateAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [sortTodoViewByDueDateAction, openTodoAction]() {
                sortTodoViewByDueDateAction->setEnabled(openTodoAction->isChecked());
            });
            sortTodoViewByDueDateAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_sort_by_priority");
    if (KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewByPriorityAction = mSortCollection.addAction(actionName, this, &KalendarApplication::todoViewSortByPriority);
        sortTodoViewByPriorityAction->setText(i18n("By Priority Level"));
        sortTodoViewByPriorityAction->setIcon(QIcon::fromTheme(QStringLiteral("emblem-important-symbolic")));
        sortTodoViewByPriorityAction->setCheckable(true);
        sortTodoViewByPriorityAction->setActionGroup(m_todoViewSortGroup);
        mSortCollection.addAction(sortTodoViewByPriorityAction->objectName(), sortTodoViewByPriorityAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [sortTodoViewByPriorityAction, openTodoAction]() {
                sortTodoViewByPriorityAction->setEnabled(openTodoAction->isChecked());
            });
            sortTodoViewByPriorityAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_order_ascending");
    if (KAuthorized::authorizeAction(actionName)) {
        auto orderTodoViewAscendingAction = mSortCollection.addAction(actionName, this, &KalendarApplication::todoViewOrderAscending);
        orderTodoViewAscendingAction->setText(i18n("Ascending order"));
        orderTodoViewAscendingAction->setIcon(QIcon::fromTheme(QStringLiteral("view-sort-ascending")));
        orderTodoViewAscendingAction->setCheckable(true);
        orderTodoViewAscendingAction->setActionGroup(m_todoViewOrderGroup);
        mSortCollection.addAction(orderTodoViewAscendingAction->objectName(), orderTodoViewAscendingAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [orderTodoViewAscendingAction, openTodoAction]() {
                orderTodoViewAscendingAction->setEnabled(openTodoAction->isChecked());
            });
            orderTodoViewAscendingAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_order_descending");
    if (KAuthorized::authorizeAction(actionName)) {
        auto orderTodoViewDescendingAction = mSortCollection.addAction(actionName, this, &KalendarApplication::todoViewOrderDescending);
        orderTodoViewDescendingAction->setText(i18n("Descending Order"));
        orderTodoViewDescendingAction->setIcon(QIcon::fromTheme(QStringLiteral("view-sort-descending")));
        orderTodoViewDescendingAction->setCheckable(true);
        orderTodoViewDescendingAction->setActionGroup(m_todoViewOrderGroup);
        mSortCollection.addAction(orderTodoViewDescendingAction->objectName(), orderTodoViewDescendingAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [orderTodoViewDescendingAction, openTodoAction]() {
                orderTodoViewDescendingAction->setEnabled(openTodoAction->isChecked());
            });
            orderTodoViewDescendingAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_show_completed");
    if (KAuthorized::authorizeAction(actionName)) {
        auto todoViewShowCompletedAction = mSortCollection.addAction(actionName, this, &KalendarApplication::todoViewShowCompleted);
        todoViewShowCompletedAction->setText(i18n("Show Completed Tasks"));
        todoViewShowCompletedAction->setIcon(QIcon::fromTheme(QStringLiteral("task-complete")));
        mSortCollection.addAction(todoViewShowCompletedAction->objectName(), todoViewShowCompletedAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [todoViewShowCompletedAction, openTodoAction]() {
                todoViewShowCompletedAction->setEnabled(openTodoAction->isChecked());
            });
            todoViewShowCompletedAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("open_kcommand_bar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openKCommandBarAction = mCollection.addAction(actionName, this, &KalendarApplication::openKCommandBarAction);
        openKCommandBarAction->setText(i18n("Open Command Bar"));
        openKCommandBarAction->setIcon(QIcon::fromTheme(QStringLiteral("new-command-alarm")));

        mCollection.addAction(openKCommandBarAction->objectName(), openKCommandBarAction);
        mCollection.setDefaultShortcut(openKCommandBarAction, QKeySequence(Qt::CTRL | Qt::ALT | Qt::Key_I));
    }

    actionName = QLatin1String("refresh_all_calendars");
    if (KAuthorized::authorizeAction(actionName)) {
        auto refreshAllAction = mCollection.addAction(actionName, this, &KalendarApplication::refreshAllCalendars);
        refreshAllAction->setText(i18n("Refresh All Calendars"));
        refreshAllAction->setIcon(QIcon::fromTheme(QStringLiteral("view-refresh")));

        mCollection.addAction(refreshAllAction->objectName(), refreshAllAction);
        mCollection.setDefaultShortcut(refreshAllAction, QKeySequence(QKeySequence::Refresh));
    }

    mSortCollection.readSettings();
    mCollection.readSettings();
}

void KalendarApplication::configureShortcuts()
{
    // TODO replace with QML version
    KShortcutsDialog dlg(KShortcutsEditor::ApplicationAction, KShortcutsEditor::LetterShortcutsAllowed, nullptr);
    dlg.setModal(true);
    dlg.addCollection(&mCollection);
    dlg.addCollection(&mSortCollection);
    dlg.configure();
}

void KalendarApplication::setWindow(QWindow *window)
{
    if (m_window == window) {
        return;
    }
    m_window = window;
    Q_EMIT windowChanged();
}

QWindow *KalendarApplication::window() const
{
    return m_window;
}

QString KalendarApplication::iconName(const QIcon &icon) const
{
    return icon.name();
}

//---- KCommandBar QML licensed LGPL

/**
 * A helper function that takes a list of KActionCollection* and converts it
 * to KCommandBar::ActionGroup
 */
static QVector<KalCommandBarModel::ActionGroup> actionCollectionToActionGroup(const std::vector<KActionCollection *> &actionCollections)
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

QSortFilterProxyModel *KalendarApplication::actionsModel()
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
    std::vector<KActionCollection *> actionCollections = {&mCollection, &mSortCollection};
    m_actionModel->refresh(actionCollectionToActionGroup(actionCollections));
    return m_proxyModel;
}

void KalendarApplication::setCalendar(Akonadi::ETMCalendar::Ptr calendar)
{
    m_calendar = calendar;
}

void KalendarApplication::importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId)
{
    if (!m_calendar) {
        return;
    }

    auto importer = new Akonadi::ICalImporter(m_calendar->incidenceChanger());
    bool jobStarted;

    if (merge) {
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &KalendarApplication::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &KalendarApplication::importIntoExistingFinished);
        auto collection = m_calendar->collection(collectionId);
        jobStarted = importer->importIntoExistingResource(url, collection);
    } else {
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &KalendarApplication::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &KalendarApplication::importIntoNewFinished);
        jobStarted = importer->importIntoNewResource(url.path());
    }

    if (jobStarted) {
        Q_EMIT importStarted();
    } else {
        // empty error message means user canceled.
        if (!importer->errorMessage().isEmpty()) {
            qCDebug(KALENDAR_LOG) << i18n("An error occurred: %1", importer->errorMessage());
            m_importErrorMessage = importer->errorMessage();
            Q_EMIT importErrorMessageChanged();
        }
    }
}

QString KalendarApplication::importErrorMessage()
{
    return m_importErrorMessage;
}

void KalendarApplication::saveWindowGeometry(QQuickWindow *window)
{
    KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    KConfigGroup windowGroup(&dataResource, QStringLiteral("Window"));
    KWindowConfig::saveWindowPosition(window, windowGroup);
    KWindowConfig::saveWindowSize(window, windowGroup);
    dataResource.sync();
}

void KalendarApplication::showIncidenceByUid(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken)
{
    const auto incidence = m_calendar->incidence(uid);
    if (!incidence) {
        return;
    }

    const auto collection = m_calendar->item(incidence).parentCollection();
    const auto incidenceEnd = incidence->endDateForStart(occurrence);
    KFormat format;
    KCalendarCore::Duration duration(occurrence, incidenceEnd);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = rColorsConfig.keyList();

    QColor incidenceColor;

    for (const QString &key : colorKeyList) {
        if (key == QString::number(collection.id())) {
            incidenceColor = rColorsConfig.readEntry(key, QColor("blue"));
        }
    }

    auto incidenceData = QVariantMap{
        {QStringLiteral("text"), incidence->summary()},
        {QStringLiteral("description"), incidence->description()},
        {QStringLiteral("location"), incidence->location()},
        {QStringLiteral("startTime"), occurrence},
        {QStringLiteral("endTime"), incidenceEnd},
        {QStringLiteral("allDay"), incidence->allDay()},
        {QStringLiteral("todoCompleted"), false},
        {QStringLiteral("priority"), incidence->priority()},
        {QStringLiteral("durationString"), duration.asSeconds() > 0 ? format.formatSpelloutDuration(duration.asSeconds() * 1000) : QString()},
        {QStringLiteral("recurs"), incidence->recurs()},
        {QStringLiteral("hasReminders"), incidence->alarms().length() > 0},
        {QStringLiteral("isOverdue"), false},
        {QStringLiteral("isReadOnly"), collection.rights().testFlag(Akonadi::Collection::ReadOnly)},
        {QStringLiteral("color"), QVariant::fromValue(incidenceColor)},
        {QStringLiteral("collectionId"), collection.id()},
        {QStringLiteral("incidenceId"), uid},
        {QStringLiteral("incidenceType"), incidence->type()},
        {QStringLiteral("incidenceTypeStr"), incidence->typeStr()},
        {QStringLiteral("incidenceTypeIcon"), incidence->iconName()},
        {QStringLiteral("incidencePtr"), QVariant::fromValue(incidence)},
    };

    if (incidence->type() == KCalendarCore::Incidence::TypeTodo) {
        const auto todo = incidence.staticCast<KCalendarCore::Todo>();
        incidenceData[QStringLiteral("todoCompleted")] = todo->isCompleted();
        incidenceData[QStringLiteral("isOverdue")] = todo->isOverdue();
    }

    Q_EMIT openIncidence(incidenceData, occurrence);

    KWindowSystem::setCurrentXdgActivationToken(xdgActivationToken);
    QWindow *window = QGuiApplication::topLevelWindows().isEmpty() ? nullptr : QGuiApplication::topLevelWindows().at(0);
    if (window) {
        KWindowSystem::activateWindow(window);
        window->raise();
    }
}

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr);
