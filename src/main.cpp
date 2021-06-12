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
#include <AkonadiCore/AgentFilterProxyModel>
#include "monthmodel.h"
#include "multidayeventmodel.h"
#include "eventoccurrencemodel.h"
#include "calendarmanager.h"
#include "agentconfiguration.h"

using namespace KCalendarCore;

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("Kalendar"));

    QQmlApplicationEngine engine;

    auto manager = new CalendarManager(&engine);
    AgentConfiguration agentConfiguration;
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "CalendarManager", manager);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "AgentConfiguration", &agentConfiguration);
    qmlRegisterType<MonthModel>("org.kde.kalendar", 1, 0, "MonthModel");
    qmlRegisterType<MultiDayEventModel>("org.kde.kalendar", 1, 0, "MultiDayEventModel");
    qmlRegisterType<EventOccurrenceModel>("org.kde.kalendar", 1, 0, "EventOccurrenceModel");
    qmlRegisterType<MonthModel>("org.kde.kalendar", 1, 0, "MonthModel");
    qRegisterMetaType<Akonadi::AgentFilterProxyModel *>();

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
