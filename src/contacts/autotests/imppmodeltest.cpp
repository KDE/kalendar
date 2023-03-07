// SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: BSD-2-Clause

#include "../imppmodel.h"
#include <KContacts/Impp>
#include <KLocalizedString>
#include <QObject>
#include <QtTest/QtTest>

class ImppModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        KContacts::Addressee addressee;
        KContacts::Impp::List impps;
        impps.append(KContacts::Impp(QUrl{QStringLiteral("matrix:@carl:kde.org")}));
        impps.append(KContacts::Impp(QUrl{QStringLiteral("matrix:@carl2:kde.org")}));
        addressee.setImppList(impps);
        ImppModel imppModel;
        imppModel.loadContact(addressee);

        QCOMPARE(imppModel.rowCount(), 2);
        QCOMPARE(imppModel.data(imppModel.index(1, 0), ImppModel::UrlRole).toString(), QStringLiteral("matrix:@carl2:kde.org"));
    }
};

QTEST_MAIN(ImppModelTest)
#include "imppmodeltest.moc"
