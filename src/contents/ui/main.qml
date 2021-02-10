import QtQuick 2.1
import org.kde.kirigami 2.4 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0

Kirigami.ApplicationWindow {
    id: root

    title: i18n("Calendar")

    pageStack.initialPage: mainPageComponent

    Component {
        id: mainPageComponent

        Kirigami.Page {
            title: new Date(monthModel.year, monthModel.month, 1).toLocaleDateString(Qt.locale(), "MMMM yyyy")
            actions {
                left: Kirigami.Action {
                    text: i18n("Previous")
                    onTriggered: monthModel.previous()
                }
                right: Kirigami.Action {
                    text: i18n("Next")
                    onTriggered: monthModel.next()
                }
            }
            padding: 0
            background: Rectangle {
                Kirigami.Theme.colorSet: Kirigami.Theme.Header
                color: Kirigami.Theme.alternateBackgroundColor
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
                    columnSpacing: 1
                    rowSpacing: 1
                    Kirigami.Theme.inherit: false
                    
                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        Controls.Control {
                            implicitWidth: monthGrid.width / 7
                            Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            padding: Kirigami.Units.smallSpacing
                            contentItem: Kirigami.Heading {
                                text: modelData
                                horizontalAlignment: Text.AlignRight
                            }
                            background: Rectangle {
                                Kirigami.Theme.colorSet: Kirigami.Theme.View
                                color: Kirigami.Theme.backgroundColor
                            }
                        }
                    }
                    
                    Repeater {
                        model: monthModel
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
                            padding: Kirigami.Units.smallSpacing
                            contentItem: Controls.ScrollView {
                                ColumnLayout {
                                    width: button.width - Kirigami.Units.largeSpacing
                                    Kirigami.Heading {
                                        level: 3
                                        text: model.dayNumber
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Repeater {
                                        model: EventsModel {
                                            events: eventList
                                        }
                                        Controls.Label {
                                            text: summary
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
