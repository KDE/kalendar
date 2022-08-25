// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtLocation 5.15
import "labelutils.js" as LabelUtils

import org.kde.kalendar 1.0

Kirigami.OverlayDrawer {
    id: root

    signal addSubTodo(var parentWrapper)
    signal editIncidence(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)

    property var incidenceData
    property var incidenceWrapper
    property var collectionData
    readonly property var activeTags : Filter.tags

    enabled: true
    interactive: enabled
    edge: Kirigami.Settings.isMobile ? Qt.BottomEdge :
        Qt.application.layoutDirection == Qt.RightToLeft ? Qt.LeftEdge : Qt.RightEdge

    topPadding: 0
    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    contentItem: Loader {
        anchors.fill: parent

        active: root.drawerOpen
        sourceComponent: ColumnLayout {
            anchors.fill: parent

            Kirigami.AbstractApplicationHeader {
                Layout.fillWidth: true
                topPadding: Kirigami.Units.smallSpacing / 2;
                bottomPadding: Kirigami.Units.smallSpacing / 2;
                rightPadding: Kirigami.Units.smallSpacing
                leftPadding: Kirigami.Units.smallSpacing

                RowLayout {
                    anchors.fill: parent
                    Kirigami.Heading {
                        id: infoHeader
                        Layout.fillHeight: true
                        Layout.leftMargin: Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing
                        text: i18n(incidenceInfoContents.incidenceWrapper.incidenceTypeStr)
                    }

                    Kirigami.ActionToolBar {
                        id: actionToolbar
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        alignment: Qt.AlignRight

                        actions: [
                            Kirigami.Action {
                                icon.name: "list-add"
                                text: i18n("Add Sub-Task")
                                visible: incidenceInfoContents.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                                onTriggered: {
                                    Kalendar.UiUtils.setUpAddSubTodo(incidenceInfoContents.incidenceWrapper);

                                    if(Kirigami.Settings.isMobile) {
                                        root.close();
                                    }
                                }
                            },
                            Kirigami.Action {
                                property bool todoCompleted: incidenceInfoContents.incidenceWrapper.todoCompleted
                                icon.name: todoCompleted ? "edit-undo" : "checkmark"
                                text: todoCompleted ? i18n("Mark Incomplete") : i18n("Mark Complete")
                                visible: incidenceInfoContents.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                                onTriggered: {
                                    incidenceInfoContents.incidenceWrapper.todoCompleted = !incidenceInfoContents.incidenceWrapper.todoCompleted;
                                    CalendarManager.editIncidence(incidenceInfoContents.incidenceWrapper);
                                }
                            },
                            Kirigami.Action {
                                icon.name: "edit-entry"
                                text: i18n("Edit")
                                enabled: incidenceInfoContents.collectionData && !incidenceInfoContents.collectionData.readOnly
                                onTriggered: KalendarUiUtils.setUpEdit(incidenceInfoContents.incidenceData.incidencePtr)
                            },
                            Kirigami.Action {
                                icon.name: "edit-delete"
                                text: i18n("Delete")
                                enabled: incidenceInfoContents.collectionData && !incidenceInfoContents.collectionData.readOnly
                                onTriggered: {
                                    KalendarUiUtils.setUpDelete(incidenceInfoContents.incidenceData.incidencePtr, incidenceInfoContents.incidenceData.startTime);

                                    if(Kirigami.Settings.isMobile) {
                                        root.close();
                                    }
                                }
                            }
                        ]
                    }
                }
            }

            IncidenceInfoContents {
                id: incidenceInfoContents

                Layout.fillWidth: true
                Layout.fillHeight: true

                incidenceData: root.incidenceData
                activeTags: root.activeTags
                onTagClicked: Filter.toggleFilterTag(modelData)
            }
        }
    }
}
