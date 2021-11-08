// Copyright (c) 2018 Michael Bohlender <michael.bohlender@kdemail.net>
// Copyright (c) 2018 Christian Mollekopf <mollekopf@kolabsys.com>
// Copyright (c) 2018 Rémi Nicole <minijackson@riseup.net>
// Copyright (c) 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "multidayincidencemodel.h"
#include "viewincidencesmodel.h"
#include <QBitArray>

MultiDayIncidenceModel::MultiDayIncidenceModel(QObject *parent)
    : QAbstractListModel(parent)
{
    mRefreshTimer.setSingleShot(true);
}

int MultiDayIncidenceModel::rowCount(const QModelIndex &parent) const
{
    // Number of weeks
    if (!parent.isValid() && mSourceModel) {
        return qMax(mSourceModel->length() / mPeriodLength, 1);
    }
    return 0;
}

int MultiDayIncidenceModel::columnCount(const QModelIndex &) const
{
    return 1;
}

QVariant MultiDayIncidenceModel::data(const QModelIndex &idx, int role) const
{
    if (!hasIndex(idx.row(), idx.column())) {
        return {};
    }
    if (!mSourceModel) {
        return {};
    }
    const auto rowStart = mSourceModel->start().addDays(idx.row() * mPeriodLength);
    switch (role) {
    case PeriodStartDate:
        return rowStart.startOfDay();
    case Incidences: {
        if (!m_incidencesModels.contains(rowStart)) {
            auto viewIncidenceModel = new ViewIncidencesModel(rowStart, mPeriodLength, mSourceModel);
            viewIncidenceModel->setFilters(m_filters);
            viewIncidenceModel->setModel(mSourceModel);
            m_incidencesModels[rowStart] = viewIncidenceModel;
        }

        return QVariant::fromValue(m_incidencesModels[rowStart]);
    }
    default:
        Q_ASSERT(false);
        return {};
    }
}

IncidenceOccurrenceModel *MultiDayIncidenceModel::model()
{
    return mSourceModel;
}

void MultiDayIncidenceModel::setModel(IncidenceOccurrenceModel *model)
{
    beginResetModel();

    mSourceModel = model;
    Q_EMIT modelChanged();

    for (auto incidencesModel : m_incidencesModels) {
        incidencesModel->setModel(mSourceModel);
    }
    endResetModel();
}

int MultiDayIncidenceModel::periodLength()
{
    return mPeriodLength;
}

void MultiDayIncidenceModel::setPeriodLength(int periodLength)
{
    mPeriodLength = periodLength;
}

MultiDayIncidenceModel::Filters MultiDayIncidenceModel::filters()
{
    return m_filters;
}

void MultiDayIncidenceModel::setFilters(MultiDayIncidenceModel::Filters filters)
{
    beginResetModel();
    m_filters = filters;

    for (auto incidencesModel : m_incidencesModels) {
        incidencesModel->setFilters(filters);
    }

    Q_EMIT filtersChanged();
    endResetModel();
}

QHash<int, QByteArray> MultiDayIncidenceModel::roleNames() const
{
    return {
        {Incidences, "incidences"},
        {PeriodStartDate, "periodStartDate"},
    };
}

Q_DECLARE_METATYPE(ViewIncidencesModel *);
