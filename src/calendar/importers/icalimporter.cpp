// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "icalimporter.h"
#include "kalendar_calendar_debug.h"
#include <Akonadi/ICalImporter>
#include <KLocalizedString>

ICalImporter::ICalImporter(QObject *parent)
    : QObject(parent)
{
}

void ICalImporter::importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId)
{
    if (!m_calendar) {
        return;
    }

    auto importer = new Akonadi::ICalImporter(m_calendar->incidenceChanger());
    bool jobStarted;

    if (merge) {
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &ICalImporter::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &ICalImporter::importIntoExistingFinished);
        auto collection = m_calendar->collection(collectionId);
        jobStarted = importer->importIntoExistingResource(url, collection);
    } else {
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &ICalImporter::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &ICalImporter::importIntoNewFinished);
        jobStarted = importer->importIntoNewResource(url.path());
    }

    if (jobStarted) {
        Q_EMIT importStarted();
    } else {
        // empty error message means user canceled.
        if (!importer->errorMessage().isEmpty()) {
            qCDebug(KALENDAR_CALENDAR_LOG) << i18n("An error occurred: %1", importer->errorMessage());
            m_importErrorMessage = importer->errorMessage();
            Q_EMIT importErrorMessageChanged();
        }
    }
}

QString ICalImporter::importErrorMessage() const
{
    return m_importErrorMessage;
}
