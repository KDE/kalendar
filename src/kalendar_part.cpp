// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <KLocalizedString>
#include <QDBusConnection>
#include <kalendar_part.h>
#include <partadaptor.h>

K_PLUGIN_FACTORY(KalendarPartFactory, registerPlugin<KalendarPart>();) // produce a factory

KalendarPart::KalendarPart(QWidget *parentWidget, QObject *parent, const QVariantList &)
    : KParts::Part(parent)
{
    setComponentName(QStringLiteral("kalendar"), i18n("Kalendar"));
    setXMLFile(QStringLiteral("kalendar_part.rc"), true);
    // we need an instance
    (void)new PartAdaptor(this);
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/Kalendar"), this);

    m_widget = new QQuickWidget;
    m_widget->setSource(QUrl(QStringLiteral("qrc:///main.qml")));
    m_widget->show();
    setWidget(m_widget);
}

#include "kalendar_part.moc"
