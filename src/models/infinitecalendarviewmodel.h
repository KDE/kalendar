// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include "hourlyincidencemodel.h"
#include "multidayincidencemodel.h"
#include <kalendarconfig.h>
#include <akonadi-calendar_version.h>
#if AKONADICALENDAR_VERSION > QT_VERSION_CHECK(5, 19, 41)
#include <Akonadi/ETMCalendar>
#else
#include <Akonadi/Calendar/ETMCalendar>
#endif
#include <QLocale>
#include <QQueue>

class InfiniteCalendarViewModel : public QAbstractListModel
{
    Q_OBJECT
    // Amount of dates to add each time the model adds more dates
    Q_PROPERTY(int datesToAdd READ datesToAdd WRITE setDatesToAdd NOTIFY datesToAddChanged)
    Q_PROPERTY(int scale READ scale WRITE setScale NOTIFY scaleChanged)
    Q_PROPERTY(QStringList hourlyViewLocalisedHourLabels MEMBER m_hourlyViewLocalisedHourLabels CONSTANT)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(QVariantMap filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(int maxLiveModels READ maxLiveModels WRITE setMaxLiveModels NOTIFY maxLiveModelsChanged)

public:
    // The decade scale is designed to be used in a 4x3 grid, so shows 12 years at a time
    enum Scale { DayScale, ThreeDayScale, WeekScale, MonthScale, YearScale, DecadeScale };
    Q_ENUM(Scale);

    enum Roles {
        StartDateRole = Qt::UserRole + 1,
        FirstDayOfMonthRole,
        SelectedMonthRole,
        SelectedYearRole,
        MonthViewModelRole,
        ScheduleViewModelRole,
        WeekViewModelRole,
        WeekViewMultiDayModelRole,
        ThreeDayViewModelRole,
        ThreeDayViewMultiDayModelRole,
        DayViewModelRole,
        DayViewMultiDayModelRole
    };
    Q_ENUM(Roles);

    enum ModelType { TypeDay, TypeDayMultiDay, TypeThreeDay, TypeThreeDayMultiDay, TypeMonth, TypeSchedule, TypeWeek, TypeWeekMultiDay };
    Q_ENUM(ModelType);

    explicit InfiniteCalendarViewModel(QObject *parent = nullptr);
    ~InfiniteCalendarViewModel() override = default;

    void setup();
    QVariant data(const QModelIndex &idx, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = {}) const override;

    Q_INVOKABLE void addDates(bool atEnd, const QDate startFrom = QDate());
    void addDayDates(bool atEnd, const QDate &startFrom, int amount = 1);
    void addWeekDates(bool atEnd, const QDate &startFrom);
    void addMonthDates(bool atEnd, const QDate &startFrom);
    void addYearDates(bool atEnd, const QDate &startFrom);
    void addDecadeDates(bool atEnd, const QDate &startFrom);

    int datesToAdd() const;
    void setDatesToAdd(int datesToAdd);

    int scale();
    void setScale(int scale);

    Akonadi::ETMCalendar::Ptr calendar();
    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);

    QVariantMap filter() const;
    void setFilter(const QVariantMap &filter);

    int maxLiveModels();
    void setMaxLiveModels(int maxLiveModels);

    QDateTime openDate();
    void setOpenDate(QDateTime openDate);

    void checkModels(const QDate &start, const QDate &end, KCalendarCore::Incidence::Ptr incidence);
    void checkCalendarIndex(const QModelIndex &index);
    void triggerAffectedModelUpdates();
    void handleCalendarDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &roles);
    void handleCalendarRowsInserted(const QModelIndex &parent, int first, int last);
    void handleCalendarRowsRemoved(const QModelIndex &parent, int first, int last);

Q_SIGNALS:
    void datesToAddChanged();
    void scaleChanged();
    void calendarChanged();
    void filterChanged();
    void maxLiveModelsChanged();
    void openDateChanged();

private:
    QVector<QDate> m_startDates;
    QVector<QDate> m_firstDayOfMonthDates;
    QStringList m_hourlyViewLocalisedHourLabels;
    QLocale m_locale;
    int m_datesToAdd = 10;
    int m_scale = MonthScale;

    struct ModelMetaData {
        QVector<QDate> affectedStartDates;
        int modelLength;
        int modelType;
        QHash<QDate, MultiDayIncidenceModel *> *multiDayModels;
        QHash<QDate, HourlyIncidenceModel *> *hourlyModels;
        QQueue<QDate> *liveKeysQueue;
    };

    KalendarConfig *m_config = nullptr;
    QBitArray m_hiddenSpaces = QBitArray(7); // TODO: Use a more flexible way of doing this

    QVector<ModelMetaData> m_models;
    mutable QHash<QDate, MultiDayIncidenceModel *> m_monthViewModels;
    mutable QHash<QDate, MultiDayIncidenceModel *> m_scheduleViewModels;
    mutable QHash<QDate, HourlyIncidenceModel *> m_weekViewModels;
    mutable QHash<QDate, MultiDayIncidenceModel *> m_weekViewMultiDayModels;
    mutable QHash<QDate, HourlyIncidenceModel *> m_threeDayViewModels;
    mutable QHash<QDate, MultiDayIncidenceModel *> m_threeDayViewMultiDayModels;
    mutable QHash<QDate, HourlyIncidenceModel *> m_dayViewModels;
    mutable QHash<QDate, MultiDayIncidenceModel *> m_dayViewMultiDayModels;
    QSet<Akonadi::Item::Id> m_insertedIds;
    mutable QQueue<QDate> m_liveMonthViewModelKeys;
    mutable QQueue<QDate> m_liveScheduleViewModelKeys;
    mutable QQueue<QDate> m_liveWeekViewModelKeys;
    mutable QQueue<QDate> m_liveWeekViewMultiDayModelKeys;
    mutable QQueue<QDate> m_liveThreeDayViewModelKeys;
    mutable QQueue<QDate> m_liveThreeDayViewMultiDayModelKeys;
    mutable QQueue<QDate> m_liveDayViewModelKeys;
    mutable QQueue<QDate> m_liveDayViewMultiDayModelKeys;
    int m_maxLiveModels = 10;
    mutable int m_lastAccessedModelType = TypeMonth;
    Akonadi::ETMCalendar::Ptr m_calendar;
    QVariantMap mFilter;
};
