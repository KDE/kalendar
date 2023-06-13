// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "actionsmodel.h"
#include <KActionCollection>
#include <QObject>
#include <QSortFilterProxyModel>

class AbstractApplication : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSortFilterProxyModel *actionsModel READ actionsModel CONSTANT)

public:
    explicit AbstractApplication(QObject *parent = nullptr);
    ~AbstractApplication();

    Q_INVOKABLE void configureShortcuts();
    Q_INVOKABLE QAction *action(const QString &actionName);

    virtual QVector<KActionCollection *> actionCollections() const = 0;
    QSortFilterProxyModel *actionsModel();

Q_SIGNALS:
    void openSettings();
    void openAboutPage();
    void openAboutKDEPage();
    void openKCommandBarAction();
    void openTagManager();

protected:
    virtual void toggleMenubar() = 0;
    virtual bool showMenubar() const = 0;

    virtual void setupActions();
    KActionCollection *mCollection = nullptr;

private:
    KalCommandBarModel *m_actionModel = nullptr;
    QSortFilterProxyModel *m_proxyModel = nullptr;
};
