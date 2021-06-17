// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <KAboutData>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KCalendarCore/VCalFormat>
#include <KCalendarCore/MemoryCalendar>
#include <AkonadiCore/AgentFilterProxyModel>
#include "multidayeventmodel.h"
#include "eventoccurrencemodel.h"
#include "calendarmanager.h"
#include "agentconfiguration.h"
#include "eventwrapper.h"
#include "about.h"
#include "config-kalendar.h"

using namespace KCalendarCore;

int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("KDE"));
    QCoreApplication::setApplicationName(QStringLiteral("Kalendar"));

    KAboutData aboutData(
                         // The program name used internally.
                         QStringLiteral("kalendar"),
                         // A displayable program name string.
                         i18nc("@title", "Kalendar"),
                         QStringLiteral(KALENDAR_VERSION_STRING),
                         // Short description of what the app does.
                         i18n("Calendar application"),
                         // The license this code is released under.
                         KAboutLicense::GPL,
                         // Copyright Statement.
                         i18n("(c) KDE Community 2021"));
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"), i18nc("@info:credit", "Maintainer"), QStringLiteral("carl@carlschwan.eu"), QStringLiteral("https://carlschwan.eu"));
    aboutData.addAuthor(i18nc("@info:credit", "Clau Cambra"), i18nc("@info:credit", "Developer"));
    KAboutData::setApplicationData(aboutData);


    QQmlApplicationEngine engine;

    auto manager = new CalendarManager(&engine);
    AgentConfiguration agentConfiguration;
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "CalendarManager", manager);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "AgentConfiguration", &agentConfiguration);
    qmlRegisterType<EventWrapper>("org.kde.kalendar", 1, 0, "EventWrapper");
    qmlRegisterType<MultiDayEventModel>("org.kde.kalendar", 1, 0, "MultiDayEventModel");
    qmlRegisterType<EventOccurrenceModel>("org.kde.kalendar", 1, 0, "EventOccurrenceModel");
    qRegisterMetaType<Akonadi::AgentFilterProxyModel *>();

    qmlRegisterSingletonType<AboutType>("org.kde.kalendar", 1, 0, "AboutType", [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)

        return new AboutType();
    });

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
