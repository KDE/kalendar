// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/AgentFilterProxyModel>
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/ETMViewStateSaver>
#include <Akonadi/EntityRightsFilterModel>
#else
#include <AkonadiCore/AgentFilterProxyModel>
#include <AkonadiCore/CollectionFilterProxyModel>
#include <AkonadiCore/EntityRightsFilterModel>
#include <ETMViewStateSaver>
#endif
#include <Akonadi/Calendar/IncidenceChanger>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>
#include <KDescendantsProxyModel>
#include <incidencewrapper.h>
#include <todosortfilterproxymodel.h>

namespace Akonadi
{
class ETMCalendar;
}

class KCheckableProxyModel;
class QAbstractProxyModel;
class QAbstractItemModel;
class ColorProxyModel;
class CalendarCategoriesModel;

class CalendarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QAbstractProxyModel *collections READ collections CONSTANT)
    Q_PROPERTY(QAbstractItemModel *todoCollections READ todoCollections CONSTANT)
    Q_PROPERTY(QAbstractItemModel *viewCollections READ viewCollections CONSTANT)
    Q_PROPERTY(KDescendantsProxyModel *allCalendars READ allCalendars CONSTANT)
    Q_PROPERTY(Akonadi::EntityRightsFilterModel *selectableEventCalendars READ selectableEventCalendars CONSTANT)
    Q_PROPERTY(Akonadi::EntityRightsFilterModel *selectableTodoCalendars READ selectableTodoCalendars CONSTANT)
    Q_PROPERTY(Akonadi::ETMCalendar *calendar READ calendar CONSTANT)
    Q_PROPERTY(Akonadi::IncidenceChanger *incidenceChanger READ incidenceChanger CONSTANT)
    Q_PROPERTY(QVariantMap undoRedoData READ undoRedoData NOTIFY undoRedoDataChanged)

public:
    CalendarManager(QObject *parent = nullptr);
    ~CalendarManager() override;

    KCheckableProxyModel *collectionSelectionProxyModel() const;
    void setCollectionSelectionProxyModel(KCheckableProxyModel *);

    bool loading() const;
    QAbstractProxyModel *collections();
    QAbstractItemModel *todoCollections();
    QAbstractItemModel *viewCollections();
    Q_INVOKABLE void save();
    Akonadi::ETMCalendar *calendar() const;
    Akonadi::IncidenceChanger *incidenceChanger() const;
    KDescendantsProxyModel *allCalendars();
    Akonadi::EntityRightsFilterModel *selectableEventCalendars() const;
    Akonadi::EntityRightsFilterModel *selectableTodoCalendars() const;
    Q_INVOKABLE qint64 defaultCalendarId(IncidenceWrapper *incidenceWrapper);
    Q_INVOKABLE int getCalendarSelectableIndex(IncidenceWrapper *incidenceWrapper);
    QVariantMap undoRedoData();

    Q_INVOKABLE void addIncidence(IncidenceWrapper *incidenceWrapper);
    Q_INVOKABLE void editIncidence(IncidenceWrapper *incidenceWrapper);
    Q_INVOKABLE bool hasChildren(KCalendarCore::Incidence::Ptr incidence);
    void deleteAllChildren(KCalendarCore::Incidence::Ptr incidence);
    Q_INVOKABLE void deleteIncidence(KCalendarCore::Incidence::Ptr incidence, bool deleteChildren = false);
    Q_INVOKABLE QVariantMap getCollectionDetails(QVariant collectionId);
    Q_INVOKABLE void setCollectionColor(qint64 collectionId, QColor color);
    Q_INVOKABLE QVariant getIncidenceSubclassed(KCalendarCore::Incidence::Ptr incidencePtr);
    Q_INVOKABLE void undoAction();
    Q_INVOKABLE void redoAction();

private Q_SLOTS:
    void delayedInit();

Q_SIGNALS:
    void loadingChanged();
    void entityTreeModelChanged();
    void undoRedoDataChanged();
    void incidenceChanged();

private:
    Akonadi::ETMCalendar::Ptr m_calendar = nullptr;
    Akonadi::IncidenceChanger *m_changer;
    KDescendantsProxyModel *m_flatCollectionTreeModel;
    ColorProxyModel *m_baseModel = nullptr;
    KCheckableProxyModel *m_selectionProxyModel = nullptr;
    Akonadi::ETMViewStateSaver *mCollectionSelectionModelStateSaver = nullptr;
    KDescendantsProxyModel *m_allCalendars = nullptr;
    Akonadi::CollectionFilterProxyModel *m_eventMimeTypeFilterModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_todoMimeTypeFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_eventRightsFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_todoRightsFilterModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_todoViewCollectionModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_viewCollectionModel = nullptr;
};
