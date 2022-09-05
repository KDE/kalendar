// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "incidenceoccurrencemodel.h"
#include "kalendar_debug.h"

#include "../filter.h"
#include <Akonadi/EntityTreeModel>
#include <KCalendarCore/MemoryCalendar>
#include <KCalendarCore/OccurrenceIterator>
#include <KConfigGroup>
#include <KLocalizedString>
#include <KSharedConfig>
#include <QMetaEnum>

IncidenceOccurrenceModel::IncidenceOccurrenceModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_coreCalendar(nullptr)
{
    mRefreshTimer.setSingleShot(true);
    QObject::connect(&mRefreshTimer, &QTimer::timeout, this, &IncidenceOccurrenceModel::updateFromSource);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    m_colorWatcher = KConfigWatcher::create(config);

    // This is quite slow; would be nice to find a quicker way
    QObject::connect(m_colorWatcher.data(), &KConfigWatcher::configChanged, this, &IncidenceOccurrenceModel::updateFromSource);

    load();
}

void IncidenceOccurrenceModel::setStart(const QDate &start)
{
    if (start != mStart) {
        mStart = start;
        updateQuery();
        Q_EMIT startChanged();
    }
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
    updateQuery();
    Q_EMIT lengthChanged();
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
    updateQuery();
    Q_EMIT filterChanged();
}

void IncidenceOccurrenceModel::updateQuery()
{
    if (!m_coreCalendar) {
        return;
    }

    if (!mLength || !mStart.isValid()) {
        refreshView();
        return;
    }
    mEnd = mStart.addDays(mLength);

    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::dataChanged, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsInserted, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsRemoved, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::modelReset, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar.get(), &Akonadi::ETMCalendar::collectionsRemoved, this, &IncidenceOccurrenceModel::refreshView);

    refreshView();
}

void IncidenceOccurrenceModel::refreshView()
{
    if (!mRefreshTimer.isActive()) {
        // Instant update, but then only refresh every 100ms max.
        mRefreshTimer.start(100);
    }
}

void IncidenceOccurrenceModel::updateFromSource()
{
    beginResetModel();

    m_incidences.clear();
    load();

    if (m_coreCalendar) {
        KCalendarCore::OccurrenceIterator occurrenceIterator{*m_coreCalendar, QDateTime{mStart, {0, 0, 0}}, QDateTime{mEnd, {12, 59, 59}}};

        while (occurrenceIterator.hasNext()) {
            occurrenceIterator.next();
            const auto incidence = occurrenceIterator.incidence();

            if (mFilter && mFilter->tags().length() > 0) {
                bool match = false;
                QStringList tags = mFilter->tags();
                for (const auto &tag : tags) {
                    if (incidence->categories().contains(tag)) {
                        match = true;
                        break;
                    }
                }

                if (!match) {
                    continue;
                }
            }

            auto start = occurrenceIterator.occurrenceStartDate();
            auto end = incidence->endDateForStart(start);

            if (incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
                KCalendarCore::Todo::Ptr todo = incidence.staticCast<KCalendarCore::Todo>();

                if (!start.isValid()) { // Todos are very likely not to have a set start date
                    start = todo->dtDue();
                }
            }

            if (start.date() < mEnd && end.date() >= mStart) {
                m_incidences.append(Occurrence{
                    start,
                    end,
                    incidence,
                    getColor(incidence),
                    getCollectionId(incidence),
                    incidence->allDay(),
                });
            }
        }
    }

    endResetModel();
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
    auto incidence = m_incidences.at(idx.row());
    auto icalIncidence = incidence.incidence;
    const KCalendarCore::Duration duration(incidence.start, incidence.end);

    switch (role) {
    case Summary:
        return icalIncidence->summary();
    case Description:
        return icalIncidence->description();
    case Location:
        return icalIncidence->location();
    case StartTime:
        return incidence.start;
    case EndTime:
        return incidence.end;
    case Duration:
        return QVariant::fromValue(duration);
    case DurationString: {
        if (duration.asSeconds() == 0) {
            return QString();
        }

        return m_format.formatSpelloutDuration(duration.asSeconds() * 1000);
    }
    case Recurs:
        return icalIncidence->recurs();
    case HasReminders:
        return icalIncidence->alarms().length() > 0;
    case Priority:
        return icalIncidence->priority();
    case Color:
        return incidence.color;
    case CollectionId:
        return incidence.collectionId;
    case AllDay:
        return incidence.allDay;
    case TodoCompleted: {
        if (icalIncidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
            return false;
        }

        auto todo = icalIncidence.staticCast<KCalendarCore::Todo>();
        return todo->isCompleted();
    }
    case IsOverdue: {
        if (icalIncidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
            return false;
        }

        auto todo = icalIncidence.staticCast<KCalendarCore::Todo>();
        return todo->isOverdue();
    }
    case IsReadOnly: {
        const auto collection = m_coreCalendar->collection(incidence.collectionId);
        return collection.rights().testFlag(Akonadi::Collection::ReadOnly);
    }
    case IncidenceId:
        return icalIncidence->uid();
    case IncidenceType:
        return icalIncidence->type();
    case IncidenceTypeStr:
        return icalIncidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n(icalIncidence->typeStr().constData());
    case IncidenceTypeIcon:
        return icalIncidence->iconName();
    case IncidencePtr:
        return QVariant::fromValue(icalIncidence);
    case IncidenceOccurrence:
        return QVariant::fromValue(incidence);
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

void IncidenceOccurrenceModel::setCalendar(Akonadi::ETMCalendar::Ptr calendar)
{
    if (m_coreCalendar == calendar) {
        return;
    }
    m_coreCalendar = calendar;
    updateQuery();
    Q_EMIT calendarChanged();
}

Akonadi::ETMCalendar::Ptr IncidenceOccurrenceModel::calendar() const
{
    return m_coreCalendar;
}

void IncidenceOccurrenceModel::load()
{
    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    const QStringList colorKeyList = rColorsConfig.keyList();

    for (const QString &key : colorKeyList) {
        QColor color = rColorsConfig.readEntry(key, QColor("blue"));
        m_colors[key] = color;
    }
}
