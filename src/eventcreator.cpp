// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <eventcreator.h>

EventCreator::EventCreator(QObject *parent)
    : QObject(parent)
{
    KCalendarCore::Event::Ptr m_event(new KCalendarCore::Event);
}

EventCreator::~EventCreator()
{

}
