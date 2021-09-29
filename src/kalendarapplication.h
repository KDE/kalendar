// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include <QObject>
#include <QActionGroup>
#include <KXmlGui/KActionCollection>
#include "actionsmodel.h"

class QWindow;
class QSortFilterProxyModel;

class KalendarApplication : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QSortFilterProxyModel *actionsModel READ actionsModel CONSTANT)
public:
    explicit KalendarApplication(QObject *parent = nullptr);
    ~KalendarApplication();
    Q_INVOKABLE QAction* action(const QString& name);

    Q_INVOKABLE QString iconName(const QIcon& icon) const;
    void setupActions();
    QWindow *window() const;
    void setWindow(QWindow *window);

    QSortFilterProxyModel *actionsModel();

public Q_SLOTS:
    void configureShortcuts();

Q_SIGNALS:
    void openMonthView();
    void openScheduleView();
    void openTodoView();
    void openAboutPage();
    void createNewEvent();
    void createNewTodo();
    void windowChanged();
    void openSettings();
    void openLanguageSwitcher();
    void openTagManager();
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

private:
    KActionCollection mCollection;
    KActionCollection mSortCollection;
    QWindow *m_window = nullptr;
    QActionGroup *m_viewGroup = nullptr;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
    KalCommandBarModel *m_actionModel = nullptr;
    QSortFilterProxyModel *m_proxyModel = nullptr;
};
