// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <abstractapplication.h>

class MailApplication : public AbstractApplication
{
    Q_OBJECT

public:
    explicit MailApplication(QObject *parent = nullptr);

    QVector<KActionCollection *> actionCollections() const override;

Q_SIGNALS:
    void createNewMail();

private:
    void setupActions() override;
};
