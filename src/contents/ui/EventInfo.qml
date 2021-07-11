import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import "labelutils.js" as LabelUtils

Kirigami.OverlayDrawer {
    id: eventInfo

    signal editEvent(var eventPtr, var collectionId)
    signal deleteEvent(var eventPtr, date deleteDate)

    /**
     * We use both eventData and eventWrapper to get info about the occurrence.
     * EventData contains information about the specific occurrence (i.e. date of occurrence)
     * as well as some general data about the event such as summary and description.
     *
     * The eventWrapper contains more indepth data about reminders, attendees, etc. that is
     * general to the event as a whole, not a specific occurrence.
     **/

    property var eventData
    property var eventWrapper
    property var collectionData

    onEventDataChanged: {
        eventWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; EventWrapper {id: event}',
                                          eventInfo,
                                          "event");
        eventWrapper.eventPtr = eventData.eventPtr
    }

    enabled: true
    interactive: enabled
    edge: Qt.application.layoutDirection == Qt.RightToLeft ? Qt.LeftEdge : Qt.RightEdge

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    Kirigami.Theme.colorSet: Kirigami.Theme.View

    contentItem: Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true

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
                            enabled: !eventInfo.collectionData.readOnly
                            onClicked: editEvent(eventInfo.eventData.eventPtr, eventInfo.eventData.collectionId)
                        }
                        QQC2.ToolButton {
                            icon.name: "edit-delete"
                            text:i18n("Delete")
                            enabled: !eventInfo.collectionData.readOnly
                            onClicked: deleteEvent(eventInfo.eventData.eventPtr, eventInfo.eventData.startTime)
                        }
                    }
                }

                GridLayout {
                    id: infoBody

                    Layout.margins: Kirigami.Units.largeSpacing
                    Layout.fillWidth: true
                    Layout.maximumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)
                    Layout.minimumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)

                    columns:2

                    RowLayout {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.maximumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)
                        Layout.minimumWidth: contentsView.availableWidth - (Kirigami.Units.largeSpacing * 2)

                        Kirigami.Heading {
                            Layout.fillWidth: true

                            text: "<b>" + eventInfo.eventData.text + "</b>"
                            wrapMode: Text.Wrap
                        }
                        Kirigami.Icon {
                            source: "tag-events"
                            // TODO: This will need dynamic changing with implementation of to-dos/journals
                        }
                        Kirigami.Icon {
                            source: "appointment-recurring"
                            visible: eventInfo.eventWrapper.recurrenceData.type
                        }
                        Kirigami.Icon {
                            source: "appointment-reminder"
                            visible: eventInfo.eventWrapper.remindersModel.rowCount() > 0
                        }
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

                        text: eventInfo.collectionData.displayName
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
                        text: i18n("<b>Duration:</b>")
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
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Recurrence:</b>")
                        visible: eventInfo.eventWrapper.recurrenceData.type
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: eventInfo.eventWrapper.recurrenceData.type

                        QQC2.Label {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true

                            text: LabelUtils.recurrenceToString(eventInfo.eventWrapper.recurrenceData)
                            wrapMode: Text.Wrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: exceptionsRepeater.count

                            QQC2.Label {
                                Layout.alignment: Qt.AlignTop
                                visible: exceptionsRepeater.count

                                text: i18n("Except on:")

                            }
                            ColumnLayout {
                                Layout.fillWidth: true

                                Repeater {
                                    id: exceptionsRepeater
                                    model: eventInfo.eventWrapper.recurrenceExceptionsModel
                                    delegate: QQC2.Label {
                                        Layout.fillWidth: true
                                        text: date.toLocaleDateString(Qt.locale())
                                    }
                                }
                            }
                        }

                        QQC2.Label {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true
                            visible: eventInfo.eventWrapper.recurrenceData.duration > -1

                            text: LabelUtils.recurrenceEndToString(eventInfo.eventWrapper.recurrenceData)
                            wrapMode: Text.Wrap
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Location:</b>")
                        visible: eventInfo.eventWrapper.location
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        textFormat: Text.MarkdownText
                        text: eventInfo.eventWrapper.location.replace(LabelUtils.urlRegexp, (match) => `[${match}](${match})`)
                        onLinkActivated: Qt.openUrlExternally(link)
                        wrapMode: Text.Wrap
                        visible: eventInfo.eventWrapper.location
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
                        text: eventInfo.eventWrapper.description.replace(LabelUtils.urlRegexp, (match) => `[${match}](${match})`)
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
                        id: attachmentsColumn

                        Layout.fillWidth: true
                        visible: eventInfo.eventWrapper.attachmentsModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: eventInfo.eventWrapper.attachmentsModel

                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                // This didn't work in Markdown format
                                text: `<a href="${uri}">${attachmentLabel}</a>`
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
                        id: remindersColumn

                        Layout.fillWidth: true
                        visible: eventInfo.eventWrapper.remindersModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: eventInfo.eventWrapper.remindersModel

                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                text: LabelUtils.secondsToReminderLabel(startOffset)
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Organizer:</b>")
                        visible: eventInfo.eventWrapper.organizer.fullName
                    }
                    QQC2.Label {
                        Layout.fillWidth: true

                        property var organizer: eventInfo.eventWrapper.organizer

                        textFormat: Text.MarkdownText
                        text: organizer.name ?
                              `[${organizer.name}](mailto:${organizer.email})` :
                              `[${organizer.email}](mailto:${organizer.email})`
                        onLinkActivated: Qt.openUrlExternally(link)
                        wrapMode: Text.Wrap
                        visible: eventInfo.eventWrapper.organizer.fullName
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Guests:</b>")
                        visible: eventInfo.eventWrapper.attendeesModel.rowCount() > 0
                    }
                    ColumnLayout {
                        id: attendeesColumn

                        Layout.fillWidth: true
                        visible: eventInfo.eventWrapper.attendeesModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: eventInfo.eventWrapper.attendeesModel

                            delegate: QQC2.Label {
                                Layout.fillWidth: true
                                textFormat: Text.MarkdownText
                                text: name ? `[${name}](mailto:${email})` : `[${email}](mailto:${email})`
                                onLinkActivated: Qt.openUrlExternally(link)
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
