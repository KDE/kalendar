/*
   SPDX-FileCopyrightText: 2014-2022 Laurent Montel <montel@kde.org>

   SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "followupreminderselectdatedialog.h"

#include <KDateComboBox>
#include <KLocalizedString>
#include <KMessageBox>
#include <KSharedConfig>

#include <Akonadi/CollectionComboBox>

#include <KCalendarCore/Todo>

#include <QDialogButtonBox>
#include <QFormLayout>
#include <QLineEdit>
#include <QVBoxLayout>
using namespace MessageComposer;
class MessageComposer::FollowUpReminderSelectDateDialogPrivate
{
public:
    KDateComboBox *mDateComboBox = nullptr;
    Akonadi::CollectionComboBox *mCollectionCombobox = nullptr;
    QPushButton *mOkButton = nullptr;
};

FollowUpReminderSelectDateDialog::FollowUpReminderSelectDateDialog(QWidget *parent, QAbstractItemModel *model)
    : QDialog(parent)
    , d(new MessageComposer::FollowUpReminderSelectDateDialogPrivate)
{
    setWindowTitle(i18nc("@title:window", "Select Date"));
    auto topLayout = new QVBoxLayout(this);

    auto buttonBox = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, this);
    d->mOkButton = buttonBox->button(QDialogButtonBox::Ok);
    d->mOkButton->setObjectName(QStringLiteral("ok_button"));
    d->mOkButton->setDefault(true);
    d->mOkButton->setShortcut(Qt::CTRL | Qt::Key_Return);
    connect(buttonBox, &QDialogButtonBox::accepted, this, &FollowUpReminderSelectDateDialog::accept);
    connect(buttonBox, &QDialogButtonBox::rejected, this, &FollowUpReminderSelectDateDialog::reject);
    setModal(true);

    auto mainWidget = new QWidget(this);
    topLayout->addWidget(mainWidget);
    topLayout->addWidget(buttonBox);
    auto mainLayout = new QVBoxLayout(mainWidget);
    mainLayout->setContentsMargins({});
    auto formLayout = new QFormLayout;
    formLayout->setContentsMargins({});
    mainLayout->addLayout(formLayout);

    d->mDateComboBox = new KDateComboBox;
    QDate currentDate = QDate::currentDate().addDays(1);
    d->mDateComboBox->setMinimumDate(QDate::currentDate());
    d->mDateComboBox->setObjectName(QStringLiteral("datecombobox"));

    d->mDateComboBox->setDate(currentDate);

    formLayout->addRow(i18n("Date:"), d->mDateComboBox);

    d->mCollectionCombobox = new Akonadi::CollectionComboBox(model);
    d->mCollectionCombobox->setMinimumWidth(250);
    d->mCollectionCombobox->setAccessRightsFilter(Akonadi::Collection::CanCreateItem);
    d->mCollectionCombobox->setMimeTypeFilter(QStringList() << KCalendarCore::Todo::todoMimeType());
    d->mCollectionCombobox->setObjectName(QStringLiteral("collectioncombobox"));

    formLayout->addRow(i18n("Store to-do in:"), d->mCollectionCombobox);

    connect(d->mDateComboBox->lineEdit(), &QLineEdit::textChanged, this, &FollowUpReminderSelectDateDialog::slotDateChanged);
    connect(d->mCollectionCombobox, qOverload<int>(&Akonadi::CollectionComboBox::currentIndexChanged), this, &FollowUpReminderSelectDateDialog::updateOkButton);
    updateOkButton();
}

FollowUpReminderSelectDateDialog::~FollowUpReminderSelectDateDialog() = default;

void FollowUpReminderSelectDateDialog::updateOkButton()
{
    d->mOkButton->setEnabled(!d->mDateComboBox->lineEdit()->text().isEmpty() && d->mDateComboBox->date().isValid() && (d->mCollectionCombobox->count() > 0)
                             && d->mCollectionCombobox->currentCollection().isValid());
}

void FollowUpReminderSelectDateDialog::slotDateChanged()
{
    updateOkButton();
}

QDate FollowUpReminderSelectDateDialog::selectedDate() const
{
    return d->mDateComboBox->date();
}

Akonadi::Collection FollowUpReminderSelectDateDialog::collection() const
{
    return d->mCollectionCombobox->currentCollection();
}

void FollowUpReminderSelectDateDialog::accept()
{
    const QDate date = selectedDate();
    if (date < QDate::currentDate()) {
        KMessageBox::error(this, i18n("The selected date must be greater than the current date."), i18n("Invalid date"));
        return;
    }
    if (!d->mCollectionCombobox->currentCollection().isValid()) {
        KMessageBox::error(this, i18n("The selected folder is not valid."), i18n("Invalid folder"));
        return;
    }
    QDialog::accept();
}
