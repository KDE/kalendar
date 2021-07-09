// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <ETMViewStateSaver>
#include <KDescendantsProxyModel>
#include <AkonadiCore/AgentFilterProxyModel>
#include <AkonadiCore/CollectionFilterProxyModel>
#include <AkonadiCore/EntityRightsFilterModel>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>

namespace Akonadi {
    class ETMCalendar;
}

class KCheckableProxyModel;
class QAbstractProxyModel;
class EventWrapper;

class CalendarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QAbstractProxyModel *collections READ collections CONSTANT)
    Q_PROPERTY(KDescendantsProxyModel *allCalendars READ allCalendars CONSTANT)
    Q_PROPERTY(Akonadi::EntityRightsFilterModel *selectableCalendars READ selectableCalendars CONSTANT)
    Q_PROPERTY(qint64 defaultCalendarId READ defaultCalendarId CONSTANT)
    Q_PROPERTY(int defaultCalendarSelectableIndex READ defaultCalendarSelectableIndex NOTIFY defaultCalendarSelectableIndexChanged)
    Q_PROPERTY(Akonadi::ETMCalendar *calendar READ calendar CONSTANT)
public:
    CalendarManager(QObject *parent = nullptr);
    ~CalendarManager() override;

    KCheckableProxyModel *collectionSelectionProxyModel() const;
    void setCollectionSelectionProxyModel(KCheckableProxyModel *);

    bool loading() const;
    QAbstractProxyModel *collections();
    Q_INVOKABLE void save();
    Akonadi::ETMCalendar *calendar() const;
    KDescendantsProxyModel *allCalendars();
    Akonadi::EntityRightsFilterModel *selectableCalendars() const;
    qint64 defaultCalendarId();
    Q_INVOKABLE int getCalendarSelectableIndex(qint64 collectionId);
    int defaultCalendarSelectableIndex();
    void updateDefaultCalendarSelectableIndex();

    Q_INVOKABLE void addEvent(qint64 collectionId, KCalendarCore::Event::Ptr event);
    Q_INVOKABLE void editEvent(KCalendarCore::Event::Ptr editedEvent);
    Q_INVOKABLE void deleteEvent(KCalendarCore::Event::Ptr event);
    Q_INVOKABLE QVariantMap getCollectionDetails(qint64 collectionId);
    Q_INVOKABLE EventWrapper *createNewEvent();
    Q_INVOKABLE EventWrapper *createNewEventWrapperFrom(KCalendarCore::Event::Ptr event, qint64 collectionId);

private Q_SLOTS:
    void delayedInit();

Q_SIGNALS:
    void loadingChanged();
    void entityTreeModelChanged();
    void defaultCalendarSelectableIndexChanged();

private:
    Akonadi::ETMCalendar *m_calendar = nullptr;
    KDescendantsProxyModel *m_treeModel;
    QAbstractProxyModel *m_baseModel = nullptr;
    KCheckableProxyModel *m_selectionProxyModel = nullptr;
    Akonadi::ETMViewStateSaver *mCollectionSelectionModelStateSaver = nullptr;
    KDescendantsProxyModel *m_allCalendars = nullptr;
    Akonadi::CollectionFilterProxyModel *m_mimeTypeFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_rightsFilterModel = nullptr;
    int m_defaultCalendarSelectableIndex;
};
