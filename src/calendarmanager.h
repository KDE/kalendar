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

class CalendarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QAbstractProxyModel *collections READ collections CONSTANT)
    Q_PROPERTY(Akonadi::EntityRightsFilterModel *selectableCalendars READ selectableCalendars CONSTANT)
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
    Akonadi::EntityRightsFilterModel *selectableCalendars() const;
    Q_INVOKABLE void addEvent(qint64 collectionId, KCalendarCore::Event::Ptr event);

private Q_SLOTS:
    void delayedInit();

Q_SIGNALS:
    void loadingChanged();
    void entityTreeModelChanged();

private:
    Akonadi::ETMCalendar *m_calendar = nullptr;
    KDescendantsProxyModel *m_treeModel;
    QAbstractProxyModel *m_baseModel = nullptr;
    KCheckableProxyModel *m_selectionProxyModel = nullptr;
    Akonadi::ETMViewStateSaver *mCollectionSelectionModelStateSaver = nullptr;
    Akonadi::CollectionFilterProxyModel *m_mimeTypeFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_rightsFilterModel = nullptr;
};
