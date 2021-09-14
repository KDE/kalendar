// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <tagmanager.h>

class FlatTagModel : public QSortFilterProxyModel
{
public:
    explicit FlatTagModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        Akonadi::Monitor *monitor = new Akonadi::Monitor(this);
        monitor->setObjectName(QStringLiteral("TagModelMonitor"));
        monitor->setTypeMonitored(Akonadi::Monitor::Tags);

        auto flatTagModel = new KDescendantsProxyModel;
        flatTagModel->setSourceModel(new Akonadi::TagModel(monitor));
        setSourceModel(flatTagModel);

        setDynamicSortFilter(true);
        sort(0);
    };

protected:
    bool filterAcceptsRow(int row, const QModelIndex &sourceParent) const override
    {
        // Eliminate duplicate tag names
        const QModelIndex sourceIndex = sourceModel()->index(row, 0, sourceParent);
        Q_ASSERT(sourceIndex.isValid());

        auto data = sourceIndex.data(Akonadi::TagModel::NameRole);
        auto matches = match(index(0,0), Akonadi::TagModel::NameRole, data, 2, Qt::MatchExactly | Qt::MatchWrap | Qt::MatchRecursive);

        return matches.length() < 2;
    }
};

TagManager::TagManager(QObject* parent)
{
    m_tagModel = new FlatTagModel;
}

QSortFilterProxyModel * TagManager::tagModel()
{
    return m_tagModel;
}


