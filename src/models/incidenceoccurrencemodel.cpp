// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "incidenceoccurrencemodel.h"
#include "kalendar_debug.h"

#include "../filter.h"
#include "../utils.h"
#include <Akonadi/EntityTreeModel>
#include <KCalendarCore/OccurrenceIterator>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QMetaEnum>

IncidenceOccurrenceModel::IncidenceOccurrenceModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_coreCalendar(nullptr)
{
    m_resetThrottlingTimer.setSingleShot(true);
    QObject::connect(&m_resetThrottlingTimer, &QTimer::timeout, this, &IncidenceOccurrenceModel::resetFromSource);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    m_colorWatcher = KConfigWatcher::create(config);

    // This is quite slow; would be nice to find a quicker way
    connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &IncidenceOccurrenceModel::resetFromSource);
}

void IncidenceOccurrenceModel::setStart(const QDate &start)
{
    if (start == mStart) {
        return;
    }

    mStart = start;
    Q_EMIT startChanged();

    mEnd = mStart.addDays(mLength);
    scheduleReset();
}

QDate IncidenceOccurrenceModel::start() const
{
    return mStart;
}

void IncidenceOccurrenceModel::setLength(int length)
{
    if (mLength == length) {
        return;
    }
    mLength = length;
    Q_EMIT lengthChanged();

    mEnd = mStart.addDays(mLength);
    scheduleReset();
}

int IncidenceOccurrenceModel::length() const
{
    return mLength;
}

Filter *IncidenceOccurrenceModel::filter() const
{
    return mFilter;
}

void IncidenceOccurrenceModel::setFilter(Filter *filter)
{
    mFilter = filter;
    Q_EMIT filterChanged();

    scheduleReset();
}

bool IncidenceOccurrenceModel::loading() const
{
    return m_loading;
}

void IncidenceOccurrenceModel::setLoading(const bool loading)
{
    if (loading == m_loading) {
        return;
    }

    m_loading = loading;
    Q_EMIT loadingChanged();
}

int IncidenceOccurrenceModel::resetThrottleInterval() const
{
    return m_resetThrottleInterval;
}

void IncidenceOccurrenceModel::setResetThrottleInterval(const int resetThrottleInterval)
{
    if (resetThrottleInterval == m_resetThrottleInterval) {
        return;
    }

    m_resetThrottleInterval = resetThrottleInterval;
    Q_EMIT resetThrottleIntervalChanged();
}

void IncidenceOccurrenceModel::scheduleReset()
{
    if (!m_resetThrottlingTimer.isActive()) {
        // Instant update, but then only refresh every interval at most.
        m_resetThrottlingTimer.start(m_resetThrottleInterval);
    }
}

void IncidenceOccurrenceModel::resetFromSource()
{
    if (!m_coreCalendar) {
        qCWarning(KALENDAR_LOG) << "Not resetting IOC from source as no core calendar set.";
        return;
    }

    setLoading(true);

    if (m_resetThrottlingTimer.isActive() || m_coreCalendar->isLoading()) {
        // If calendar is still loading then just schedule a refresh later
        // If refresh timer already active this won't restart it
        scheduleReset();
        return;
    }

    loadColors();

    beginResetModel();

    m_incidences.clear();
    m_occurrenceIndexHash.clear();

    KCalendarCore::OccurrenceIterator occurrenceIterator(*m_coreCalendar, QDateTime(mStart, {0, 0, 0}), QDateTime(mEnd, {12, 59, 59}));

    while (occurrenceIterator.hasNext()) {
        occurrenceIterator.next();
        const auto incidence = occurrenceIterator.incidence();

        if (!incidencePassesFilter(incidence)) {
            continue;
        }

        const auto occurrenceStartEnd = incidenceOccurrenceStartEnd(occurrenceIterator.occurrenceStartDate(), incidence);
        const auto start = occurrenceStartEnd.first;
        const auto end = occurrenceStartEnd.second;
        const auto occurrenceHashKey = incidenceOccurrenceHash(start, end, incidence->uid());
        const Occurrence occurrence{
            start,
            end,
            incidence,
            getColor(incidence),
            getCollectionId(incidence),
            incidence->allDay(),
        };

        const auto indexRow = m_incidences.count();
        m_incidences.append(occurrence);

        const auto occurrenceIndex = index(indexRow);
        const QPersistentModelIndex persistentIndex(occurrenceIndex);

        m_occurrenceIndexHash.insert(occurrenceHashKey, persistentIndex);
    }

    endResetModel();

    setLoading(false);
}

void IncidenceOccurrenceModel::slotSourceDataChanged(const QModelIndex &upperLeft, const QModelIndex &bottomRight)
{
    if (!m_coreCalendar || !upperLeft.isValid() || !bottomRight.isValid() || m_resetThrottlingTimer.isActive()) {
        return;
    }

    setLoading(true);

    const auto startRow = upperLeft.row();
    const auto endRow = bottomRight.row();

    for (int i = startRow; i <= endRow; ++i) {
        const auto sourceModelIndex = m_coreCalendar->model()->index(i, 0, upperLeft.parent());
        const auto incidenceItem = sourceModelIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();

        if (!incidenceItem.isValid() || !incidenceItem.hasPayload<KCalendarCore::Incidence::Ptr>()) {
            continue;
        }

        const auto incidence = incidenceItem.payload<KCalendarCore::Incidence::Ptr>();
        KCalendarCore::OccurrenceIterator occurrenceIterator{*m_coreCalendar, incidence, QDateTime{mStart, {0, 0, 0}}, QDateTime{mEnd, {12, 59, 59}}};

        while (occurrenceIterator.hasNext()) {
            occurrenceIterator.next();

            const auto occurrenceStartEnd = incidenceOccurrenceStartEnd(occurrenceIterator.occurrenceStartDate(), incidence);
            const auto start = occurrenceStartEnd.first;
            const auto end = occurrenceStartEnd.second;
            const auto occurrenceHashKey = incidenceOccurrenceHash(start, end, incidence->uid());

            if (!m_occurrenceIndexHash.contains(occurrenceHashKey)) {
                continue;
            }

            const Occurrence occurrence{
                start,
                end,
                incidence,
                getColor(incidence),
                getCollectionId(incidence),
                incidence->allDay(),
            };

            const auto existingOccurrenceIndex = m_occurrenceIndexHash.value(occurrenceHashKey);
            const auto existingOccurrenceRow = existingOccurrenceIndex.row();

            m_incidences.replace(existingOccurrenceRow, occurrence);
            Q_EMIT dataChanged(existingOccurrenceIndex, existingOccurrenceIndex);
        }
    }

    setLoading(false);
}

void IncidenceOccurrenceModel::slotSourceRowsInserted(const QModelIndex &parent, const int first, const int last)
{
    if (!m_coreCalendar || m_resetThrottlingTimer.isActive()) {
        return;
    } else if (m_coreCalendar->isLoading()) {
        m_resetThrottlingTimer.start(m_resetThrottleInterval);
        return;
    }

    setLoading(true);

    for (int i = first; i <= last; ++i) {
        const auto sourceModelIndex = m_coreCalendar->model()->index(i, 0, parent);
        const auto incidenceItem = sourceModelIndex.data(Akonadi::EntityTreeModel::ItemRole).value<Akonadi::Item>();

        if (!incidenceItem.isValid() || !incidenceItem.hasPayload<KCalendarCore::Incidence::Ptr>()) {
            continue;
        }

        const auto incidence = incidenceItem.payload<KCalendarCore::Incidence::Ptr>();

        if (!incidencePassesFilter(incidence)) {
            continue;
        }

        KCalendarCore::OccurrenceIterator occurrenceIterator{*m_coreCalendar, incidence, QDateTime{mStart, {0, 0, 0}}, QDateTime{mEnd, {12, 59, 59}}};

        while (occurrenceIterator.hasNext()) {
            occurrenceIterator.next();

            const auto occurrenceStartEnd = incidenceOccurrenceStartEnd(occurrenceIterator.occurrenceStartDate(), incidence);
            const auto start = occurrenceStartEnd.first;
            const auto end = occurrenceStartEnd.second;
            const auto occurrenceHashKey = incidenceOccurrenceHash(start, end, incidence->uid());

            if (m_occurrenceIndexHash.contains(occurrenceHashKey)) {
                continue;
            }

            const Occurrence occurrence{
                start,
                end,
                incidence,
                getColor(incidence),
                getCollectionId(incidence),
                incidence->allDay(),
            };

            const auto indexRow = m_incidences.count();

            beginInsertRows({}, indexRow, indexRow);
            m_incidences.append(occurrence);
            endInsertRows();

            const auto occurrenceIndex = index(indexRow);
            const QPersistentModelIndex persistentIndex(occurrenceIndex);

            m_occurrenceIndexHash.insert(occurrenceHashKey, persistentIndex);
        }
    }

    setLoading(false);
}

int IncidenceOccurrenceModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid()) {
        return m_incidences.size();
    }
    return 0;
}

qint64 IncidenceOccurrenceModel::getCollectionId(const KCalendarCore::Incidence::Ptr &incidence)
{
    auto item = m_coreCalendar->item(incidence);
    if (!item.isValid()) {
        return {};
    }
    auto collection = item.parentCollection();
    if (!collection.isValid()) {
        return {};
    }
    return collection.id();
}

QColor IncidenceOccurrenceModel::getColor(const KCalendarCore::Incidence::Ptr &incidence)
{
    auto item = m_coreCalendar->item(incidence);
    if (!item.isValid()) {
        return {};
    }
    auto collection = item.parentCollection();
    if (!collection.isValid()) {
        return {};
    }
    const QString id = QString::number(collection.id());
    // qDebug() << "Collection id: " << collection.id();

    if (m_colors.contains(id)) {
        // qDebug() << collection.id() << "Found in m_colors";
        return m_colors[id];
    }

    return {};
}

QVariant IncidenceOccurrenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }

    const auto occurrence = m_incidences.at(idx.row());
    const auto incidence = occurrence.incidence;

    switch (role) {
    case Summary:
        return incidence->summary();
    case Description:
        return incidence->description();
    case Location:
        return incidence->location();
    case StartTime:
        return occurrence.start;
    case EndTime:
        return occurrence.end;
    case Duration: {
        const KCalendarCore::Duration duration(occurrence.start, occurrence.end);
        return QVariant::fromValue(duration);
    }
    case DurationString: {
        const KCalendarCore::Duration duration(occurrence.start, occurrence.end);
        return Utils::formatSpelloutDuration(duration, m_format, occurrence.allDay);
    }
    case Recurs:
        return incidence->recurs();
    case HasReminders:
        return incidence->alarms().length() > 0;
    case Priority:
        return incidence->priority();
    case Color:
        return occurrence.color;
    case CollectionId:
        return occurrence.collectionId;
    case AllDay:
        return occurrence.allDay;
    case TodoCompleted: {
        if (incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
            return false;
        }

        auto todo = incidence.staticCast<KCalendarCore::Todo>();
        return todo->isCompleted();
    }
    case IsOverdue: {
        if (incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
            return false;
        }

        auto todo = incidence.staticCast<KCalendarCore::Todo>();
        return todo->isOverdue();
    }
    case IsReadOnly: {
        const auto collection = m_coreCalendar->collection(occurrence.collectionId);
        return collection.rights().testFlag(Akonadi::Collection::ReadOnly);
    }
    case IncidenceId:
        return incidence->uid();
    case IncidenceType:
        return incidence->type();
    case IncidenceTypeStr:
        return incidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n(incidence->typeStr().constData());
    case IncidenceTypeIcon:
        return incidence->iconName();
    case IncidencePtr:
        return QVariant::fromValue(incidence);
    case IncidenceOccurrence:
        return QVariant::fromValue(occurrence);
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for occurrence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

void IncidenceOccurrenceModel::setCalendar(Akonadi::ETMCalendar::Ptr calendar)
{
    if (m_coreCalendar == calendar) {
        return;
    }
    m_coreCalendar = calendar;

    connect(m_coreCalendar->model(), &QAbstractItemModel::dataChanged, this, &IncidenceOccurrenceModel::slotSourceDataChanged);
    connect(m_coreCalendar->model(), &QAbstractItemModel::rowsInserted, this, &IncidenceOccurrenceModel::slotSourceRowsInserted);
    connect(m_coreCalendar->model(), &QAbstractItemModel::rowsRemoved, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar->model(), &QAbstractItemModel::modelReset, this, &IncidenceOccurrenceModel::scheduleReset);
    connect(m_coreCalendar.get(), &Akonadi::ETMCalendar::collectionsRemoved, this, &IncidenceOccurrenceModel::scheduleReset);

    Q_EMIT calendarChanged();

    scheduleReset();
}

Akonadi::ETMCalendar::Ptr IncidenceOccurrenceModel::calendar() const
{
    return m_coreCalendar;
}

void IncidenceOccurrenceModel::loadColors()
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = rColorsConfig.keyList();

    for (const QString &key : colorKeyList) {
        QColor color = rColorsConfig.readEntry(key, QColor("blue"));
        m_colors[key] = color;
    }
}

std::pair<QDateTime, QDateTime> IncidenceOccurrenceModel::incidenceOccurrenceStartEnd(const QDateTime &ocStart, const KCalendarCore::Incidence::Ptr &incidence)
{
    auto start = ocStart;
    const auto end = incidence->endDateForStart(start);

    if (incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
        KCalendarCore::Todo::Ptr todo = incidence.staticCast<KCalendarCore::Todo>();

        if (!start.isValid()) { // Todos are very likely not to have a set start date
            start = todo->dtDue();
        }
    }

    return {start, end};
}

uint IncidenceOccurrenceModel::incidenceOccurrenceHash(const QDateTime &ocStart, const QDateTime &ocEnd, const QString &incidenceUid)
{
    return qHash(QString::number(ocStart.toSecsSinceEpoch()) + QString::number(ocEnd.toSecsSinceEpoch()) + incidenceUid);
}

bool IncidenceOccurrenceModel::incidencePassesFilter(const KCalendarCore::Incidence::Ptr &incidence)
{
    if (!mFilter || mFilter->tags().empty()) {
        return true;
    }

    auto match = false;
    const auto tags = mFilter->tags();
    for (const auto &tag : tags) {
        if (incidence->categories().contains(tag)) {
            match = true;
            break;
        }
    }

    return match;
}
