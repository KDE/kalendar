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

using namespace KCalendarCore;

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("GameCenter"));

    VCalFormat vcalLoader;
    auto calendar = MemoryCalendar::Ptr(new MemoryCalendar(QTimeZone{}));
    vcalLoader.load(calendar, QStringLiteral("/home/carl/project/kde/kalendar/build/test.vcal"));

    QQmlApplicationEngine engine;
    auto monthModel = new MonthModel(&engine);
    monthModel->setYear(2005);
    monthModel->setMonth(5);
    monthModel->setCalendar(calendar);
    qmlRegisterType<MonthModel>("org.kde.kalendar", 1, 0, "MonthModel");

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.rootContext()->setContextProperty(QStringLiteral("monthModel"), monthModel);
    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
