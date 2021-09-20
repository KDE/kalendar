// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <AkonadiCore/TagModel>
#include <AkonadiCore/Monitor>
#include <QSortFilterProxyModel>
#include <KDescendantsProxyModel>

class TagManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSortFilterProxyModel *tagModel READ tagModel CONSTANT)

public:
    TagManager(QObject *parent = nullptr);
    ~TagManager() = default;

    QSortFilterProxyModel *tagModel();
    Q_INVOKABLE void createTag(const QString &name);
    Q_INVOKABLE void renameTag(Akonadi::Tag tag, const QString &newName);
    Q_INVOKABLE void deleteTag(Akonadi::Tag tag);

private:
    QSortFilterProxyModel *m_tagModel = nullptr;
};
