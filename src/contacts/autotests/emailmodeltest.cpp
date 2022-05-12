// SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: BSD-2-Clause

#include "../emailmodel.h"
#include <KContacts/Email>
#include <KLocalizedString>
#include <QObject>
#include <QtTest/QtTest>

class EmailModelTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
    }

    void testReading()
    {
        KContacts::Email::List emails;
        emails.append(KContacts::Email(QStringLiteral("carl@carlschwan.eu")));
        emails.append(KContacts::Email(QStringLiteral("carl1@carlschwan.eu")));
        KContacts::Email email(QStringLiteral("carl2@carlschwan.eu"));
        email.setPreferred(true);
        email.setType(KContacts::Email::Home);
        emails.append(email);
        EmailModel emailModel;
        emailModel.setEmails(emails);

        QCOMPARE(emailModel.rowCount(), 3);
        QCOMPARE(emailModel.data(emailModel.index(2, 0), Qt::DisplayRole).toString(), QStringLiteral("carl2@carlschwan.eu"));
        QCOMPARE(emailModel.data(emailModel.index(2, 0), EmailModel::DefaultRole).toBool(), true);
        QCOMPARE(emailModel.data(emailModel.index(2, 0), EmailModel::TypeRole).toString(), i18n("Home:"));
    }
};

QTEST_MAIN(EmailModelTest)
#include "emailmodeltest.moc"
