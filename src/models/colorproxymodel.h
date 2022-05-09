// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-FileCopyrightText: 2022 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <Akonadi/EntityTreeModel>
#include <EventViews/Prefs>
#include <QSortFilterProxyModel>

/// Despite the name, this handles the presentation of collections including display text and icons, not just colors.
class ColorProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT

public:
    enum Roles {
        isResource = Akonadi::EntityTreeModel::UserRole + 1,
    };
    Q_ENUM(Roles);

    explicit ColorProxyModel(QObject *parent = nullptr);
    QVariant data(const QModelIndex &index, int role) const override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QHash<int, QByteArray> roleNames() const override;
    QColor getCollectionColor(Akonadi::Collection collection) const;
    void load();
    void save() const;
    mutable QHash<QString, QColor> colorCache;

private:
    mutable bool mInitDefaultCalendar;
    EventViews::PrefsPtr mEventViewsPrefs;
};
