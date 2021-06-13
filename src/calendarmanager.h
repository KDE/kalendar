// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <KDescendantsProxyModel>
#include <KViewStateMaintainer>
#include <ETMViewStateSaver>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>

namespace Akonadi {
    class ETMCalendar;
}
class MonthModel;

class CalendarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(MonthModel *monthModel READ monthModel CONSTANT)
    Q_PROPERTY(KDescendantsProxyModel *collections READ collections CONSTANT)
public:
    CalendarManager(QObject *parent = nullptr);
    ~CalendarManager() override;

    bool loading() const;
    MonthModel *monthModel() const;
    KDescendantsProxyModel *collections();
    Q_INVOKABLE void save();
    Q_INVOKABLE void addEvent(qint64 collectionId, KCalendarCore::Event::Ptr event);

private Q_SLOTS:
    void delayedInit();

Q_SIGNALS:
    void loadingChanged();
    void entityTreeModelChanged();

private:
    Akonadi::ETMCalendar *m_calendar;
    MonthModel *m_monthModel;
    KViewStateMaintainer<Akonadi::ETMViewStateSaver> *mCollectionSelectionModelStateSaver = nullptr;
};
