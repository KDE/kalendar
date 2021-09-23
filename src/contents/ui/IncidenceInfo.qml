import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtLocation 5.15
import "labelutils.js" as LabelUtils

import org.kde.kalendar 1.0

Kirigami.OverlayDrawer {
    id: incidenceInfo

    signal addSubTodo(var parentWrapper)
    signal editIncidence(var incidencePtr, var collectionId)
    signal deleteIncidence(var incidencePtr, date deleteDate)

    /**
     * We use both incidenceData and incidenceWrapper to get info about the occurrence.
     * IncidenceData contains information about the specific occurrence (i.e. date of occurrence)
     * as well as some general data about the incidence such as summary and description.
     *
     * The incidenceWrapper contains more indepth data about reminders, attendees, etc. that is
     * general to the incidence as a whole, not a specific occurrence.
     **/

    property var incidenceData
    property var incidenceWrapper
    property var collectionData

    onIncidenceDataChanged: {
        incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                                              incidenceInfo, "incidence");
        incidenceWrapper.incidencePtr = incidenceData.incidencePtr;
    }

    enabled: true
    interactive: enabled
    edge: Kirigami.Settings.isMobile ? Qt.BottomEdge :
        Qt.application.layoutDirection == Qt.RightToLeft ? Qt.LeftEdge : Qt.RightEdge

    Layout.bottomMargin: Kirigami.Units.largeSpacing
    height: applicationWindow().height * 0.6

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    contentItem: Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true

        active: incidenceInfo.drawerOpen
        sourceComponent: ColumnLayout {
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
                        text: i18n(incidenceInfo.incidenceWrapper.incidenceTypeStr)
                    }

                    Kirigami.ActionToolBar {
                        id: actionToolbar
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        alignment: Qt.AlignRight

                        // If accessing directly, updated incidenceWrapper data not grabbed (???)
                        property string incidenceType: incidenceInfo.incidenceWrapper.incidenceType

                        actions: [
                            Kirigami.Action {
                                icon.name: "list-add"
                                text: i18n("Add Sub-Task")
                                visible: actionToolbar.incidenceType === IncidenceWrapper.TypeTodo
                                onTriggered: {
                                    incidenceInfo.incidenceWrapper.collectionId = collectionData.id;
                                    addSubTodo(incidenceInfo.incidenceWrapper);
                                }
                            },
                            Kirigami.Action {
                                property bool todoCompleted: incidenceInfo.incidenceWrapper.todoCompleted
                                icon.name: todoCompleted ? "edit-undo" : "checkmark"
                                text: todoCompleted ? i18n("Mark Incomplete") : i18n("Mark Complete")
                                visible: actionToolbar.incidenceType === IncidenceWrapper.TypeTodo
                                onTriggered: {
                                    incidenceInfo.incidenceWrapper.todoCompleted = !incidenceInfo.incidenceWrapper.todoCompleted;
                                    CalendarManager.editIncidence(incidenceInfo.incidenceWrapper);
                                }
                            },
                            Kirigami.Action {
                                icon.name: "edit-entry"
                                text: i18n("Edit")
                                enabled: !incidenceInfo.collectionData.readOnly
                                onTriggered: editIncidence(incidenceInfo.incidenceData.incidencePtr, incidenceInfo.incidenceData.collectionId)
                            },
                            Kirigami.Action {
                                icon.name: "edit-delete"
                                text: i18n("Delete")
                                enabled: !incidenceInfo.collectionData.readOnly
                                onTriggered: deleteIncidence(incidenceInfo.incidenceData.incidencePtr, incidenceInfo.incidenceData.startTime)
                            }
                        ]
                    }
                }
            }
            QQC2.ScrollView {
                id: contentsView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: this.availableWidth
                clip: true

                property real yScrollPos: QQC2.ScrollBar.vertical.position
                onYScrollPosChanged: {
                    console.log(yScrollPos, incidenceInfo.enabled && yScrollPos <= 0)
                    if(Kirigami.Settings.isMobile) incidenceInfo.interactive = incidenceInfo.enabled && yScrollPos <= 0
                }

                GridLayout {
                    id: infoBody

                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    columns: 2

                    RowLayout {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true

                        Kirigami.Heading {
                            Layout.fillWidth: true

                            text: "<b>" + incidenceInfo.incidenceData.text + "</b>"
                            wrapMode: Text.Wrap
                        }
                        Kirigami.Icon {
                            source: incidenceInfo.incidenceWrapper.incidenceIconName
                        }
                        Kirigami.Icon {
                            source: "appointment-recurring"
                            visible: incidenceInfo.incidenceWrapper.recurrenceData.type
                        }
                        Kirigami.Icon {
                            source: "appointment-reminder"
                            visible: incidenceInfo.incidenceWrapper.remindersModel.rowCount() > 0
                        }
                    }
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        height: Kirigami.Units.gridUnit / 2

                        color: incidenceInfo.incidenceData.color
                    }

                    ColumnLayout {
                        id: todoCompletionLayout

                        Layout.columnSpan: 2
                        visible: incidenceInfo.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo

                        Kirigami.Heading {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true
                            level: 2
                            text: i18nc("%1 is a percentage number", "<b>%1\%</b> Complete", String(incidenceInfo.incidenceWrapper.todoPercentComplete))
                        }
                        QQC2.Slider {
                            Layout.fillWidth: true
                            orientation: Qt.Horizontal
                            from: 0
                            to: 100.0
                            stepSize: 10.0
                            value: incidenceInfo.incidenceWrapper.todoPercentComplete
                            onValueChanged: {
                                if (incidenceInfo.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo && activeFocus) {
                                    incidenceInfo.incidenceWrapper.todoPercentComplete = value;
                                    CalendarManager.editIncidence(incidenceInfo.incidenceWrapper);
                                }
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        visible: todoCompletionLayout.visible
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Calendar:</b>")
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: incidenceInfo.collectionData.displayName
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Tags:</b>")
                        visible: incidenceInfo.incidenceWrapper.categories.length > 0
                    }
                    Flow {
                        Layout.fillWidth: true
                        visible: incidenceInfo.incidenceWrapper.categories.length > 0
                        spacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: incidenceInfo.incidenceWrapper.categories
                            Tag {
                                text: modelData
                                icon.name: "edit-delete-remove"
                                actionText: i18n("Remove %1 tag", modelData)
                                showAction: false
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Date:</b>")
                        visible: !isNaN(incidenceInfo.incidenceData.startTime.getTime()) || !isNaN(incidenceInfo.incidenceData.endTime.getTime())
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: if(incidenceInfo.incidenceData.startTime.toDateString() === incidenceInfo.incidenceData.endTime.toDateString()) {
                            return incidenceInfo.incidenceData.startTime.toLocaleDateString(Qt.locale());
                        } else if (!isNaN(incidenceInfo.incidenceData.startTime.getTime()) && !isNaN(incidenceInfo.incidenceData.endTime.getTime())) {
                            incidenceInfo.incidenceData.startTime.toLocaleDateString(Qt.locale()) + " - " + incidenceInfo.incidenceData.endTime.toLocaleDateString(Qt.locale())
                        } else if (isNaN(incidenceInfo.incidenceData.startTime.getTime()) && !isNaN(incidenceInfo.incidenceData.endTime.getTime())) {
                            return incidenceInfo.incidenceData.endTime.toLocaleDateString(Qt.locale())
                        } else if (isNaN(incidenceInfo.incidenceData.endTime.getTime()) && !isNaN(incidenceInfo.incidenceData.startTime.getTime())) {
                            return incidenceInfo.incidenceData.startTime.toLocaleDateString(Qt.locale())
                        }
                        wrapMode: Text.Wrap
                        visible: !isNaN(incidenceInfo.incidenceData.startTime.getTime()) || !isNaN(incidenceInfo.incidenceData.endTime.getTime())
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Time:</b>")
                        visible: !incidenceInfo.incidenceData.allDay &&
                            incidenceInfo.incidenceData.startTime.toDateString() == incidenceInfo.incidenceData.endTime.toDateString() &&
                            (!isNaN(incidenceInfo.incidenceData.startTime.getTime()) || !isNaN(incidenceInfo.incidenceData.endTime.getTime()))
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: {
                            if(incidenceInfo.incidenceData.startTime.toTimeString() != incidenceInfo.incidenceData.endTime.toTimeString()) {
                                incidenceInfo.incidenceData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat) + " - " + incidenceInfo.incidenceData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            } else if (incidenceInfo.incidenceData.startTime.toTimeString() == incidenceInfo.incidenceData.endTime.toTimeString()) {
                                incidenceInfo.incidenceData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            }
                        }
                        wrapMode: Text.Wrap
                        visible: !incidenceInfo.incidenceData.allDay &&
                            incidenceInfo.incidenceData.startTime.toDateString() == incidenceInfo.incidenceData.endTime.toDateString() &&
                            (!isNaN(incidenceInfo.incidenceData.startTime.getTime()) || !isNaN(incidenceInfo.incidenceData.endTime.getTime()))
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Duration:</b>")
                        visible: incidenceInfo.incidenceData.durationString &&
                            (!isNaN(incidenceInfo.incidenceData.startTime.getTime()) || !isNaN(incidenceInfo.incidenceData.endTime.getTime()))
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: incidenceInfo.incidenceData.durationString
                        visible: incidenceInfo.incidenceData.durationString &&
                            (!isNaN(incidenceInfo.incidenceData.startTime.getTime()) || !isNaN(incidenceInfo.incidenceData.endTime.getTime()))
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Priority level:</b>")
                        visible: incidenceInfo.incidenceWrapper.priority
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        text: LabelUtils.priorityString(incidenceInfo.incidenceWrapper.priority)
                        visible: incidenceInfo.incidenceWrapper.priority
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Completed:</b>")
                        visible: incidenceInfo.incidenceWrapper.todoCompleted
                    }
                    QQC2.Label {
                        id: todoCompletedTimeLabel
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        property date completionDate: incidenceInfo.incidenceWrapper.todoCompletionDt

                        text: completionDate.toLocaleString(Qt.locale())
                        visible: incidenceInfo.incidenceWrapper.todoCompleted
                        // HACK: For some reason, calling the todoCompletionDt always returns an invalid date once it is changed (???)
                        onVisibleChanged: if(visible && isNaN(completionDate.getTime())) { text = new Date().toLocaleString(Qt.locale()) }
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Recurrence:</b>")
                        visible: incidenceInfo.incidenceWrapper.recurrenceData.type
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: incidenceInfo.incidenceWrapper.recurrenceData.type

                        QQC2.Label {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true

                            text: LabelUtils.recurrenceToString(incidenceInfo.incidenceWrapper.recurrenceData)
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
                                    model: incidenceInfo.incidenceWrapper.recurrenceExceptionsModel
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
                            visible: incidenceInfo.incidenceWrapper.recurrenceData.duration > -1

                            text: LabelUtils.recurrenceEndToString(incidenceInfo.incidenceWrapper.recurrenceData)
                            wrapMode: Text.Wrap
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Location:</b>")
                        visible: incidenceInfo.incidenceWrapper.location
                    }
                    QQC2.Label {
                        id: locationLabel
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        property bool isLink: false

                        textFormat: Text.MarkdownText
                        text: incidenceInfo.incidenceWrapper.location.replace(LabelUtils.urlRegexp, (match) => `[${match}](${match})`)
                        onTextChanged: isLink = LabelUtils.urlRegexp.test(incidenceInfo.incidenceWrapper.location);
                        onLinkActivated: Qt.openUrlExternally(link)
                        wrapMode: Text.Wrap
                        visible: incidenceInfo.incidenceWrapper.location

                        MouseArea {
                            TextEdit {  // HACK: TextEdit has copy to clipboard capabilities
                                id: textEdit
                                visible: false
                            }

                            anchors.fill: parent
                            enabled: !locationLabel.isLink
                            propagateComposedEvents: true
                            onClicked: {
                                textEdit.text = incidenceInfo.incidenceWrapper.location;
                                textEdit.selectAll();
                                textEdit.copy();
                                showPassiveNotification(i18n("Location copied to clipboard"));
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        visible: Config.enableMaps && (incidenceInfo.incidenceWrapper.location || incidenceInfo.incidenceWrapper.hasGeo)

                        QQC2.BusyIndicator {
                            id: mapLoadingIndicator
                            Layout.fillWidth: true

                            property bool showCondition: !locationLabel.isLink &&
                                (mapLoader.status === Loader.Loading || mapLoader.item.queryStatus === GeocodeModel.Loading)

                            running: showCondition
                            visible: showCondition
                        }

                        Kirigami.InlineMessage {
                            id: noLocationsMessage

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            visible: mapLoader.status === Loader.Ready &&
                                mapLoader.item.queryStatus === GeocodeModel.Ready &&
                                !mapLoader.item.queryHasResults
                            type: Kirigami.MessageType.Warning
                            text: i18n("Unable to find location.")
                        }

                        Loader {
                            id: mapLoader

                            Layout.fillWidth: true
                            height: Kirigami.Settings.isMobile ? Kirigami.Units.gridUnit * 12 : Kirigami.Units.gridUnit * 16
                            asynchronous: true
                            active: Config.enableMaps &&
                                incidenceInfo.visible &&
                                (incidenceInfo.incidenceWrapper.location || incidenceInfo.incidenceWrapper.hasGeo) &&
                                !locationLabel.isLink
                            visible: active && (item.queryHasResults || item.hasCoordinate)

                            sourceComponent: LocationMap {
                                id: map
                                query: incidenceInfo.incidenceWrapper.location
                                selectedLatitude: incidenceInfo.incidenceWrapper.hasGeo ? incidenceInfo.incidenceWrapper.geoLatitude : NaN
                                selectedLongitude: incidenceInfo.incidenceWrapper.hasGeo ? incidenceInfo.incidenceWrapper.geoLongitude : NaN

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (incidenceInfo.incidenceWrapper.hasGeo)
                                            Qt.openUrlExternally("https://www.openstreetmap.org/#map=17/" + incidenceInfo.incidenceWrapper.geoLatitude + "/" + incidenceInfo.incidenceWrapper.geoLongitude)
                                        else
                                            Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + incidenceInfo.incidenceWrapper.location)
                                    }
                                }
                            }
                        }
                    }

                    QQC2.Label {
                        id: descriptionLabel
                        Layout.alignment: Qt.AlignTop

                        text: i18n("<b>Description:</b>")
                        visible: incidenceInfo.incidenceWrapper.description
                    }
                    QQC2.Label {
                        id: descriptionText
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        textFormat: Text.MarkdownText
                        text: incidenceInfo.incidenceWrapper.description.replace(LabelUtils.urlRegexp, (match) => `[${match}](${match})`)
                        onLinkActivated: Qt.openUrlExternally(link)
                        wrapMode: Text.Wrap
                        visible: incidenceInfo.incidenceWrapper.description
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18np("<b>Attachment:</b>", "<b>Attachments:</b>", incidenceInfo.incidenceWrapper.attachmentsModel.rowCount())
                        visible: incidenceInfo.incidenceWrapper.attachmentsModel.rowCount() > 0
                    }

                    ColumnLayout {
                        id: attachmentsColumn

                        Layout.fillWidth: true
                        visible: incidenceInfo.incidenceWrapper.attachmentsModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: incidenceInfo.incidenceWrapper.attachmentsModel

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
                        visible: incidenceInfo.incidenceWrapper.remindersModel.rowCount() > 0
                    }

                    ColumnLayout {
                        id: remindersColumn

                        Layout.fillWidth: true
                        visible: incidenceInfo.incidenceWrapper.remindersModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: incidenceInfo.incidenceWrapper.remindersModel

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
                        visible: incidenceInfo.incidenceWrapper.organizer.fullName
                    }
                    QQC2.Label {
                        Layout.fillWidth: true

                        property var organizer: incidenceInfo.incidenceWrapper.organizer

                        textFormat: Text.MarkdownText
                        text: organizer.name ?
                            `[${organizer.name}](mailto:${organizer.email})` :
                            `[${organizer.email}](mailto:${organizer.email})`
                        onLinkActivated: Qt.openUrlExternally(link)
                        wrapMode: Text.Wrap
                        visible: incidenceInfo.incidenceWrapper.organizer.fullName
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Guests:</b>")
                        visible: incidenceInfo.incidenceWrapper.attendeesModel.rowCount() > 0
                    }
                    ColumnLayout {
                        id: attendeesColumn

                        Layout.fillWidth: true
                        visible: incidenceInfo.incidenceWrapper.attendeesModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: incidenceInfo.incidenceWrapper.attendeesModel

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
