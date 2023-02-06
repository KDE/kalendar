// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

/**
* Returns the week number for this date.  dowOffset is the day of week the week
* "starts" on for your locale - it can be from 0 to 6. If dowOffset is 1 (Monday),
* the week returned is the ISO 8601 week number.
* @param int dowOffset
* @return int
*/
function getWeek(date, dowOffset) {
    let newYear = new Date(date.getFullYear(),0,1);
    let day = newYear.getDay() - dowOffset; //the day of week the year begins on
    day = (day >= 0 ? day : day + 7);
    let daynum = Math.floor((date.getTime() - newYear.getTime() - (date.getTimezoneOffset()-newYear.getTimezoneOffset())*60000)/86400000) + 1;
    let weeknum;
    //if the year starts before the middle of a week
    if(day < 4) {
        weeknum = Math.floor((daynum+day-1)/7) + 1;
        if(weeknum > 52) {
            let nYear = new Date(date.getFullYear() + 1,0,1);
            let nday = nYear.getDay() - dowOffset;
            nday = nday >= 0 ? nday : nday + 7;
            /*if the next year starts before the middle of
            the week, it is week #1 of that year*/
            weeknum = nday < 4 ? 1 : 53;
        }
    }
    else {
        weeknum = Math.floor((daynum+day-1)/7);
    }
    return weeknum;
}

function roundToDay(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function roundToMinutes(date, delta) {
    let totalMinutes = date.getHours() * 60 +  date.getMinutes()
    //Round to nearest delta
    totalMinutes = Math.round(totalMinutes / delta) * delta
    let minutes = totalMinutes % 60
    let hours = (totalMinutes - minutes) / 60
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), hours, minutes, 0)
}

function addDaysToDate(date, days) {
    let newDate = new Date(date);
    newDate.setDate(newDate.getDate() + days);
    return newDate;
}

function addMinutesToDate(date, minutes) {
    return new Date(date.getTime() + minutes*60000);
}

function sameDay(date1, date2) {
    return date1.getFullYear() === date2.getFullYear()
        && date1.getMonth() === date2.getMonth()
        && date1.getDate() === date2.getDate();
}

function sameTime(date1, date2) {
    return date1.getHours() === date2.getHours()
        && date1.getMinutes() === date2.getMinutes();
}

function sameMonth(date1, date2) {
    return date1.getFullYear() === date2.getFullYear() && date1.getMonth() === date2.getMonth()
}

function nextWeek(date) {
    let d = date
    d.setTime(date.getTime() + (24*60*60*1000) * 7);
    return d
}

function previousWeek(date) {
    let d = date
    d.setTime(date.getTime() - (24*60*60*1000) * 7);
    return d
}

function addMonthsToDate(date, months) {
    const d = date
    d.setMonth(date.getMonth() + months);
    return d
}

function nextMonth(date) {
    let d = date
    //FIXME, if you add a month to the 31.3 you will end up on the 5.1 because April has only 30 days. Wtf javascript
    d.setMonth(date.getMonth() + 1);
    return d
}

function previousMonth(date) {
    let d = date
    d.setMonth(date.getMonth() - 1);
    return d
}

function getFirstDayOfWeek(date) {
    //This works with negative days to get to the previous month
    //Date.getDate() is the day of the month, Date.getDay() is the day of the week
    // Examples:
    // 28 = 28 - (1 - 1)
    // 21 = 27 - (0 - 1)
    // 21 = 26 - (6 - 1)
    // 21 = 25 - (5 - 1)
    let offset = date.getDay() - Qt.locale().firstDayOfWeek;
    if (offset < 0) {
        offset = 7 + offset;
    }
    return new Date(date.getFullYear(), date.getMonth(), date.getDate() - offset)
}

function getLastDayOfWeek(date) {
    let firstOfWeek = getFirstDayOfWeek(date);
    return new Date(firstOfWeek.getFullYear(), firstOfWeek.getMonth(), firstOfWeek.getDate() - 1)
}

function getFirstDayOfMonth(date) {
    let d = date
    d.setDate(1)
    return d
}

function fullDaysBetweenDates(date1, date2) {
    let days = 1;
    let date1Mn = new Date(date1.setHours(0,0,0,0));
    let date2Mn = new Date(date2.setHours(0,0,0,0));
    if(date1Mn.getTime() < date2Mn.getTime()) {
        while(date1Mn.getTime() < date2Mn.getTime()) {
            date1Mn = addDaysToDate(date1Mn, 1);
            days += 1;
        }
    } else {
        while (date1Mn.getTime() > date2Mn.getTime()) {
            date1Mn = addDaysToDate(date1Mn, -1);
            days -= 1;
        }
    }
    return days;
}

function adjustDateTimeToLocalTimeZone(dateTime, timeZoneOffset) {
    // Creates a new date object set to the time and date of the prior object, only in your local timezone
    return new Date(dateTime.getTime() + (timeZoneOffset * 1000) + (new Date().getTimezoneOffset() * 60 * 1000));
}

function unadjustDateTimeToLocalTimeZone(dateTime, timeZoneOffset) {
    // Undoes what prior func does
    return new Date(dateTime.getTime() - (timeZoneOffset * 1000) - (new Date().getTimezoneOffset() * 60 * 1000));
}

function parseDateString(dateString) {
    function defaultParse() {
        return Date.fromLocaleDateString(Qt.locale(), dateString, Locale.NarrowFormat);
    }

    const dateStringDelimiterMatches = dateString.match(/\D/);
    if(dateStringDelimiterMatches.length === 0) { // Let the date method figure out this weirdness
        return defaultParse();
    }

    const dateStringDelimiter = dateStringDelimiterMatches[0];

    const localisedDateFormatSplit = Qt.locale().dateFormat(Locale.NarrowFormat).split(dateStringDelimiter);
    const localisedDateDayPosition = localisedDateFormatSplit.findIndex((x) => /d/gi.test(x));
    const localisedDateMonthPosition = localisedDateFormatSplit.findIndex((x) => /m/gi.test(x));
    const localisedDateYearPosition = localisedDateFormatSplit.findIndex((x) => /y/gi.test(x));

    let splitDateString = dateString.split(dateStringDelimiter);
    let userProvidedYear = splitDateString[localisedDateYearPosition]

    const dateNow = new Date();
    const stringifiedCurrentYear = dateNow.getFullYear().toString();

    // If we have any input weirdness, or if we have a fully-written year (e.g. 2022 instead of 22) then use default parse
    if(splitDateString.length === 0 || splitDateString.length > 3 || userProvidedYear.length >= stringifiedCurrentYear.length) {
        return defaultParse();
    }

    let fullyWrittenYear = userProvidedYear.split("");
    const digitsToAdd = stringifiedCurrentYear.length - fullyWrittenYear.length;
    for(let i = 0; i < digitsToAdd; i++) {
        fullyWrittenYear.splice(i, 0, stringifiedCurrentYear[i])
    }
    fullyWrittenYear = fullyWrittenYear.join("");

    const fixedYearNum = Number(fullyWrittenYear);
    const monthIndexNum = Number(splitDateString[localisedDateMonthPosition]) - 1;
    const dayNum = Number(splitDateString[localisedDateDayPosition]);

    console.log(new Date(fixedYearNum, monthIndexNum, dayNum))

    return new Date(fixedYearNum, monthIndexNum, dayNum);
}
