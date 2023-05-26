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
    explicit MouseTracker(QObject *parent = nullptr);

    QPointF mousePosition() const;

Q_SIGNALS:
    void mousePositionChanged(QPointF position);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    QPointF m_lastMousePos;
};
