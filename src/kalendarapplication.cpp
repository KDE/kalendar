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
    }

    if (actionName == QLatin1String("open_schedule_view") && KAuthorized::authorizeAction(actionName)) {
        auto openScheduleAction = mCollection.addAction(actionName, this, &KalendarApplication::openScheduleView);
        openScheduleAction->setText(i18n("Schedule View"));
        openScheduleAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar-list")));
        openScheduleAction->setCheckable(true);
        openScheduleAction->setActionGroup(m_viewGroup);
    }

    if (actionName == QLatin1String("open_month_view") && KAuthorized::authorizeAction(actionName)) {
        auto openMonthAction = mCollection.addAction(actionName, this, &KalendarApplication::openMonthView);
        openMonthAction->setText(i18n("Month View"));
        openMonthAction->setIcon(QIcon::fromTheme(QStringLiteral("view-calendar")));
        openMonthAction->setCheckable(true);
        openMonthAction->setActionGroup(m_viewGroup);
        mCollection.setDefaultShortcut(openMonthAction, QKeySequence(Qt::Key_F11)); // TODO better default shortcut
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
        mCollection.addAction(action->objectName(), action);
    }

    if (actionName == QLatin1String("edit_redo") && KAuthorized::authorizeAction(actionName)) {
        auto action = KStandardAction::redo(this, &KalendarApplication::redo, this);
        mCollection.addAction(action->objectName(), action);
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
