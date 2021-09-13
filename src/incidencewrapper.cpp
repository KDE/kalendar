// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <QBitArray>
#include <QJSValue>
#include <KLocalizedString>
#include <incidencewrapper.h>

IncidenceWrapper::IncidenceWrapper(QObject *parent)
    : QObject(parent)
    , m_incidence(new KCalendarCore::Event)
    , m_remindersModel(parent, m_incidence)
    , m_attendeesModel(parent, m_incidence)
    , m_recurrenceExceptionsModel(parent, m_incidence)
    , m_attachmentsModel(parent, m_incidence)
{

    // Change incidence pointer in remindersmodel if changed here
    connect(this, &IncidenceWrapper::incidencePtrChanged,
            &m_remindersModel, [=](KCalendarCore::Incidence::Ptr incidencePtr){ m_remindersModel.setIncidencePtr(incidencePtr); });
    connect(this, &IncidenceWrapper::incidencePtrChanged,
            &m_attendeesModel, [=](KCalendarCore::Incidence::Ptr incidencePtr){ m_attendeesModel.setIncidencePtr(incidencePtr); });
    connect(this, &IncidenceWrapper::incidencePtrChanged,
            &m_recurrenceExceptionsModel, [=](KCalendarCore::Incidence::Ptr incidencePtr){ m_recurrenceExceptionsModel.setIncidencePtr(incidencePtr); });
    connect(this, &IncidenceWrapper::incidencePtrChanged,
            &m_attachmentsModel, [=](KCalendarCore::Incidence::Ptr incidencePtr){ m_attachmentsModel.setIncidencePtr(incidencePtr); });

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
    Q_EMIT incidenceTypeChanged();
    Q_EMIT incidenceTypeStrChanged();
    Q_EMIT incidenceIconNameChanged();
    Q_EMIT collectionIdChanged();
    Q_EMIT summaryChanged();
    Q_EMIT categoriesChanged();
    Q_EMIT descriptionChanged();
    Q_EMIT locationChanged();
    Q_EMIT incidenceStartChanged();
    Q_EMIT incidenceEndChanged();
    Q_EMIT allDayChanged();
    Q_EMIT priorityChanged();
    Q_EMIT remindersModelChanged();
    Q_EMIT organizerChanged();
    Q_EMIT attendeesModelChanged();
    Q_EMIT recurrenceDataChanged();
    Q_EMIT recurrenceExceptionsModelChanged();
    Q_EMIT attachmentsModelChanged();
    Q_EMIT todoCompletedChanged();
    Q_EMIT todoCompletionDtChanged();
    Q_EMIT todoPercentCompleteChanged();
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
    return i18n(m_incidence->typeStr());
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
    return m_collectionId;
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
    Q_EMIT parentChanged();
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

void IncidenceWrapper::setIncidenceStart(const QDateTime &incidenceStart)
{
    qDebug() << incidenceStart;
    m_incidence->setDtStart(incidenceStart);
    Q_EMIT incidenceStartChanged();
}

QDateTime IncidenceWrapper::incidenceEnd() const
{
    if(m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeEvent) {
        KCalendarCore::Event::Ptr event = m_incidence.staticCast<KCalendarCore::Event>();
        return event->dtEnd();
    } else if(m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
        KCalendarCore::Todo::Ptr todo = m_incidence.staticCast<KCalendarCore::Todo>();
        return todo->dtDue();
    }
    return {};
}

void IncidenceWrapper::setIncidenceEnd(const QDateTime &incidenceEnd)
{
    if(m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeEvent) {
        KCalendarCore::Event::Ptr event = m_incidence.staticCast<KCalendarCore::Event>();
        event->setDtEnd(incidenceEnd);
    } else if(m_incidence->type() == KCalendarCore::Incidence::IncidenceType::TypeTodo) {
        KCalendarCore::Todo::Ptr todo = m_incidence.staticCast<KCalendarCore::Todo>();
        todo->setDtDue(incidenceEnd);
    } else {
        qWarning() << "Unknown incidence type";
    }
    Q_EMIT incidenceEndChanged();
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

KCalendarCore::Recurrence * IncidenceWrapper::recurrence() const
{
    KCalendarCore::Recurrence *recurrence = m_incidence->recurrence();
    return recurrence;
}

QVariantMap IncidenceWrapper::recurrenceData()
{
    QBitArray weekDaysBits = m_incidence->recurrence()->days();
    QVector<bool> weekDaysBools(7);

    for(int i = 0; i < weekDaysBits.size(); i++) {
        weekDaysBools[i] = weekDaysBits[i];
    }

    QVariantList monthPositions;
    for(auto pos : m_incidence->recurrence()->monthPositions()) {
        QVariantMap positionToAdd;
        positionToAdd[QStringLiteral("day")] = pos.day();
        positionToAdd[QStringLiteral("pos")] = pos.pos();
        monthPositions.append(positionToAdd);
    }

    // FYI: yearPositions() just calls monthPositions(), so we're cutting out the middleman
    return QVariantMap {
        {QStringLiteral("weekdays"), QVariant::fromValue(weekDaysBools)},
        {QStringLiteral("duration"), m_incidence->recurrence()->duration()},
        {QStringLiteral("frequency"), m_incidence->recurrence()->frequency()},
        {QStringLiteral("startDateTime"), m_incidence->recurrence()->startDateTime()},
        {QStringLiteral("endDateTime"), m_incidence->recurrence()->endDateTime()},
        {QStringLiteral("allDay"), m_incidence->recurrence()->allDay()},
        {QStringLiteral("type"), m_incidence->recurrence()->recurrenceType()},
        {QStringLiteral("monthDays"), QVariant::fromValue(m_incidence->recurrence()->monthDays())},
        {QStringLiteral("monthPositions"), monthPositions},
        {QStringLiteral("yearDays"), QVariant::fromValue(m_incidence->recurrence()->yearDays())},
        {QStringLiteral("yearDates"), QVariant::fromValue(m_incidence->recurrence()->yearDates())},
        {QStringLiteral("yearMonths"), QVariant::fromValue(m_incidence->recurrence()->yearMonths())}
    };
}

void IncidenceWrapper::setRecurrenceDataItem(const QString &key, const QVariant &value)
{
    QVariantMap map = recurrenceData();
    if(map.contains(key)) {
        if(key == QStringLiteral("weekdays") && value.canConvert<QJSValue>()) {

            auto jsval = value.value<QJSValue>();

            if(!jsval.isArray()) {
                return;
            }

            QVariantList vlist = jsval.toVariant().value<QVariantList>();
            QBitArray days(7);

            for(int i = 0; i < vlist.size(); i++) {
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

        } else if(key == QStringLiteral("frequency")) {

            m_incidence->recurrence()->setFrequency(value.toInt());

        } else if (key == QStringLiteral("startDateTime") && value.toDateTime().isValid()) {

            m_incidence->recurrence()->setStartDateTime(value.toDateTime(), false);

        } else if (key == QStringLiteral("endDateTime") && value.toDateTime().isValid()) {

            m_incidence->recurrence()->setEndDateTime(value.toDateTime());

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

            for(auto pos : value.value<QList<QVariantMap>>()) {
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

QVariantMap IncidenceWrapper::organizer()
{
    auto organizerPerson = m_incidence->organizer();
    return QVariantMap {
        {QStringLiteral("name"), organizerPerson.name()},
        {QStringLiteral("email"), organizerPerson.email()},
        {QStringLiteral("fullName"), organizerPerson.fullName()}
    };
}

KCalendarCore::Attendee::List IncidenceWrapper::attendees() const
{
    return m_incidence->attendees();
}

RemindersModel * IncidenceWrapper::remindersModel()
{
    return &m_remindersModel;
}

AttendeesModel * IncidenceWrapper::attendeesModel()
{
    return &m_attendeesModel;
}

RecurrenceExceptionsModel * IncidenceWrapper::recurrenceExceptionsModel()
{
    return &m_recurrenceExceptionsModel;
}

AttachmentsModel * IncidenceWrapper::attachmentsModel()
{
    return &m_attachmentsModel;
}

bool IncidenceWrapper::todoCompleted()
{
    if(m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return false;
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    return todo->isCompleted();
}

void IncidenceWrapper::setTodoCompleted(bool completed)
{
    if(m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
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
    if(m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return QDateTime();
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    return todo->completed();
}

int IncidenceWrapper::todoPercentComplete()
{
    if(m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
        return 0;
    }

    auto todo = m_incidence.staticCast<KCalendarCore::Todo>();
    return todo->percentComplete();
}

void IncidenceWrapper::setTodoPercentComplete(int todoPercentComplete)
{
    if(m_incidence->type() != KCalendarCore::IncidenceBase::TypeTodo) {
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

void IncidenceWrapper::setNewEvent()
{
    auto event = KCalendarCore::Event::Ptr(new KCalendarCore::Event);
    event->setDtStart(QDateTime::currentDateTime());
    event->setDtEnd(QDateTime::currentDateTime().addSecs(60 * 60));
    setIncidencePtr(event);
}

void IncidenceWrapper::setNewTodo()
{
    auto todo = KCalendarCore::Todo::Ptr(new KCalendarCore::Todo);
    setIncidencePtr(todo);
}

void IncidenceWrapper::addAlarms(KCalendarCore::Alarm::List alarms)
{
    for (int i = 0; i < alarms.size(); i++) {
        m_incidence->addAlarm(alarms[i]);
    }
}

void IncidenceWrapper::setRegularRecurrence(IncidenceWrapper::RecurrenceIntervals interval, int freq)
{
    switch(interval) {
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
            qWarning() << "Unknown interval for recurrence" << interval;
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

Q_DECLARE_METATYPE(KCalendarCore::Incidence::Ptr);
