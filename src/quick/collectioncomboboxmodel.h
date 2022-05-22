// SPDX-FileCopyrightText: 2007-2009 Tobias Koenig <tokoe@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <Akonadi/Collection>
#include <QSortFilterProxyModel>
#include <memory>
#include <qobjectdefs.h>

namespace Akonadi
{
namespace Quick
{
class CollectionComboBoxModelPrivate;

/**
 * @short The model for a combobox for selecting an Akonadi collection.
 *
 * This model provides a way easily select a collection
 * from the Akonadi storage.
 * The available collections can be filtered by mime type and
 * access rights.
 *
 * Example:
 *
 * @code{.qml}
 *
 * import QtQuick.Controls 2.15 as QQC2
 * import org.kde.akonadi 1.0 as Akonadi
 *
 * QQC2.ComboBox {
 *     model: AkonadiQuick.ComboBoxModel {
 *         mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
 *         accessRightsFilter: Akonadi.Collection.CanCreateItem
 *     }
 * }
 * @endcode
 *
 * @author Carl Schwan <carl@carlschwan.eu>
 */
class CollectionComboBoxModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QStringList mimeTypeFilter READ mimeTypeFilter WRITE setMimeTypeFilter NOTIFY mimeTypeFilterChanged)
    Q_PROPERTY(Akonadi::Collection::Right accessRightsFilter READ accessRightsFilter WRITE setAccessRightsFilter NOTIFY accessRightsFilterChanged)
    Q_PROPERTY(Akonadi::Collection currentCollection READ currentCollection NOTIFY currentCollectionChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)

public:
    explicit CollectionComboBoxModel(QObject *parent = nullptr);
    ~CollectionComboBoxModel();

    /**
     * Sets the content @p mimetypes the collections shall be filtered by.
     */
    void setMimeTypeFilter(const QStringList &mimetypes);

    /**
     * Returns the content mimetype the collections are filtered by.
     * Don't assume this list has the original order.
     */
    Q_REQUIRED_RESULT QStringList mimeTypeFilter() const;

    /**
     * Sets the access @p rights the collections shall be filtered by.
     */
    void setAccessRightsFilter(Akonadi::Collection::Right rights);

    /**
     * Returns the access rights the collections are filtered by.
     */
    Q_REQUIRED_RESULT Akonadi::Collection::Right accessRightsFilter() const;

    /**
     * Sets the @p collection that shall be selected by default.
     */
    void setDefaultCollection(const Akonadi::Collection &collection);

    /**
     * Returns the current selection.
     */
    Q_REQUIRED_RESULT Akonadi::Collection currentCollection() const;

    /**
     * Sets if the virtual collections are excluded.
     */
    void setExcludeVirtualCollections(bool b);

    /**
     * Returns if the virual exollections are excluded
     */
    Q_REQUIRED_RESULT bool excludeVirtualCollections() const;

    int currentIndex() const;
    void setCurrentIndex(int currendIndex);

Q_SIGNALS:
    /**
     * This signal is emitted whenever the current selection
     * has been changed.
     *
     * @param collection The current selection.
     */
    void currentCollectionChanged();
    void currentIndexChanged();
    void mimeTypeFilterChanged();
    void accessRightsFilterChanged();

private:
    std::unique_ptr<CollectionComboBoxModelPrivate> const d;

    Q_PRIVATE_SLOT(d, void activated(int))
    Q_PRIVATE_SLOT(d, void activated(const QModelIndex &))
};

}
}
