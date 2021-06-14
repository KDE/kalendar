// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <QDebug>
#include <KLocalizedContext>
#include <KCalendarCore/VCalFormat>
#include <KCalendarCore/MemoryCalendar>
#include "monthmodel.h"
#include "calendarmanager.h"
#include "eventwrapper.h"

using namespace KCalendarCore;

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("Kalendar"));

    QQmlApplicationEngine engine;

    auto manager = new CalendarManager(&engine);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "CalendarManager", manager);
    qmlRegisterType<EventWrapper>("org.kde.kalendar", 1, 0, "EventWrapper");
    qmlRegisterType<MonthModel>("org.kde.kalendar", 1, 0, "MonthModel");

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
