// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once
#include "actionsmodel.h"
#include "kalendarconfig.h"
#include <Akonadi/Calendar/ETMCalendar>
#include <Akonadi/Calendar/ICalImporter>
#include <KXmlGui/KActionCollection>
#include <QActionGroup>
#include <QObject>

class QWindow;
class QSortFilterProxyModel;

class KalendarApplication : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QSortFilterProxyModel *actionsModel READ actionsModel CONSTANT)
public:
    explicit KalendarApplication(QObject *parent = nullptr);
    ~KalendarApplication() override;
    Q_INVOKABLE QAction *action(const QString &name);

    Q_INVOKABLE QString iconName(const QIcon &icon) const;
    void setupActions();
    QWindow *window() const;
    void setWindow(QWindow *window);

    QSortFilterProxyModel *actionsModel();
    void setCalendar(Akonadi::ETMCalendar *calendar);
    Q_INVOKABLE void importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId = -1);

public Q_SLOTS:
    void configureShortcuts();

Q_SIGNALS:
    void openMonthView();
    void openWeekView();
    void openScheduleView();
    void openTodoView();
    void openAboutPage();
    void moveViewForwards();
    void moveViewBackwards();
    void moveViewToToday();
    void openDateChanger();
    void toggleMenubar();
    void createNewEvent();
    void createNewTodo();
    void windowChanged();
    void openSettings();
    void openLanguageSwitcher();
    void openTagManager();
    void importCalendar();
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
    void importStarted();
    void importFinished();

private:
    KActionCollection mCollection;
    KActionCollection mSortCollection;
    QWindow *m_window = nullptr;
    QActionGroup *m_viewGroup = nullptr;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
    KalCommandBarModel *m_actionModel = nullptr;
    QSortFilterProxyModel *m_proxyModel = nullptr;
    KalendarConfig *m_config = nullptr;
    Akonadi::ETMCalendar *m_calendar;
};
