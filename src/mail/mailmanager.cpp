// SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "mailmanager.h"
#include "mailmodel.h"

#include <QTimer>

// Akonadi
#include <Akonadi/ChangeRecorder>
#include <Akonadi/CollectionFilterProxyModel>
#include <Akonadi/EntityMimeTypeFilterModel>
#include <Akonadi/EntityTreeModel>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/MessageModel>
#include <Akonadi/Monitor>
#include <Akonadi/SelectionProxyModel>
#include <Akonadi/ServerManager>
#include <Akonadi/Session>
#include <KDescendantsProxyModel>
#include <KMime/Message>
#include <MailCommon/FolderCollectionMonitor>
#include <QApplication>
#include <QtCore/QItemSelectionModel>

#include "mailadaptor.h"
#include <KItemModels/KDescendantsProxyModel>
#include <qabstractitemmodel.h>

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
    //           /---------------> selectionModel
    //           |                      ^
    //           |                      |
    //  collectionFilter                |
    //            \__________________treemodel

    m_session = new Session(QByteArrayLiteral("Kalendar Mail Manager Kernel ETM"), this);
    auto folderCollectionMonitor = new MailCommon::FolderCollectionMonitor(m_session, this);

    // setup collection model
    auto treeModel = new Akonadi::EntityTreeModel(folderCollectionMonitor->monitor(), this);
    treeModel->setItemPopulationStrategy(Akonadi::EntityTreeModel::LazyPopulation);

    m_foldersModel = new Akonadi::CollectionFilterProxyModel(this);
    m_foldersModel->setSourceModel(treeModel);
    m_foldersModel->addMimeTypeFilter(KMime::Message::mimeType());

    // Setup selection model
    m_collectionSelectionModel = new QItemSelectionModel(m_foldersModel);
    connect(m_collectionSelectionModel, &QItemSelectionModel::selectionChanged, this, &MailManager::computeFolderName);

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
        connect(Akonadi::ServerManager::self(), &Akonadi::ServerManager::stateChanged, this, [this](Akonadi::ServerManager::State state) {
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

    (void)new MailManagerAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Mail"), this);
}

MailModel *MailManager::folderModel() const
{
    return m_folderModel;
}

void MailManager::loadMailCollectionByIndex(const QModelIndex &modelIndex)
{
    if (!modelIndex.isValid()) {
        return;
    }

    m_collectionSelectionModel->select(modelIndex, QItemSelectionModel::ClearAndSelect);
}

QModelIndex findCollectionInTreeModel(QAbstractItemModel *model, Akonadi::Collection::Id id, const QModelIndex &parentIndex = {})
{
    for (int i = 0; i < model->rowCount(); i++) {
        const auto index = model->index(i, 0, parentIndex);
        const auto collectionId = model->data(index, Akonadi::EntityTreeModel::CollectionIdRole);
        if (collectionId == id) {
            return index;
        }
        if (model->rowCount(index)) {
            const auto childIndex = findCollectionInTreeModel(model, id, index);
            if (childIndex.isValid()) {
                return childIndex;
            }
        }
    }
    return {};
}

void MailManager::loadMailCollection(const Akonadi::Collection &collection)
{
    if (!collection.isValid()) {
        return;
    }

    const auto index = findCollectionInTreeModel(m_collectionSelectionModel->model(), collection.id());
    if (index.isValid()) {
        m_collectionSelectionModel->select(index, QItemSelectionModel::ClearAndSelect);
    }
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

void MailManager::setSelectedFolderName(const QString &selectedFolderName)
{
    if (m_selectedFolderName == selectedFolderName) {
        return;
    }
    m_selectedFolderName = selectedFolderName;
    Q_EMIT selectedFolderNameChanged();
}

bool MailManager::showMail(qint64 serialNumber)
{
    auto job = new Akonadi::ItemFetchJob(Akonadi::Item(serialNumber), this);
    job->fetchScope().fetchFullPayload();
    job->fetchScope().setAncestorRetrieval(Akonadi::ItemFetchScope::Parent);
    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        const auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        if (fetchJob->items().count() >= 1) {
            const auto item = fetchJob->items().at(0);
            const auto collection = item.parentCollection();
            loadMailCollection(collection);
            Q_EMIT showMailInViewer(item);
        }
    });

    return true;
}

void MailManager::computeFolderName(const QItemSelection &selected, const QItemSelection &deselected)
{
    Q_UNUSED(deselected)

    const auto indexes = selected.indexes();
    if (indexes.count()) {
        QModelIndex index = indexes[0];
        QString name;
        while (index.isValid()) {
            if (name.isEmpty()) {
                name = index.data(Qt::DisplayRole).toString();
            } else {
                name = index.data(Qt::DisplayRole).toString() + QLatin1String(" / ") + name;
            }
            index = index.parent();
        }
        setSelectedFolderName(name);
    }
}
