// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2017 Matthieu Gallien <matthieu_gallien@yahoo.fr>
// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "calendarapplication.h"

#include <KAuthorized>
#include <KConfigGroup>
#include <KFormat>
#include <KLocalizedString>
#include <KSharedConfig>
#include <KShortcutsDialog>
#include <KWindowConfig>
#include <KWindowSystem>
#include <QGuiApplication>
#include <QMenu>
#include <QQuickWindow>
#include <QSortFilterProxyModel>
#include <vector>

#include "calendaradaptor.h"
#include "kalendar_calendar_debug.h"
#include "mousetracker.h"

CalendarApplication::CalendarApplication(QObject *parent)
    : AbstractApplication(parent)
    , mSortCollection(new KActionCollection(parent, i18n("Sort")))
    , m_viewGroup(new QActionGroup(this))
    , m_config(new CalendarConfig(this))
{
    mSortCollection->setComponentDisplayName(i18n("Sort"));
    setupActions();

    new CalendarAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Calendar"), this);

    KConfig cfg(QStringLiteral("defaultcalendarrc"));
    KConfigGroup grp(&cfg, QStringLiteral("General"));
    grp.writeEntry(QStringLiteral("ApplicationId"), QStringLiteral("org.kde.kalendar"));

    connect(MouseTracker::instance(), &MouseTracker::mouseButtonReleased, this, &CalendarApplication::handleMouseViewNavButtons);
}

CalendarApplication::~CalendarApplication()
{
}

void CalendarApplication::setupActions()
{
    AbstractApplication::setupActions();

    auto actionName = QLatin1String("open_todo_view");
    QAction *openTodoAction = nullptr;
    if (KAuthorized::authorizeAction(actionName)) {
        openTodoAction = mCollection->addAction(actionName, this, &CalendarApplication::openTodoView);
        openTodoAction->setText(i18n("Tasks View"));
        openTodoAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-tasks")));
        openTodoAction->setCheckable(true);
        openTodoAction->setActionGroup(m_viewGroup);
        connect(openTodoAction, &QAction::toggled, this, [this](bool checked) {
            if (checked) {
                m_config->setLastOpenedView(CalendarConfig::TodoView);
                m_config->save();
            }
        });
        mCollection->setDefaultShortcut(openTodoAction, QKeySequence(i18n("Ctrl+6")));
    }

    actionName = QLatin1String("open_week_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openWeekAction = mCollection->addAction(actionName, this, &CalendarApplication::openWeekView);
        openWeekAction->setText(i18n("Week View"));
        openWeekAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-week")));
        openWeekAction->setCheckable(true);
        openWeekAction->setActionGroup(m_viewGroup);
        connect(openWeekAction, &QAction::toggled, this, [this](bool checked) {
            if (checked) {
                m_config->setLastOpenedView(CalendarConfig::WeekView);
                m_config->save();
            }
        });
        mCollection->setDefaultShortcut(openWeekAction, QKeySequence(i18n("Ctrl+2")));
    }

    actionName = QLatin1String("open_threeday_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openThreeDayAction = mCollection->addAction(actionName, this, &CalendarApplication::openThreeDayView);
        openThreeDayAction->setText(i18n("3 Day View"));
        openThreeDayAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-workweek")));
        openThreeDayAction->setCheckable(true);
        openThreeDayAction->setActionGroup(m_viewGroup);
        connect(openThreeDayAction, &QAction::toggled, this, [this](bool checked) {
            if (checked) {
                m_config->setLastOpenedView(CalendarConfig::ThreeDayView);
                m_config->save();
            }
        });
        mCollection->setDefaultShortcut(openThreeDayAction, QKeySequence(i18n("Ctrl+3")));
    }

    actionName = QLatin1String("open_day_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openDayAction = mCollection->addAction(actionName, this, &CalendarApplication::openDayView);
        openDayAction->setText(i18n("Day View"));
        openDayAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-day")));
        openDayAction->setCheckable(true);
        openDayAction->setActionGroup(m_viewGroup);
        connect(openDayAction, &QAction::toggled, this, [this](bool checked) {
            if (checked) {
                m_config->setLastOpenedView(CalendarConfig::DayView);
                m_config->save();
            }
        });
        mCollection->setDefaultShortcut(openDayAction, QKeySequence(i18n("Ctrl+4")));
    }

    actionName = QLatin1String("open_schedule_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openScheduleAction = mCollection->addAction(actionName, this, &CalendarApplication::openScheduleView);
        openScheduleAction->setText(i18n("Schedule View"));
        openScheduleAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-list")));
        openScheduleAction->setCheckable(true);
        openScheduleAction->setActionGroup(m_viewGroup);
        connect(openScheduleAction, &QAction::toggled, this, [this](bool checked) {
            if (checked) {
                m_config->setLastOpenedView(CalendarConfig::ScheduleView);
                m_config->save();
            }
        });
        mCollection->setDefaultShortcut(openScheduleAction, QKeySequence(i18n("Ctrl+5")));
    }

    actionName = QLatin1String("open_month_view");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openMonthAction = mCollection->addAction(actionName, this, &CalendarApplication::openMonthView);
        openMonthAction->setText(i18n("Month View"));
        openMonthAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-month")));
        openMonthAction->setCheckable(true);
        openMonthAction->setActionGroup(m_viewGroup);
        connect(openMonthAction, &QAction::toggled, this, [this](bool checked) {
            if (checked) {
                m_config->setLastOpenedView(CalendarConfig::MonthView);
                m_config->save();
            }
        });
        mCollection->setDefaultShortcut(openMonthAction, QKeySequence(i18n("Ctrl+1")));
    }

    actionName = QLatin1String("open_about_page");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &CalendarApplication::openAboutPage);
        action->setText(i18n("About Kalendar"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("help-about")));
    }

    actionName = QLatin1String("move_view_backwards");
    if (KAuthorized::authorizeAction(actionName)) {
        auto moveViewBackwardsAction = mCollection->addAction(actionName, this, &CalendarApplication::moveViewBackwards);
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
        auto moveViewForwardsAction = mCollection->addAction(actionName, this, &CalendarApplication::moveViewForwards);
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
        auto moveViewToTodayAction = mCollection->addAction(actionName, this, &CalendarApplication::moveViewToToday);
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
        auto openDateChangerAction = mCollection->addAction(actionName, this, &CalendarApplication::openDateChanger);
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
        auto action = mCollection->addAction(actionName, this, &CalendarApplication::toggleMenubar);
        action->setText(i18n("Show Menubar"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("show-menu")));
        action->setCheckable(true);
        action->setChecked(m_config->showMenubar());
        mCollection->setDefaultShortcut(action, QKeySequence(i18n("Ctrl+M")));
    }

    actionName = QLatin1String("create_event");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &CalendarApplication::createNewEvent);
        action->setText(i18n("New Event…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("resource-calendar-insert")));
    }

    actionName = QLatin1String("create_todo");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection->addAction(actionName, this, &CalendarApplication::createNewTodo);
        action->setText(i18n("New Task…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("view-task-add")));
    }


    actionName = QLatin1String("options_configure_schedule");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &CalendarApplication::configureSchedule);
        action->setText(i18n("Configure Schedule…"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-month")));
    }

    actionName = QLatin1String("options_configure");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::preferences(this, &CalendarApplication::openSettings, this);
        mCollection.addAction(action->objectName(), action);
    }

    actionName = QLatin1String("open_tag_manager");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openTagManagerAction = mCollection.addAction(actionName, this, &CalendarApplication::openTagManager);
        openTagManagerAction->setText(i18n("Manage Tags…"));
        openTagManagerAction->setIcon(QIcon::fromTheme(QStringLiteral("action-rss_tag")));
    }

    actionName = QLatin1String("switch_application_language");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::switchApplicationLanguage(this, &CalendarApplication::openLanguageSwitcher, this);
        mCollection->addAction(action->objectName(), action);
    }

    actionName = QLatin1String("import_calendar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto importIcalAction = mCollection->addAction(actionName, this, &CalendarApplication::importCalendar);
        importIcalAction->setText(i18n("Import Calendar…"));
        importIcalAction->setIcon(QIcon::fromTheme(QStringLiteral("document-import-ocal")));
        connect(this, &CalendarApplication::importStarted, this, [importIcalAction]() {
            importIcalAction->setEnabled(false);
        });
        connect(this, &CalendarApplication::importFinished, this, [importIcalAction]() {
            importIcalAction->setEnabled(true);
        });
    }

    actionName = QLatin1String("edit_undo");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::undo(this, &CalendarApplication::undo, this);
        action->setEnabled(false);
        mCollection->addAction(action->objectName(), action);
    }
    actionName = QLatin1String("edit_redo");
    if (KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::redo(this, &CalendarApplication::redo, this);
        action->setEnabled(false);
        mCollection->addAction(action->objectName(), action);
    }

    actionName = QLatin1String("todoview_sort_alphabetically");
    if (KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewAlphabeticallyAction = mSortCollection->addAction(actionName, this, &CalendarApplication::todoViewSortAlphabetically);
        sortTodoViewAlphabeticallyAction->setText(i18n("Alphabetically"));
        sortTodoViewAlphabeticallyAction->setIcon(QIcon::fromTheme(QStringLiteral("font")));
        sortTodoViewAlphabeticallyAction->setCheckable(true);
        sortTodoViewAlphabeticallyAction->setActionGroup(m_todoViewSortGroup);
        mSortCollection->addAction(sortTodoViewAlphabeticallyAction->objectName(), sortTodoViewAlphabeticallyAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [sortTodoViewAlphabeticallyAction, openTodoAction]() {
                sortTodoViewAlphabeticallyAction->setEnabled(openTodoAction->isChecked());
            });
            sortTodoViewAlphabeticallyAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_sort_by_due_date");
    if (KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewByDueDateAction = mSortCollection->addAction(actionName, this, &CalendarApplication::todoViewSortByDueDate);
        sortTodoViewByDueDateAction->setText(i18n("By Due Date"));
        sortTodoViewByDueDateAction->setIcon(QIcon::fromTheme(QStringLiteral("change-date-symbolic")));
        sortTodoViewByDueDateAction->setCheckable(true);
        sortTodoViewByDueDateAction->setActionGroup(m_todoViewSortGroup);
        mSortCollection->addAction(sortTodoViewByDueDateAction->objectName(), sortTodoViewByDueDateAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [sortTodoViewByDueDateAction, openTodoAction]() {
                sortTodoViewByDueDateAction->setEnabled(openTodoAction->isChecked());
            });
            sortTodoViewByDueDateAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_sort_by_priority");
    if (KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewByPriorityAction = mSortCollection->addAction(actionName, this, &CalendarApplication::todoViewSortByPriority);
        sortTodoViewByPriorityAction->setText(i18n("By Priority Level"));
        sortTodoViewByPriorityAction->setIcon(QIcon::fromTheme(QStringLiteral("emblem-important-symbolic")));
        sortTodoViewByPriorityAction->setCheckable(true);
        sortTodoViewByPriorityAction->setActionGroup(m_todoViewSortGroup);
        mSortCollection->addAction(sortTodoViewByPriorityAction->objectName(), sortTodoViewByPriorityAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [sortTodoViewByPriorityAction, openTodoAction]() {
                sortTodoViewByPriorityAction->setEnabled(openTodoAction->isChecked());
            });
            sortTodoViewByPriorityAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_order_ascending");
    if (KAuthorized::authorizeAction(actionName)) {
        auto orderTodoViewAscendingAction = mSortCollection->addAction(actionName, this, &CalendarApplication::todoViewOrderAscending);
        orderTodoViewAscendingAction->setText(i18n("Ascending order"));
        orderTodoViewAscendingAction->setIcon(QIcon::fromTheme(QStringLiteral("view-sort-ascending")));
        orderTodoViewAscendingAction->setCheckable(true);
        orderTodoViewAscendingAction->setActionGroup(m_todoViewOrderGroup);
        mSortCollection->addAction(orderTodoViewAscendingAction->objectName(), orderTodoViewAscendingAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [orderTodoViewAscendingAction, openTodoAction]() {
                orderTodoViewAscendingAction->setEnabled(openTodoAction->isChecked());
            });
            orderTodoViewAscendingAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_order_descending");
    if (KAuthorized::authorizeAction(actionName)) {
        auto orderTodoViewDescendingAction = mSortCollection->addAction(actionName, this, &CalendarApplication::todoViewOrderDescending);
        orderTodoViewDescendingAction->setText(i18n("Descending Order"));
        orderTodoViewDescendingAction->setIcon(QIcon::fromTheme(QStringLiteral("view-sort-descending")));
        orderTodoViewDescendingAction->setCheckable(true);
        orderTodoViewDescendingAction->setActionGroup(m_todoViewOrderGroup);
        mSortCollection->addAction(orderTodoViewDescendingAction->objectName(), orderTodoViewDescendingAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [orderTodoViewDescendingAction, openTodoAction]() {
                orderTodoViewDescendingAction->setEnabled(openTodoAction->isChecked());
            });
            orderTodoViewDescendingAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("todoview_show_completed");
    if (KAuthorized::authorizeAction(actionName)) {
        auto todoViewShowCompletedAction = mSortCollection->addAction(actionName, this, &CalendarApplication::todoViewShowCompleted);
        todoViewShowCompletedAction->setText(i18n("Show Completed Tasks"));
        todoViewShowCompletedAction->setIcon(QIcon::fromTheme(QStringLiteral("task-complete")));
        mSortCollection->addAction(todoViewShowCompletedAction->objectName(), todoViewShowCompletedAction);
        if (openTodoAction) {
            connect(openTodoAction, &QAction::changed, this, [todoViewShowCompletedAction, openTodoAction]() {
                todoViewShowCompletedAction->setEnabled(openTodoAction->isChecked());
            });
            todoViewShowCompletedAction->setEnabled(openTodoAction->isChecked());
        }
    }

    actionName = QLatin1String("open_kcommand_bar");
    if (KAuthorized::authorizeAction(actionName)) {
        auto openKCommandBarAction = mCollection->addAction(actionName, this, &CalendarApplication::openKCommandBarAction);
        openKCommandBarAction->setText(i18n("Open Command Bar"));
        openKCommandBarAction->setIcon(QIcon::fromTheme(QStringLiteral("new-command-alarm")));

        mCollection->addAction(openKCommandBarAction->objectName(), openKCommandBarAction);
        mCollection->setDefaultShortcut(openKCommandBarAction, QKeySequence(Qt::CTRL | Qt::ALT | Qt::Key_I));
    }

    actionName = QLatin1String("refresh_all");
    if (KAuthorized::authorizeAction(actionName)) {
        auto refreshAllAction = mCollection->addAction(actionName, this, &CalendarApplication::refreshAll);
        refreshAllAction->setText(i18n("Refresh All"));
        refreshAllAction->setIcon(QIcon::fromTheme(QStringLiteral("view-refresh")));

        mCollection->addAction(refreshAllAction->objectName(), refreshAllAction);
        mCollection->setDefaultShortcut(refreshAllAction, QKeySequence(QKeySequence::Refresh));
    }

    mSortCollection->readSettings();
    mCollection->readSettings();
}

void CalendarApplication::setWindow(QWindow *window)
{
    if (m_window == window) {
        return;
    }
    m_window = window;
    Q_EMIT windowChanged();
}

QWindow *CalendarApplication::window() const
{
    return m_window;
}

void CalendarApplication::setCalendar(Akonadi::ETMCalendar::Ptr calendar)
{
    m_calendar = calendar;
}

void CalendarApplication::importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId)
{
    if (!m_calendar) {
        return;
    }

    auto importer = new Akonadi::ICalImporter(m_calendar->incidenceChanger());
    bool jobStarted;

    if (merge) {
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &CalendarApplication::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &CalendarApplication::importIntoExistingFinished);
        auto collection = m_calendar->collection(collectionId);
        jobStarted = importer->importIntoExistingResource(url, collection);
    } else {
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &CalendarApplication::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &CalendarApplication::importIntoNewFinished);
        jobStarted = importer->importIntoNewResource(url.path());
    }

    if (jobStarted) {
        Q_EMIT importStarted();
    } else {
        // empty error message means user canceled.
        if (!importer->errorMessage().isEmpty()) {
            qCDebug(KALENDAR_CALENDAR_LOG) << i18n("An error occurred: %1", importer->errorMessage());
            m_importErrorMessage = importer->errorMessage();
            Q_EMIT importErrorMessageChanged();
        }
    }
}

QString CalendarApplication::importErrorMessage()
{
    return m_importErrorMessage;
}

void CalendarApplication::saveWindowGeometry(QQuickWindow *window)
{
    KConfig dataResource(QStringLiteral("data"), KConfig::SimpleConfig, QStandardPaths::AppDataLocation);
    KConfigGroup windowGroup(&dataResource, QStringLiteral("Window"));
    KWindowConfig::saveWindowPosition(window, windowGroup);
    KWindowConfig::saveWindowSize(window, windowGroup);
    dataResource.sync();
}

void CalendarApplication::showIncidenceByUid(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken)
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

void CalendarApplication::handleMouseViewNavButtons(const Qt::MouseButton pressedButton)
{
    switch (pressedButton) {
    case Qt::MouseButton::BackButton:
        mCollection->action(QStringLiteral("move_view_backwards"))->trigger();
        break;
    case Qt::MouseButton::ForwardButton:
        mCollection->action(QStringLiteral("move_view_forwards"))->trigger();
        break;
    default:
        break;
    }
}

QVector<KActionCollection *> CalendarApplication::actionCollections() const
{
    return {mCollection, mSortCollection};
}

void CalendarApplication::toggleMenubar()
{
    m_config->setShowMenubar(!m_config->showMenubar());
    m_config->save();
}

bool CalendarApplication::showMenubar() const
{
    return m_config->showMenubar();
}

#ifndef UNITY_CMAKE_SUPPORT
Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
#endif
