#pragma once

#include "qwayland-pointer-gestures-unstable-v1.h"
#include <QtWaylandClient/qwaylandclientextension.h>
#include <qpa/qplatformnativeinterface.h>
#include <qwindow.h>

class SwipeGesture;
class PointerGestures;

class PointerGesturesWayland : public QObject
{
    Q_OBJECT

public:
    PointerGesturesWayland(QObject *parent = nullptr);
    virtual ~PointerGesturesWayland() = default;

    Q_INVOKABLE void init();

private:
    PointerGestures *m_pointerGestures = nullptr;
    SwipeGesture *m_swipeGesture = nullptr;
};
