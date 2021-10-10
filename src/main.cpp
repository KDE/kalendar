// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QApplication>
#include <QCommandLineParser>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <KAboutData>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KCalendarCore/VCalFormat>
#include <KCalendarCore/MemoryCalendar>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/AgentFilterProxyModel>
#else
#include <AkonadiCore/AgentFilterProxyModel>
#endif
#include "multidayincidencemodel.h"
#include "incidenceoccurrencemodel.h"
#include "monthviewmodel.h"
#include "calendarmanager.h"
#include "agentconfiguration.h"
#include "incidencewrapper.h"
#include "about.h"
#include "config-kalendar.h"
#include "contactsmanager.h"
#include "kalendarconfig.h"
#include "kalendarapplication.h"
#include "itemtagsmodel.h"
#include "tagmanager.h"
#include "hourlyincidencemodel.h"
#include "weekviewmodel.h"
#include "timezonelistmodel.h"

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
                         i18n("Calendar Application"),
                         // The license this code is released under.
                         KAboutLicense::GPL,
                         // Copyright Statement.
                         i18n("(c) KDE Community 2021"));
    aboutData.addAuthor(i18nc("@info:credit", "Carl Schwan"), i18nc("@info:credit", "Maintainer"), QStringLiteral("carl@carlschwan.eu"), QStringLiteral("https://carlschwan.eu"));
    aboutData.addAuthor(i18nc("@info:credit", "Clau Cambra"), i18nc("@info:credit", "Maintainer"), QStringLiteral("claudio.cambra@gmail.com"), QStringLiteral("https://claudiocambra.com"));
    KAboutData::setApplicationData(aboutData);

    QCommandLineParser parser;
    aboutData.setupCommandLine(&parser);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QQmlApplicationEngine engine;

    auto config = KalendarConfig::self();
    CalendarManager manager;
    AgentConfiguration agentConfiguration;
    auto contactsManager = new ContactsManager(&engine);
    auto tagManager = new TagManager(&engine);

    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "Config", config);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "CalendarManager", &manager);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "AgentConfiguration", &agentConfiguration);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "ContactsManager", contactsManager);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "TagManager", tagManager);
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "AboutType", new AboutType());
    qmlRegisterSingletonInstance("org.kde.kalendar", 1, 0, "KalendarApplication", new KalendarApplication());

    qmlRegisterType<IncidenceWrapper>("org.kde.kalendar", 1, 0, "IncidenceWrapper");
    qmlRegisterType<AttendeesModel>("org.kde.kalendar", 1, 0, "AttendeesModel");
    qmlRegisterType<MultiDayIncidenceModel>("org.kde.kalendar", 1, 0, "MultiDayIncidenceModel");
    qmlRegisterType<IncidenceOccurrenceModel>("org.kde.kalendar", 1, 0, "IncidenceOccurrenceModel");
    qmlRegisterType<ExtraTodoModel>("org.kde.kalendar", 1, 0, "ExtraTodoModel");
    qmlRegisterType<TodoSortFilterProxyModel>("org.kde.kalendar", 1, 0, "TodoSortFilterProxyModel");
    qmlRegisterType<MonthViewModel>("org.kde.kalendar", 1, 0, "MonthViewModel");
    qmlRegisterType<ItemTagsModel>("org.kde.kalendar", 1, 0, "ItemTagsModel");
    qmlRegisterType<HourlyIncidenceModel>("org.kde.kalendar", 1, 0, "HourlyIncidenceModel");
    qmlRegisterType<WeekViewModel>("org.kde.kalendar", 1, 0, "WeekViewModel");
    qmlRegisterType<TimeZoneListModel>("org.kde.kalendar", 1, 0, "TimeZoneListModel");

    qRegisterMetaType<Akonadi::AgentFilterProxyModel *>();
    qRegisterMetaType<QAction*>();

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.load(QUrl(QStringLiteral("qrc:///main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
