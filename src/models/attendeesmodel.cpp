// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "attendeesmodel.h"
#include "kalendar_debug.h"
#include <KContacts/Addressee>
#include <KLocalizedString>
#include <QMetaEnum>
#include <QModelIndex>
#include <QRegularExpression>

#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/SearchQuery>

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 19, 40)
#include <Akonadi/ContactSearchJob>
#else
#include <Akonadi/Contact/ContactSearchJob>
#endif
#else
#include <Akonadi/ContactSearchJob>
#endif

AttendeeStatusModel::AttendeeStatusModel(QObject *parent)
    : QAbstractListModel(parent)
{
    QRegularExpression lowerToCapitalSep(QStringLiteral("([a-z])([A-Z])"));
    QRegularExpression capitalToCapitalSep(QStringLiteral("([A-Z])([A-Z])"));

    for (int i = 0; i < QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().keyCount(); i++) {
        int value = QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().value(i);

        // QLatin1String is a workaround for QT_NO_CAST_FROM_ASCII.
        // Regular expression adds space between every lowercase and Capitalised character then does the same
        // for capitalised letters together, e.g. ThisIsATest. Not a problem right now, but best to be safe.
        const QLatin1String enumName = QLatin1String(QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().key(i));
        QString displayName = enumName;
        displayName.replace(lowerToCapitalSep, QStringLiteral("\\1 \\2"));
        displayName.replace(capitalToCapitalSep, QStringLiteral("\\1 \\2"));
        displayName.replace(lowerToCapitalSep, QStringLiteral("\\1 \\2"));

        m_status[value] = i18n(displayName.toStdString().c_str());
    }
}

QVariant AttendeeStatusModel::data(const QModelIndex &idx, int role) const
{
    if (!idx.isValid()) {
        return {};
    }

    const int value = QMetaEnum::fromType<KCalendarCore::Attendee::PartStat>().value(idx.row());

    switch (role) {
    case DisplayNameRole:
        return m_status[value];
    case ValueRole:
        return value;
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for attendee:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return {};
    }
}

QHash<int, QByteArray> AttendeeStatusModel::roleNames() const
{
    return {
        {DisplayNameRole, QByteArrayLiteral("display")},
        {ValueRole, QByteArrayLiteral("value")},
    };
}

int AttendeeStatusModel::rowCount(const QModelIndex &) const
{
    return m_status.size();
}

AttendeesModel::AttendeesModel(QObject *parent, KCalendarCore::Incidence::Ptr incidencePtr)
    : QAbstractListModel(parent)
    , m_incidence(incidencePtr)
    , m_attendeeStatusModel(parent)
{
    connect(this, &AttendeesModel::attendeesChanged, this, &AttendeesModel::updateAkonadiContactIds);
}

KCalendarCore::Incidence::Ptr AttendeesModel::incidencePtr() const
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

KCalendarCore::Attendee::List AttendeesModel::attendees() const
{
    return m_incidence->attendees();
}

void AttendeesModel::updateAkonadiContactIds()
{
    m_attendeesAkonadiIds.clear();

    const auto attendees = m_incidence->attendees();
    for (const auto &attendee : attendees) {
        auto job = new Akonadi::ContactSearchJob();
        job->setQuery(Akonadi::ContactSearchJob::Email, attendee.email());

        connect(job, &Akonadi::ContactSearchJob::result, this, [this](KJob *job) {
            auto searchJob = qobject_cast<Akonadi::ContactSearchJob *>(job);

            const auto items = searchJob->items();
            for (const auto &item : items) {
                m_attendeesAkonadiIds.append(item.id());
            }

            Q_EMIT attendeesAkonadiIdsChanged();
        });
    }

    Q_EMIT attendeesAkonadiIdsChanged();
}

AttendeeStatusModel *AttendeesModel::attendeeStatusModel()
{
    return &m_attendeeStatusModel;
}

QList<qint64> AttendeesModel::attendeesAkonadiIds() const
{
    return m_attendeesAkonadiIds;
}

QVariant AttendeesModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    const auto attendee = m_incidence->attendees().at(idx.row());
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
        qCWarning(KALENDAR_LOG) << "Unknown role for attendee:" << QMetaEnum::fromType<Roles>().valueToKey(role);
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
    case CuTypeRole: {
        const auto cuType = static_cast<KCalendarCore::Attendee::CuType>(value.toInt());
        currentAttendees[idx.row()].setCuType(cuType);
        break;
    }
    case DelegateRole: {
        const QString delegate = value.toString();
        currentAttendees[idx.row()].setDelegate(delegate);
        break;
    }
    case DelegatorRole: {
        const QString delegator = value.toString();
        currentAttendees[idx.row()].setDelegator(delegator);
        break;
    }
    case EmailRole: {
        const QString email = value.toString();
        currentAttendees[idx.row()].setEmail(email);
        break;
    }
    case FullNameRole: {
        // Not a writable property
        return false;
    }
    case IsNullRole: {
        // Not an editable value
        return false;
    }
    case NameRole: {
        const QString name = value.toString();
        currentAttendees[idx.row()].setName(name);
        break;
    }
    case RoleRole: {
        const auto role = static_cast<KCalendarCore::Attendee::Role>(value.toInt());
        currentAttendees[idx.row()].setRole(role);
        break;
    }
    case RSVPRole: {
        const bool rsvp = value.toBool();
        currentAttendees[idx.row()].setRSVP(rsvp);
        break;
    }
    case StatusRole: {
        const auto status = static_cast<KCalendarCore::Attendee::PartStat>(value.toInt());
        currentAttendees[idx.row()].setStatus(status);
        break;
    }
    case UidRole: {
        const QString uid = value.toString();
        currentAttendees[idx.row()].setUid(uid);
        break;
    }
    default:
        qCWarning(KALENDAR_LOG) << "Unknown role for incidence:" << QMetaEnum::fromType<Roles>().valueToKey(role);
        return false;
    }
    m_incidence->setAttendees(currentAttendees);
    Q_EMIT dataChanged(idx, idx);
    return true;
}

QHash<int, QByteArray> AttendeesModel::roleNames() const
{
    return {
        {CuTypeRole, QByteArrayLiteral("cuType")},
        {DelegateRole, QByteArrayLiteral("delegate")},
        {DelegatorRole, QByteArrayLiteral("delegator")},
        {EmailRole, QByteArrayLiteral("email")},
        {FullNameRole, QByteArrayLiteral("fullName")},
        {IsNullRole, QByteArrayLiteral("isNull")},
        {NameRole, QByteArrayLiteral("name")},
        {RoleRole, QByteArrayLiteral("role")},
        {RSVPRole, QByteArrayLiteral("rsvp")},
        {StatusRole, QByteArrayLiteral("status")},
        {UidRole, QByteArrayLiteral("uid")},
    };
}

int AttendeesModel::rowCount(const QModelIndex &) const
{
    return m_incidence->attendeeCount();
}

void AttendeesModel::addAttendee(qint64 itemId, const QString &email)
{
    if (itemId) {
        Akonadi::Item item(itemId);

        auto job = new Akonadi::ItemFetchJob(item);
        job->fetchScope().fetchFullPayload();

        connect(job, &Akonadi::ItemFetchJob::result, this, [this, email](KJob *job) {
            const Akonadi::ItemFetchJob *fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
            const auto item = fetchJob->items().at(0);
            const auto payload = item.payload<KContacts::Addressee>();

            KCalendarCore::Attendee attendee(payload.name(),
                                             payload.preferredEmail(),
                                             true,
                                             KCalendarCore::Attendee::NeedsAction,
                                             KCalendarCore::Attendee::ReqParticipant);

            if (!email.isNull()) {
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

    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();

    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);

        auto item = fetchJob->items().at(0);
        auto payload = item.payload<KContacts::Addressee>();

        for (int i = 0; i < m_incidence->attendeeCount(); i++) {
            const auto emails = payload.emails();
            for (const auto &email : emails) {
                if (m_incidence->attendees()[i].email() == email) {
                    deleteAttendee(i);
                    break;
                }
            }
        }
    });
}
