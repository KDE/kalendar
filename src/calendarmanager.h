// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>

#include <akonadi-calendar_version.h>
#if AKONADICALENDAR_VERSION > QT_VERSION_CHECK(5, 19, 41)
#include <Akonadi/ETMCalendar>
#else
#include <Akonadi/Calendar/ETMCalendar>
#endif
#include <KConfigWatcher>
#include <QObject>
#include <akonadi-calendar_version.h>
#include <incidencewrapper.h>

namespace Akonadi
{
class AgentFilterProxyModel;
class CollectionFilterProxyModel;
class ETMViewStateSaver;
class EntityRightsFilterModel;
class EntityMimeTypeFilterModel;
class IncidenceChanger;
}

class KDescendantsProxyModel;
class KCheckableProxyModel;
class QAbstractProxyModel;
class QAbstractItemModel;
class ColorProxyModel;

class CalendarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QAbstractProxyModel *collections READ collections CONSTANT)
    Q_PROPERTY(QAbstractItemModel *todoCollections READ todoCollections CONSTANT)
    Q_PROPERTY(QAbstractItemModel *viewCollections READ viewCollections CONSTANT)
    Q_PROPERTY(QVector<qint64> enabledTodoCollections READ enabledTodoCollections NOTIFY enabledTodoCollectionsChanged)
    Q_PROPERTY(Akonadi::CollectionFilterProxyModel *allCalendars READ allCalendars CONSTANT)
    Q_PROPERTY(Akonadi::CollectionFilterProxyModel *selectableCalendars READ selectableCalendars CONSTANT)
    Q_PROPERTY(Akonadi::CollectionFilterProxyModel *selectableEventCalendars READ selectableEventCalendars CONSTANT)
    Q_PROPERTY(Akonadi::CollectionFilterProxyModel *selectableTodoCalendars READ selectableTodoCalendars CONSTANT)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar CONSTANT)
    Q_PROPERTY(Akonadi::IncidenceChanger *incidenceChanger READ incidenceChanger CONSTANT)
    Q_PROPERTY(QVariantMap undoRedoData READ undoRedoData NOTIFY undoRedoDataChanged)

public:
    explicit CalendarManager(QObject *parent = nullptr);
    ~CalendarManager() override;

    KCheckableProxyModel *collectionSelectionProxyModel() const;
    void setCollectionSelectionProxyModel(KCheckableProxyModel *);

    bool loading() const;
    QAbstractProxyModel *collections();
    QAbstractItemModel *todoCollections();
    QAbstractItemModel *viewCollections();
    QVector<qint64> enabledTodoCollections();
    void refreshEnabledTodoCollections();

    Q_INVOKABLE void save();
    Akonadi::ETMCalendar::Ptr calendar() const;
    Akonadi::IncidenceChanger *incidenceChanger() const;
    Akonadi::CollectionFilterProxyModel *allCalendars();
    Akonadi::CollectionFilterProxyModel *selectableCalendars() const;
    Akonadi::CollectionFilterProxyModel *selectableEventCalendars() const;
    Akonadi::CollectionFilterProxyModel *selectableTodoCalendars() const;
    Q_INVOKABLE qint64 defaultCalendarId(IncidenceWrapper *incidenceWrapper);
    Q_INVOKABLE int getCalendarSelectableIndex(IncidenceWrapper *incidenceWrapper);
    QVariantMap undoRedoData();

    Q_INVOKABLE Akonadi::Item incidenceItem(KCalendarCore::Incidence::Ptr incidence);
    Q_INVOKABLE void addIncidence(IncidenceWrapper *incidenceWrapper);
    Q_INVOKABLE void editIncidence(IncidenceWrapper *incidenceWrapper);
    Q_INVOKABLE void updateIncidenceDates(IncidenceWrapper *incidenceWrapper,
                                          int startOffset,
                                          int endOffset,
                                          int occurrences = -1,
                                          const QDateTime &occurrenceDate = QDateTime());
    Q_INVOKABLE bool hasChildren(KCalendarCore::Incidence::Ptr incidence);
    void deleteAllChildren(KCalendarCore::Incidence::Ptr incidence);
    Q_INVOKABLE void deleteIncidence(KCalendarCore::Incidence::Ptr incidence, bool deleteChildren = false);
    Q_INVOKABLE void changeIncidenceCollection(KCalendarCore::Incidence::Ptr incidence, qint64 collectionId);
    void changeIncidenceCollection(Akonadi::Item item, qint64 collectionId);
    Q_INVOKABLE QVariantMap getCollectionDetails(QVariant collectionId);
    Q_INVOKABLE void setCollectionColor(qint64 collectionId, const QColor &color);
    Q_INVOKABLE QVariant getIncidenceSubclassed(KCalendarCore::Incidence::Ptr incidencePtr);
    Q_INVOKABLE void undoAction();
    Q_INVOKABLE void redoAction();

    Q_INVOKABLE void updateAllCollections();
    Q_INVOKABLE void updateCollection(qint64 collectionId);
    Q_INVOKABLE void deleteCollection(qint64 collectionId);
    Q_INVOKABLE void editCollection(qint64 collectionId);

private Q_SLOTS:
    void delayedInit();

Q_SIGNALS:
    void loadingChanged();
    void entityTreeModelChanged();
    void undoRedoDataChanged();
    void incidenceChanged();
    void enabledTodoCollectionsChanged();
    void updateIncidenceDatesCompleted();
    void collectionColorsChanged();

private:
    Akonadi::ETMCalendar::Ptr m_calendar = nullptr;
    Akonadi::IncidenceChanger *m_changer = nullptr;
    KDescendantsProxyModel *m_flatCollectionTreeModel = nullptr;
    ColorProxyModel *m_baseModel = nullptr;
    KCheckableProxyModel *m_selectionProxyModel = nullptr;
    Akonadi::ETMViewStateSaver *mCollectionSelectionModelStateSaver = nullptr;
    Akonadi::CollectionFilterProxyModel *m_allCalendars = nullptr;
    Akonadi::CollectionFilterProxyModel *m_eventMimeTypeFilterModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_todoMimeTypeFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_allCollectionsRightsFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_eventRightsFilterModel = nullptr;
    Akonadi::EntityRightsFilterModel *m_todoRightsFilterModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_selectableCollectionsModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_selectableEventCollectionsModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_selectableTodoCollectionsModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_todoViewCollectionModel = nullptr;
    Akonadi::CollectionFilterProxyModel *m_viewCollectionModel = nullptr;
    QVector<qint64> m_enabledTodoCollections;
    KConfigWatcher::Ptr m_colorWatcher;
};

Q_DECLARE_METATYPE(Akonadi::ETMCalendar::Ptr)
