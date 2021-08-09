// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15
import org.kde.kirigami 2.15 as Kirigami

Map {
    id: map
    anchors.fill: parent

    signal selectedLocationAddress(string address)

    property alias pluginComponent: mapPlugin
    property var query
    property bool queryHasResults: geocodeModel.count > 0
    property int queryStatus: geocodeModel.status
    property bool containsLocation: queryHasResults ? visibleRegion.contains(geocodeModel.get(0).coordinate) : false
    property bool selectMode: false

    function goToLocation() {
        fitViewportToGeoShape(geocodeModel.get(0).boundingBox, 0);
        if (map.zoomLevel > 18.0) {
            map.zoomLevel = 18.0;
        }
    }

    gesture.enabled: true
    plugin: Plugin {
        id: mapPlugin
        name: "osm"
    }
    onCopyrightLinkActivated: {
        Qt.openUrlExternally(link)
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: map.queryStatus === GeocodeModel.Loading
        visible: queryStatus === GeocodeModel.Loading
    }

    Button {
        anchors.right: parent.right
        text: i18n("Return to location")
        visible: !map.containsLocation && map.query
        onClicked: map.goToLocation()
        z: 10
    }

    MapItemView {
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
                plugin: map.pluginComponent
                limit: 1
                onLocationsChanged: if(count) { selectedLocationAddress(get(0).address.text) }
            }
        }

        model: GeocodeModel {
            id: geocodeModel
            plugin: map.pluginComponent
            query: map.query
            autoUpdate: true
            limit: 1
            onLocationsChanged: {
                if(count > 0) {
                    map.goToLocation();
                }
            }
        }

        delegate: MapCircle {
            id: point
            radius: locationData.boundingBox.center.distanceTo(locationData.boundingBox.topRight)
            color: Kirigami.Theme.highlightColor
            border.color: Kirigami.Theme.linkColor
            border.width: Kirigami.Units.devicePixelRatio * 2
            smooth: true
            opacity: 0.25
            center: locationData.coordinate
        }
    }
}
