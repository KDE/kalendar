// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <QMetaEnum>
#include <QRegularExpression>
#include <KLocalizedString>
#include "attendeesmodel.h"
#include <KContacts/Addressee>
#include <AkonadiCore/Item>
#include <AkonadiCore/ItemFetchJob>
#include <AkonadiCore/ItemFetchScope>
#include <AkonadiCore/SearchQuery>
#include <Akonadi/Contact/ContactSearchJob>

AttendeeStatusModel::AttendeeStatusModel(QObject *parent)
    : QAbstractListModel(parent)
{
    for(int i = 0; i < QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().keyCount(); i++) {
        int value = QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().value(i);

        // QLatin1String is a workaround for QT_NO_CAST_FROM_ASCII.
        // Regular expression adds space between every lowercase and Capitalised character then does the same
        // for capitalised letters together, e.g. ThisIsATest. Not a problem right now, but best to be safe.
        QString enumName = QLatin1String(QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().key(i));
        QString displayName = enumName.replace(QRegularExpression(QLatin1String("Role$")), QLatin1String(""));
        displayName.replace(QRegularExpression(QLatin1String("([a-z])([A-Z])")), QLatin1String("\\1 \\2"));
        displayName.replace(QRegularExpression(QLatin1String("([A-Z])([A-Z])")), QLatin1String("\\1 \\2"));
        displayName.replace(QRegularExpression(QLatin1String("([a-z])([A-Z])")), QLatin1String("\\1 \\2"));

        m_status[value] = i18n(displayName.toStdString().c_str());
    }

}

QVariant AttendeeStatusModel::data(const QModelIndex &idx, int role) const
{
    if (!idx.isValid()) {
        return {};
    }

    int value = QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().value(idx.row());

    switch (role) {
        case DisplayNameRole:
        {
            return m_status[value];
        }
        case ValueRole:
            return value;
        default:
            qWarning() << "Unknown role for attendee:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

QHash<int, QByteArray> AttendeeStatusModel::roleNames() const
{
    return {
        { DisplayNameRole, QByteArrayLiteral("display") },
        { ValueRole, QByteArrayLiteral("value") }
    };

}

int AttendeeStatusModel::rowCount(const QModelIndex &) const
{
    return m_status.size();
}








AttendeesModel::AttendeesModel(QObject* parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
    , m_attendeeStatusModel(parent)
{
    connect(this, &AttendeesModel::attendeesChanged, this, &AttendeesModel::updateAkonadiContactIds);
}

KCalendarCore::Incidence::Ptr AttendeesModel::incidencePtr()
{
    return m_incidence;
}

void AttendeesModel::setIncidencePtr(KCalendarCore::Incidence::Ptr incidence)
{
    if (m_incidence == incidence) {
        return;
    }
    m_incidence = incidence;

    Q_EMIT incidencePtrChanged();
    Q_EMIT attendeesChanged();
    Q_EMIT attendeeStatusModelChanged();
    Q_EMIT layoutChanged();
}

KCalendarCore::Attendee::List AttendeesModel::attendees()
{
    return m_incidence->attendees();
}

void AttendeesModel::updateAkonadiContactIds()
{
    m_attendeesAkonadiIds.clear();

    if (m_incidence->attendees().length()) {
        for (const auto &attendee : m_incidence->attendees()) {
            Akonadi::ContactSearchJob *job = new Akonadi::ContactSearchJob();
            job->setQuery(Akonadi::ContactSearchJob::Email, attendee.email());

            connect(job, &Akonadi::ContactSearchJob::result, this, [this](KJob *job) {
                Akonadi::ContactSearchJob *searchJob = qobject_cast<Akonadi::ContactSearchJob*>(job);

                for(const auto &item : searchJob->items()) {
                    m_attendeesAkonadiIds.append(item.id());
                }

                Q_EMIT attendeesAkonadiIdsChanged();
            });
        }
    }

    Q_EMIT attendeesAkonadiIdsChanged();
}

AttendeeStatusModel * AttendeesModel::attendeeStatusModel()
{
    return &m_attendeeStatusModel;
}

QList<qint64> AttendeesModel::attendeesAkonadiIds()
{
    return m_attendeesAkonadiIds;
}

QVariant AttendeesModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    auto attendee = m_incidence->attendees()[idx.row()];
    switch (role) {
        case CuTypeRole:
            return attendee.cuType();
        case DelegateRole:
            return attendee.delegate();
        case DelegatorRole:
            return attendee.delegator();
        case EmailRole:
            return attendee.email();
        case FullNameRole:
            return attendee.fullName();
        case IsNullRole:
            return attendee.isNull();
        case NameRole:
            return attendee.name();
        case RoleRole:
            return attendee.role();
        case RSVPRole:
            return attendee.RSVP();
        case StatusRole:
            return attendee.status();
        case UidRole:
            return attendee.uid();
        default:
            qWarning() << "Unknown role for attendee:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return {};
    }
}

bool AttendeesModel::setData(const QModelIndex &idx, const QVariant &value, int role)
{
    if (!idx.isValid()) {
        return false;
    }

    // When modifying attendees, remember you cannot change them directly from m_incidence->attendees (is a const).
    KCalendarCore::Attendee::List currentAttendees(m_incidence->attendees());

    switch (role) {
        case CuTypeRole:
        {
            KCalendarCore::Attendee::CuType cuType = static_cast<KCalendarCore::Attendee::CuType>(value.toInt());
            currentAttendees[idx.row()].setCuType(cuType);
            break;
        }
        case DelegateRole:
        {
            QString delegate = value.toString();
            currentAttendees[idx.row()].setDelegate(delegate);
            break;
        }
        case DelegatorRole:
        {
            QString delegator = value.toString();
            currentAttendees[idx.row()].setDelegator(delegator);
            break;
        }
        case EmailRole:
        {
            QString email = value.toString();
            currentAttendees[idx.row()].setEmail(email);
            break;
        }
        case FullNameRole:
        {
            // Not a writable property
            return false;
        }
        case IsNullRole:
        {
            // Not an editable value
            return false;
        }
        case NameRole:
        {
            QString name = value.toString();
            currentAttendees[idx.row()].setName(name);
            break;
        }
        case RoleRole:
        {
            KCalendarCore::Attendee::Role role = static_cast<KCalendarCore::Attendee::Role>(value.toInt());
            currentAttendees[idx.row()].setRole(role);
            break;
        }
        case RSVPRole:
        {
            bool rsvp = value.toBool();
            currentAttendees[idx.row()].setRSVP(rsvp);
            break;
        }
        case StatusRole:
        {
            KCalendarCore::Attendee::PartStat status = static_cast<KCalendarCore::Attendee::PartStat>(value.toInt());
            currentAttendees[idx.row()].setStatus(status);
            break;
        }
        case UidRole:
        {
            QString uid = value.toString();
            currentAttendees[idx.row()].setUid(uid);
            break;
        }
        default:
            qWarning() << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
            return false;
    }
    m_incidence->setAttendees(currentAttendees);
    emit dataChanged(idx, idx);
    return true;
}

QHash<int, QByteArray> AttendeesModel::roleNames() const
{
	return {
        { CuTypeRole, QByteArrayLiteral("cuType") },
        { DelegateRole, QByteArrayLiteral("delegate") },
        { DelegatorRole, QByteArrayLiteral("delegator") },
        { EmailRole, QByteArrayLiteral("email") },
        { FullNameRole, QByteArrayLiteral("fullName") },
        { IsNullRole, QByteArrayLiteral("isNull") },
        { NameRole, QByteArrayLiteral("name") },
        { RoleRole, QByteArrayLiteral("role") },
        { RSVPRole, QByteArrayLiteral("rsvp") },
        { StatusRole, QByteArrayLiteral("status") },
        { UidRole, QByteArrayLiteral("uid") }
    };
}

int AttendeesModel::rowCount(const QModelIndex &) const
{
    return m_incidence->attendeeCount();
}

void AttendeesModel::addAttendee(qint64 itemId, const QString &email)
{
    if(itemId) {
        Akonadi::Item item(itemId);

        Akonadi::ItemFetchJob *job = new Akonadi::ItemFetchJob(item);
        job->fetchScope().fetchFullPayload();

        connect(job, &Akonadi::ItemFetchJob::result, this, [this, email](KJob *job) {

            Akonadi::ItemFetchJob *fetchJob = qobject_cast<Akonadi::ItemFetchJob*>(job);
            auto item = fetchJob->items().at(0);
            auto payload = item.payload<KContacts::Addressee>();

            KCalendarCore::Attendee attendee(payload.name(),
                                             payload.preferredEmail(),
                                             true,
                                             KCalendarCore::Attendee::NeedsAction,
                                             KCalendarCore::Attendee::ReqParticipant);

            if(!email.isNull()) {
                attendee.setEmail(email);
            }

            m_incidence->addAttendee(attendee);
            // Otherwise won't update
            Q_EMIT attendeesChanged();
            Q_EMIT layoutChanged();
        });
    } else {
        // QLatin1String is a workaround for QT_NO_CAST_FROM_ASCII
        // addAttendee method does not work with null strings, so we use empty strings
        KCalendarCore::Attendee attendee(QLatin1String(""),
                                         QLatin1String(""),
                                         true,
                                         KCalendarCore::Attendee::NeedsAction,
                                         KCalendarCore::Attendee::ReqParticipant);

        // addAttendee won't actually add any attendees without a set name
        m_incidence->addAttendee(attendee);
    }

    Q_EMIT attendeesChanged();
    Q_EMIT layoutChanged();
}

void AttendeesModel::deleteAttendee(int row)
{
    if (!hasIndex(row, 0)) {
        return;
    }

    KCalendarCore::Attendee::List currentAttendees(m_incidence->attendees());
    currentAttendees.removeAt(row);
    m_incidence->setAttendees(currentAttendees);

    Q_EMIT attendeesChanged();
    Q_EMIT layoutChanged();
}

void AttendeesModel::deleteAttendeeFromAkonadiId(qint64 itemId)
{
    Akonadi::Item item(itemId);

    Akonadi::ItemFetchJob *job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();

    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        Akonadi::ItemFetchJob *fetchJob = qobject_cast<Akonadi::ItemFetchJob*>(job);

        auto item = fetchJob->items().at(0);
        auto payload = item.payload<KContacts::Addressee>();

        for(int i = 0; i < m_incidence->attendeeCount(); i++) {

            for(const auto &email : payload.emails()) {
                if(m_incidence->attendees()[i].email() == email) {
                    deleteAttendee(i);
                    break;
                }
            }
        }
    });
}

