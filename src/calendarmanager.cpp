// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
//
// SPDX-License-Identifier: LGPL-2.1-or-later


#include "calendarmanager.h"

// Akonadi
#include <control.h>
#include <etmcalendar.h>
#include <CollectionFilterProxyModel>
#include <Monitor>
#include <EntityTreeModel>
#include <QApplication>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <AkonadiCore/CollectionIdentificationAttribute>
#include <KCheckableProxyModel>
#include <QTimer>
#include "monthmodel.h"

CalendarManager::CalendarManager(QObject *parent)
    : QObject(parent)
    , m_calendar(nullptr)
    , m_monthModel(nullptr)

{
    auto currentDate = QDate::currentDate();
    m_monthModel = new MonthModel(this);
    m_monthModel->setYear(currentDate.year());
    m_monthModel->setMonth(currentDate.month());
    if (!Akonadi::Control::start() ) {
        qApp->exit(-1);
        return;
    }

    m_calendar = new Akonadi::ETMCalendar(this);
    
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    mCollectionSelectionModelStateSaver = new KViewStateMaintainer<Akonadi::ETMViewStateSaver>(config->group("GlobalCollectionSelection"));
    mCollectionSelectionModelStateSaver->setSelectionModel(m_calendar->checkableProxyModel()->selectionModel());
    mCollectionSelectionModelStateSaver->restoreState();
    
    m_monthModel->setCalendar(m_calendar);
    
    connect(m_calendar, &Akonadi::ETMCalendar::calendarChanged,
            m_monthModel, &MonthModel::refreshGridPosition);
    /* KCalendarCore::Event::Ptr event(new KCalendarCore::Event);
    event->setSummary(QStringLiteral("Hello"));
    event->setDtStart(QDateTime::currentDateTime());
    event->setDtEnd(QDateTime::currentDateTime().addSecs(60 * 60* 3));
    m_calendar->addEvent(event);*/

    Q_EMIT entityTreeModelChanged();
    Q_EMIT loadingChanged();
}

CalendarManager::~CalendarManager()
{
    delete mCollectionSelectionModelStateSaver;
}

void CalendarManager::save()
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    mCollectionSelectionModelStateSaver->saveState();
    KConfigGroup selectionGroup = config->group("GlobalCollectionSelection");
    selectionGroup.sync();
    config->sync();
    m_monthModel->save();
}


void CalendarManager::delayedInit()
{
    /*if (!Akonadi::Control::start() ) {
        qApp->exit(-1);
        return;
    }

    Akonadi::Monitor *monitor = new Akonadi::Monitor(this);
    monitor->setObjectName(QStringLiteral("CollectionWidgetMonitor"));
    monitor->fetchCollection(true);
    monitor->setAllMonitored(true);

    m_calendar = new Akonadi::ETMCalendar(monitor);
    m_monthModel->setCalendar(m_calendar);
    connect(m_calendar, &Akonadi::ETMCalendar::calendarChanged,
            m_monthModel, &MonthModel::refreshGridPosition);
    connect(m_calendar, &Akonadi::ETMCalendar::calendarChanged,
            this, [this]() {
               qDebug() << "changed" << m_calendar->events() << m_calendar->isLoaded(); 
               qDebug() << m_calendar->checkableProxyModel();
            });*/
    /*KCalendarCore::Event::Ptr event(new KCalendarCore::Event);
    event->setSummary(QStringLiteral("Hello"));
    event->setDtStart(QDateTime::currentDateTime());
    event->setDtEnd(QDateTime::currentDateTime().addSecs(60 * 60* 3));
    m_calendar->addEvent(event);*/

    Q_EMIT entityTreeModelChanged();
    Q_EMIT loadingChanged();
}

KDescendantsProxyModel *CalendarManager::collections()
{
    auto model = new KDescendantsProxyModel(this);
    auto checkableModel = m_calendar->checkableProxyModel();
    qDebug() << "CheckableModel rolenames: " << checkableModel->roleNames();
    model->setSourceModel(checkableModel);
    model->setExpandsByDefault(true);
    return model;
}


bool CalendarManager::loading() const
{
    return !m_calendar->isLoaded();
}

MonthModel *CalendarManager::monthModel() const
{
    return m_monthModel;
}

