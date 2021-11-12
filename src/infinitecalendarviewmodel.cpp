// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "incidenceoccurrencemodel.h"
#include <QAbstractItemModel>
#include <QDebug>
#include <QMetaEnum>
#include <akonadi_version.h>
#include <cmath>
#include <infinitecalendarviewmodel.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/EntityTreeModel>
#else
#include <AkonadiCore/EntityTreeModel>
#endif

InfiniteCalendarViewModel::InfiniteCalendarViewModel(QObject *parent)
    : QAbstractListModel(parent)
{
    setup();

    ModelMetaData monthModel = {QVector<QDate>(), 42, TypeMonth, &m_monthViewModels, {}, &m_liveMonthViewModelKeys};
    ModelMetaData scheduleModel = {QVector<QDate>(), 0, TypeSchedule, &m_scheduleViewModels, {}, &m_liveScheduleViewModelKeys};
    ModelMetaData weekModel = {QVector<QDate>(), 7, TypeWeek, {}, &m_weekViewModels, &m_liveWeekViewModelKeys};
    ModelMetaData weekMultiDayModel = {QVector<QDate>(), 7, TypeWeekMultiDay, &m_weekViewMultiDayModels, {}, &m_liveWeekViewMultiDayModelKeys};

    m_models = QVector<ModelMetaData>{monthModel, scheduleModel, weekModel, weekMultiDayModel};

    m_triggerUpdatesTimer.setSingleShot(true);
    QObject::connect(&m_triggerUpdatesTimer, &QTimer::timeout, this, [&]() {
        if (m_calendar->isLoaded()) { // Save cycles
            for (auto &model : m_models) {
                if (model.modelType != TypeWeek) {
                    for (const auto &startDate : std::as_const(model.affectedStartDates)) {
                        if (model.multiDayModels->value(startDate) != nullptr) {
                            model.multiDayModels->value(startDate)->model()->updateQuery();
                        }
                    }
                } else {
                    for (const auto &startDate : std::as_const(model.affectedStartDates)) {
                        if (model.weekModels->value(startDate) != nullptr) {
                            model.weekModels->value(startDate)->model()->updateQuery();
                        }
                    }
                }
            }
        } else {
            m_triggerUpdatesTimer.start(); // Avoid situation where no calls are made after cal loaded
        }
    });
}

void InfiniteCalendarViewModel::setup()
{
    const QDate today = QDate::currentDate();
    QTime time;

    if (!m_weekViewLocalisedHourLabels.length()) {
        m_weekViewLocalisedHourLabels.clear();
        for (int i = 1; i < 24; i++) {
            time.setHMS(i, 0, 0);
            m_weekViewLocalisedHourLabels.append(QLocale::system().toString(time, QLocale::NarrowFormat));
        }
    }

    switch (m_scale) {
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
        model->model()->setHandleOwnRefresh(false);
        model->model()->setStart(start);
        model->model()->setLength(length);
        model->model()->setFilter(mFilter);
        model->model()->setCalendar(m_calendar);

        return model;
    };

    auto cleanUpModels = [&, this]() {
        int numLiveModels = m_liveMonthViewModelKeys.length() + m_liveScheduleViewModelKeys.length() + m_liveWeekViewModelKeys.length()
            + m_liveWeekViewMultiDayModelKeys.length();

        while (numLiveModels > m_maxLiveModels) {
            for (int i = 0; i < m_models.length(); i++) {
                if (m_models[i].liveKeysQueue->length() > m_maxLiveModels) {
                    while (m_models[i].liveKeysQueue->length() > m_maxLiveModels) {
                        auto firstKey = m_models[i].liveKeysQueue->dequeue();

                        if (m_models[i].modelType == TypeWeek && m_models[i].weekModels->contains(firstKey)) {
                            delete m_models[i].weekModels->value(firstKey);
                            m_models[i].weekModels->remove(firstKey);
                        } else if (m_models[i].multiDayModels->contains(firstKey)) {
                            delete m_models[i].multiDayModels->value(firstKey);
                            m_models[i].multiDayModels->remove(firstKey);
                        }
                    }

                } else if(m_models[i].modelType == m_lastAccessedModelType/* ||
                   ((m_lastAccessedModelType == TypeWeek && m_models[i].modelType == TypeWeekMultiDay) ||
                   (m_lastAccessedModelType == TypeWeekMultiDay && m_models[i].modelType == TypeWeek))*/) {
                    continue;

                } else if (m_models[i].liveKeysQueue->length() > 0) {
                    auto firstKey = m_models[i].liveKeysQueue->dequeue();

                    if (m_models[i].modelType == TypeWeek && m_models[i].weekModels->contains(firstKey)) {
                        delete m_models[i].weekModels->value(firstKey);
                        m_models[i].weekModels->remove(firstKey);
                    } else if (m_models[i].multiDayModels->contains(firstKey)) {
                        delete m_models[i].multiDayModels->value(firstKey);
                        m_models[i].multiDayModels->remove(firstKey);
                    }
                }

                numLiveModels = m_liveMonthViewModelKeys.length() + m_liveScheduleViewModelKeys.length() + m_liveWeekViewModelKeys.length()
                    + m_liveWeekViewMultiDayModelKeys.length();
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
            if (!m_monthViewModels.contains(startDate)) {
                m_monthViewModels[startDate] = generateMultiDayIncidenceModel(startDate, 42, 7);

                m_liveMonthViewModelKeys.enqueue(startDate);
                cleanUpModels();
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
            }

            return QVariant::fromValue(m_scheduleViewModels[firstDay]);
        }
        default:
            qWarning() << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
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
            m_weekViewModels[startDate] = new HourlyIncidenceModel;
            m_weekViewModels[startDate]->setPeriodLength(7);
            m_weekViewModels[startDate]->setFilters(HourlyIncidenceModel::NoAllDay | HourlyIncidenceModel::NoMultiDay);
            m_weekViewModels[startDate]->setModel(new IncidenceOccurrenceModel);
            m_weekViewModels[startDate]->model()->setHandleOwnRefresh(false);
            m_weekViewModels[startDate]->model()->setStart(startDate);
            m_weekViewModels[startDate]->model()->setLength(7);
            m_weekViewModels[startDate]->model()->setFilter(mFilter);
            m_weekViewModels[startDate]->model()->setCalendar(m_calendar);

            m_liveWeekViewModelKeys.enqueue(startDate);
            cleanUpModels();
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
        }

        return QVariant::fromValue(m_weekViewMultiDayModels[startDate]);
    }
    default:
        qWarning() << "Unknown role for startdate:" << QMetaEnum::fromType<Roles>().valueToKey(role);
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
        {WeekViewMultiDayModelRole, QByteArrayLiteral("weekViewMultiDayViewModel")},
    };
}

void InfiniteCalendarViewModel::addDates(bool atEnd, const QDate startFrom)
{
    switch (m_scale) {
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

Akonadi::ETMCalendar *InfiniteCalendarViewModel::calendar()
{
    return m_calendar;
}

void InfiniteCalendarViewModel::setCalendar(Akonadi::ETMCalendar *calendar)
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

    connect(m_calendar->model(), &QAbstractItemModel::dataChanged, this, &InfiniteCalendarViewModel::handleCalendarDataChanged);
    connect(m_calendar->model(), &QAbstractItemModel::rowsInserted, this, &InfiniteCalendarViewModel::handleCalendarRowsInserted);
    connect(m_calendar->model(), &QAbstractItemModel::rowsRemoved, this, &InfiniteCalendarViewModel::handleCalendarRowsRemoved);
}

void InfiniteCalendarViewModel::checkModels(const QDate &start, const QDate &end, KCalendarCore::Incidence::Ptr incidence)
{
    for (auto &model : m_models) {
        auto modelKeys = model.modelType != TypeWeek ? model.multiDayModels->keys() : model.weekModels->keys();

        for (const auto &modelStartDate : modelKeys) {
            if (model.affectedStartDates.contains(modelStartDate)) {
                continue;
            }

            QDate modelEndDate =
                model.modelType == TypeSchedule ? modelStartDate.addDays(modelStartDate.daysInMonth()) : modelStartDate.addDays(model.modelLength);

            if (incidence->recurs() && incidence->recurrence()->timesInInterval(modelStartDate.startOfDay(), modelEndDate.endOfDay()).length()) {
                model.affectedStartDates.append(modelStartDate);
            } else if (!incidence->recurs()
                       && (((start <= modelStartDate) && (end >= modelStartDate)) || ((start < modelEndDate) && (end > modelEndDate))
                           || ((start >= modelStartDate) && (end <= modelEndDate)))) {
                model.affectedStartDates.append(modelStartDate);
            }
        }
    }
}

void InfiniteCalendarViewModel::checkCalendarIndex(const QModelIndex &index)
{
    const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();

    if (item.hasPayload<KCalendarCore::Incidence::Ptr>()) {
        // If the id is already in the set then we don't need to check anything
        const auto incidence = item.payload<KCalendarCore::Incidence::Ptr>();

        if (incidence->type() == KCalendarCore::Incidence::TypeTodo) {
            const auto todo = incidence.staticCast<KCalendarCore::Todo>();
            const QDate dateStart = todo->dtStart().date();
            const QDate dateDue = todo->dtDue().date();

            if (!dateStart.isValid() && !dateDue.isValid()) {
                return;
            } else if (!dateStart.isValid()) {
                checkModels(dateDue, dateDue, incidence);
            } else {
                checkModels(dateStart, dateDue, incidence);
            }
        } else if (incidence->type() == KCalendarCore::Incidence::TypeEvent) {
            const auto event = incidence.staticCast<KCalendarCore::Event>();
            const QDate dateStart = event->dtStart().date();
            const QDate dateEnd = event->dtEnd().date();

            checkModels(dateStart, dateEnd, incidence);
        }
    }
}

void InfiniteCalendarViewModel::triggerAffectedModelUpdates()
{
    if (!m_triggerUpdatesTimer.isActive()) {
        m_triggerUpdatesTimer.start(50);
    }
}

void InfiniteCalendarViewModel::handleCalendarDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight, const QVector<int> &)
{
    const auto parent = topLeft.parent();
    int first = topLeft.row();
    int last = bottomRight.row();

    for (int i = first; i <= last; i++) {
        auto index = m_calendar->model()->index(i, 0, parent);
        checkCalendarIndex(index);
    }

    triggerAffectedModelUpdates();
}

void InfiniteCalendarViewModel::handleCalendarRowsInserted(const QModelIndex &parent, int first, int last)
{
    for (int i = first; i <= last; i++) {
        const auto index = m_calendar->model()->index(i, 0, parent);
        const auto item = index.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();

        // Sometimes the calendar updates with inserted rows for incidences that we have already checked.
        // We keep track of which incidence ids have already been checked on prior row insertions, so that
        // we can skip these ones.

        if (!m_insertedIds.contains(item.id())) {
            m_insertedIds.insert(item.id());
            checkCalendarIndex(index);
        }
    }

    triggerAffectedModelUpdates();
}

void InfiniteCalendarViewModel::handleCalendarRowsRemoved(const QModelIndex &, int, int)
{
    // We don't know if this is a collection being removed or an incidence being deleted, so be safe
    // The IncidenceOccurrenceModels also handle this themselves for this reason
    m_insertedIds.clear();
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
    Q_EMIT filterChanged();
}
