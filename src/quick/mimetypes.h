// SPDX-FileCopyrightText: 2007-2009 Tobias Koenig <tokoe@kde.org>
// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
namespace Akonadi
{
namespace Quick
{
class MimeTypes : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString calendar READ calendar CONSTANT)
    Q_PROPERTY(QString todo READ todo CONSTANT)
    Q_PROPERTY(QString address READ address CONSTANT)
    Q_PROPERTY(QString contactGroup READ contactGroup CONSTANT)
    Q_PROPERTY(QString mail READ mail CONSTANT)

public:
    MimeTypes(QObject *parent = nullptr);
    QString calendar() const;
    QString todo() const;
    QString address() const;
    QString contactGroup() const;
    QString mail() const;
};
}
}
