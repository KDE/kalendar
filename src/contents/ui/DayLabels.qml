// SPDX-FileCopyrightText: 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2
import "dateutils.js" as DateUtils

Row {
    id: root
    property int dayWidth
    property int daysToShow
    property Component delegate
    property date startDate

    height: childrenRect.height
    spacing: 0

    Repeater {
        model: root.daysToShow

        delegate: Loader {
            property date day: DateUtils.addDaysToDate(root.startDate, modelData)

            sourceComponent: root.delegate
            width: root.dayWidth
        }
    }
}
