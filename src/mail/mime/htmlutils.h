// SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <QString>
#include <QTextDocument>

namespace HtmlUtils
{
QString linkify(const QString &in);

class HtmlUtils : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE QString linkify(const QString &s)
    {
        return ::HtmlUtils::linkify(s);
    };

    Q_INVOKABLE QString toHtml(const QString &s)
    {
        if (Qt::mightBeRichText(s)) {
            return s;
        } else {
            return ::HtmlUtils::linkify(Qt::convertFromPlainText(s));
        }
    }
};
}
