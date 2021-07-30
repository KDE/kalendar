// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QAbstractItemModel>
#include <QList>
#include <QSet>
#include <QSharedPointer>
#include <QTimer>
#include <QDateTime>
#include "incidenceoccurrencemodel.h"

namespace KCalendarCore {
    class MemoryCalendar;
    class Incidence;
}

/**
 * Each toplevel index represents a week.
 * The "incidences" roles provides a list of lists, where each list represents a visual line,
 * containing a number of events to display.
 */
class MultiDayIncidenceModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(int periodLength READ periodLength WRITE setPeriodLength NOTIFY periodLengthChanged)
    Q_PROPERTY(IncidenceOccurrenceModel* model WRITE setModel)

public:
    MultiDayIncidenceModel(QObject *parent = nullptr);
    ~MultiDayIncidenceModel() = default;

    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    int rowCount(const QModelIndex &parent) const override;
    int columnCount(const QModelIndex &parent) const override;

    QVariant data(const QModelIndex &index, int role) const override;

    QHash<int, QByteArray> roleNames() const override;

    void setModel(IncidenceOccurrenceModel *model);
    int periodLength();
    void setPeriodLength(int periodLength);

Q_SIGNALS:
    void periodLengthChanged();

private:
    QList<QModelIndex> sortedIncidencesFromSourceModel(const QDate &rowStart) const;
    QVariantList layoutLines(const QDate &rowStart) const;
    IncidenceOccurrenceModel *mSourceModel{nullptr};
    int mPeriodLength{7};
};

