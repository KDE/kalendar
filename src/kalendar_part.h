// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include <KParts/Part>
#include <KPluginFactory>
#include <QtQuickWidgets/QQuickWidget>

class KalendarPart : public KParts::Part
{
    Q_OBJECT

public:
    KalendarPart(QWidget *parentWidget, QObject *parent, const QVariantList &);
    virtual ~KalendarPart(){};

private:
    QQuickWidget *m_widget;
};
