// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// Copyright (c) 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "incidenceoccurrencemodel.h"

#include <QMetaEnum>

#include <KCalendarCore/OccurrenceIterator>
#include <KCalendarCore/MemoryCalendar>
#include <KFormat>
#include <etmcalendar.h>
#include <KSharedConfig>
#include <KConfigGroup>
#include <KLocalizedString>

IncidenceOccurrenceModel::IncidenceOccurrenceModel(QObject *parent)
    : QAbstractItemModel(parent)
    , m_coreCalendar(nullptr)
{
    mRefreshTimer.setSingleShot(true);
    QObject::connect(&mRefreshTimer, &QTimer::timeout, this, &IncidenceOccurrenceModel::updateFromSource);

    KSharedConfig::Ptr config = KSharedConfig::openConfig();
    KConfigGroup rColorsConfig(config, "Resources Colors");
    colorWatcher = KConfigWatcher::create(config);

    // This is quite slow; would be nice to find a quicker way
    QObject::connect(colorWatcher.data(), &KConfigWatcher::configChanged, this, &IncidenceOccurrenceModel::updateFromSource);

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

void IncidenceOccurrenceModel::setFilter(const QVariantMap &filter)
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
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::layoutChanged, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::modelReset, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsInserted, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsMoved, this, &IncidenceOccurrenceModel::refreshView);
    QObject::connect(m_coreCalendar->model(), &QAbstractItemModel::rowsRemoved, this, &IncidenceOccurrenceModel::refreshView);

    refreshView();
}

void IncidenceOccurrenceModel::refreshView()
{
    if (!mRefreshTimer.isActive()) {
        // Instant update, but then only refresh every 50ms max.
        updateFromSource();
        mRefreshTimer.start(50);
    }
}

void IncidenceOccurrenceModel::updateFromSource()
{
    beginResetModel();

    m_incidences.clear();

    load();

    if (m_coreCalendar) {
        QMap<QByteArray, KCalendarCore::Incidence::Ptr> recurringIncidences;
        QMultiMap<QByteArray, KCalendarCore::Incidence::Ptr> exceptions;

        const auto allEvents = Calendar::sortEvents(
            m_coreCalendar->events(mStart, mEnd),
            EventSortField::EventSortStartDate,
            SortDirection::SortDirectionAscending
        ); // get all events

        const auto allTodos = Calendar::sortTodos(
            m_coreCalendar->todos(mStart, mEnd),
            TodoSortField::TodoSortDueDate, // Todos tend to not have a set start date
            SortDirection::SortDirectionAscending
        );

        Incidence::List allIncidences = Calendar::mergeIncidenceList(allEvents, allTodos, {});

        QMap<QByteArray, KCalendarCore::Incidence::Ptr> incidences;
        for (int i = 0; i < allIncidences.count(); ++i) {
            KCalendarCore::Incidence::Ptr &incidence = allIncidences[i];
            //const bool skip = [&] {
            //    for (auto it = mFilter.constBegin(); it!= mFilter.constEnd(); it++) {
            //        if (event->getProperty(it.key().toLatin1()) != it.value()) {
            //            return true;
            //        }
            //    }
            //    return false;
            //}();
            //if (skip) {
            //    continue;
            //}
            //
            // Collect recurring events and add the rest immediately
            if (incidence->recurs()) {
                recurringIncidences.insert(incidence->uid().toLatin1(), incidence);
                incidences.insert(incidence->instanceIdentifier().toLatin1(), incidence);
            } else if(incidence->recurrenceId().isValid()) {
                exceptions.insert(incidence->uid().toLatin1(), incidence);
                incidences.insert(incidence->instanceIdentifier().toLatin1(), incidence);
            } else {
                if(incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeEvent) {
                    KCalendarCore::Event::Ptr event = m_coreCalendar->event(incidence->uid());

                    if (event->dtStart().date() < mEnd && event->dtEnd().date() >= mStart) {
                        m_incidences.append(Occurrence {
                            event->dtStart(),
                            event->dtEnd(),
                            event,
                            getColor(event),
                            getCollectionId(event),
                            event->allDay()
                        });
                    }
                } else if(incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
                    KCalendarCore::Todo::Ptr todo = m_coreCalendar->todo(incidence->uid());
                    QDateTime todoStart = todo->dtStart();

                    if(!todoStart.isValid()) { // Todos are very likely not to have a set start date
                        todoStart = todo->dtDue();
                    }

                    if (todoStart.date() < mEnd && todo->dtDue().date() >= mStart) {
                        m_incidences.append(Occurrence {
                            todoStart,
                            todo->dtDue(),
                            todo,
                            getColor(todo),
                            getCollectionId(todo),
                            todo->allDay()
                        });
                    }
                }
            }

        }

        // process all recurring events and their exceptions.
        for (const auto &uid : recurringIncidences.keys()) {
            KCalendarCore::MemoryCalendar calendar{ QTimeZone::systemTimeZone() };
            calendar.addIncidence(recurringIncidences.value(uid));
            for (const auto &incidence : exceptions.values(uid)) {
                calendar.addIncidence(incidence);
            }
            KCalendarCore::OccurrenceIterator occurrenceIterator{calendar, QDateTime{mStart, {0, 0, 0}}, QDateTime{mEnd, {12, 59, 59}}};

            while (occurrenceIterator.hasNext()) {
                occurrenceIterator.next();
                const auto incidence = occurrenceIterator.incidence();
                const auto start = occurrenceIterator.occurrenceStartDate();
                const auto end = incidence->endDateForStart(start);

                if (start.date() < mEnd && end.date() >= mStart) {
                    m_incidences.append(Occurrence {
                        start,
                        end,
                        incidence,
                        getColor(incidence),
                        getCollectionId(incidence),
                        incidence->allDay()
                    });
                }
            }
        }
    }

    endResetModel();
}

QModelIndex IncidenceOccurrenceModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent)) {
        return {};
    }

    if (!parent.isValid()) {
        return createIndex(row, column);
    }
    return {};
}

QModelIndex IncidenceOccurrenceModel::parent(const QModelIndex &) const
{
    return {};
}

int IncidenceOccurrenceModel::rowCount(const QModelIndex &parent) const
{
    if (!parent.isValid()) {
        return m_incidences.size();
    }
    return 0;
}

int IncidenceOccurrenceModel::columnCount(const QModelIndex &) const
{
    return 1;
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
    //qDebug() << "Collection id: " << collection.id();

    if (m_colors.contains(id)) {
        //qDebug() << collection.id() << "Found in m_colors";
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
    KCalendarCore::Duration duration(incidence.start, incidence.end);

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
        case DurationString:
        {
            KFormat format;
            if (incidence.incidence->allDay()) {
                return format.formatSpelloutDuration(24*60*60*1000); // format milliseconds in 1 day
            } else if (duration.asSeconds() == 0) {
                return QLatin1String("");
            } else {
                return format.formatSpelloutDuration(duration.asSeconds() * 1000);
            }
        }
        case Color:
            return incidence.color;
        case CollectionId:
            return incidence.collectionId;
        case AllDay:
            return incidence.allDay;
        case TodoCompleted:
        {
            if(incidence.incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
                return false;
            }

            auto todo = incidence.incidence.staticCast<KCalendarCore::Todo>();
            return todo->isCompleted();
        }
        case IncidenceId:
            return incidence.incidence->uid();
        case IncidenceType:
            return incidence.incidence->type();
        case IncidenceTypeStr:
            return i18n(incidence.incidence->typeStr());
        case IncidenceTypeIcon:
            return incidence.incidence->iconName();
        case IncidencePtr:
            return QVariant::fromValue(incidence.incidence);
        case IncidenceOccurrence:
            return QVariant::fromValue(incidence);
        default:
            qWarning() << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

void IncidenceOccurrenceModel::setCalendar(Akonadi::ETMCalendar *calendar)
{
    if (m_coreCalendar == calendar) {
        return;
    }
    m_coreCalendar = calendar;
    updateQuery();
    Q_EMIT calendarChanged();
}

Akonadi::ETMCalendar *IncidenceOccurrenceModel::calendar() const
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
