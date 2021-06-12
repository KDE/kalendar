// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QObject>
#include <CalendarSupport/KCalPrefs>
#include <CalendarSupport/Utils>

class EventCreator : public QObject
{
    Q_OBJECT

public:
    EventCreator(QObject *parent = nullptr);
    ~EventCreator() override;

private:
    KCalendarCore::Event::Ptr m_event;
};
