// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <eventcreator.h>

EventCreator::EventCreator(QObject *parent)
    : QObject(parent)
{

}

EventCreator::~EventCreator()
{

}

KCalendarCore::Event::Ptr EventCreator::newEventPtr()
{
    KCalendarCore::Event::Ptr event(new KCalendarCore::Event);
    return event;
}
