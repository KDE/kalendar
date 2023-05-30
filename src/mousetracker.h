// SPDX-FileCopyrightText: 2023 Claudio Cambra <claudio.cambra@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <QPointF>

class MouseTracker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QPointF mousePosition READ mousePosition NOTIFY mousePositionChanged)

public:
    static MouseTracker *instance();
    QPointF mousePosition() const;

Q_SIGNALS:
    void mousePositionChanged(QPointF position);
    void mouseButtonReleased(Qt::MouseButton button);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    explicit MouseTracker(QObject *parent = nullptr);

    QPointF m_lastMousePos;
};
