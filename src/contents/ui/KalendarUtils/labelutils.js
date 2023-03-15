// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

.import "dateutils.js" as DateUtils;

// This regex detects URLs in the description text, so we can turn them into links
const urlRegexp = /^(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,}))\.?)(?::\d{2,5})?(?:[/?#]\S*)?$/ig

function numberToString(number) {
    // The code in here was adapted from an article by Johnathan Wood, see:
    // http://www.blackbeltcoder.com/Articles/strings/converting-numbers-to-ordinal-strings

    let numSuffixes = [ "th",
    "st",
    "nd",
    "rd",
    "th",
    "th",
    "th",
    "th",
    "th",
    "th"];

    let i = (number % 100);
    let j = (i > 10 && i < 20) ? 0 : (number % 10);
    return i18n(number + numSuffixes[j]);
}

function weeklyRecurrenceToString(recurrenceData) {
    let returnString = i18np("Every week", "Every %1 weeks", recurrenceData.frequency);

    if (recurrenceData.weekdays.filter(x => x === true).length > 0) {
        returnString = i18np("Every week on", "Every %1 weeks on", recurrenceData.frequency);

        for(let i = 0; i < recurrenceData.weekdays.length; i++) {

            if(recurrenceData.weekdays[i]) {
                returnString += ` ${Qt.locale().dayName(i + 1, 0)},`; // C++ Qt weekdays go Mon->Sun, JS goes Sun->Sat, 0 is HACK for locale enum
            }
        }
        // Delete last comma
        returnString = returnString.slice(0, -1);
    }

    return returnString;
}

function monthPositionsToString(recurrenceData) {
    let returnString = "";

    for(let position of recurrenceData.monthPositions) {
        returnString += `${numberToString(position.pos)} ${Qt.locale().dayName(position.day)}, `
    }

    return returnString.slice(0, -2);
}

function yearlyPosRecurrenceToString(recurrenceData) {
    let months = "";

    for(let i = 0; i < recurrenceData.yearMonths.length; i++) {
        months += `${Qt.locale().monthName(recurrenceData.yearMonths[i])}, `;
    }
    months = months.slice(0, -2); // Remove space and comma

    return i18np("Every year on the %2 of %3", "Every %1 years on the %2 of %3",
                 recurrenceData.frequency, monthPositionsToString(recurrenceData), months);
}

function yearlyDaysRecurrenceToString(recurrenceData) {
    let dayNumsString = "";

    for(let dayNum of recurrenceData.yearDays) {
        dayNumsString += `${numberToString(dayNum)}, `;
    }
    return dayNumsString.slice(0, -2); // Remove space and comma
}

function recurrenceToString(recurrenceData) {
    switch(recurrenceData.type) {
        case 0:
            return i18n("Never");

        case 1:
            return i18np("Every minute", "Every %1 minutes", recurrenceData.frequency);

        case 2:
            return i18np("Every hour", "Every %1 hours", recurrenceData.frequency);

        case 3: // Daily
            return i18np("Every day", "Every %1 days", recurrenceData.frequency);

        case 4: // Weekly
            return weeklyRecurrenceToString(recurrenceData);

        case 5: // Monthly on position (e.g. third Monday)
            return i18np("Every month on the %2", "Every %1 months on the %2",
                  recurrenceData.frequency, monthPositionsToString(recurrenceData));

        case 6: // Monthly on day (1st of month)
            return i18np("Every month on the %2", "Every %1 months on the %2",
                         recurrenceData.frequency, numberToString(recurrenceData.startDateTime.getDate()));

        case 7: // Yearly on month (e.g. every April 15th)
            return i18np("Every year on the %2 of %3", "Every %1 years on the %2 of %3", recurrenceData.frequency,
                         numberToString(recurrenceData.startDateTime.getDate()), Qt.locale().monthName(recurrenceData.startDateTime.getMonth()));

        case 8: // Yearly on day (e.g. 192nd day of the year)
            return i18np("Every year on the %2 day of the year", "Every %1 years on the %2 day of the year", recurrenceData.frequency,
                         yearlyDaysRecurrenceToString(recurrenceData));
        case 9: // Yearly on position
            return yearlyPosRecurrenceToString(recurrenceData);

        case 10:
            return i18n("Complex recurrence rule");

        default:
            return i18n("Unknown");
    }

}

function recurrenceEndToString(recurrenceData) {
    switch(recurrenceData.duration) {
        case -1:
            return i18n("Never ends");
        case 0:
            return !isNaN(recurrenceData.endDateTime) ? i18n("Ends on %1", recurrenceData.endDateTime.toLocaleDateString()) : "";
        default:
            return i18n("Ends after %1 occurrences", recurrenceData.duration);
    }
}

function getDarkness(background) {
    // Thanks to Gojir4 from the Qt forum
    // https://forum.qt.io/topic/106362/best-way-to-set-text-color-for-maximum-contrast-on-background-color/
    var temp = Qt.darker(background, 1);
    var a = 1 - ( 0.299 * temp.r + 0.587 * temp.g + 0.114 * temp.b);
    return a;
}

function isDarkColor(background) {
    var temp = Qt.darker(background, 1);
    return temp.a > 0 && getDarkness(background) >= 0.4;
}

function getIncidenceDelegateBackgroundColor(backgroundColor, darkMode, eventEnd = null, pastEventsDimLevel = 0.0) {
    let bgColor = getDarkness(backgroundColor) > 0.9 ? Qt.lighter(backgroundColor, 1.5) : backgroundColor;
    if(darkMode) {
        if(getDarkness(backgroundColor) >= 0.5) {
            bgColor.a = 0.6;
        } else {
            bgColor.a = 0.4;
        }
    } else {
        bgColor.a = 0.7;
    }

    if(pastEventsDimLevel > 0 && eventEnd) {
        const now = new Date();
        if (modelData.endTime < now) {
            bgColor.a = Math.max(0.0, bgColor.a - pastEventsDimLevel);
        }
    }
    return bgColor;
}

function getIncidenceLabelColor(background, darkMode) {

    if(getDarkness(background) >= 0.9) {
        return "white";
    } else if(darkMode) {
        if(getDarkness(background) >= 0.5) {
            return Qt.lighter(background, 2.1);
        } else {
            return Qt.lighter(background, 1.5);
        }
    }
    else if(getDarkness(background) >= 0.68) {
        return Qt.lighter(background, 2.4);
    } else {
        return Qt.darker(background, 2.1);
    }

}

function priorityString(priority) {
    if(priority === 1) {
        return i18nc("%1 is the priority level number", "%1 (Highest priority)", priority);
    } else if (priority < 5) {
        return i18nc("%1 is the priority level number", "%1 (Mid-high priority)", priority);
    } else if (priority === 5) {
        return i18nc("%1 is the priority level number", "%1 (Medium priority)", priority);
    } else if (priority < 9) {
        return i18nc("%1 is the priority level number", "%1 (Mid-low priority)", priority);
    } else if (priority === 9) {
        return i18nc("%1 is the priority level number", "%1 (Lowest priority)", priority);
    } else {
        return i18n("No set priority level");
    }
}
