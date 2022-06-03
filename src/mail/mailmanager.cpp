// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailmanager.h"
#include "mailmodel.h"

#include <QTimer>

// Akonadi
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/MessageModel>
#include <Akonadi/Monitor>
#include <Akonadi/Session>
#include <Akonadi/ChangeRecorder>
#include <MailCommon/FolderCollectionMonitor>
#include <KMime/Message>
#include <KDescendantsProxyModel>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/SelectionProxyModel>
#include <Akonadi/ServerManager>
#include <QApplication>
#include <QtCore/QItemSelectionModel>

#include <KItemModels/KDescendantsProxyModel>

MailManager::MailManager(QObject *parent)
    : QObject(parent)
    , m_loading(true)
{

    using namespace Akonadi;
    //                              mailModel
    //                                  ^
    //                                  |
    //                              itemModel
    //                                  |
    //                              flatModel
    //                                  |
    //  descendantsProxyModel ------> selectionModel
    //           ^                      ^
    //           |                      |
    //  collectionFilter                |
    //            \__________________treemodel

    m_session = new Session(QByteArrayLiteral("KMailManager Kernel ETM"), this);
    auto folderCollectionMonitor = new MailCommon::FolderCollectionMonitor(m_session, this);

    // setup collection model
    auto treeModel = new Akonadi::EntityTreeModel(folderCollectionMonitor->monitor(), this);
    treeModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::LazyPopulation);

    m_foldersModel = new Akonadi::CollectionFilterProxyModel(this);
    m_foldersModel->setSourceModel(treeModel);
    m_foldersModel->addMimeTypeFilter(KMime::Message::mimeType());

    // Setup selection model
    m_collectionSelectionModel = new QItemSelectionModel(m_foldersModel);
    connect(m_collectionSelectionModel, &QItemSelectionModel::selectionChanged, this, [this](const QItemSelection &selected, const QItemSelection &deselected) {
        Q_UNUSED(deselected)
        const auto indexes = selected.indexes();
        if (indexes.count()) {
            QString name;
            QModelIndex index = indexes[0];
            while (index.isValid()) {
                if (name.isEmpty()) {
                    name = index.data(Qt::DisplayRole).toString();
                } else {
                    name = index.data(Qt::DisplayRole).toString() + QLatin1String(" / ") + name;
                }
                index = index.parent();
            }
            m_selectedFolderName = name;
            Q_EMIT selectedFolderNameChanged();
        }
    });
    auto selectionModel = new SelectionProxyModel(m_collectionSelectionModel, this);
    selectionModel->setSourceModel(treeModel);
    selectionModel->setFilterBehavior(KSelectionProxyModel::ChildrenOfExactSelection);

    // Setup mail model
    auto folderFilterModel = new EntityMimeTypeFilterModel(this);
    folderFilterModel->setSourceModel(selectionModel);
    folderFilterModel->setHeaderGroup(EntityTreeModel::ItemListHeaders);
    folderFilterModel->addMimeTypeInclusionFilter(KMime::Message::mimeType());
    folderFilterModel->addMimeTypeExclusionFilter(Collection::mimeType());

    // Proxy for QML roles
    m_folderModel = new MailModel(this);
    m_folderModel->setSourceModel(folderFilterModel);

    if (Akonadi::ServerManager::isRunning()) {
        m_loading = false;
    } else {
        connect(Akonadi::ServerManager::self(), &Akonadi::ServerManager::stateChanged,
                this, [this](Akonadi::ServerManager::State state) {
                    if (state == Akonadi::ServerManager::State::Broken) {
                        qApp->exit(-1);
                        return;
                    }
                    bool loading = state != Akonadi::ServerManager::State::Running;
                    if (loading == m_loading) {
                        return;
                    }
                    m_loading = loading;
                    Q_EMIT loadingChanged();
                    disconnect(Akonadi::ServerManager::self(), &Akonadi::ServerManager::stateChanged, this, nullptr);
                });
    }
    Q_EMIT folderModelChanged();
    Q_EMIT loadingChanged();
}

MailModel *MailManager::folderModel() const
{
    return m_folderModel;
}

void MailManager::loadMailCollection(const QModelIndex &modelIndex)
{
    if (!modelIndex.isValid()) {
        return;
    }

    m_collectionSelectionModel->select(modelIndex, QItemSelectionModel::ClearAndSelect);
}

bool MailManager::loading() const
{
    return m_loading;
}

Akonadi::CollectionFilterProxyModel *MailManager::foldersModel() const
{
    return m_foldersModel;
}

Akonadi::Session *MailManager::session() const
{
    return m_session;
}

QString MailManager::selectedFolderName() const
{
    return m_selectedFolderName;
}
