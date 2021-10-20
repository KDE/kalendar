// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <KAboutData>
#include <KCalendarCore/MemoryCalendar>
#include <KCalendarCore/VCalFormat>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KontactInterface/PimUniqueApplication>
#include <QApplication>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QQmlApplicationEngine>
#include <QUrl>
#include <QtQml>
#include <akonadi_version.h>
#include <kalendar_part.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/AgentFilterProxyModel>
#else
#include <AkonadiCore/AgentFilterProxyModel>
#endif
#include "about.h"
#include "agentconfiguration.h"
#include "calendarmanager.h"
#include "config-kalendar.h"
#include "contactsmanager.h"
#include "hourlyincidencemodel.h"
#include "incidenceoccurrencemodel.h"
#include "incidencewrapper.h"
#include "infinitecalendarviewmodel.h"
#include "itemtagsmodel.h"
#include "kalendarapplication.h"
#include "kalendarconfig.h"
#include "monthmodel.h"
#include "multidayincidencemodel.h"
#include "tagmanager.h"
#include "timezonelistmodel.h"

K_PLUGIN_CLASS_WITH_JSON(KalendarPart, "kalendar_part.json")

KalendarPart::KalendarPart(QWidget *parentWidget, QObject *parent, const QVariantList &)
    : KParts::Part(parent)
{
    setComponentName(QStringLiteral("kalendar"), i18n("Kalendar"));
    // setXMLFile(QStringLiteral("kalendar_part.rc"), true);
    //(void)new PartAdaptor(this);

    auto config = KalendarConfig::self();
    CalendarManager manager;
    AgentConfiguration agentConfiguration;
    auto contactsManager = new ContactsManager;
    auto tagManager = new TagManager;

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
    // qmlRegisterType<ItemTagsModel>("org.kde.kalendar", 1, 0, "ItemTagsModel");
    qmlRegisterType<HourlyIncidenceModel>("org.kde.kalendar", 1, 0, "HourlyIncidenceModel");
    qmlRegisterType<TimeZoneListModel>("org.kde.kalendar", 1, 0, "TimeZoneListModel");
    qmlRegisterType<MonthModel>("org.kde.kalendar", 1, 0, "MonthModel");
    qmlRegisterType<InfiniteCalendarViewModel>("org.kde.kalendar", 1, 0, "InfiniteCalendarViewModel");

    qRegisterMetaType<Akonadi::AgentFilterProxyModel *>();
    qRegisterMetaType<QAction *>();

    m_widget = new QQuickWidget;
    m_widget->rootContext()->setContextObject(new KLocalizedContext(m_widget->engine()));
    m_widget->setSource(QUrl(QStringLiteral("qrc:///MonthView.qml")));
    m_widget->show();

    setWidget(m_widget);
}

#include "kalendar_part.moc"
