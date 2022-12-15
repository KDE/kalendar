#include "qwayland-pointer-gestures-unstable-v1.h"
#include <QDebug>
#include <QGuiApplication>
#include <QtWaylandClient/qwaylandclientextension.h>
#include <qpa/qplatformnativeinterface.h>

#include "pointergestureswayland.h"
#include "wayland-pointer-gestures-unstable-v1-client-protocol.h"

class PointerGestures : public QWaylandClientExtensionTemplate<PointerGestures>, public QtWayland::zwp_pointer_gestures_v1
{
public:
    PointerGestures()
        : QWaylandClientExtensionTemplate<PointerGestures>(3)
    {
    }
};

class SwipeGesture : public QObject, public QtWayland::zwp_pointer_gesture_swipe_v1
{
    Q_OBJECT
public:
public:
    SwipeGesture(struct ::zwp_pointer_gesture_swipe_v1 *object, QObject *parent)
        : QObject(parent)
        , zwp_pointer_gesture_swipe_v1(object)
    {
        qWarning() << "Creating SwipeGesture";
    }

Q_SIGNALS:
    void gestureBegin(uint32_t serial, uint32_t time, uint32_t fingers);
    void gestureUpdate(uint32_t time, wl_fixed_t dx, wl_fixed_t dy);
    void gestureEnd(uint32_t serial, uint32_t time, int32_t cancelled);

private:
    virtual void zwp_pointer_gesture_swipe_v1_begin(uint32_t serial, uint32_t time, struct ::wl_surface *surface, uint32_t fingers) override
    {
        qWarning() << "Gesture started" << serial << time << fingers;
        Q_EMIT gestureBegin(serial, time, fingers);
    }

    virtual void zwp_pointer_gesture_swipe_v1_update(uint32_t time, wl_fixed_t dx, wl_fixed_t dy) override
    {
        qWarning() << "Gesture updated" << time << dx << dy;
        Q_EMIT gestureUpdate(time, dx, dy);
    }

    virtual void zwp_pointer_gesture_swipe_v1_end(uint32_t serial, uint32_t time, int32_t cancelled) override
    {
        qWarning() << "Gesture end" << serial << time << cancelled;
        Q_EMIT gestureEnd(serial, time, cancelled);
    }
};

PointerGesturesWayland::PointerGesturesWayland(QObject *parent)
    : QObject(parent)
{
    m_pointerGestures = new PointerGestures();
    connect(m_pointerGestures, &PointerGestures::activeChanged, this, [this]() {
        init();
    });
}

void PointerGesturesWayland::init()
{
    QPlatformNativeInterface *native = qGuiApp->platformNativeInterface();
    if (!native) {
        return;
    }

    const auto pointer = reinterpret_cast<wl_pointer *>(native->nativeResourceForIntegration(QByteArrayLiteral("wl_pointer")));
    if (!pointer) {
        return;
    }

    m_swipeGesture = new SwipeGesture(m_pointerGestures->get_swipe_gesture(pointer), this);
}

#include "pointergestureswayland.moc"
