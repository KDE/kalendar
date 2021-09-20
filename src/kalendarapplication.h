// SPDX-FileCopyrightText: 2012 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include <QObject>
#include <QActionGroup>
#include <KXmlGui/KActionCollection>

class QWindow;

class KalendarApplication : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
public:
    explicit KalendarApplication(QObject *parent = nullptr);
    Q_INVOKABLE QAction* action(const QString& name);

    Q_INVOKABLE QString iconName(const QIcon& icon) const;
    void setupActions(const QString &actionName);
    QWindow *window() const;
    void setWindow(QWindow *window);

public Q_SLOTS:
    void configureShortcuts();

Q_SIGNALS:
    void openMonthView();
    void openScheduleView();
    void openTodoView();
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

private:
    KActionCollection mCollection;
    QWindow *m_window = nullptr;
    QActionGroup *m_viewGroup = nullptr;
    QActionGroup *m_todoViewOrderGroup = nullptr;
    QActionGroup *m_todoViewSortGroup = nullptr;
};
