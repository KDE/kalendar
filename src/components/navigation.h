// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QDate>
#include <QObject>
#include <QTimer>
#include <QVariantMap>

/**
 * @brief Central navigation component exposed as singleton to the QML engine
 */
class Navigation : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject *pageStack READ pageStack WRITE setPageStack NOTIFY pageStackChanged)
    Q_PROPERTY(QDate selectedDate MEMBER m_selectedDate NOTIFY selectedDateChanged)
    Q_PROPERTY(QDate currentDate MEMBER m_currentDate NOTIFY currentDateChanged)

public:
    explicit Navigation(QObject *parent = nullptr);

    QObject *pageStack() const;
    void setPageStack(QObject *pageStack);

    Q_INVOKABLE void switchView(const QString &app, const QString &viewName, const QVariantMap args = {});

Q_SIGNALS:
    void pageStackChanged();
    void selectedDateChanged();
    void currentDateChanged();

    /**
     * Triggered when a new requested view and it is different than the current view
     * @internal
     */
    void switchViewRequested(const QString &app, const QString &viewName, const QVariantMap args = {});

    /**
     * Triggered when the new requested view is the same as the current one
     * @internal
     */
    void argUpdated(const QString &app, const QVariantMap args = {});

private:
    QObject *m_pageStack = nullptr;
    QString m_currentApp;
    QString m_currentView;
    QDate m_selectedDate;
    QDate m_currentDate;
    QTimer m_currentDateTimer;
};
