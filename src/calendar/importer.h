// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#pragma once

#include <Akonadi/ETMCalendar>
#include <QAction>
#include <QObject>

class Importer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool calendarImportInProgress MEMBER m_calendarImportInProgress NOTIFY calendarImportInProgressChanged)
    Q_PROPERTY(QList<QUrl> calendarFilesToImport MEMBER m_calendarFilesToImport NOTIFY calendarFilesToImportChanged)
    Q_PROPERTY(QUrl currentFile MEMBER m_currentFile NOTIFY currentFileChanged)
    Q_PROPERTY(QAction *importAction READ importAction WRITE setImportAction NOTIFY importActionChanged)
    Q_PROPERTY(Akonadi::ETMCalendar::Ptr calendar MEMBER m_calendar NOTIFY calendarChanged)
    Q_PROPERTY(QString importErrorMessage READ importErrorMessage NOTIFY importErrorMessageChanged)

public:
    explicit Importer(QObject *parent = nullptr);

    Q_INVOKABLE void importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId = -1);
    QString importErrorMessage();

    QAction *importAction() const;
    void setImportAction(QAction *importAction);

Q_SIGNALS:
    void importActionChanged();
    void importStarted();
    void importFinished();
    void importCalendar();
    void importCalendarFromFile(const QUrl &url);
    void importIntoExistingFinished(bool success, int total);
    void importIntoNewFinished(bool success);
    void importErrorMessageChanged();
    void calendarImportInProgressChanged();
    void calendarFilesToImport();
    void currentFileChanged();
    void calendarChanged();
    void calendarFilesToImportChanged();

private:
    Akonadi::ETMCalendar::Ptr m_calendar;
    QString m_importErrorMessage;
    bool m_calendarImportInProgress = false;
    QList<QUrl> m_calendarFilesToImport;
    QAction *m_importAction = nullptr;
    QUrl m_currentFile;
};