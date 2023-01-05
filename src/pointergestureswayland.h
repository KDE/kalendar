// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>

class PointerGestures;
class PinchGesture;

class PointerGesturesWayland : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double startZoom READ startZoom WRITE setStartZoom NOTIFY pinchZoomChanged)

public:
    PointerGesturesWayland(QObject *parent = nullptr);
    virtual ~PointerGesturesWayland() = default;

    double startZoom() const;
    void setStartZoom(double startZoom);

    Q_INVOKABLE void init();

Q_SIGNALS:
    void pinchGestureStarted();
    void pinchZoomChanged(double);

private:
    PointerGestures *m_pointerGestures = nullptr;
    PinchGesture *m_pinchGesture;
    double m_startZoom;
    double m_zoomModifier;
};
