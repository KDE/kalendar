// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once
#include "calendarconfig.h"
#include <abstractapplication.h>

#include <Akonadi/ETMCalendar>
#include <Akonadi/ICalImporter>

#include <KActionCollection>
#include <QActionGroup>
#include <QObject>
#include <QWindow>

class QQuickWindow;
class QSortFilterProxyModel;

class CalendarApplication : public AbstractApplication
{
    Q_OBJECT

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QString importErrorMessage READ importErrorMessage NOTIFY importErrorMessageChanged)

public:
    enum Mode {
        Month = 1,
        Week = 2,
        ThreeDay = 4,
        Day = 8,
        Schedule = 16,
        Event = Month | Week | ThreeDay | Day | Schedule,
        Todo = 32,
    };
    Q_ENUM(Mode)

    explicit CalendarApplication(QObject *parent = nullptr);
    ~CalendarApplication() override;

    QVector<KActionCollection *> actionCollections() const override;

    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);
    QWindow *window() const;
    void setWindow(QWindow *window);

    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);
    Q_INVOKABLE void importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId = -1);
    QString importErrorMessage();

    // D-Bus interface
    void showIncidenceByUid(const QString &uid, const QDateTime &occurrence, const QString &xdgActivationToken);

Q_SIGNALS:
    void openMonthView();
    void openWeekView();
    void openThreeDayView();
    void openDayView();
    void openScheduleView();
    void openTodoView();
    void openAboutPage();
    void moveViewForwards();
    void moveViewBackwards();
    void moveViewToToday();
    void openDateChanger();
    void createNewEvent();
    void createNewTodo();
    void windowChanged();
    void configureSchedule();
    void openSettings();
    void openLanguageSwitcher();
    void openTagManager();
    void importCalendar();
    void importCalendarFromFile(const QUrl &url);
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
    void importIntoExistingFinished(bool success, int total);
    void importIntoNewFinished(bool success);
    void importErrorMessageChanged();
    void refreshAll();
    void openIncidence(const QVariantMap incidenceData, const QDateTime occurrence);

private Q_SLOTS:
    void handleMouseViewNavButtons(const Qt::MouseButton pressedButton);

private:
    void setupActions() override;
    void toggleMenubar();
    bool showMenubar() const;

    KActionCollection *mSortCollection = nullptr;
    QWindow *m_window = nullptr;
    QActionGroup *const m_viewGroup;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
    CalendarConfig *m_config = nullptr;
    Akonadi::ETMCalendar::Ptr m_calendar;
    QString m_importErrorMessage;
};
