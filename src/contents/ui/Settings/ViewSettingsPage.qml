// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick 2.15
import org.kde.kirigami 2.19 as Kirigami
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kalendar 1.0
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

Kirigami.ScrollablePage {
    title: i18n("Appearance")

    ColumnLayout {
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("General settings")
                }

                MobileForm.FormSwitchDelegate {
                    text: i18n("Use popup to show incidence information")
                    checked: Config.useIncidenceInfoPopup
                    enabled: !Config.isUseIncidenceInfoPopupImmutable && !Kirigami.Settings.isMobile
                    visible: !Kirigami.Settings.isMobile
                    onClicked: {
                        Config.useIncidenceInfoPopup = !Config.useIncidenceInfoPopup;
                        Config.save();
                    }
                }

                MobileForm.FormSwitchDelegate {
                    text: i18n("Show sub-tasks in calendar views")
                    checked: Config.showSubtodosInCalendarViews
                    enabled: !Config.isShowSubtodosInCalendarViewsImmutable
                    onClicked: {
                        Config.showSubtodosInCalendarViews = !Config.showSubtodosInCalendarViews;
                        Config.save();
                    }
                }
                MobileForm.AbstractFormDelegate {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Controls.Label {
                            text: i18n("Past event transparency:")
                            Layout.fillWidth: true
                        }
                        Controls.Slider {
                            Layout.fillWidth: true
                            stepSize: 1.0
                            from: 0.0
                            to: 100.0
                            value: Config.pastEventsTransparencyLevel * 100
                            onMoved: {
                                Config.pastEventsTransparencyLevel = value / 100;
                                Config.save();
                            }
                        }
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("Month view settings")
                }

                Controls.ButtonGroup {
                    id: monthGridModeGroup
                    exclusive: true
                    onCheckedButtonChanged: {
                        Config.monthGridMode = checkedButton.value;
                        Config.save();
                    }
                }
                MobileForm.FormSectionText {
                    text: i18n("Month view mode")
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    MobileForm.FormRadioDelegate {
                        property int value: Config.SwipeableMonthGrid
                        text: i18n("Swipeable month grid")
                        enabled: !Config.isMonthGridModeImmutable
                        checked: Config.monthGridMode === value
                        Controls.ButtonGroup.group: monthGridModeGroup
                    }
                    MobileForm.FormRadioDelegate {
                        property int value: Config.BasicMonthGrid
                        text: i18n("Basic month grid")
                        enabled: !Config.isMonthGridModeImmutable
                        checked: Config.monthGridMode === value
                        Controls.ButtonGroup.group: monthGridModeGroup
                    }
                    MobileForm.FormTextDelegate {
                        text: i18n("Swipeable month grid requires higher system performance.")
                        visible: Config.monthGridMode === Config.SwipeableMonthGrid
                    }
                }

                Controls.ButtonGroup {
                    id: weekdayLabelGroup
                    exclusive: true
                    onCheckedButtonChanged: {
                        Config.weekdayLabelAlignment = checkedButton.value;
                        Config.save();
                    }
                }
                MobileForm.FormSectionText {
                    text: i18n("Weekday label alignment")
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    MobileForm.FormRadioDelegate {
                        property int value: Config.Left
                        text: i18n("Left")
                        enabled: !Config.isWeekdayLabelAlignmentImmutable
                        checked: Config.weekdayLabelAlignment === value
                        Controls.ButtonGroup.group: weekdayLabelGroup
                    }
                    MobileForm.FormRadioDelegate {
                        property int value: Config.Center
                        text: i18n("Center")
                        enabled: !Config.isWeekdayLabelAlignmentImmutable
                        checked: Config.weekdayLabelAlignment === value
                        Controls.ButtonGroup.group: weekdayLabelGroup
                    }
                    MobileForm.FormRadioDelegate {
                        property int value: Config.Right
                        text: i18n("Right")
                        enabled: !Config.isWeekdayLabelAlignmentImmutable
                        checked: Config.weekdayLabelAlignment === value
                        Controls.ButtonGroup.group: weekdayLabelGroup
                    }
                }

                Controls.ButtonGroup {
                    id: weekdayLabelLengthGroup
                    exclusive: true
                    onCheckedButtonChanged: {
                        Config.weekdayLabelLength = checkedButton.value;
                        Config.save();
                    }
                }

                MobileForm.FormSectionText {
                    text: i18n("Weekday label length:")
                }

                MobileForm.FormRadioDelegate {
                    property int value: Config.Full
                    text: i18n("Full name (Monday)")
                    enabled: !Config.isWeekdayLabelLengthImmutable
                    checked: Config.weekdayLabelLength === value
                    Controls.ButtonGroup.group: weekdayLabelLengthGroup
                }
                MobileForm.FormRadioDelegate {
                    property int value: Config.Abbreviated
                    text: i18n("Abbreviated (Mon)")
                    enabled: !Config.isWeekdayLabelLengthImmutable
                    checked: Config.weekdayLabelLength === value
                    Controls.ButtonGroup.group: weekdayLabelLengthGroup
                }
                MobileForm.FormRadioDelegate {
                    property int value: Config.Letter
                    text: i18n("Letter only (M)")
                    enabled: !Config.isWeekdayLabelLengthImmutable
                    checked: Config.weekdayLabelLength === value
                    Controls.ButtonGroup.group: weekdayLabelLengthGroup
                }

                MobileForm.FormCheckDelegate {
                    text: i18n("Show week numbers")
                    checked: Config.showWeekNumbers
                    enabled: !Config.isShowWeekNumbersImmutable
                    onClicked: {
                        Config.showWeekNumbers = !Config.showWeekNumbers;
                        Config.save();
                    }
                }
                MobileForm.AbstractFormDelegate {
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        Controls.Label {
                            text: i18n("Grid border width (pixels):")
                        }
                        Controls.SpinBox {
                            Layout.fillWidth: true
                            value: Config.monthGridBorderWidth
                            onValueModified: {
                                Config.monthGridBorderWidth = value;
                                Config.save();
                            }
                            from: 0
                            to: 50
                        }
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: Kirigami.Units.gridUnit * 4
                            implicitHeight: height
                            height: Config.monthGridBorderWidth
                            color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.15)
                        }
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("Week view settings")
                }

                Controls.ButtonGroup {
                    id: hourlyViewModeGroup
                    exclusive: true
                    onCheckedButtonChanged: {
                        Config.hourlyViewMode = checkedButton.value;
                        Config.save();
                    }
                }
                MobileForm.FormSectionText {
                    text: i18n("Week view mode")
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    MobileForm.FormRadioDelegate {
                        property int value: Config.SwipeableInternalHourlyView
                        text: i18n("Swipeable week view")
                        enabled: !Config.isHourlyViewModeImmutable
                        checked: Config.monthGridMode === value
                        Controls.ButtonGroup.group: hourlyViewModeGroup
                    }
                    MobileForm.FormRadioDelegate {
                        property int value: Config.BasicInternalHourlyView
                        text: i18n("Basic week view")
                        enabled: !Config.isHourlyViewModeImmutable
                        checked: Config.monthGridMode === value
                        Controls.ButtonGroup.group: hourlyViewModeGroup
                    }
                    MobileForm.FormTextDelegate {
                        text: i18n("Swipeable week view requires higher system performance.")
                        visible: Config.hourlyViewMode === Config.SwipeableInternalHourlyView
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("Schedule View settings")
                }
                MobileForm.FormCheckDelegate {
                    text: i18n("Show week headers")
                    checked: Config.showWeekHeaders
                    enabled: !Config.isShowWeekHeadersImmutable
                    onClicked: {
                        Config.showWeekHeaders = !Config.showWeekHeaders;
                        Config.save();
                    }
                }
            }
        }

        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("Tasks View settings")
                }
                MobileForm.FormCheckDelegate {
                    text: i18n("Show completed sub-tasks")
                    checked: Config.showCompletedSubtodos
                    enabled: !Config.isShowCompletedSubtodosImmutable
                    onClicked: {
                        Config.showCompletedSubtodos = !Config.showCompletedSubtodos;
                        Config.save();
                    }
                }
            }
        }
        MobileForm.FormCard {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            contentItem: ColumnLayout {
                spacing: 0
                MobileForm.FormCardHeader {
                    title: i18n("Maps")
                }
                MobileForm.FormCheckDelegate {
                    text: i18n("Enable maps")

                    checked: Config.enableMaps
                    enabled: !Config.isEnableMapsImmutable
                    onClicked: {
                        Config.enableMaps = !Config.enableMaps;
                        Config.save();
                    }
                }
                MobileForm.FormTextDelegate {
                    text: i18n("May cause crashing on some systems.")
                }
                Controls.ButtonGroup {
                    id: locationGroup
                    exclusive: true
                    onCheckedButtonChanged: {
                        Config.locationMarker = checkedButton.value;
                        Config.save();
                    }
                }
                MobileForm.FormSectionText {
                    text: i18n("Location marker")
                }
                ColumnLayout {
                    id: locationMarkerButtonColumn
                    Layout.fillWidth: true

                    MobileForm.FormRadioDelegate {
                        property int value: Config.Circle
                        text: i18n("Circle (shows area of location)")
                        enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
                        checked: Config.locationMarker === value
                        Controls.ButtonGroup.group: locationGroup
                    }
                    MobileForm.FormRadioDelegate {
                        property int value: Config.Pin
                        text: i18n("Pin (shows exact location)")
                        enabled: Config.enableMaps && !Config.isLocationMarkerImmutable
                        checked: Config.locationMarker === value
                        Controls.ButtonGroup.group: locationGroup
                    }
                }
            }
        }
    }
}
