// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

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

function secondsToReminderLabel(seconds) { // Gives prettified time

    function numAndUnit(secs) {
        if(secs >= (2 * 24 * 60 * 60))
            return i18nc("%1 is 2 or more", "%1 days", Math.round(secs / (24*60*60))); // 2 days +
            else if (secs >= (1 * 24 * 60 * 60))
                return i18n("1 day");
            else if (secs >= (2 * 60 * 60))
                return i18nc("%1 is 2 or mores", "%1 hours", Math.round(secs / (60*60))); // 2 hours +
                else if (secs >= (1 * 60 * 60))
                    return i18n("1 hour");
                else
                    return i18n("%1 minutes", Math.round(secs / 60));
    }

    if (seconds < 0) {
        return i18n("%1 before start of event", numAndUnit(seconds * -1));
    } else if (seconds < 0) {
        return i18n("%1 after start of event", numAndUnit(seconds));
    } else {
        return i18n("On event start");
    }
}

function weeklyRecurrenceToString(recurrenceData) {
    let returnString = i18np("Every week", "Every %1 weeks", recurrenceData.frequency);

    if (recurrenceData.weekdays.filter(x => x === true).length > 0) {
        returnString = i18np("Every week on", "Every %1 weeks on", recurrenceData.frequency);

        for(let i = 0; i < recurrenceData.weekdays.length; i++) {

            if(recurrenceData.weekdays[i]) {
                returnString += ` ${Qt.locale().dayName(i + 1, Locale.ShortFormat)},`; // C++ Qt weekdays go Mon->Sun, JS goes Sun->Sat
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
            return i18n("Ends on %1", recurrenceData.endDateTime.toLocaleDateString(Qt.locale()))
        default:
            return i18n("Ends after %1 occurrences", recurrenceData.duration);
    }
}
