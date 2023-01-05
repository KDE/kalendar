// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "pointergestureswayland.h"

#ifdef WITH_WAYLAND
#include "qwayland-pointer-gestures-unstable-v1.h"
#include "wayland-pointer-gestures-unstable-v1-client-protocol.h"
#include <QGuiApplication>
#include <QtWaylandClient/qwaylandclientextension.h>
#include <qpa/qplatformnativeinterface.h>

class PointerGestures : public QWaylandClientExtensionTemplate<PointerGestures>, public QtWayland::zwp_pointer_gestures_v1
{
public:
    PointerGestures()
        : QWaylandClientExtensionTemplate<PointerGestures>(3)
    {
    }
};

class PinchGesture : public QObject, public QtWayland::zwp_pointer_gesture_pinch_v1
{
    Q_OBJECT
public:
public:
    PinchGesture(struct ::zwp_pointer_gesture_pinch_v1 *object, QObject *parent)
        : QObject(parent)
        , zwp_pointer_gesture_pinch_v1(object)
    {
    }

Q_SIGNALS:
    void gestureBegin(uint32_t serial, uint32_t time, uint32_t fingers);
    void gestureUpdate(uint32_t time, wl_fixed_t dx, wl_fixed_t dy, wl_fixed_t scale, wl_fixed_t rotation);
    void gestureEnd(uint32_t serial, uint32_t time, int32_t cancelled);

private:
    virtual void zwp_pointer_gesture_pinch_v1_begin(uint32_t serial, uint32_t time, struct ::wl_surface *surface, uint32_t fingers) override
    {
        Q_UNUSED(surface);
        Q_EMIT gestureBegin(serial, time, fingers);
    }

    virtual void zwp_pointer_gesture_pinch_v1_update(uint32_t time, wl_fixed_t dx, wl_fixed_t dy, wl_fixed_t scale, wl_fixed_t rotation) override
    {
        Q_EMIT gestureUpdate(time, dx, dy, scale, rotation);
    }

    virtual void zwp_pointer_gesture_pinch_v1_end(uint32_t serial, uint32_t time, int32_t cancelled) override
    {
        Q_EMIT gestureEnd(serial, time, cancelled);
    }
};

#endif

PointerGesturesWayland::PointerGesturesWayland(QObject *parent)
    : QObject(parent)
#ifdef WITH_WAYLAND
    , m_pointerGestures(new PointerGestures())
#endif
    , m_startZoom(1.0)
    , m_zoomModifier(1.0)
{
#ifdef WITH_WAYLAND
    connect(m_pointerGestures, &PointerGestures::activeChanged, this, [this]() {
        init();
    });
#endif
}

void PointerGesturesWayland::init()
{
#ifdef WITH_WAYLAND
    QPlatformNativeInterface *native = qGuiApp->platformNativeInterface();
    if (!native) {
        return;
    }

    const auto pointer = reinterpret_cast<wl_pointer *>(native->nativeResourceForIntegration(QByteArrayLiteral("wl_pointer")));
    if (!pointer) {
        return;
    }

    m_pinchGesture = new PinchGesture(m_pointerGestures->get_pinch_gesture(pointer), this);

    connect(m_pinchGesture, &PinchGesture::gestureBegin, this, [this]() {
        Q_EMIT pinchGestureStarted();
    });

    connect(m_pinchGesture, &PinchGesture::gestureUpdate, this, [this](uint32_t time, wl_fixed_t dx, wl_fixed_t dy, wl_fixed_t scale, wl_fixed_t rotation) {
        Q_EMIT pinchZoomChanged(m_startZoom * wl_fixed_to_double(scale) * m_zoomModifier);
    });
#endif
}

double PointerGesturesWayland::startZoom() const
{
    return m_startZoom;
}
void PointerGesturesWayland::setStartZoom(double startZoom)
{
    m_startZoom = startZoom;
}

#include "pointergestureswayland.moc"
