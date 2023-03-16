// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once

#include <Akonadi/ETMCalendar>
#include <QObject>
#include <QUrl>

class ICalImporter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(QString importErrorMessage READ importErrorMessage NOTIFY importErrorMessageChanged)

public:
    explicit ICalImporter(QObject *parent = nullptr);

    Akonadi::ETMCalendar::Ptr calendar() const;
    void setCalendar(Akonadi::ETMCalendar::Ptr calendar);

    QString importErrorMessage() const;

    Q_INVOKABLE void importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId = -1);

Q_SIGNALS:
    void calendarChanged();
    void importStarted();
    void importFinished();
    void importErrorMessageChanged();
    void importIntoExistingFinished(bool success, int total);
    void importIntoNewFinished(bool success);

private:
    Akonadi::ETMCalendar::Ptr m_calendar;
    QString m_importErrorMessage;
};
