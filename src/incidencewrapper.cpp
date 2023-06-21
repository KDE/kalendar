// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "kalendar_debug.h"
#include "utils.h"
#include <KLocalizedString>
#include <QBitArray>
#include <QJSValue>
#include <incidencewrapper.h>

IncidenceWrapper::IncidenceWrapper(QObject *parent)
    : QObject(parent)
    , Akonadi::ItemMonitor()
{
    connect(this, &IncidenceWrapper::incidencePtrChanged, &m_attendeesModel, [this](KCalendarCore::Incidence::Ptr incidencePtr) {
        m_attendeesModel.setIncidencePtr(incidencePtr);
    });
    connect(this, &IncidenceWrapper::incidencePtrChanged, &m_recurrenceExceptionsModel, [this](KCalendarCore::Incidence::Ptr incidencePtr) {
        m_recurrenceExceptionsModel.setIncidencePtr(incidencePtr);
    });
    connect(this, &IncidenceWrapper::incidencePtrChanged, &m_attachmentsModel, [this](KCalendarCore::Incidence::Ptr incidencePtr) {
        m_attachmentsModel.setIncidencePtr(incidencePtr);
    });

    // While generally we know of the relationship an incidence has regarding its parent,
    // from the POV of an incidence, we have no idea of its relationship to its children.
    // This is a limitation of KCalendarCore, which only supports one type of relationship
    // type per incidence and throughout the PIM infrastructure it is always the 'parent'
    // relationship that is used.

    // We therefore need to rely on the ETMCalendar for this information. Since the ETMCalendar
    // does not provide us with any specific information about the incidences changed when it
    // updates, we unfortunately have to this the coarse way and just update everything when
    // things change.
    connect(CalendarManager::instance(), &CalendarManager::calendarChanged, this, &IncidenceWrapper::resetChildIncidences);

    Akonadi::ItemFetchScope scope;
    scope.fetchFullPayload();
    scope.fetchAllAttributes();
    scope.setFetchRelations(true);
    scope.setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
    setFetchScope(scope);

    setNewEvent();
}

IncidenceWrapper::~IncidenceWrapper()
{
    cleanupChildIncidences();
}

void IncidenceWrapper::notifyDataChanged()
{
    Q_EMIT incidenceTypeChanged();
    Q_EMIT incidenceTypeStrChanged();
    Q_EMIT incidenceIconNameChanged();
    Q_EMIT collectionIdChanged();
    Q_EMIT parentChanged();
    Q_EMIT parentIncidenceChanged();
    Q_EMIT childIncidencesChanged();
    Q_EMIT summaryChanged();
    Q_EMIT categoriesChanged();
    Q_EMIT descriptionChanged();
    Q_EMIT locationChanged();
    Q_EMIT incidenceStartChanged();
    Q_EMIT incidenceStartDateDisplayChanged();
    Q_EMIT incidenceStartTimeDisplayChanged();
    Q_EMIT incidenceEndChanged();
    Q_EMIT incidenceEndDateDisplayChanged();
    Q_EMIT incidenceEndTimeDisplayChanged();
    Q_EMIT timeZoneChanged();
    Q_EMIT startTimeZoneUTCOffsetMinsChanged();
    Q_EMIT endTimeZoneUTCOffsetMinsChanged();
    Q_EMIT durationChanged();
    Q_EMIT durationDisplayStringChanged();
    Q_EMIT allDayChanged();
    Q_EMIT priorityChanged();
    Q_EMIT organizerChanged();
    Q_EMIT attendeesModelChanged();
    Q_EMIT recurrenceDataChanged();
    Q_EMIT recurrenceExceptionsModelChanged();
    Q_EMIT attachmentsModelChanged();
    Q_EMIT todoCompletedChanged();
    Q_EMIT todoCompletionDtChanged();
    Q_EMIT todoPercentCompleteChanged();
    Q_EMIT googleConferenceUrlChanged();
}

Akonadi::Item IncidenceWrapper::incidenceItem() const
{
    return item();
}

void IncidenceWrapper::setIncidenceItem(const Akonadi::Item &incidenceItem)
{
    if (incidenceItem.hasPayload<KCalendarCore::Incidence::Ptr>()) {
        setItem(incidenceItem);
        setIncidencePtr(incidenceItem.payload<KCalendarCore::Incidence::Ptr>());

        Q_EMIT incidenceItemChanged();
        Q_EMIT collectionIdChanged();
    } else {
        qCWarning(KALENDAR_LOG) << "This is not an incidence item.";
    }
}

KCalendarCore::Incidence::Ptr IncidenceWrapper::incidencePtr() const
{
    return m_incidence;
}

void IncidenceWrapper::setIncidencePtr(const KCalendarCore::Incidence::Ptr incidencePtr)
{
    m_incidence = incidencePtr;

    KCalendarCore::Incidence::Ptr originalIncidence(incidencePtr->clone());
    m_originalIncidence = originalIncidence;

    Q_EMIT incidencePtrChanged(incidencePtr);
    Q_EMIT originalIncidencePtrChanged();
    notifyDataChanged();
}

KCalendarCore::Incidence::Ptr IncidenceWrapper::originalIncidencePtr()
{
    return m_originalIncidence;
}

int IncidenceWrapper::incidenceType() const
{
    return m_incidence->type();
}

QString IncidenceWrapper::incidenceTypeStr() const
{
    return m_incidence->type() == KCalendarCore::Incidence::TypeTodo ? i18n("Task") : i18n(m_incidence->typeStr().constData());
}

QString IncidenceWrapper::incidenceIconName() const
{
    return m_incidence->iconName();
}

QString IncidenceWrapper::uid() const
{
    return m_incidence->uid();
}

qint64 IncidenceWrapper::collectionId() const
{
    return m_collectionId < 0 ? item().parentCollection().id() : m_collectionId;
}

void IncidenceWrapper::setCollectionId(qint64 collectionId)
{
    m_collectionId = collectionId;
    Q_EMIT collectionIdChanged();
}

QString IncidenceWrapper::parent() const
{
    return m_incidence->relatedTo();
}

void IncidenceWrapper::setParent(QString parent)
{
    m_incidence->setRelatedTo(parent);
    updateParentIncidence();
    Q_EMIT parentChanged();
}

IncidenceWrapper *IncidenceWrapper::parentIncidence()
{
    updateParentIncidence();
    return m_parentIncidence.data();
}

QVariantList IncidenceWrapper::childIncidences()
{
    resetChildIncidences();
    return m_childIncidences;
}

QString IncidenceWrapper::summary() const
{
    return m_incidence->summary();
}

void IncidenceWrapper::setSummary(const QString &summary)
{
    m_incidence->setSummary(summary);
    Q_EMIT summaryChanged();
}

QStringList IncidenceWrapper::categories()
{
    return m_incidence->categories();
}

void IncidenceWrapper::setCategories(QStringList categories)
{
    m_incidence->setCategories(categories);
    Q_EMIT categoriesChanged();
}

QString IncidenceWrapper::description() const
{
    return m_incidence->description();
}

void IncidenceWrapper::setDescription(const QString &description)
{
    if (m_incidence->description() == description) {
        return;
    }
    m_incidence->setDescription(description);
    Q_EMIT descriptionChanged();
}

QString IncidenceWrapper::location() const
{
    return m_incidence->location();
}

void IncidenceWrapper::setLocation(const QString &location)
{
    m_incidence->setLocation(location);
    Q_EMIT locationChanged();
}

bool IncidenceWrapper::hasGeo() const
{
    return m_incidence->hasGeo();
}

float IncidenceWrapper::geoLatitude() const
{
    return m_incidence->geoLatitude();
}

float IncidenceWrapper::geoLongitude() const
{
    return m_incidence->geoLongitude();
}

QDateTime IncidenceWrapper::incidenceStart() const
{
    return m_incidence->dtStart();
}

void IncidenceWrapper::setIncidenceStart(const QDateTime &incidenceStart, bool respectTimeZone)
{
    // When we receive dates from QML, these are all set to the local system timezone but
    // have the dates and times we want. We need to preserve date and time but set the new
    // QDateTime to have the correct timezone.

    // When we set the timeZone property, however, we invariably also set the incidence start and end.
    // This object needs no change. We therefore need to make sure to preserve the entire QDateTime object here.
    auto oldStart = this->incidenceStart();

    if (respectTimeZone) {
        m_incidence->setDtStart(incidenceStart);
        auto newTzEnd = incidenceEnd();
        newTzEnd.setTimeZone(incidenceStart.timeZone());
        setIncidenceEnd(newTzEnd, true);
    } else {
        const auto date = incidenceStart.date();
        const auto time = incidenceStart.time();
        QDateTime start;
        start.setTimeZone(QTimeZone(timeZone()));
        start.setDate(date);
        start.setTime(time);
        m_incidence->setDtStart(start);
    }

    auto oldStartEndDifference = oldStart.secsTo(incidenceEnd());
    auto newEnd = this->incidenceStart().addSecs(oldStartEndDifference);
    setIncidenceEnd(newEnd);

    Q_EMIT incidenceStartChanged();
    Q_EMIT incidenceStartDateDisplayChanged();
    Q_EMIT incidenceStartTimeDisplayChanged();
    Q_EMIT durationChanged();
    Q_EMIT durationDisplayStringChanged();
}

void IncidenceWrapper::setIncidenceStartDate(int day, int month, int year)
{
    QDate date;
    date.setDate(year, month, day);

    auto newStart = incidenceStart();
    newStart.setDate(date);

    setIncidenceStart(newStart, true);
}

void IncidenceWrapper::setIncidenceStartTime(int hours, int minutes)
{
    QTime time;
    time.setHMS(hours, minutes, 0);

    auto newStart = incidenceStart();
    newStart.setTime(time);

    setIncidenceStart(newStart, true);
}

QString IncidenceWrapper::incidenceStartDateDisplay() const
{
    return QLocale::system().toString(incidenceStart().date(), QLocale::NarrowFormat);
}

QString IncidenceWrapper::incidenceStartTimeDisplay() const
{
    return QLocale::system().toString(incidenceStart().time(), QLocale::NarrowFormat);
}

QDateTime IncidenceWrapper::incidenceEnd() const
{
    if (m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeEvent) {
        KCalendarCore::Event::Ptr event = m_incidence.staticCast<KCalendarCore::Event>();
        return event->dtEnd();
    } else if (m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
        KCalendarCore::Todo::Ptr todo = m_incidence.staticCast<KCalendarCore::Todo>();
        return todo->dtDue();
    }
    return {};
}

void IncidenceWrapper::setIncidenceEnd(const QDateTime &incidenceEnd, bool respectTimeZone)
{
    QDateTime end;
    if (respectTimeZone) {
        end = incidenceEnd;
    } else {
        const auto date = incidenceEnd.date();
        const auto time = incidenceEnd.time();
        end.setTimeZone(QTimeZone(timeZone()));
        end.setDate(date);
        end.setTime(time);
    }

    if (m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeEvent) {
        KCalendarCore::Event::Ptr event = m_incidence.staticCast<KCalendarCore::Event>();
        event->setDtEnd(end);
    } else if (m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
        KCalendarCore::Todo::Ptr todo = m_incidence.staticCast<KCalendarCore::Todo>();
        todo->setDtDue(end);
    } else {
        qCWarning(KALENDAR_LOG) << "Unknown incidence type";
    }
    Q_EMIT incidenceEndChanged();
    Q_EMIT incidenceEndDateDisplayChanged();
    Q_EMIT incidenceEndTimeDisplayChanged();
    Q_EMIT durationChanged();
    Q_EMIT durationDisplayStringChanged();
}

void IncidenceWrapper::setIncidenceEndDate(int day, int month, int year)
{
    QDate date;
    date.setDate(year, month, day);

    auto newEnd = incidenceEnd();
    newEnd.setDate(date);

    setIncidenceEnd(newEnd, true);
}

void IncidenceWrapper::setIncidenceEndTime(int hours, int minutes)
{
    QTime time;
    time.setHMS(hours, minutes, 0);

    auto newEnd = incidenceEnd();
    newEnd.setTime(time);

    setIncidenceEnd(newEnd, true);
}

QString IncidenceWrapper::incidenceEndDateDisplay() const
{
    return QLocale::system().toString(incidenceEnd().date(), QLocale::NarrowFormat);
}

QString IncidenceWrapper::incidenceEndTimeDisplay() const
{
    return QLocale::system().toString(incidenceEnd().time(), QLocale::NarrowFormat);
}

void IncidenceWrapper::setIncidenceTimeToNearestQuarterHour(bool setStartTime, bool setEndTime)
{
    const int now = QDateTime::currentSecsSinceEpoch();
    const int quarterHourInSecs = 15 * 60;
    const int secsToSet = now + (quarterHourInSecs - now % quarterHourInSecs);
    QDateTime startTime = QDateTime::currentDateTime();
    startTime.setSecsSinceEpoch(secsToSet);
    if (setStartTime) {
        setIncidenceStart(startTime, true);
    }
    if (setEndTime) {
        setIncidenceEnd(startTime.addSecs(3600), true);
    }
}

QByteArray IncidenceWrapper::timeZone() const
{
    return incidenceEnd().timeZone().id();
}

void IncidenceWrapper::setTimeZone(const QByteArray &timeZone)
{
    QDateTime start(incidenceStart());
    if (start.isValid()) {
        start.setTimeZone(QTimeZone(timeZone));
        setIncidenceStart(start, true);
    }

    QDateTime end(incidenceEnd());
    if (end.isValid()) {
        end.setTimeZone(QTimeZone(timeZone));
        setIncidenceEnd(end, true);
    }

    Q_EMIT timeZoneChanged();
    Q_EMIT startTimeZoneUTCOffsetMinsChanged();
    Q_EMIT endTimeZoneUTCOffsetMinsChanged();
}

int IncidenceWrapper::startTimeZoneUTCOffsetMins()
{
    return QTimeZone(timeZone()).offsetFromUtc(incidenceStart());
}

int IncidenceWrapper::endTimeZoneUTCOffsetMins()
{
    return QTimeZone(timeZone()).offsetFromUtc(incidenceEnd());
}

KCalendarCore::Duration IncidenceWrapper::duration() const
{
    return m_incidence->duration();
}

QString IncidenceWrapper::durationDisplayString() const
{
    return Utils::formatSpelloutDuration(duration(), m_format, allDay());
}

bool IncidenceWrapper::allDay() const
{
    return m_incidence->allDay();
}

void IncidenceWrapper::setAllDay(bool allDay)
{
    m_incidence->setAllDay(allDay);
    Q_EMIT allDayChanged();
}

int IncidenceWrapper::priority() const
{
    return m_incidence->priority();
}

void IncidenceWrapper::setPriority(int priority)
{
    m_incidence->setPriority(priority);
    Q_EMIT priorityChanged();
}

KCalendarCore::Recurrence *IncidenceWrapper::recurrence() const
{
    KCalendarCore::Recurrence *recurrence = m_incidence->recurrence();
    return recurrence;
}

QVariantMap IncidenceWrapper::recurrenceData()
{
    QBitArray weekDaysBits = m_incidence->recurrence()->days();
    QList<bool> weekDaysBools(7);

    for (int i = 0; i < weekDaysBits.size(); i++) {
        weekDaysBools[i] = weekDaysBits[i];
    }

    QVariantList monthPositions;
    const auto monthPositionsToConvert = m_incidence->recurrence()->monthPositions();
    for (const auto &pos : monthPositionsToConvert) {
        QVariantMap positionToAdd;
        positionToAdd[QStringLiteral("day")] = pos.day();
        positionToAdd[QStringLiteral("pos")] = pos.pos();
        monthPositions.append(positionToAdd);
    }

    // FYI: yearPositions() just calls monthPositions(), so we're cutting out the middleman
    return QVariantMap{
        {QStringLiteral("weekdays"), QVariant::fromValue(weekDaysBools)},
        {QStringLiteral("duration"), m_incidence->recurrence()->duration()},
        {QStringLiteral("frequency"), m_incidence->recurrence()->frequency()},
        {QStringLiteral("startDateTime"), m_incidence->recurrence()->startDateTime()},
        {QStringLiteral("startDateTimeDisplay"), QLocale::system().toString(m_incidence->recurrence()->startDateTime(), QLocale::NarrowFormat)},
        {QStringLiteral("endDateTime"), m_incidence->recurrence()->endDateTime()},
        {QStringLiteral("endDateTimeDisplay"), QLocale::system().toString(m_incidence->recurrence()->endDateTime(), QLocale::NarrowFormat)},
        {QStringLiteral("allDay"), m_incidence->recurrence()->allDay()},
        {QStringLiteral("type"), m_incidence->recurrence()->recurrenceType()},
        {QStringLiteral("monthDays"), QVariant::fromValue(m_incidence->recurrence()->monthDays())},
        {QStringLiteral("monthPositions"), monthPositions},
        {QStringLiteral("yearDays"), QVariant::fromValue(m_incidence->recurrence()->yearDays())},
        {QStringLiteral("yearDates"), QVariant::fromValue(m_incidence->recurrence()->yearDates())},
        {QStringLiteral("yearMonths"), QVariant::fromValue(m_incidence->recurrence()->yearMonths())},
    };
}

void IncidenceWrapper::setRecurrenceDataItem(const QString &key, const QVariant &value)
{
    QVariantMap map = recurrenceData();
    if (map.contains(key)) {
        if (key == QStringLiteral("weekdays") && value.canConvert<QJSValue>()) {
            auto jsval = value.value<QJSValue>();

            if (!jsval.isArray()) {
                return;
            }

            auto vlist = jsval.toVariant().value<QVariantList>();
            QBitArray days(7);

            for (int i = 0; i < vlist.size(); i++) {
                days[i] = vlist[i].toBool();
            }

            KCalendarCore::RecurrenceRule *rrule = m_incidence->recurrence()->defaultRRule();
            QList<KCalendarCore::RecurrenceRule::WDayPos> positions;

            for (int i = 0; i < 7; ++i) {
                if (days.testBit(i)) {
                    KCalendarCore::RecurrenceRule::WDayPos p(0, i + 1);
                    positions.append(p);
                }
            }

            rrule->setByDays(positions);
            m_incidence->recurrence()->updated();

        } else if (key == QStringLiteral("duration")) {
            m_incidence->recurrence()->setDuration(value.toInt());

        } else if (key == QStringLiteral("frequency")) {
            m_incidence->recurrence()->setFrequency(value.toInt());

        } else if ((key == QStringLiteral("startDateTime") || key == QStringLiteral("endDateTime")) && value.toDateTime().isValid()) {
            auto dt = value.toDateTime();
            QDateTime adjustedDt;
            adjustedDt.setTimeZone(incidenceEnd().timeZone());
            adjustedDt.setDate(dt.date());
            adjustedDt.setTime(dt.time());

            if (key == QStringLiteral("startDateTime")) {
                m_incidence->recurrence()->setStartDateTime(adjustedDt, false);

            } else if (key == QStringLiteral("endDateTime")) {
                m_incidence->recurrence()->setEndDateTime(adjustedDt);
            }

        } else if (key == QStringLiteral("allDay")) {
            m_incidence->recurrence()->setAllDay(value.toBool());

        } else if (key == QStringLiteral("monthDays") && value.canConvert<QList<int>>()) {
            m_incidence->recurrence()->setMonthlyDate(value.value<QList<int>>());

        } else if (key == QStringLiteral("yearDays") && value.canConvert<QList<int>>()) {
            m_incidence->recurrence()->setYearlyDay(value.value<QList<int>>());

        } else if (key == QStringLiteral("yearDates") && value.canConvert<QList<int>>()) {
            m_incidence->recurrence()->setYearlyDate(value.value<QList<int>>());

        } else if (key == QStringLiteral("yearMonths") && value.canConvert<QList<int>>()) {
            m_incidence->recurrence()->setYearlyMonth(value.value<QList<int>>());

        } else if (key == QStringLiteral("monthPositions") && value.canConvert<QList<QVariantMap>>()) {
            QList<KCalendarCore::RecurrenceRule::WDayPos> newMonthPositions;
            const auto values = value.value<QList<QVariantMap>>();
            for (const auto &pos : values) {
                KCalendarCore::RecurrenceRule::WDayPos newPos;
                newPos.setDay(pos[QStringLiteral("day")].toInt());
                newPos.setPos(pos[QStringLiteral("pos")].toInt());
                newMonthPositions.append(newPos);
            }

            m_incidence->recurrence()->setMonthlyPos(newMonthPositions);
        }
    }
    Q_EMIT recurrenceDataChanged();
}

QString IncidenceWrapper::googleConferenceUrl()
{
    return m_incidence->customProperty("LIBKGAPI", "EventHangoutLink");
}

QVariantMap IncidenceWrapper::organizer()
{
    auto organizerPerson = m_incidence->organizer();
    return QVariantMap{{QStringLiteral("name"), organizerPerson.name()},
                       {QStringLiteral("email"), organizerPerson.email()},
                       {QStringLiteral("fullName"), organizerPerson.fullName()}};
}

KCalendarCore::Attendee::List IncidenceWrapper::attendees() const
{
    return m_incidence->attendees();
}

AttendeesModel *IncidenceWrapper::attendeesModel()
{
    return &m_attendeesModel;
}

RecurrenceExceptionsModel *IncidenceWrapper::recurrenceExceptionsModel()
{
    return &m_recurrenceExceptionsModel;
}

AttachmentsModel *IncidenceWrapper::attachmentsModel()
{
    return &m_attachmentsModel;
}

bool IncidenceWrapper::todoCompleted()
{
    if (m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return false;
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    return todo->isCompleted();
}

void IncidenceWrapper::setTodoCompleted(bool completed)
{
    if (m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return;
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    todo->setCompleted(completed);

    Q_EMIT todoCompletionDtChanged();
    Q_EMIT todoPercentCompleteChanged();
    Q_EMIT incidenceIconNameChanged();
    Q_EMIT todoCompletedChanged();
}

QDateTime IncidenceWrapper::todoCompletionDt()
{
    if (m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return {};
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    return todo->completed();
}

int IncidenceWrapper::todoPercentComplete()
{
    if (m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return 0;
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    return todo->percentComplete();
}

void IncidenceWrapper::setTodoPercentComplete(int todoPercentComplete)
{
    if (m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return;
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    todo->setPercentComplete(todoPercentComplete);

    Q_EMIT todoPercentCompleteChanged();

    if (todoPercentComplete < 100 && todoCompleted()) {
        setTodoCompleted(false);
    }

    Q_EMIT todoCompletedChanged();
}

void IncidenceWrapper::triggerEditMode() // You edit a clone so that the original ptr isn't messed with
{
    auto itemToEdit = item();
    KCalendarCore::Incidence::Ptr clonedPtr(m_incidence->clone());
    itemToEdit.setPayload<KCalendarCore::Incidence::Ptr>(clonedPtr);
    setIncidenceItem(itemToEdit);
}

static int nearestQuarterHour(int secsSinceEpoch)
{
    const int quarterHourInSecs = 60 * 15;
    return secsSinceEpoch + (quarterHourInSecs - secsSinceEpoch % quarterHourInSecs);
}

void IncidenceWrapper::setNewEvent()
{
    auto event = KCalendarCore::Event::Ptr(new KCalendarCore::Event);
    QDateTime start;
    start.setSecsSinceEpoch(nearestQuarterHour(QDateTime::currentSecsSinceEpoch()));
    event->setDtStart(start);
    event->setDtEnd(start.addSecs(60 * 60));

    KCalendarCore::Alarm::Ptr alarm(new KCalendarCore::Alarm(event.get()));
    alarm->setEnabled(true);
    alarm->setType(KCalendarCore::Alarm::Display);
    alarm->setStartOffset(-1 * 15 * 60); // 15 minutes

    event->addAlarm(alarm);

    setNewIncidence(event);
}

void IncidenceWrapper::setNewTodo()
{
    auto todo = KCalendarCore::Todo::Ptr(new KCalendarCore::Todo);
    setNewIncidence(todo);
}

void IncidenceWrapper::setNewIncidence(KCalendarCore::Incidence::Ptr incidence)
{
    Akonadi::Item incidenceItem;
    incidenceItem.setPayload<KCalendarCore::Incidence::Ptr>(incidence);
    setIncidenceItem(incidenceItem);
}

// We need to be careful when we call updateParentIncidence and resetChildIncidences.
// For instance, we always call them on-demand based on access to the properties and not
// upon object construction on upon setting the incidence pointer.

// Calling them both recursively down a family tree can cause a cascade of infinite
// new IncidenceWrappers being created. Say we create a new incidence wrapper here and
// call this new incidence's updateParentIncidence and resetChildIncidences, creating
// a new child wrapper, creating more wrappers there, and so on.

void IncidenceWrapper::updateParentIncidence()
{
    if (!m_incidence) {
        return;
    }

    if (!parent().isEmpty() && (!m_parentIncidence || m_parentIncidence->uid() != parent())) {
        m_parentIncidence.reset(new IncidenceWrapper);
        m_parentIncidence->setIncidenceItem(CalendarManager::instance()->incidenceItem(parent()));
        Q_EMIT parentIncidenceChanged();
    }
}

void IncidenceWrapper::resetChildIncidences()
{
    cleanupChildIncidences();

    if (!m_incidence) {
        return;
    }

    const auto incidences = CalendarManager::instance()->childIncidences(uid());
    QVariantList wrappedIncidences;

    for (const auto &incidence : incidences) {
        const auto wrappedIncidence = new IncidenceWrapper;
        wrappedIncidence->setIncidenceItem(CalendarManager::instance()->incidenceItem(incidence));
        wrappedIncidences.append(QVariant::fromValue(wrappedIncidence));
    }

    m_childIncidences = wrappedIncidences;
    Q_EMIT childIncidencesChanged();
}

void IncidenceWrapper::cleanupChildIncidences()
{
    while (!m_childIncidences.isEmpty()) {
        const auto incidence = m_childIncidences.takeFirst();
        const auto incidencePtr = incidence.value<IncidenceWrapper *>();

        delete incidencePtr;
    }
}

void IncidenceWrapper::addAlarms(KCalendarCore::Alarm::List alarms)
{
    for (int i = 0; i < alarms.size(); i++) {
        m_incidence->addAlarm(alarms[i]);
    }
}

void IncidenceWrapper::setRegularRecurrence(IncidenceWrapper::RecurrenceIntervals interval, int freq)
{
    switch (interval) {
    case Daily:
        m_incidence->recurrence()->setDaily(freq);
        Q_EMIT recurrenceDataChanged();
        return;
    case Weekly:
        m_incidence->recurrence()->setWeekly(freq);
        Q_EMIT recurrenceDataChanged();
        return;
    case Monthly:
        m_incidence->recurrence()->setMonthly(freq);
        Q_EMIT recurrenceDataChanged();
        return;
    case Yearly:
        m_incidence->recurrence()->setYearly(freq);
        Q_EMIT recurrenceDataChanged();
        return;
    default:
        qCWarning(KALENDAR_LOG) << "Unknown interval for recurrence" << interval;
        return;
    }
}

void IncidenceWrapper::setMonthlyPosRecurrence(short pos, int day)
{
    QBitArray daysBitArray(7);
    daysBitArray[day] = 1;
    m_incidence->recurrence()->addMonthlyPos(pos, daysBitArray);
}

void IncidenceWrapper::setRecurrenceOccurrences(int occurrences)
{
    m_incidence->recurrence()->setDuration(occurrences);
    Q_EMIT recurrenceDataChanged();
}

void IncidenceWrapper::clearRecurrences()
{
    m_incidence->recurrence()->clear();
    Q_EMIT recurrenceDataChanged();
}

void IncidenceWrapper::itemChanged(const Akonadi::Item &item)
{
    if (item.hasPayload<KCalendarCore::Incidence::Ptr>()) {
        qCDebug(KALENDAR_LOG) << item.payload<KCalendarCore::Incidence::Ptr>()->summary() << item.parentCollection().id();
        setIncidenceItem(item);
    }
}

// TODO remove with 22.08, won't be needed anymore
void IncidenceWrapper::setCollection(const Akonadi::Collection &collection)
{
    setCollectionId(collection.id());
}

#ifndef UNITY_CMAKE_SUPPORT
Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr)
#endif

#include "moc_incidencewrapper.cpp"
