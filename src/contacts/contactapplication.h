// SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <abstractapplication.h>

class ContactApplication : public AbstractApplication
{
    Q_OBJECT

public:
    explicit ContactApplication(QObject *parent = nullptr);

    QVector<KActionCollection *> actionCollections() const override;

Q_SIGNALS:
    void createNewContact();
    void createNewContactGroup();
    void refreshAll();

private:
    void setupActions() override;
    KActionCollection *mContactCollection = nullptr;
};
