// SPDX-FileCopyrightText: 2021 Simon Schmeisser <s.schmeisser@gmx.net>
// SPDX-FileCopyrightText: 2021 Carl Schwan <carlschwan@kde.org>
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QIdentityProxyModel>
#include <QItemSelectionModel>

//class ViewerHelper;

class MailModel : public QIdentityProxyModel
{
    Q_OBJECT

//    Q_PROPERTY(ViewerHelper *viewerHelper READ viewerHelper WRITE setViewerHelper NOTIFY viewerHelperChanged)

public:
    enum AnimalRoles {
        TitleRole = Qt::UserRole + 1,
        SenderRole,
        TextColorRole,
        DateRole,
        DateTimeRole,
        BackgroundColorRole,
        UnreadRole,
        MailRole,
        FavoriteRole,
    };

    //    ViewerHelper *viewerHelper() const;
    //    void setViewerHelper(ViewerHelper *viewerHelper);

    explicit MailModel(QObject *parent = nullptr);
    QHash<int, QByteArray> roleNames() const override;
    virtual QVariant data(const QModelIndex &index, int role) const override;

    Q_INVOKABLE void loadItem(int row);

///Q_SIGNALS:
///    void viewerHelperChanged();
///
///private:
///    ViewerHelper *m_viewerHelper = nullptr;
};
