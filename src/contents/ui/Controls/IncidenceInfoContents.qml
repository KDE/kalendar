// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import QtLocation 5.15
import "labelutils.js" as LabelUtils

import org.kde.kalendar 1.0

Item {
    id: root

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

    readonly property var activeTags : Filter.tags
    readonly property int relatedIncidenceDelegateHeight: Kirigami.Units.gridUnit * 3
    readonly property alias scrollView: contentsView

    component HoverLabel: QQC2.Label {
        Layout.fillWidth: true
        textFormat: Text.MarkdownText
        text: name ? `[${name}](mailto:${email})` : `[${email}](mailto:${email})`
        onLinkActivated: Qt.openUrlExternally(link)
        wrapMode: Text.Wrap
        onHoveredLinkChanged: hoveredLink.length > 0 ?
            applicationWindow().hoverLinkIndicator.text = hoveredLink : applicationWindow().hoverLinkIndicator.text = ""

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.NoButton // Not actually accepting clicks, just changing the cursor
        }
    }

    onIncidenceDataChanged: {
        incidenceWrapper = Qt.createQmlObject('import org.kde.kalendar 1.0; IncidenceWrapper {id: incidence}', root, "incidence");
        incidenceWrapper.incidenceItem = CalendarManager.incidenceItem(incidenceData.incidencePtr);
        collectionData = CalendarManager.getCollectionDetails(incidenceWrapper.collectionId);
    }

    QQC2.ScrollView {
        id: contentsView

        anchors.fill: parent
        contentWidth: availableWidth
        contentHeight: infoBody.implicitHeight + (infoBody.padding * 2)
        clip: true

        property real yScrollPos: QQC2.ScrollBar.vertical.position
        onYScrollPosChanged: if(Kirigami.Settings.isMobile) root.interactive = root.enabled && yScrollPos <= 0

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

                    text: root.incidenceWrapper.summary
                    textFormat: Text.PlainText
                    font.weight: Font.Bold
                    wrapMode: Text.Wrap
                }
                Kirigami.Icon {
                    source: root.incidenceWrapper.incidenceIconName
                }
                Kirigami.Icon {
                    source: "appointment-recurring"
                    visible: root.incidenceWrapper.recurrenceData.type
                }
                Kirigami.Icon {
                    source: "appointment-reminder"
                    visible: root.incidenceWrapper.remindersModel.rowCount() > 0
                }
            }
            Rectangle {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit / 2

                color: root.collectionData.color
            }

            ColumnLayout {
                id: todoCompletionLayout

                Layout.columnSpan: 2
                visible: root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo

                Kirigami.Heading {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    level: 2
                    text: i18nc("%1 is a percentage number", "<b>%1\%</b> Complete", String(root.incidenceWrapper.todoPercentComplete))
                }
                QQC2.Slider {
                    Layout.fillWidth: true

                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.highlightColor: root.incidenceData.color

                    orientation: Qt.Horizontal
                    from: 0
                    to: 100.0
                    stepSize: 10.0
                    value: root.incidenceWrapper.todoPercentComplete
                    onValueChanged: {
                        if (root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo && activeFocus) {
                            root.incidenceWrapper.todoPercentComplete = value;
                            CalendarManager.editIncidence(root.incidenceWrapper);
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

                text: root.collectionData ? root.collectionData.displayName : ""
                wrapMode: Text.Wrap
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Tags:</b>")
                visible: root.incidenceWrapper.categories.length > 0
            }
            Flow {
                id: tagFlow
                Layout.fillWidth: true
                visible: root.incidenceWrapper.categories.length > 0
                spacing: Kirigami.Units.largeSpacing
                Repeater {
                    model: root.incidenceWrapper.categories
                    Tag {
                        text: modelData
                        icon.name: "edit-delete-remove"
                        actionText: i18n("Remove %1 tag", modelData)
                        showAction: false
                        implicitWidth: itemLayout.implicitWidth > tagFlow.width ? tagFlow.width : itemLayout.implicitWidth
                        activeFocusOnTab: true
                        backgroundColor: mainDrawer.activeTags.includes(modelData) ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        onClicked: Filter.toggleFilterTag(modelData)
                    }
                }
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Date:</b>")
                visible: !isNaN(root.incidenceData.startTime.getTime()) || !isNaN(root.incidenceData.endTime.getTime())
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true

                text: if(root.incidenceData.startTime.toDateString() === root.incidenceData.endTime.toDateString()) {
                    return root.incidenceData.startTime.toLocaleDateString(Qt.locale());
                } else if (!isNaN(root.incidenceData.startTime.getTime()) && !isNaN(root.incidenceData.endTime.getTime())) {
                    root.incidenceData.startTime.toLocaleDateString(Qt.locale()) + "–" + root.incidenceData.endTime.toLocaleDateString(Qt.locale())
                } else if (isNaN(root.incidenceData.startTime.getTime()) && !isNaN(root.incidenceData.endTime.getTime())) {
                    return root.incidenceData.endTime.toLocaleDateString(Qt.locale())
                } else if (isNaN(root.incidenceData.endTime.getTime()) && !isNaN(root.incidenceData.startTime.getTime())) {
                    return root.incidenceData.startTime.toLocaleDateString(Qt.locale())
                }
                wrapMode: Text.Wrap
                visible: !isNaN(root.incidenceData.startTime.getTime()) || !isNaN(root.incidenceData.endTime.getTime())
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Time:</b>")
                visible: !root.incidenceData.allDay &&
                    root.incidenceData.startTime.toDateString() == root.incidenceData.endTime.toDateString() &&
                    (!isNaN(root.incidenceData.startTime.getTime()) || !isNaN(root.incidenceData.endTime.getTime()))
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true

                text: {
                    if(root.incidenceData.startTime.toTimeString() != root.incidenceData.endTime.toTimeString()) {
                        root.incidenceData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat) + "–" + root.incidenceData.endTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    } else if (root.incidenceData.startTime.toTimeString() == root.incidenceData.endTime.toTimeString()) {
                        root.incidenceData.startTime.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                    }
                }
                wrapMode: Text.Wrap
                visible: !root.incidenceData.allDay &&
                    root.incidenceData.startTime.toDateString() == root.incidenceData.endTime.toDateString() &&
                    (!isNaN(root.incidenceData.startTime.getTime()) || !isNaN(root.incidenceData.endTime.getTime()))
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Duration:</b>")
                visible: root.incidenceData.durationString &&
                    (!isNaN(root.incidenceData.startTime.getTime()) || !isNaN(root.incidenceData.endTime.getTime()))
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true

                text: root.incidenceData.durationString
                visible: root.incidenceData.durationString &&
                    (!isNaN(root.incidenceData.startTime.getTime()) || !isNaN(root.incidenceData.endTime.getTime()))
                wrapMode: Text.Wrap
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Priority level:</b>")
                visible: root.incidenceWrapper.priority
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                text: LabelUtils.priorityString(root.incidenceWrapper.priority)
                visible: root.incidenceWrapper.priority
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Completed:</b>")
                visible: root.incidenceWrapper.todoCompleted
            }
            QQC2.Label {
                id: todoCompletedTimeLabel
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true

                property date completionDate: root.incidenceWrapper.todoCompletionDt

                text: completionDate.toLocaleString(Qt.locale())
                visible: root.incidenceWrapper.todoCompleted
                // HACK: For some reason, calling the todoCompletionDt always returns an invalid date once it is changed (???)
                onVisibleChanged: if(visible && isNaN(completionDate.getTime())) { text = new Date().toLocaleString(Qt.locale()) }
                wrapMode: Text.Wrap
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Recurrence:</b>")
                visible: root.incidenceWrapper.recurrenceData.type
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.incidenceWrapper.recurrenceData.type

                QQC2.Label {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true

                    text: LabelUtils.recurrenceToString(root.incidenceWrapper.recurrenceData)
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
                            model: root.incidenceWrapper.recurrenceExceptionsModel
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
                    visible: root.incidenceWrapper.recurrenceData.duration > -1

                    text: LabelUtils.recurrenceEndToString(root.incidenceWrapper.recurrenceData)
                    wrapMode: Text.Wrap
                }
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Location:</b>")
                visible: root.incidenceWrapper.location
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
                text: root.incidenceWrapper.location.replace(LabelUtils.urlRegexp, (match) => `<a style="color: "${Kirigami.Theme.linkColor}"; text-decoration: none;" href="${match}">${match}</a>`)
                onTextChanged: isLink = LabelUtils.urlRegexp.test(root.incidenceWrapper.location);
                onLinkActivated: Qt.openUrlExternally(link)
                visible: root.incidenceWrapper.location
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
                visible: Config.enableMaps && (root.incidenceWrapper.location || root.incidenceWrapper.hasGeo)

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
                        root.visible &&
                        (root.incidenceWrapper.location || root.incidenceWrapper.hasGeo) &&
                        !locationLabel.isLink
                    visible: active && (item.queryHasResults || item.hasCoordinate)

                    sourceComponent: LocationMap {
                        id: map
                        query: root.incidenceWrapper.location
                        selectedLatitude: root.incidenceWrapper.hasGeo ? root.incidenceWrapper.geoLatitude : NaN
                        selectedLongitude: root.incidenceWrapper.hasGeo ? root.incidenceWrapper.geoLongitude : NaN

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.incidenceWrapper.hasGeo ?
                                Qt.openUrlExternally("https://www.openstreetmap.org/#map=17/" + root.incidenceWrapper.geoLatitude + "/" + root.incidenceWrapper.geoLongitude) :
                                Qt.openUrlExternally("https://www.openstreetmap.org/search?query=" + root.incidenceWrapper.location)
                        }
                    }
                }
            }

            QQC2.Label {
                id: descriptionLabel
                Layout.alignment: Qt.AlignTop

                text: i18n("<b>Description:</b>")
                visible: root.incidenceWrapper.description
            }
            HoverLabel {
                id: descriptionText
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true

                textFormat: Text.MarkdownText
                text: root.incidenceWrapper.description.replace(LabelUtils.urlRegexp, (match) => `[${match}](${match})`)
                onLinkActivated: Qt.openUrlExternally(link)
                visible: root.incidenceWrapper.description
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18np("<b>Attachment:</b>", "<b>Attachments:</b>", root.incidenceWrapper.attachmentsModel.rowCount())
                visible: root.incidenceWrapper.attachmentsModel.rowCount() > 0
            }

            ColumnLayout {
                id: attachmentsColumn

                Layout.fillWidth: true
                visible: root.incidenceWrapper.attachmentsModel.rowCount() > 0

                Repeater {
                    Layout.fillWidth: true

                    model: root.incidenceWrapper.attachmentsModel

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
                visible: root.incidenceWrapper.remindersModel.rowCount() > 0
            }

            ColumnLayout {
                id: remindersColumn

                Layout.fillWidth: true
                visible: root.incidenceWrapper.remindersModel.rowCount() > 0

                Repeater {
                    Layout.fillWidth: true

                    model: root.incidenceWrapper.remindersModel

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
                visible: root.incidenceWrapper.organizer.fullName
            }

            HoverLabel {
                Layout.fillWidth: true

                property var organizer: root.incidenceWrapper.organizer
                visible: root.incidenceWrapper.organizer.fullName

                text: organizer.name ?
                    `[${organizer.name}](mailto:${organizer.email})` :
                    `[${organizer.email}](mailto:${organizer.email})`
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignTop
                text: i18n("<b>Guests:</b>")
                visible: root.incidenceWrapper.attendeesModel.rowCount() > 0
            }

            ColumnLayout {
                id: attendeesColumn

                Layout.fillWidth: true
                visible: root.incidenceWrapper.attendeesModel.rowCount() > 0

                Repeater {
                    Layout.fillWidth: true

                    model: root.incidenceWrapper.attendeesModel

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
                visible: root.incidenceWrapper.parent !== ""

                Kirigami.Heading {
                    text: i18n("Super-task")
                    level: 2
                    font.weight: Font.Bold
                }

                Loader {
                    Layout.fillWidth: true
                    height: root.relatedIncidenceDelegateHeight

                    active: root.incidenceWrapper.parent !== ""
                    sourceComponent: RelatedIncidenceDelegate {
                        incidenceWrapper: root.incidenceWrapper.parentIncidence
                    }
                }
            }

            ColumnLayout {
                id: subTaskColumn
                Layout.topMargin: superTaskColumn.visible ? Kirigami.Units.largeSpacing : 0
                Layout.columnSpan: 2
                Layout.fillWidth: true
                visible: root.incidenceWrapper.childIncidences.length > 0 || placeholderAddSubtaskCard.visible

                Kirigami.Heading {
                    text: i18np("Sub-task", "Sub-tasks", root.incidenceWrapper.childIncidences.length)
                    level: 2
                    font.weight: Font.Bold
                }

                Repeater {
                    model: root.incidenceWrapper.childIncidences
                    delegate: RelatedIncidenceDelegate {
                        implicitHeight: root.relatedIncidenceDelegateHeight
                        incidenceWrapper: modelData
                    }
                }

                MouseArea {
                    id: placeholderAddSubtaskCard

                    Layout.fillWidth: true
                    implicitHeight: root.relatedIncidenceDelegateHeight

                    visible: root.incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo

                    onClicked: Kalendar.UiUtils.setUpAddSubTodo(incidenceInfoContents.incidenceWrapper);

                    IncidenceDelegateBackground {
                        color: Kirigami.Theme.backgroundColor
                    }

                    RowLayout {
                        id: incidenceContents
                        clip: true

                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            Layout.maximumWidth: height
                            Layout.maximumHeight: parent.height

                            source: "list-add"
                            isMask: true
                            color: Kirigami.Theme.textColor
                            visible: incidenceWrapper.incidenceType === IncidenceWrapper.TypeTodo
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("Add a sub-task")
                            elide: Text.ElideRight
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }
}
