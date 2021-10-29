// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15
import org.kde.kirigami 2.15 as Kirigami
import org.kde.kalendar 1.0 as Kalendar

Map {
    id: map
    property bool containsLocation: queryHasResults ? visibleRegion.contains(geocodeModel.get(0).coordinate) : false
    readonly property bool hasCoordinate: !isNaN(selectedLatitude) && !isNaN(selectedLongitude)
    property alias pluginComponent: mapPlugin
    property var query
    property bool queryHasResults: geocodeModel.count > 0
    property int queryStatus: geocodeModel.status
    property bool selectMode: false
    property real selectedLatitude: NaN
    property real selectedLongitude: NaN

    anchors.fill: parent
    gesture.enabled: true

    function goToLocation() {
        fitViewportToGeoShape(geocodeModel.get(0).boundingBox, 0);
        if (map.zoomLevel > 18.0) {
            map.zoomLevel = 18.0;
        }
    }
    signal selectedLocationAddress(string address)

    Component.onCompleted: {
        if (hasCoordinate) {
            map.center = QtPositioning.coordinate(selectedLatitude, selectedLongitude);
            map.zoomLevel = 17.0;
        }
    }
    onCopyrightLinkActivated: {
        Qt.openUrlExternally(link);
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: map.queryStatus === GeocodeModel.Loading
        visible: queryStatus === GeocodeModel.Loading
    }
    Button {
        anchors.right: parent.right
        text: i18n("Return to Location")
        visible: !map.containsLocation && map.query
        z: 10

        onClicked: map.goToLocation()
    }
    MapItemView {
        property Component circle: MapCircle {
            id: mapCircle
            border.color: Kirigami.Theme.linkColor
            border.width: 2
            center: locationData.coordinate
            color: Kirigami.Theme.highlightColor
            opacity: 0.25
            radius: locationData.boundingBox.center.distanceTo(locationData.boundingBox.topRight)
            smooth: true
        }
        property Component pin: MapQuickItem {
            id: mapPin
            anchorPoint.x: iconMarker.width / 2
            anchorPoint.y: iconMarker.height
            coordinate: locationData.coordinate

            sourceItem: Kirigami.Icon {
                id: iconMarker
                color: Kirigami.Theme.negativeTextColor // Easier to see
                isMask: true
                source: "mark-location"
            }
        }

        delegate: switch (Kalendar.Config.locationMarker) {
        case Kalendar.Config.Circle:
            return circle;
        case Kalendar.Config.Pin:
        default:
            return pin;
        }

        MouseArea {
            anchors.fill: parent
            enabled: map.selectMode

            onClicked: {
                var coords = map.toCoordinate(Qt.point(mouseX, mouseY), false);
                clickGeocodeModel.query = coords;
                clickGeocodeModel.update();
            }

            GeocodeModel {
                id: clickGeocodeModel
                limit: 1
                plugin: map.pluginComponent

                onLocationsChanged: if (count) {
                    selectedLocationAddress(get(0).address.text);
                }
            }
        }

        model: GeocodeModel {
            id: geocodeModel
            autoUpdate: true
            limit: 1
            plugin: map.pluginComponent
            query: hasCoordinate ? undefined : map.query

            onLocationsChanged: {
                if (count > 0) {
                    map.goToLocation();
                }
            }
        }
    }

    plugin: Plugin {
        id: mapPlugin
        name: "osm"
    }
}
