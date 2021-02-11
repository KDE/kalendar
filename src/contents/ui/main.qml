import QtQuick 2.1
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15 
import org.kde.kalendar 1.0
import QtQml.Models 2.15

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
                                                model: monthModel
                                                rootIndex: modelIndex(index)
                                                delegate: Kirigami.ShadowedRectangle {
                                                    Layout.topMargin: prefix * (implicitHeight + Kirigami.Units.smallSpacing)
                                                    Layout.fillWidth: true
                                                    color: "red" //Qt.rgba(7, 250, 250, 90)
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
                                                        opacity: isBegin ? 1 : 0
                                                        text: summary
                                                        padding: Kirigami.Units.smallSpacing
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
        }
    }
}
