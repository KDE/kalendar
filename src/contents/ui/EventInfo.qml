import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15

Kirigami.OverlayDrawer {
    id: eventInfo

    signal editEvent(var eventPtr, var collectionId)
    signal deleteEvent(var eventPtr, date deleteDate)

    property var eventData
    property var collectionData

    enabled: true
    interactive: enabled
    edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.LeftEdge : Qt.RightEdge

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    Kirigami.Theme.colorSet: Kirigami.Theme.View

    contentItem: Loader {
        active: eventInfo.drawerOpen
        sourceComponent: QQC2.ScrollView {
            id: contentsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Kirigami.Units.largeSpacing *5
            contentWidth: this.availableWidth

            ColumnLayout {
                id: detailsColumn
                Layout.fillWidth: true
                Layout.maximumWidth: contentsView.availableWidth
                Layout.minimumWidth: contentsView.availableWidth

                Kirigami.AbstractApplicationHeader {
                    Layout.fillWidth: true
                    topPadding: Kirigami.Units.smallSpacing / 2;
                    bottomPadding: Kirigami.Units.smallSpacing / 2;
                    rightPadding: Kirigami.Units.smallSpacing
                    leftPadding: Kirigami.Units.smallSpacing


                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            text: i18n("Event")
                        }

                        QQC2.ToolButton {
                            icon.name: "edit-entry"
                            text:i18n("Edit")
                            enabled: !eventInfo.collectionData["readOnly"]
                            onClicked: editEvent(eventInfo.eventData.eventPtr, eventInfo.eventData.collectionId)
                        }
                        QQC2.ToolButton {
                            icon.name: "edit-delete"
                            text:i18n("Delete")
                            enabled: !eventInfo.collectionData["readOnly"]
                            onClicked: deleteEvent(eventInfo.eventData.eventPtr, eventInfo.eventData.startTime)
                        }
                    }
                }

                GridLayout {
                    Layout.margins: Kirigami.Units.largeSpacing
                    Layout.fillWidth: true
                    Layout.maximumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)
                    Layout.minimumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)

                    columns:2

                    Kirigami.Heading {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.maximumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)
                        Layout.minimumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)

                        text: "<b>" + eventInfo.eventData.text + "</b>"
                        wrapMode: Text.Wrap
                    }
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        height: Kirigami.Units.gridUnit / 2

                        color: eventInfo.eventData.color
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Calendar:</b>")
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: eventInfo.collectionData["displayName"]
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Date:</b>")
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: eventInfo.eventData.startTime.toDateString() == eventInfo.eventData.endTime.toDateString() ?
                        eventInfo.eventData.startTime.toLocaleDateString(Qt.locale()) :
                        eventInfo.eventData.startTime.toLocaleDateString(Qt.locale()) + " - " + eventInfo.eventData.endTime.toLocaleDateString(Qt.locale())
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Time:</b>")
                        visible: !eventInfo.eventData.allDay &&
                        eventInfo.eventData.startTime.toDateString() == eventInfo.eventData.endTime.toDateString()
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: {
                            if(eventInfo.eventData.startTime.toTimeString() != eventInfo.eventData.endTime.toTimeString()) {
                                eventInfo.eventData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat) + " - " + eventInfo.eventData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            } else if (eventInfo.eventData.startTime.toTimeString() == eventInfo.eventData.endTime.toTimeString()) {
                                eventInfo.eventData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            }
                        }
                        wrapMode: Text.Wrap
                        visible: !eventInfo.eventData.allDay &&
                        eventInfo.eventData.startTime.toDateString() == eventInfo.eventData.endTime.toDateString()
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Duration: </b>")
                        visible: eventInfo.eventData.durationString
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: eventInfo.eventData.durationString
                        visible: eventInfo.eventData.durationString
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        id: descriptionLabel
                        Layout.alignment: Qt.AlignTop

                        text: i18n("<b>Description:</b>")
                        visible: eventInfo.eventWrapper.description
                    }
                    QQC2.Label {
                        id: descriptionText
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        textFormat: Text.MarkdownText
                        text: {
                            var regexp = /^(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?$/ig
                            eventInfo.eventWrapper.description.replace(regexp, (match) => {
                                return `[${match}](${match})`;
                            })
                        }
                        onLinkActivated: Qt.openUrlExternally(link)
                        wrapMode: Text.Wrap
                        visible: eventInfo.eventWrapper.description
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18np("<b>Attachment:</b>", "<b>Attachments:</b>", eventInfo.eventWrapper.attachmentsModel.rowCount())
                        visible: eventInfo.eventWrapper.attachmentsModel.rowCount() > 0
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Repeater {
                            Layout.fillWidth: true
                            visible: eventInfo.eventWrapper.attachmentsModel.rowCount() > 0

                            model: eventInfo.eventWrapper.attachmentsModel

                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                // This didn't work in Markdown format
                                text: `<a href="${uri}">${label}</a>`
                                onLinkActivated: Qt.openUrlExternally(link)
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Reminders:</b>")
                        visible: eventInfo.eventWrapper.remindersModel.rowCount() > 0
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Repeater {
                            Layout.fillWidth: true
                            visible: eventInfo.eventWrapper.remindersModel.rowCount() > 0

                            model: eventInfo.eventWrapper.remindersModel

                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                text: LabelUtils.secondsToReminderLabel(startOffset) + i18n(" start of event")
                                wrapMode: Text.Wrap
                            }
                        }
>>>>>>> c6c751d (Event info drawer can now show attachments)
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: eventInfo.eventData.description
                        wrapMode: Text.Wrap
                        visible: eventInfo.eventData.description
                    }
                }
            }
        }
    }
}
