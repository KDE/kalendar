// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <KLocalizedString>
#include <QDBusConnection>
#include <kalendar_part.h>

K_PLUGIN_CLASS_WITH_JSON(KalendarPart, "kalendar_part.json")

KalendarPart::KalendarPart(QWidget *parentWidget, QObject *parent, const QVariantList &)
    : KParts::Part(parent)
{
    setComponentName(QStringLiteral("kalendar"), i18n("Kalendar"));
    // setXMLFile(QStringLiteral("kalendar_part.rc"), true);
    //(void)new PartAdaptor(this);

    m_widget = new QQuickWidget;
    m_widget->setSource(QUrl(QStringLiteral("qrc:///main.qml")));
    m_widget->show();

    setWidget(m_widget);
}

#include "kalendar_part.moc"
