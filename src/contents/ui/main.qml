import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0
import QtQml.Models 2.15

Kirigami.ApplicationWindow {
    id: root

    title: i18n("Calendar")

    pageStack.initialPage: mainPageComponent

    EventEditor {
        id: eventEditor
        onAdded: CalendarManager.addEvent(collectionId, name, desc, start, end, repeat, reminder, attendees)
    }

    globalDrawer: Kirigami.GlobalDrawer {
        bottomPadding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                model: CalendarManager.collections
                delegate: Kirigami.BasicListItem {
                    leftPadding: Kirigami.Units.largeSpacing * kDescendantLevel
                    leading: Controls.CheckBox {
                        visible: checkState != null
                        checked: checkState == 2
                        onClicked: model.checkState = (checked ? 2 : 0)
                    }
                    label: display
                    icon: decoration
                    Component.onCompleted: {
                        for (let i in model) {
                            console.log("Iteration: " + i, "Model iteration: " + model[i]);
                        }
                    }
                }
                footer: Controls.Button {
                    text: "save"
                    onClicked: CalendarManager.save();
                }
            }
        }
    }

    Component {
        id: mainPageComponent

        Kirigami.Page {
            id: monthPage
            title: new Date(CalendarManager.monthModel.year, CalendarManager.monthModel.month - 1, 1).toLocaleDateString(Qt.locale(), "<b>MMMM</b> yyyy")
            readonly property bool isLarge: width > Kirigami.Units.gridUnit * 30
            actions {
                left: Kirigami.Action {
                    text: i18n("Previous")
                    icon.name: "go-previous-view"
                    onTriggered: CalendarManager.monthModel.previous()
                }
                right: Kirigami.Action {
                    text: i18n("Next")
                    icon.name: "go-next-view"
                    onTriggered: CalendarManager.monthModel.next()
                }
                main: Kirigami.Action {
                    text: "Add event"
                    icon.name: "list-add"
                    onTriggered: eventEditor.open()
                }

                /*Kirigami.Action {
                    text: "Show week"
                    icon.name: "view-calendar-week"
                    onTriggered: pageStack.push(weekPageComponent); //, { "weekModel": monthModel.week() });
                }*/
            }
            padding: 0
            background: Rectangle {
                Kirigami.Theme.colorSet: monthPage.isLarge ? Kirigami.Theme.Header : Kirigami.Theme.View
                Component.onCompleted: console.log("isLarge: " + monthPage.isLarge, "Theme colorset: " + Kirigami.Theme.colorSet, "Color: " + color)
                color: monthPage.isLarge ? Kirigami.Theme.alternateBackgroundColor : Kirigami.Theme.backgroundColor
            }

            Component {
                id: mobileMonthDelegate
                Controls.AbstractButton {
                    id: button
                    implicitWidth: monthGrid.width / 7
                    implicitHeight: (monthGrid.height - Kirigami.Units.gridUnit * 2) / 6
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 0
                    contentItem: Column {
                        Kirigami.Heading {
                            id: number
                            width: parent.width
                            level: 3
                            text: model.dayNumber
                            horizontalAlignment: Text.AlignHCenter
                            padding: Kirigami.Units.smallSpacing
                            opacity: sameMonth ? 1 : 0.7
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Kirigami.Units.smallSpacing
                            Repeater {
                                model: DelegateModel {
                                    model: CalendarManager.monthModel
                                    rootIndex: modelIndex(index)
                                    delegate: Rectangle {
                                        width: Kirigami.Units.smallSpacing
                                        height: width
                                        radius: width / 2
                                        color: eventColor
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: desktopMonthDelegate
                Controls.AbstractButton {
                    id: button
                    implicitWidth: monthGrid.width / 7
                    implicitHeight: (monthGrid.height - Kirigami.Units.gridUnit * 2) / 6
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: model.sameMonth ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor
                    }
                    padding: 0
                    contentItem: ColumnLayout {
                        Kirigami.Heading {
                            level: 3
                            text: model.dayNumber
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            padding: Kirigami.Units.smallSpacing
                        }
                        Controls.ScrollView {
                            id: scrollEvents
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ColumnLayout {
                                width: scrollEvents.width
                                spacing: Kirigami.Units.smallSpacing
                                Repeater {
                                    // TODO create a delegate for mobile just showing points for events
                                    model: DelegateModel {
                                        model: CalendarManager.monthModel
                                        rootIndex: modelIndex(index)
                                        delegate: Kirigami.ShadowedRectangle {
                                            Layout.topMargin: prefix * (implicitHeight + Kirigami.Units.smallSpacing)
                                            Layout.fillWidth: true
                                            color: eventColor
                                            corners {
                                                bottomLeftRadius: isBegin ? 4 : 0
                                                topLeftRadius: isBegin ? 4 : 0
                                                bottomRightRadius: isEnd ? 4 : 0
                                                topRightRadius: isEnd ? 4 : 0
                                            }
                                            Layout.leftMargin: isBegin ? Kirigami.Units.smallSpacing : 0
                                            Layout.rightMargin: isEnd ? Kirigami.Units.smallSpacing : 0
                                            implicitHeight: Kirigami.Units.gridUnit + Kirigami.Units.smallSpacing * 2
                                            Controls.Label {
                                                id: eventItem
                                                visible: isBegin ? 1 : 0
                                                text: summary
                                                padding: Kirigami.Units.smallSpacing
                                                Component.onCompleted: console.log("Summary: " + summary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Controls.Control {
                id: monthGrid
                anchors.fill: parent
                padding: 0
                topPadding: 0
                leftPadding: 0
                rightPadding: 0
                bottomPadding: 0
                GridLayout {
                    anchors.fill: parent
                    columns: 7
                    columnSpacing: monthPage.isLarge ? 1 : 0
                    rowSpacing: monthPage.isLarge ? 1 : 0
                    Kirigami.Theme.inherit: false

                    Repeater {
                        model: CalendarManager.monthModel.weekDays
                        Controls.Control {
                            implicitWidth: monthGrid.width / 7
                            Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            padding: Kirigami.Units.smallSpacing
                            contentItem: Kirigami.Heading {
                                text: modelData
                                level: 2
                                horizontalAlignment: monthPage.isLarge ? Text.AlignRight : Text.AlignHCenter
                            }
                            background: Rectangle {
                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                color: Kirigami.Theme.backgroundColor
                            }
                        }
                    }

                    Repeater {
                        model: CalendarManager.monthModel
                        delegate: monthPage.isLarge ? desktopMonthDelegate : mobileMonthDelegate
                    }
                }
            }
        }
    }

    Component {
        id: weekPageComponent

        Kirigami.ScrollablePage {
            //required property var weekModel
            actions {
                left: Kirigami.Action {
                    text: i18n("Previous")
                    onTriggered: monthModel.previous()
                }
                right: Kirigami.Action {
                    text: i18n("Next")
                    onTriggered: weekModel.next()
                }
            }
            padding: 0
            background: Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.Header
                color: Kirigami.Theme.alternateBackgroundColor

                Instantiator {
                    model: weekModel
                    delegate: Controls.Label {
                        text: summary
                    }
                    onObjectAdded: console.log("Index: " + index, "Object: " + object)
                }
            }

            /*GridLayout {
                id: weekGrid
                width: parent.width
                columns: 7
                columnSpacing: 1
                rowSpacing: 1
                Kirigami.Theme.inherit: false

                Repeater {
                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    Controls.Control {
                        implicitWidth: weekGrid.width / 7
                        Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        padding: Kirigami.Units.smallSpacing
                        contentItem: Kirigami.Heading {
                            text: modelData
                            level: 2
                            horizontalAlignment: Text.AlignRight
                        }
                        background: Rectangle {
                            Kirigami.Theme.colorSet: Kirigami.Theme.View
                            color: Kirigami.Theme.backgroundColor
                        }
                    }
                }

                Repeater {
                    model: 7 * 24
                    Rectangle {
                        implicitWidth: weekGrid.width / 7
                        implicitHeight: Kirigami.Units.gridUnit * 3
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: Kirigami.Theme.backgroundColor
                    }
                }
            }*/

            TableView {
                id: tableView
                anchors.fill: parent
                model: weekModel
                rowHeightProvider: function() { return Kirigami.Units.gridUnit * 8 }
                onWidthChanged: forceLayout()
                columnWidthProvider: function() { return tableView.width > 0 ? tableView.width / 7 - 1 : 100; }
                rowSpacing: 1
                columnSpacing: 1
                delegate: Controls.Control {
                    background: Rectangle {
                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                        color: "blue"
                    }
                    contentItem: ColumnLayout {
                        Controls.Label {
                            text: "child count " + display
                        }
                        Repeater {
                            // TODO create a delegate for mobile just showing points for events
                            model: DelegateModel {
                                model: weekModel
                                rootIndex: tableIndex
                                delegate: Controls.Label { text: summary + index; }
                            }
                        }
                    }
                }
            }
        }
    }
}
