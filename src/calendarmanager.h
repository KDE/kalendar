// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <ETMViewStateSaver>
#include <KDescendantsProxyModel>
#include <AkonadiCore/AgentFilterProxyModel>

namespace Akonadi {
    class ETMCalendar;
}

class KCheckableProxyModel;
class QAbstractProxyModel;
class MonthModel;

class CalendarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(MonthModel *monthModel READ monthModel CONSTANT)
    Q_PROPERTY(QAbstractProxyModel *collections READ collections CONSTANT)
    Q_PROPERTY(Akonadi::ETMCalendar *calendar READ calendar CONSTANT)
public:
    CalendarManager(QObject *parent = nullptr);
    ~CalendarManager() override;

    KCheckableProxyModel *collectionSelectionProxyModel() const;
    void setCollectionSelectionProxyModel(KCheckableProxyModel *);

    bool loading() const;
    MonthModel *monthModel() const;
    QAbstractProxyModel *collections();
    Q_INVOKABLE void save();
    Akonadi::ETMCalendar *calendar() const;

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
    MonthModel *m_monthModel;
    Akonadi::ETMViewStateSaver *mCollectionSelectionModelStateSaver = nullptr;
};
