// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-3.0-or-later

#include "importer.h"
#include "kalendar_calendar_debug.h"
#include <Akonadi/ICalImporter>
#include <KLocalizedString>
#include <QTimer>

using namespace std::chrono_literals;

Importer::Importer(QObject *parent)
    : QObject(parent)
{
    connect(this, &Importer::calendarImportInProgressChanged, this, [this]() {
        if (m_calendarImportInProgress && m_calendarFilesToImport.length() > 0) {
            QTimer::singleShot(100ms, [this]() {
                Q_EMIT importCalendarFromFile(m_calendarFilesToImport.takeFirst());
            });
        }
    });
}

void Importer::importCalendarFromUrl(const QUrl &url, bool merge, qint64 collectionId)
{
    if (!m_calendar) {
        return;
    }

    auto importer = new Akonadi::ICalImporter(m_calendar->incidenceChanger());
    bool jobStarted;

    if (merge) {
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &Importer::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoExistingFinished, this, &Importer::importIntoExistingFinished);
        auto collection = m_calendar->collection(collectionId);
        jobStarted = importer->importIntoExistingResource(url, collection);
    } else {
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &Importer::importFinished);
        connect(importer, &Akonadi::ICalImporter::importIntoNewFinished, this, &Importer::importIntoNewFinished);
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

QString Importer::importErrorMessage()
{
    return m_importErrorMessage;
}

QAction *Importer::importAction() const
{
    return m_importAction;
}

void Importer::setImportAction(QAction *importAction)
{
    if (m_importAction == importAction) {
        return;
    }

    if (m_importAction) {
        disconnect(this, &Importer::importFinished, m_importAction, nullptr);
        disconnect(this, &Importer::importStarted, m_importAction, nullptr);
    }

    m_importAction = importAction;
    Q_EMIT importActionChanged();

    if (m_importAction) {
        connect(this, &Importer::importFinished, m_importAction, [this] {
            m_importAction->setEnabled(true);
        });
        connect(this, &Importer::importStarted, m_importAction, [this] {
            m_importAction->setEnabled(false);
        });
    }
}
