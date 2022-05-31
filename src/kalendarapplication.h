// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once
#include "kalendarconfig.h"
#include "models/actionsmodel.h"

#include <akonadi-calendar_version.h>
#if AKONADICALENDAR_VERSION > QT_VERSION_CHECK(5, 19, 41)
#include <Akonadi/ETMCalendar>
#include <Akonadi/ICalImporter>
#else
#include <Akonadi/Calendar/ETMCalendar>
#include <Akonadi/Calendar/ICalImporter>
#endif

#include <KActionCollection>
#include <QActionGroup>
#include <QObject>
#include <QWindow>

class QWindow;
class QQuickWindow;
class QSortFilterProxyModel;

class KalendarApplication : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QSortFilterProxyModel *actionsModel READ actionsModel CONSTANT)
    Q_PROPERTY(QString importErrorMessage READ importErrorMessage NOTIFY importErrorMessageChanged)

public:
    enum Mode {
        Event,
        Todo,
        Contact,
        Mail,
    };
    Q_ENUM(Mode);

    explicit KalendarApplication(QObject *parent = nullptr);
    ~KalendarApplication() override;
    Q_INVOKABLE QAction *action(const QString &name);

    Q_INVOKABLE QString iconName(const QIcon &icon) const;
    Q_INVOKABLE void saveWindowGeometry(QQuickWindow *window);
    void setupActions();
    QWindow *window() const;
    void setWindow(QWindow *window);

    QSortFilterProxyModel *actionsModel();
    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);
    Q_INVOKABLE void importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId = -1);
    QString importErrorMessage();

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
    void importStarted();
    void importFinished();
    void importIntoExistingFinished(bool success, int total);
    void importIntoNewFinished(bool success);
    void importErrorMessageChanged();
    void refreshAll();
    void openIncidence(const QVariantMap incidenceData, const QDateTime occurrence);

private:
    KActionCollection mCollection;
    KActionCollection mSortCollection;
    QWindow *m_window = nullptr;
    QActionGroup *const m_viewGroup;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
    KalCommandBarModel *m_actionModel = nullptr;
    QSortFilterProxyModel *m_proxyModel = nullptr;
    KalendarConfig *m_config = nullptr;
    Akonadi::ETMCalendar::Ptr m_calendar;
    QString m_importErrorMessage;
};
