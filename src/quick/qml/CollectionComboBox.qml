// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.akonadi 1.0 as Akonadi
import org.kde.kirigami 2.19 as Kirigami

/**
 * Special combobox control that allows to choose a collection.
 * The collection displayed can be filtered using the \p mimeTypeFilter
 * and \p accessRightsFilter properties.
 */
QQC2.ComboBox {
    id: comboBox

    /**
     * This property holds the id of the default collection, that is the
     * collection that will be selected by default.
     * @property int defaultCollectionId
     */
    property alias defaultCollectionId: collectionComboBoxModel.defaultCollectionId

    /**
     * This property holds the mime types of the collection that should be
     * displayed.
     *
     * @property list<string> mimeTypeFilter
     * @code{.qml}
     * import org.kde.akonadi 1.0 as Akonadi
     * 
     * Akonadi.CollectionComboBoxModel {
     *     mimeTypeFilter: [Akonadi.MimeTypes.address, Akonadi.MimeTypes.contactGroup]
     * }
     * @endcode
     */
    property alias mimeTypeFilter: collectionComboBoxModel.mimeTypeFilter

    /**
     * This property holds the access right of the collection that should be
     * displayed.
     *
     * @property Akonadi::Collection::Rights rights
     * @code{.qml}
     * import org.kde.akonadi 1.0 as Akonadi
     * 
     * Akonadi.CollectionComboBoxModel {
     *     accessRightsFilter: Akonadi.Collection.CanCreateItem
     * }
     * @endcode
     */
    property alias accessRightsFilter: collectionComboBoxModel.accessRightsFilter

    signal userSelectedCollection(var collection)

    currentIndex: 0
    onActivated: if (index > -1) {
        const selectedModelIndex = collectionComboBoxModel.index(currentIndex, 0);
        const selectedCollection = collectionComboBoxModel.data(selectedModelIndex, Akonadi.Collection.CollectionRole);
        userSelectedCollection(selectedCollection);
    }

    textRole: "display"
    valueRole: "collectionId"

    indicator: Rectangle {
        id: indicatorDot

        // Make sure to check the currentValue property directly or risk listening to something that won't necessarily emit a changed() signal'
        readonly property var selectedModelIndex: comboBox.currentValue > -1 ? comboBox.model.index(comboBox.currentIndex, 0) : null
        readonly property var selectedCollectionColor: comboBox.currentValue > -1 ? comboBox.model.data(selectedModelIndex, Akonadi.Collection.CollectionColorRole) : null

        implicitHeight: comboBox.implicitHeight * 0.4
        implicitWidth: implicitHeight

        x: comboBox.mirrored ? comboBox.leftPadding : comboBox.width - (comboBox.leftPadding * 3) - Kirigami.Units.iconSizes.smallMedium
        y: comboBox.topPadding + (comboBox.availableHeight - height) / 2

        radius: width * 0.5
        color: selectedCollectionColor
    }

    model: Akonadi.CollectionComboBoxModel {
        id: collectionComboBoxModel
        onCurrentIndexChanged: comboBox.currentIndex = currentIndex
    }

    delegate: Kirigami.BasicListItem {
        label: display
        icon: decoration
        trailing: Rectangle {
            anchors.margins: Kirigami.Units.smallSpacing
            width: height
            radius: width * 0.5
            color: model.collectionColor
        }
    }

    popup.z: 1000
}
