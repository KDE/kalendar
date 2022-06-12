// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "incidenceoccurrencemodel.h"
#include "kalendar_debug.h"
#include <Akonadi/EntityTreeModel>
#include <QDebug>
#include <QMetaEnum>
#include <cmath>
#include <models/infinitecalendarviewmodel.h>

InfiniteCalendarViewModel::InfiniteCalendarViewModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_config = KalendarConfig::self();

    connect(m_config, &KalendarConfig::showDay1Changed, this, &InfiniteCalendarViewModel::setup);
    connect(m_config, &KalendarConfig::showDay2Changed, this, &InfiniteCalendarViewModel::setup);
    connect(m_config, &KalendarConfig::showDay3Changed, this, &InfiniteCalendarViewModel::setup);
    connect(m_config, &KalendarConfig::showDay4Changed, this, &InfiniteCalendarViewModel::setup);
    connect(m_config, &KalendarConfig::showDay5Changed, this, &InfiniteCalendarViewModel::setup);
    connect(m_config, &KalendarConfig::showDay6Changed, this, &InfiniteCalendarViewModel::setup);
    connect(m_config, &KalendarConfig::showDay7Changed, this, &InfiniteCalendarViewModel::setup);

    setup();

    ModelMetaData monthModel = {QVector<QDate>(), 42, TypeMonth, &m_monthViewModels, {}, &m_liveMonthViewModelKeys};
    ModelMetaData scheduleModel = {QVector<QDate>(), 0, TypeSchedule, &m_scheduleViewModels, {}, &m_liveScheduleViewModelKeys};
    ModelMetaData weekModel = {QVector<QDate>(), 7, TypeWeek, {}, &m_weekViewModels, &m_liveWeekViewModelKeys};
    ModelMetaData weekMultiDayModel = {QVector<QDate>(), 7, TypeWeekMultiDay, &m_weekViewMultiDayModels, {}, &m_liveWeekViewMultiDayModelKeys};
    ModelMetaData threeDayModel = {QVector<QDate>(), 7, TypeThreeDay, {}, &m_threeDayViewModels, &m_liveThreeDayViewModelKeys};
    ModelMetaData threeDayMultiDayModel = {QVector<QDate>(), 7, TypeThreeDayMultiDay, &m_threeDayViewMultiDayModels, {}, &m_liveThreeDayViewMultiDayModelKeys};
    ModelMetaData dayModel = {QVector<QDate>(), 7, TypeDay, {}, &m_dayViewModels, &m_liveDayViewModelKeys};
    ModelMetaData dayMultiDayModel = {QVector<QDate>(), 7, TypeDayMultiDay, &m_dayViewMultiDayModels, {}, &m_liveDayViewMultiDayModelKeys};

    m_models =
        QVector<ModelMetaData>{monthModel, scheduleModel, weekModel, weekMultiDayModel, threeDayModel, threeDayMultiDayModel, dayModel, dayMultiDayModel};
}

void InfiniteCalendarViewModel::setup()
{
    m_startDates.clear();

    m_hiddenSpaces[0] = !m_config->showDay1();
    m_hiddenSpaces[1] = !m_config->showDay2();
    m_hiddenSpaces[2] = !m_config->showDay3();
    m_hiddenSpaces[3] = !m_config->showDay4();
    m_hiddenSpaces[4] = !m_config->showDay5();
    m_hiddenSpaces[5] = !m_config->showDay6();
    m_hiddenSpaces[6] = !m_config->showDay7();

    const QDate today = QDate::currentDate();
    QTime time;

    if (!m_hourlyViewLocalisedHourLabels.length()) {
        m_hourlyViewLocalisedHourLabels.clear();
        for (int i = 1; i < 24; i++) {
            time.setHMS(i, 0, 0);
            m_hourlyViewLocalisedHourLabels.append(QLocale::system().toString(time, QLocale::NarrowFormat));
        }
    }

    switch (m_scale) {
    case DayScale: {
        QDate firstDay = today;
        firstDay = firstDay.addDays(m_datesToAdd / 2);

        addDayDates(true, firstDay);
        break;
    }
    case ThreeDayScale: {
        QDate firstDay = today;
        firstDay = firstDay.addDays((-m_datesToAdd * 3) / 2);

        addDayDates(true, firstDay, 3);
        break;
    }
    case WeekScale: {
        QDate firstDay = today.addDays(-today.dayOfWeek() + m_locale.firstDayOfWeek());
        // We create dates before and after where our view will start from (which is today)
        firstDay = firstDay.addDays((-m_datesToAdd * 7) / 2);

        addWeekDates(true, firstDay);
        break;
    }
    case MonthScale: {
        QDate firstDay(today.year(), today.month(), 1);
        firstDay = firstDay.addMonths(-m_datesToAdd / 2);

        addMonthDates(true, firstDay);
        break;
    }
    case YearScale: {
        QDate firstDay(today.year(), today.month(), 1);
        firstDay = firstDay.addYears(-m_datesToAdd / 2);

        addYearDates(true, firstDay);
        break;
    }
    case DecadeScale: {
        const int firstYear = ((floor(today.year() / 10)) * 10) - 1; // E.g. For 2020 have view start at 2019...
        QDate firstDay(firstYear, today.month(), 1);
        firstDay = firstDay.addYears(((-m_datesToAdd * 12) / 2) + 10); // 3 * 4 grid so 12 years, end at 2030, and align for mid index to be current decade

        addDecadeDates(true, firstDay);
        break;
    }
    }
}

QVariant InfiniteCalendarViewModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    const QDate startDate = m_startDates[idx.row()];

    auto generateMultiDayIncidenceModel = [&](QDate start, int length, int periodLength) {
        auto model = new MultiDayIncidenceModel;
        model->setPeriodLength(periodLength);
        model->setModel(new IncidenceOccurrenceModel);
        model->model()->setStart(start);
        model->model()->setLength(length);
        model->model()->setFilter(mFilter);
        model->model()->setCalendar(m_calendar);

        return model;
    };

    auto generateHourlyIncidenceModel = [&](QDate start, int length, int periodLength, bool handleHiddenDays = false) {
        auto model = new HourlyIncidenceModel;
        model->setPeriodLength(periodLength);
        model->setFilters(HourlyIncidenceModel::NoAllDay | HourlyIncidenceModel::NoMultiDay);
        model->setModel(new IncidenceOccurrenceModel);
        model->model()->setStart(start);
        model->model()->setLength(length);
        model->model()->setFilter(mFilter);
        model->model()->setCalendar(m_calendar);

        return model;
    };

    auto cleanUpModels = [&, this]() {
        int numLiveModels = m_liveMonthViewModelKeys.length() + m_liveScheduleViewModelKeys.length() + m_liveWeekViewModelKeys.length()
            + m_liveWeekViewMultiDayModelKeys.length() + m_liveThreeDayViewModelKeys.length() + m_liveThreeDayViewMultiDayModelKeys.length()
            + m_liveDayViewModelKeys.length() + m_liveDayViewMultiDayModelKeys.length(); // Find a more elegant way to do this

        while (numLiveModels > m_maxLiveModels) {
            for (int i = 0; i < m_models.length(); i++) {
                if (m_models[i].liveKeysQueue->length() > m_maxLiveModels) {
                    while (m_models[i].liveKeysQueue->length() > m_maxLiveModels) {
                        auto firstKey = m_models[i].liveKeysQueue->dequeue();

                        if ((m_models[i].modelType == TypeWeek || m_models[i].modelType == TypeThreeDay || m_models[i].modelType == TypeDay)
                            && m_models[i].hourlyModels->contains(firstKey)) {
                            delete m_models[i].hourlyModels->value(firstKey);
                            m_models[i].hourlyModels->remove(firstKey);
                        } else if (m_models[i].multiDayModels->contains(firstKey)) {
                            delete m_models[i].multiDayModels->value(firstKey);
                            m_models[i].multiDayModels->remove(firstKey);
                        }
                    }

                } else if (m_models[i].liveKeysQueue->length() > 0) {
                    auto firstKey = m_models[i].liveKeysQueue->dequeue();

                    if ((m_models[i].modelType == TypeWeek || m_models[i].modelType == TypeThreeDay || m_models[i].modelType == TypeDay)
                        && m_models[i].hourlyModels->contains(firstKey)) {
                        delete m_models[i].hourlyModels->value(firstKey);
                        m_models[i].hourlyModels->remove(firstKey);
                    } else if (m_models[i].multiDayModels->contains(firstKey)) {
                        delete m_models[i].multiDayModels->value(firstKey);
                        m_models[i].multiDayModels->remove(firstKey);
                    }
                }

                numLiveModels = m_liveMonthViewModelKeys.length() + m_liveScheduleViewModelKeys.length() + m_liveWeekViewModelKeys.length()
                    + m_liveWeekViewMultiDayModelKeys.length() + m_liveThreeDayViewModelKeys.length() + m_liveThreeDayViewMultiDayModelKeys.length()
                    + m_liveDayViewModelKeys.length() + m_liveDayViewMultiDayModelKeys.length();
            }
        }
    };

    auto requeue = [&](QQueue<QDate> &liveKeysQueue, const QDate &key) {
        for (int i = 0; i < liveKeysQueue.length(); i++) {
            if (liveKeysQueue[i] == key) {
                liveKeysQueue.move(i, liveKeysQueue.length() - 1);
                break;
            }
        }
    };

    if (m_scale == MonthScale && role != StartDateRole) {
        const QDate firstDay = m_firstDayOfMonthDates[idx.row()];

        switch (role) {
        case FirstDayOfMonthRole:
            return firstDay.startOfDay();
        case SelectedMonthRole:
            return firstDay.month();
        case SelectedYearRole:
            return firstDay.year();
        case MonthViewModelRole: {
            m_lastAccessedModelType = TypeMonth;

            if (m_datesToAdd > 5 && idx.row() < 2 && m_monthViewModels.count() < 3) {
                return {}; // HACK: Prevent creating the models for the default index 1 date
                // Unfortunately this gets called by the pathviews no matter what the currentIndex
                // value is set to.
            }
            if (!m_liveMonthViewModelKeys.contains(startDate)) {
                m_monthViewModels[startDate] = generateMultiDayIncidenceModel(startDate, 42, 7);

                m_liveMonthViewModelKeys.enqueue(startDate);
                cleanUpModels();
            } else {
                requeue(m_liveMonthViewModelKeys, startDate);
            }

            return QVariant::fromValue(m_monthViewModels[startDate]);
        }
        case ScheduleViewModelRole: {
            m_lastAccessedModelType = TypeSchedule;

            if (m_datesToAdd > 5 && idx.row() < 2 && m_scheduleViewModels.count() < 3) {
                return {};
            }

            if (!m_scheduleViewModels.contains(firstDay)) {
                m_scheduleViewModels[firstDay] = generateMultiDayIncidenceModel(firstDay, firstDay.daysInMonth(), 1);

                m_liveScheduleViewModelKeys.enqueue(startDate);
                cleanUpModels();
            } else {
                requeue(m_liveScheduleViewModelKeys, startDate);
            }

            return QVariant::fromValue(m_scheduleViewModels[firstDay]);
        }
        default:
            qCWarning(KALENDAR_LOG) << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
        }
    }

    switch (role) {
    case StartDateRole:
        return startDate.startOfDay();
    case SelectedMonthRole:
        return startDate.month();
    case SelectedYearRole:
        return startDate.year();
    case WeekViewModelRole: {
        m_lastAccessedModelType = TypeWeek;

        if (m_datesToAdd > 5 && idx.row() < 2 && m_weekViewModels.count() < 3) {
            return {};
        }

        if (!m_weekViewModels.contains(startDate)) {
            m_weekViewModels[startDate] = generateHourlyIncidenceModel(startDate, 7, 15, true);

            m_liveWeekViewModelKeys.enqueue(startDate);
            cleanUpModels();
        } else {
            requeue(m_liveWeekViewModelKeys, startDate);
        }

        return QVariant::fromValue(m_weekViewModels[startDate]);
    }
    case WeekViewMultiDayModelRole: {
        m_lastAccessedModelType = TypeWeekMultiDay;

        if (m_datesToAdd > 5 && idx.row() < 2 && m_weekViewMultiDayModels.count() < 3) {
            return {};
        }

        if (!m_weekViewMultiDayModels.contains(startDate)) {
            m_weekViewMultiDayModels[startDate] = generateMultiDayIncidenceModel(startDate, 7, 7);
            m_weekViewMultiDayModels[startDate]->setFilters(MultiDayIncidenceModel::AllDayOnly | MultiDayIncidenceModel::MultiDayOnly);

            m_liveWeekViewMultiDayModelKeys.enqueue(startDate);
            cleanUpModels();
        } else {
            requeue(m_liveWeekViewMultiDayModelKeys, startDate);
        }

        return QVariant::fromValue(m_weekViewMultiDayModels[startDate]);
    }
    case ThreeDayViewModelRole: {
        m_lastAccessedModelType = TypeThreeDay;

        if (m_datesToAdd > 5 && idx.row() < 2 && m_threeDayViewModels.count() < 3) {
            return {};
        }

        if (!m_threeDayViewModels.contains(startDate)) {
            m_threeDayViewModels[startDate] = generateHourlyIncidenceModel(startDate, 3, 15);

            m_liveThreeDayViewModelKeys.enqueue(startDate);
            cleanUpModels();
        } else {
            requeue(m_liveThreeDayViewModelKeys, startDate);
        }

        return QVariant::fromValue(m_threeDayViewModels[startDate]);
    }
    case ThreeDayViewMultiDayModelRole: {
        m_lastAccessedModelType = TypeThreeDayMultiDay;

        if (m_datesToAdd > 5 && idx.row() < 2 && m_threeDayViewMultiDayModels.count() < 3) {
            return {};
        }

        if (!m_threeDayViewMultiDayModels.contains(startDate)) {
            m_threeDayViewMultiDayModels[startDate] = generateMultiDayIncidenceModel(startDate, 3, 3);
            m_threeDayViewMultiDayModels[startDate]->setFilters(MultiDayIncidenceModel::AllDayOnly | MultiDayIncidenceModel::MultiDayOnly);

            m_liveThreeDayViewMultiDayModelKeys.enqueue(startDate);
            cleanUpModels();
        } else {
            requeue(m_liveThreeDayViewMultiDayModelKeys, startDate);
        }

        return QVariant::fromValue(m_threeDayViewMultiDayModels[startDate]);
    }
    case DayViewModelRole: {
        m_lastAccessedModelType = TypeDay;

        if (m_datesToAdd > 5 && idx.row() < 2 && m_dayViewModels.count() < 3) {
            return {};
        }

        if (!m_dayViewModels.contains(startDate)) {
            m_dayViewModels[startDate] = generateHourlyIncidenceModel(startDate, 1, 15);

            m_liveDayViewModelKeys.enqueue(startDate);
            cleanUpModels();
        } else {
            requeue(m_liveDayViewModelKeys, startDate);
        }

        return QVariant::fromValue(m_dayViewModels[startDate]);
    }
    case DayViewMultiDayModelRole: {
        m_lastAccessedModelType = TypeDayMultiDay;

        if (m_datesToAdd > 5 && idx.row() < 2 && m_dayViewMultiDayModels.count() < 3) {
            return {};
        }

        if (!m_dayViewMultiDayModels.contains(startDate)) {
            m_dayViewMultiDayModels[startDate] = generateMultiDayIncidenceModel(startDate, 1, 1);
            m_dayViewMultiDayModels[startDate]->setFilters(MultiDayIncidenceModel::AllDayOnly | MultiDayIncidenceModel::MultiDayOnly);

            m_liveDayViewMultiDayModelKeys.enqueue(startDate);
            cleanUpModels();
        } else {
            requeue(m_liveDayViewMultiDayModelKeys, startDate);
        }

        return QVariant::fromValue(m_dayViewMultiDayModels[startDate]);
    }
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

int InfiniteCalendarViewModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_startDates.length();
}

QHash<int, QByteArray> InfiniteCalendarViewModel::roleNames() const
{
    return {
        {StartDateRole, QByteArrayLiteral("startDate")},
        {FirstDayOfMonthRole, QByteArrayLiteral("firstDay")},
        {SelectedMonthRole, QByteArrayLiteral("selectedMonth")},
        {SelectedYearRole, QByteArrayLiteral("selectedYear")},
        {MonthViewModelRole, QByteArrayLiteral("monthViewModel")},
        {ScheduleViewModelRole, QByteArrayLiteral("scheduleViewModel")},
        {WeekViewModelRole, QByteArrayLiteral("weekViewModel")},
        {WeekViewMultiDayModelRole, QByteArrayLiteral("weekViewDayGridViewModel")},
        {ThreeDayViewModelRole, QByteArrayLiteral("threeDayViewModel")},
        {ThreeDayViewMultiDayModelRole, QByteArrayLiteral("threeDayViewDayGridViewModel")},
        {DayViewModelRole, QByteArrayLiteral("dayViewModel")},
        {DayViewMultiDayModelRole, QByteArrayLiteral("dayViewDayGridViewModel")},
    };
}

void InfiniteCalendarViewModel::addDates(bool atEnd, const QDate startFrom)
{
    switch (m_scale) {
    case DayScale:
        addDayDates(atEnd, startFrom);
        break;
    case ThreeDayScale:
        addDayDates(atEnd, startFrom, 3);
        break;
    case WeekScale:
        addWeekDates(atEnd, startFrom);
        break;
    case MonthScale:
        addMonthDates(atEnd, startFrom);
        break;
    case YearScale:
        addYearDates(atEnd, startFrom);
        break;
    case DecadeScale:
        addDecadeDates(atEnd, startFrom);
        break;
    }
}

void InfiniteCalendarViewModel::addDayDates(bool atEnd, const QDate &startFrom, int amount)
{
    const auto toLocalizedIndex = [&](const QDate &date) {
        if(!date.isValid()) {
            return -1;
        }

        // Convert to index of m_hiddenSpaces, which requires localising the day of the week
        int localizedIndex = date.dayOfWeek() - m_locale.firstDayOfWeek();
        if (localizedIndex < 0) {
            localizedIndex *= -1;
        }

        return localizedIndex;
    };

    const auto adjustStartDate = [&](const QDate &date) {
        if(!date.isValid()) {
            return QDate();
        }

        auto adjustedDate = date;
        auto spaceIndex = toLocalizedIndex(adjustedDate);
        while (m_hiddenSpaces[spaceIndex]) {
            adjustedDate = adjustedDate.addDays(1);
            spaceIndex = toLocalizedIndex(adjustedDate);
        }

        return adjustedDate;
    };

    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addDays(amount) : m_startDates[0].addDays(-amount);

        if (atEnd) {
            if (!m_startDates.empty() && amount > 1) {
                // Check hidden days in prior week and push forward if there are
                auto priorStart = m_startDates.constLast();
                auto spaceIndex = toLocalizedIndex(priorStart);

                for (int i = 0; i < amount - 1; i++) {
                    spaceIndex = ++spaceIndex % 7;
                    if (m_hiddenSpaces[spaceIndex]) {
                        startDate = startDate.addDays(1);
                    }
                }
            }

            m_startDates.append(adjustStartDate(startDate));
        } else {
            auto adjustedStartDate = adjustStartDate(startDate);
            // If we end up getting an adjusted start date that we already have as a start date, do the next set instead
            auto backOffset = amount;
            while(m_startDates.constFirst() == adjustedStartDate) {
                adjustedStartDate = adjustStartDate(adjustedStartDate.addDays(-backOffset));
                backOffset += amount;
            }
            m_startDates.insert(0, adjustedStartDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addWeekDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addDays(7) : m_startDates[0].addDays(-7);

        if (startDate.dayOfWeek() != m_locale.firstDayOfWeek()) {
            startDate = startDate.addDays(-startDate.dayOfWeek() + m_locale.firstDayOfWeek());
        }

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addMonthDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        const QDate firstDay = startFrom.isValid() && i == 0 ? startFrom
            : atEnd                                          ? m_firstDayOfMonthDates[rowCount() - 1].addMonths(1)
                                                             : m_firstDayOfMonthDates[0].addMonths(-1);
        QDate startDate = firstDay;

        startDate = startDate.addDays(-startDate.dayOfWeek() + m_locale.firstDayOfWeek());
        if (startDate >= firstDay) {
            startDate = startDate.addDays(-7);
        }

        if (atEnd) {
            m_firstDayOfMonthDates.append(firstDay);
            m_startDates.append(startDate);
        } else {
            m_firstDayOfMonthDates.insert(0, firstDay);
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addYearDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addYears(1) : m_startDates[0].addYears(-1);

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

void InfiniteCalendarViewModel::addDecadeDates(bool atEnd, const QDate &startFrom)
{
    const int newRow = atEnd ? rowCount() : 0;

    beginInsertRows(QModelIndex(), newRow, newRow + m_datesToAdd - 1);

    for (int i = 0; i < m_datesToAdd; i++) {
        QDate startDate = startFrom.isValid() && i == 0 ? startFrom : atEnd ? m_startDates[rowCount() - 1].addYears(10) : m_startDates[0].addYears(-10);

        if (atEnd) {
            m_startDates.append(startDate);
        } else {
            m_startDates.insert(0, startDate);
        }
    }

    endInsertRows();
}

int InfiniteCalendarViewModel::datesToAdd() const
{
    return m_datesToAdd;
}

void InfiniteCalendarViewModel::setDatesToAdd(int datesToAdd)
{
    m_datesToAdd = datesToAdd;
    Q_EMIT datesToAddChanged();
}

int InfiniteCalendarViewModel::scale()
{
    return m_scale;
}

void InfiniteCalendarViewModel::setScale(int scale)
{
    beginResetModel();

    m_startDates.clear();
    m_firstDayOfMonthDates.clear();

    m_scale = scale;
    setup();
    Q_EMIT scaleChanged();

    endResetModel();
}

Akonadi::ETMCalendar::Ptr InfiniteCalendarViewModel::calendar()
{
    return m_calendar;
}

void InfiniteCalendarViewModel::setCalendar(Akonadi::ETMCalendar::Ptr calendar)
{
    m_insertedIds.clear();
    m_calendar = calendar;

    for (auto model : std::as_const(m_monthViewModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_scheduleViewModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_weekViewModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_weekViewMultiDayModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_threeDayViewModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_threeDayViewMultiDayModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_dayViewModels)) {
        model->model()->setCalendar(calendar);
    }

    for (auto model : std::as_const(m_dayViewMultiDayModels)) {
        model->model()->setCalendar(calendar);
    }

    Q_EMIT calendarChanged();
}

QVariantMap InfiniteCalendarViewModel::filter() const
{
    return mFilter;
}

void InfiniteCalendarViewModel::setFilter(const QVariantMap &filter)
{
    mFilter = filter;
    for (auto model : std::as_const(m_monthViewModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_scheduleViewModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_weekViewModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_weekViewMultiDayModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_threeDayViewModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_threeDayViewMultiDayModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_dayViewModels)) {
        model->model()->setFilter(filter);
    }
    for (auto model : std::as_const(m_dayViewMultiDayModels)) {
        model->model()->setFilter(filter);
    }
    Q_EMIT filterChanged();
}

int InfiniteCalendarViewModel::maxLiveModels()
{
    return m_maxLiveModels;
}

void InfiniteCalendarViewModel::setMaxLiveModels(int maxLiveModels)
{
    m_maxLiveModels = maxLiveModels;
    Q_EMIT maxLiveModelsChanged();
}
