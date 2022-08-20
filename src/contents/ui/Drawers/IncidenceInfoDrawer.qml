// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.14 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtLocation 5.15
import "labelutils.js" as LabelUtils

import org.kde.kalendar 1.0

Kirigami.OverlayDrawer {
    id: incidenceInfoDrawer

    signal addSubTodo(var parentWrapper)
    signal editIncidence(var incidencePtr)
    signal deleteIncidence(var incidencePtr, date deleteDate)
    signal tagClicked(string tagName)

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
    property var activeTags : []

    readonly property int relatedIncidenceDelegateHeight: Kirigami.Units.gridUnit * 3

    component HoverLabel: QQC2.Label {
        Layout.fillWidth: true
        textFormat: Text.MarkdownText
        text: name ? `[${name}](mailto:${email})` : `[${email}](mailto:${email})`
        onLinkActivated: Qt.openUrlExternally(link)
        wrapMode: Text.Wrap
        onHoveredLinkChanged: if (hoveredLink.length > 0) {
            applicationWindow().hoverLinkIndicator.text = hoveredLink;
        } else {
            applicationWindow().hoverLinkIndicator.text = "";
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.NoButton // Not actually accepting clicks, just changing the cursor
        }
    }

    onIncidenceDataChanged: {
        incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}',
                                              incidenceInfoDrawer, "incidence");
        incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidenceData.incidencePtr);
        collectionData = CalendarManager.getCollectionDetails(incidenceWrapper.collectionId);
    }

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
        Layout.fillWidth: true
        Layout.fillHeight: true

        active: incidenceInfoDrawer.drawerOpen
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
                        text: i18n(incidenceInfoDrawer.incidenceWrapper.incidenceTypeStr)
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
                                visible: incidenceInfoDrawer.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                                onTriggered: {
                                    addSubTodo(incidenceInfoDrawer.incidenceWrapper);
                                }
                            },
                            Kirigami.Action {
                                property bool todoCompleted: incidenceInfoDrawer.incidenceWrapper.todoCompleted
                                icon.name: todoCompleted ? "edit-undo" : "checkmark"
                                text: todoCompleted ? i18n("Mark Incomplete") : i18n("Mark Complete")
                                visible: incidenceInfoDrawer.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                                onTriggered: {
                                    incidenceInfoDrawer.incidenceWrapper.todoCompleted = !incidenceInfoDrawer.incidenceWrapper.todoCompleted;
                                    CalendarManager.editIncidence(incidenceInfoDrawer.incidenceWrapper);
                                }
                            },
                            Kirigami.Action {
                                icon.name: "edit-entry"
                                text: i18n("Edit")
                                enabled: incidenceInfoDrawer.collectionData && !incidenceInfoDrawer.collectionData.readOnly
                                onTriggered: editIncidence(incidenceInfoDrawer.incidenceData.incidencePtr)
                            },
                            Kirigami.Action {
                                icon.name: "edit-delete"
                                text: i18n("Delete")
                                enabled: incidenceInfoDrawer.collectionData && !incidenceInfoDrawer.collectionData.readOnly
                                onTriggered: deleteIncidence(incidenceInfoDrawer.incidenceData.incidencePtr, incidenceInfoDrawer.incidenceData.startTime)
                            }
                        ]
                    }
                }
            }
            QQC2.ScrollView {
                id: contentsView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
		contentHeight: infoBody.implicitHeight + (infoBody.padding * 2)
                clip: true

                property real yScrollPos: QQC2.ScrollBar.vertical.position
                onYScrollPosChanged: if(Kirigami.Settings.isMobile) incidenceInfoDrawer.interactive = incidenceInfoDrawer.enabled && yScrollPos <= 0

                GridLayout {
                    id: infoBody

		    property int padding: Kirigami.Units.largeSpacing
		    
                    anchors.top: parent.top
		    anchors.left: parent.left
		    anchors.right: parent.right
                    anchors.margins: padding
                    columns: 2

                    RowLayout {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true

                        Kirigami.Heading {
                            Layout.fillWidth: true

                            text: incidenceInfoDrawer.incidenceWrapper.summary
                            textFormat: Text.PlainText
                            font.weight: Font.Bold
                            wrapMode: Text.Wrap
                        }
                        Kirigami.Icon {
                            source: incidenceInfoDrawer.incidenceWrapper.incidenceIconName
                        }
                        Kirigami.Icon {
                            source: "appointment-recurring"
                            visible: incidenceInfoDrawer.incidenceWrapper.recurrenceData.type
                        }
                        Kirigami.Icon {
                            source: "appointment-reminder"
                            visible: incidenceInfoDrawer.incidenceWrapper.remindersModel.rowCount() > 0
                        }
                    }
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        height: Kirigami.Units.gridUnit / 2

                        color: incidenceInfoDrawer.collectionData.color
                    }

                    ColumnLayout {
                        id: todoCompletionLayout

                        Layout.columnSpan: 2
                        visible: incidenceInfoDrawer.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo

                        Kirigami.Heading {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true
                            level: 2
                            text: i18nc("%1 is a percentage number", "<b>%1\%</b> Complete", String(incidenceInfoDrawer.incidenceWrapper.todoPercentComplete))
                        }
                        QQC2.Slider {
                            Layout.fillWidth: true

                            Kirigami.Theme.inherit: false
                            Kirigami.Theme.highlightColor: incidenceInfoDrawer.incidenceData.color

                            orientation: Qt.Horizontal
                            from: 0
                            to: 100.0
                            stepSize: 10.0
                            value: incidenceInfoDrawer.incidenceWrapper.todoPercentComplete
                            onValueChanged: {
                                if (incidenceInfoDrawer.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo && activeFocus) {
                                    incidenceInfoDrawer.incidenceWrapper.todoPercentComplete = value;
                                    CalendarManager.editIncidence(incidenceInfoDrawer.incidenceWrapper);
                                }
                            }
                        }
                    }

                    Kirigami.Separator {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        visible: todoCompletionLayout.visible
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Calendar:</b>")
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: incidenceInfoDrawer.collectionData ? incidenceInfoDrawer.collectionData.displayName : ""
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Tags:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.categories.length > 0
                    }
                    Flow {
                        id: tagFlow
                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.categories.length > 0
                        spacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: incidenceInfoDrawer.incidenceWrapper.categories
                            Tag {
                                text: modelData
                                icon.name: "edit-delete-remove"
                                actionText: i18n("Remove %1 tag", modelData)
                                showAction: false
                                implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                                activeFocusOnTab: true
                                backgroundColor: mainDrawer.activeTags.includes(modelData) ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                                onClicked: incidenceInfoDrawer.tagClicked(modelData)
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Date:</b>")
                        visible: !isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) || !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime())
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: if(incidenceInfoDrawer.incidenceData.startTime.toDateString() === incidenceInfoDrawer.incidenceData.endTime.toDateString()) {
                            return incidenceInfoDrawer.incidenceData.startTime.toLocaleDateString(Qt.locale());
                        } else if (!isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) && !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime())) {
                            incidenceInfoDrawer.incidenceData.startTime.toLocaleDateString(Qt.locale()) + "–" + incidenceInfoDrawer.incidenceData.endTime.toLocaleDateString(Qt.locale())
                        } else if (isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) && !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime())) {
                            return incidenceInfoDrawer.incidenceData.endTime.toLocaleDateString(Qt.locale())
                        } else if (isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime()) && !isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime())) {
                            return incidenceInfoDrawer.incidenceData.startTime.toLocaleDateString(Qt.locale())
                        }
                        wrapMode: Text.Wrap
                        visible: !isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) || !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime())
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Time:</b>")
                        visible: !incidenceInfoDrawer.incidenceData.allDay &&
                            incidenceInfoDrawer.incidenceData.startTime.toDateString() == incidenceInfoDrawer.incidenceData.endTime.toDateString() &&
                            (!isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) || !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime()))
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: {
                            if(incidenceInfoDrawer.incidenceData.startTime.toTimeString() != incidenceInfoDrawer.incidenceData.endTime.toTimeString()) {
                                incidenceInfoDrawer.incidenceData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat) + "–" + incidenceInfoDrawer.incidenceData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            } else if (incidenceInfoDrawer.incidenceData.startTime.toTimeString() == incidenceInfoDrawer.incidenceData.endTime.toTimeString()) {
                                incidenceInfoDrawer.incidenceData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            }
                        }
                        wrapMode: Text.Wrap
                        visible: !incidenceInfoDrawer.incidenceData.allDay &&
                            incidenceInfoDrawer.incidenceData.startTime.toDateString() == incidenceInfoDrawer.incidenceData.endTime.toDateString() &&
                            (!isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) || !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime()))
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Duration:</b>")
                        visible: incidenceInfoDrawer.incidenceData.durationString &&
                            (!isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) || !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime()))
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        text: incidenceInfoDrawer.incidenceData.durationString
                        visible: incidenceInfoDrawer.incidenceData.durationString &&
                            (!isNaN(incidenceInfoDrawer.incidenceData.startTime.getTime()) || !isNaN(incidenceInfoDrawer.incidenceData.endTime.getTime()))
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Priority level:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.priority
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        text: LabelUtils.priorityString(incidenceInfoDrawer.incidenceWrapper.priority)
                        visible: incidenceInfoDrawer.incidenceWrapper.priority
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Completed:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.todoCompleted
                    }
                    QQC2.Label {
                        id: todoCompletedTimeLabel
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        property date completionDate: incidenceInfoDrawer.incidenceWrapper.todoCompletionDt

                        text: completionDate.toLocaleString(Qt.locale())
                        visible: incidenceInfoDrawer.incidenceWrapper.todoCompleted
                        // HACK: For some reason, calling the todoCompletionDt always returns an invalid date once it is changed (???)
                        onVisibleChanged: if(visible && isNaN(completionDate.getTime())) { text = new Date().toLocaleString(Qt.locale()) }
                        wrapMode: Text.Wrap
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Recurrence:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.recurrenceData.type
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.recurrenceData.type

                        QQC2.Label {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true

                            text: LabelUtils.recurrenceToString(incidenceInfoDrawer.incidenceWrapper.recurrenceData)
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
                                    model: incidenceInfoDrawer.incidenceWrapper.recurrenceExceptionsModel
                                    delegate: QQC2.Label {
                                        Layout.fillWidth: true
                                        text: date.toLocaleDateString(Qt.locale())
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }

                        QQC2.Label {
                            Layout.alignment: Qt.AlignTop
                            Layout.fillWidth: true
                            visible: incidenceInfoDrawer.incidenceWrapper.recurrenceData.duration > -1

                            text: LabelUtils.recurrenceEndToString(incidenceInfoDrawer.incidenceWrapper.recurrenceData)
                            wrapMode: Text.Wrap
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Location:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.location
                    }
                    TextEdit {
                        id: locationLabel
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        property bool isLink: false

                        font: Kirigami.Theme.defaultFont
                        selectByMouse: !Kirigami.Settings.isMobile
                        readOnly: true
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                        color: Kirigami.Theme.textColor
                        text: incidenceInfoDrawer.incidenceWrapper.location.replace(LabelUtils.urlRegexp, (match) => `<a style="color: "${Kirigami.Theme.linkColor}"; text-decoration: none;" href="${match}">${match}</a>`)
                        onTextChanged: isLink = LabelUtils.urlRegexp.test(incidenceInfoDrawer.incidenceWrapper.location);
                        onLinkActivated: Qt.openUrlExternally(link)
                        visible: incidenceInfoDrawer.incidenceWrapper.location
                        onHoveredLinkChanged: if (hoveredLink.length > 0) {
                            applicationWindow().hoverLinkIndicator.text = hoveredLink;
                        } else {
                            applicationWindow().hoverLinkIndicator.text = "";
                        }
                        HoverHandler {
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                        }
                    }

                    ColumnLayout {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        visible: Config.enableMaps && (incidenceInfoDrawer.incidenceWrapper.location || incidenceInfoDrawer.incidenceWrapper.hasGeo)

                        QQC2.BusyIndicator {
                            id: mapLoadingIndicator
                            Layout.fillWidth: true

                            property bool showCondition: !locationLabel.isLink &&
                                (mapLoader.status === Loader.Loading || (mapLoader.item && mapLoader.item.queryStatus === GeocodeModel.Loading))

                            running: showCondition
                            visible: showCondition
                        }

                        Kirigami.InlineMessage {
                            id: noLocationsMessage

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            visible: mapLoader.item &&
                                mapLoader.status === Loader.Ready &&
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
                                incidenceInfoDrawer.visible &&
                                (incidenceInfoDrawer.incidenceWrapper.location || incidenceInfoDrawer.incidenceWrapper.hasGeo) &&
                                !locationLabel.isLink
                            visible: active && (item.queryHasResults || item.hasCoordinate)

                            sourceComponent: LocationMap {
                                id: map
                                query: incidenceInfoDrawer.incidenceWrapper.location
                                selectedLatitude: incidenceInfoDrawer.incidenceWrapper.hasGeo ? incidenceInfoDrawer.incidenceWrapper.geoLatitude : NaN
                                selectedLongitude: incidenceInfoDrawer.incidenceWrapper.hasGeo ? incidenceInfoDrawer.incidenceWrapper.geoLongitude : NaN

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (incidenceInfoDrawer.incidenceWrapper.hasGeo)
                                            Qt.openUrlExternally("https://www.openstreetmap.org/#map=17/" + incidenceInfoDrawer.incidenceWrapper.geoLatitude + "/" + incidenceInfoDrawer.incidenceWrapper.geoLongitude)
                                        else
                                            Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + incidenceInfoDrawer.incidenceWrapper.location)
                                    }
                                }
                            }
                        }
                    }

                    QQC2.Label {
                        id: descriptionLabel
                        Layout.alignment: Qt.AlignTop

                        text: i18n("<b>Description:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.description
                    }
                    HoverLabel {
                        id: descriptionText
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true

                        textFormat: Text.MarkdownText
                        text: incidenceInfoDrawer.incidenceWrapper.description.replace(LabelUtils.urlRegexp, (match) => `[${match}](${match})`)
                        onLinkActivated: Qt.openUrlExternally(link)
                        visible: incidenceInfoDrawer.incidenceWrapper.description
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18np("<b>Attachment:</b>", "<b>Attachments:</b>", incidenceInfoDrawer.incidenceWrapper.attachmentsModel.rowCount())
                        visible: incidenceInfoDrawer.incidenceWrapper.attachmentsModel.rowCount() > 0
                    }

                    ColumnLayout {
                        id: attachmentsColumn

                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.attachmentsModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: incidenceInfoDrawer.incidenceWrapper.attachmentsModel

                            delegate: HoverLabel {
                                Layout.fillWidth: true
                                // This didn't work in Markdown format
                                text: `<a href="${uri}">${attachmentLabel}</a>`
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Reminders:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.remindersModel.rowCount() > 0
                    }

                    ColumnLayout {
                        id: remindersColumn

                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.remindersModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: incidenceInfoDrawer.incidenceWrapper.remindersModel

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
                        visible: incidenceInfoDrawer.incidenceWrapper.organizer.fullName
                    }

                    HoverLabel {
                        Layout.fillWidth: true

                        property var organizer: incidenceInfoDrawer.incidenceWrapper.organizer
                        visible: incidenceInfoDrawer.incidenceWrapper.organizer.fullName

                        text: organizer.name ?
                            `[${organizer.name}](mailto:${organizer.email})` :
                            `[${organizer.email}](mailto:${organizer.email})`
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignTop
                        text: i18n("<b>Guests:</b>")
                        visible: incidenceInfoDrawer.incidenceWrapper.attendeesModel.rowCount() > 0
                    }

                    ColumnLayout {
                        id: attendeesColumn

                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.attendeesModel.rowCount() > 0

                        Repeater {
                            Layout.fillWidth: true

                            model: incidenceInfoDrawer.incidenceWrapper.attendeesModel

                            delegate: HoverLabel {}
                        }
                    }

                    Kirigami.Separator {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        visible: superTaskColumn.visible || subTaskColumn.visible
                    }

                    ColumnLayout {
                        id: superTaskColumn
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.parent !== ""

                        Kirigami.Heading {
                            text: i18n("Super-task")
                            level: 2
                            font.weight: Font.Bold
                        }

                        Loader {
                            Layout.fillWidth: true
                            height: incidenceInfoDrawer.relatedIncidenceDelegateHeight

                            active: incidenceInfoDrawer.incidenceWrapper.parent !== ""
                            sourceComponent: RelatedIncidenceDelegate {
                                incidenceWrapper: incidenceInfoDrawer.incidenceWrapper.parentIncidence
                            }
                        }
                    }

                    ColumnLayout {
                        id: subTaskColumn
                        Layout.topMargin: superTaskColumn.visible ? Kirigami.Units.largeSpacing : 0
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        visible: incidenceInfoDrawer.incidenceWrapper.childIncidences.length > 0

                        Kirigami.Heading {
                            text: i18np("Sub-task", "Sub-tasks", incidenceInfoDrawer.incidenceWrapper.childIncidences.length)
                            level: 2
                            font.weight: Font.Bold
                        }

                        Repeater {
                            model: incidenceInfoDrawer.incidenceWrapper.childIncidences
                            delegate: RelatedIncidenceDelegate {
                                implicitHeight: incidenceInfoDrawer.relatedIncidenceDelegateHeight
                                incidenceWrapper: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
