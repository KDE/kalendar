// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once
#include "actionsmodel.h"
#include "kalendarconfig.h"

#include <Akonadi/ETMCalendar>
#include <Akonadi/ICalImporter>

#include <KActionCollection>
#include <QActionGroup>
#include <QObject>
#include <QWindow>

class QQuickWindow;
class QSortFilterProxyModel;

class KalendarApplication : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QSortFilterProxyModel *actionsModel READ actionsModel CONSTANT)

public:
    enum Mode {
        Month = 1,
        Week = 2,
        ThreeDay = 4,
        Day = 8,
        Schedule = 16,
        Event = Month | Week | ThreeDay | Day | Schedule,
        Todo = 32,
        Contact = 64,
        Mail = 128,
    };
    Q_ENUM(Mode)

    explicit KalendarApplication(QObject *parent = nullptr);
    ~KalendarApplication() override;
    Q_INVOKABLE QAction *action(const QString &name);

    Q_INVOKABLE QString iconName(const QIcon &icon) const;
    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);
    void setupActions();
    QWindow *window() const;
    void setWindow(QWindow *window);

    QSortFilterProxyModel *actionsModel();

    // D-Bus interface
    void showIncidenceByUid(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken);

public Q_SLOTS:
    void configureShortcuts();

Q_SIGNALS:
    void openMonthView();
    void openWeekView();
    void openThreeDayView();
    void openDayView();
    void openScheduleView();
    void openTodoView();
    void openMailView();
    void openContactView();
    void openAboutPage();
    void moveViewForwards();
    void moveViewBackwards();
    void moveViewToToday();
    void openDateChanger();
    void toggleMenubar();
    void createNewEvent();
    void createNewMail();
    void createNewContact();
    void createNewContactGroup();
    void createNewTodo();
    void windowChanged();
    void openSettings();
    void openLanguageSwitcher();
    void openTagManager();
    void importCalendar();
    void importCalendarFromFile(const QUrl &url);
    void quit();
    void undo();
    void redo();
    void todoViewSortAlphabetically();
    void todoViewSortByDueDate();
    void todoViewSortByPriority();
    void todoViewOrderAscending();
    void todoViewOrderDescending();
    void todoViewShowCompleted();
    void openKCommandBarAction();
    void refreshAll();
    void openIncidence(const QVariantMap incidenceData, const QDateTime occurrence);
    void showIncidenceByUidRequested(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken);

private:
    KActionCollection mCollection;
    KActionCollection mSortCollection;
    KActionCollection mMailCollection;
    KActionCollection mContactCollection;
    QWindow *m_window = nullptr;
    QActionGroup *const m_viewGroup;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
    KalCommandBarModel *m_actionModel = nullptr;
    QSortFilterProxyModel *m_proxyModel = nullptr;
    KalendarConfig *m_config = nullptr;
};
