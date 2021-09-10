// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2017 Matthieu Gallien <matthieu_gallien@yahoo.fr>
// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "kalendarapplication.h"

#include <KXmlGui/KShortcutsDialog>
#include <KAuthorized>
#include <KLocalizedString>
#include <QWindow>
#include <vector>

KalendarApplication::KalendarApplication(QObject *parent)
    : QObject(parent)
    , mCollection(parent)
    , m_viewGroup(new QActionGroup(this))
{
}

QAction *KalendarApplication::action(const QString& name)
{
    auto resultAction = mCollection.action(name);

    if (!resultAction) {
        setupActions(name);
        resultAction = mCollection.action(name);
    }

    return resultAction;
}

void KalendarApplication::setupActions(const QString &actionName)
{
    if (actionName == QLatin1String("options_configure_keybinding") && KAuthorized::authorizeAction(actionName)) {
        auto keyBindingsAction = KStandardAction::keyBindings(this, &KalendarApplication::configureShortcuts, this);
        mCollection.addAction(keyBindingsAction->objectName(), keyBindingsAction);
    }

    if (actionName == QLatin1String("open_todo_view") && KAuthorized::authorizeAction(actionName)) {
        auto openTodoAction = mCollection.addAction(actionName, this, &KalendarApplication::openTodoView);
        openTodoAction->setText(i18n("Todo View"));
        openTodoAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-list")));
        openTodoAction->setCheckable(true);
        openTodoAction->setActionGroup(m_viewGroup);
        mCollection.setDefaultShortcut(openTodoAction, QKeySequence(i18n("Ctrl+3")));
    }

    if (actionName == QLatin1String("open_schedule_view") && KAuthorized::authorizeAction(actionName)) {
        auto openScheduleAction = mCollection.addAction(actionName, this, &KalendarApplication::openScheduleView);
        openScheduleAction->setText(i18n("Schedule View"));
        openScheduleAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-list")));
        openScheduleAction->setCheckable(true);
        openScheduleAction->setActionGroup(m_viewGroup);
        mCollection.setDefaultShortcut(openScheduleAction, QKeySequence(i18n("Ctrl+2")));
    }

    if (actionName == QLatin1String("open_month_view") && KAuthorized::authorizeAction(actionName)) {
        auto openMonthAction = mCollection.addAction(actionName, this, &KalendarApplication::openMonthView);
        openMonthAction->setText(i18n("Month View"));
        openMonthAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar")));
        openMonthAction->setCheckable(true);
        openMonthAction->setActionGroup(m_viewGroup);
        mCollection.setDefaultShortcut(openMonthAction, QKeySequence(i18n("Ctrl+1")));
    }

    if (actionName == QLatin1String("create_event") && KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &KalendarApplication::createNewEvent);
        action->setText(i18n("New Event"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("resource-calendar-insert")));
    }

    if (actionName == QLatin1String("create_todo") && KAuthorized::authorizeAction(actionName)) {
        auto action = mCollection.addAction(actionName, this, &KalendarApplication::createNewTodo);
        action->setText(i18n("New Todo"));
        action->setIcon(QIcon::fromTheme(QStringLiteral("view-task-add")));
    }

    if (actionName == QLatin1String("options_configure") && KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::preferences(this, &KalendarApplication::openSettings, this);
        mCollection.addAction(action->objectName(), action);
    }

    if (actionName == QLatin1String("switch_application_language") && KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::switchApplicationLanguage(this, &KalendarApplication::openLanguageSwitcher, this);
        mCollection.addAction(action->objectName(), action);
    }

    if (actionName == QLatin1String("file_quit") && KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::quit(this, &KalendarApplication::quit, this);
        mCollection.addAction(action->objectName(), action);
    }

    if (actionName == QLatin1String("edit_undo") && KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::undo(this, &KalendarApplication::undo, this);
        action->setEnabled(false);
        mCollection.addAction(action->objectName(), action);
    }

    if (actionName == QLatin1String("edit_redo") && KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::redo(this, &KalendarApplication::redo, this);
        action->setEnabled(false);
        mCollection.addAction(action->objectName(), action);
    }

    if (actionName == QLatin1String("todoview_sort_alphabetically") && KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewAlphabeticallyAction = mCollection.addAction(actionName, this, &KalendarApplication::todoViewSortAlphabetically);
        sortTodoViewAlphabeticallyAction->setText(i18n("Alphabetically"));
        sortTodoViewAlphabeticallyAction->setIcon(QIcon::fromTheme(QStringLiteral("font")));
        sortTodoViewAlphabeticallyAction->setCheckable(true);
        sortTodoViewAlphabeticallyAction->setActionGroup(m_todoViewSortGroup);
        mCollection.addAction(sortTodoViewAlphabeticallyAction->objectName(), sortTodoViewAlphabeticallyAction);
    }

    if (actionName == QLatin1String("todoview_sort_by_due_date") && KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewByDueDateAction = mCollection.addAction(actionName, this, &KalendarApplication::todoViewSortByDueDate);
        sortTodoViewByDueDateAction->setText(i18n("By due date"));
        sortTodoViewByDueDateAction->setIcon(QIcon::fromTheme(QStringLiteral("change-date-symbolic")));
        sortTodoViewByDueDateAction->setCheckable(true);
        sortTodoViewByDueDateAction->setActionGroup(m_todoViewSortGroup);
        mCollection.addAction(sortTodoViewByDueDateAction->objectName(), sortTodoViewByDueDateAction);
    }

    if (actionName == QLatin1String("todoview_sort_by_priority") && KAuthorized::authorizeAction(actionName)) {
        auto sortTodoViewByPriorityAction = mCollection.addAction(actionName, this, &KalendarApplication::todoViewSortByPriority);
        sortTodoViewByPriorityAction->setText(i18n("By priority level"));
        sortTodoViewByPriorityAction->setIcon(QIcon::fromTheme(QStringLiteral("emblem-important-symbolic")));
        sortTodoViewByPriorityAction->setCheckable(true);
        sortTodoViewByPriorityAction->setActionGroup(m_todoViewSortGroup);
        mCollection.addAction(sortTodoViewByPriorityAction->objectName(), sortTodoViewByPriorityAction);
    }

    if (actionName == QLatin1String("todoview_order_ascending") && KAuthorized::authorizeAction(actionName)) {
        auto orderTodoViewAscendingAction = mCollection.addAction(actionName, this, &KalendarApplication::todoViewOrderAscending);
        orderTodoViewAscendingAction->setText(i18n("Ascending order"));
        orderTodoViewAscendingAction->setIcon(QIcon::fromTheme(QStringLiteral("view-sort-ascending")));
        orderTodoViewAscendingAction->setCheckable(true);
        orderTodoViewAscendingAction->setActionGroup(m_todoViewOrderGroup);
        mCollection.addAction(orderTodoViewAscendingAction->objectName(), orderTodoViewAscendingAction);
    }

    if (actionName == QLatin1String("todoview_order_descending") && KAuthorized::authorizeAction(actionName)) {
        auto orderTodoViewDescendingAction = mCollection.addAction(actionName, this, &KalendarApplication::todoViewOrderDescending);
        orderTodoViewDescendingAction->setText(i18n("Descending order"));
        orderTodoViewDescendingAction->setIcon(QIcon::fromTheme(QStringLiteral("view-sort-descending")));
        orderTodoViewDescendingAction->setCheckable(true);
        orderTodoViewDescendingAction->setActionGroup(m_todoViewOrderGroup);
        mCollection.addAction(orderTodoViewDescendingAction->objectName(), orderTodoViewDescendingAction);
    }

    if (actionName == QLatin1String("todoview_show_completed") && KAuthorized::authorizeAction(actionName)) {
        auto todoViewShowCompletedAction = mCollection.addAction(actionName, this, &KalendarApplication::todoViewShowCompleted);
        todoViewShowCompletedAction->setText(i18n("Show completed todos"));
        todoViewShowCompletedAction->setIcon(QIcon::fromTheme(QStringLiteral("task-complete")));
        mCollection.addAction(todoViewShowCompletedAction->objectName(), todoViewShowCompletedAction);
    }

    mCollection.readSettings();
}

void KalendarApplication::configureShortcuts()
{
    // TODO replace with QML version
    KShortcutsDialog dlg(KShortcutsEditor::ApplicationAction, KShortcutsEditor::LetterShortcutsAllowed, nullptr);
    dlg.setModal(true);
    dlg.addCollection(&mCollection);
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
