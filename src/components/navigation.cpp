// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "navigation.h"

using namespace std::literals::chrono_literals;

Navigation::Navigation(QObject *parent)
    : QObject(parent)
    , m_selectedDate(QDate::currentDate())
    , m_currentDate(QDate::currentDate())
{
    m_currentDateTimer.setInterval(5000ms);
    connect(&m_currentDateTimer, &QTimer::timeout, this, [this] {
        m_currentDate = QDate::currentDate();
        m_currentDateTimer.start();
    });
    m_currentDateTimer.start();
}

QObject *Navigation::pageStack() const
{
    return m_pageStack;
}

void Navigation::setPageStack(QObject *pageStack)
{
    if (pageStack == m_pageStack) {
        return;
    }
    m_pageStack = pageStack;
    Q_EMIT pageStackChanged();
}

void Navigation::switchView(const QString &app, const QString &viewName, const QVariantMap args)
{
    if (app == m_currentApp && viewName == m_currentView) {
        Q_EMIT argUpdated(app, args);
    } else {
        Q_EMIT switchViewRequested(app, viewName, args);
    }
}
