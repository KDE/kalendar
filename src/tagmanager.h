// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include <QObject>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/TagModel>
#include <Akonadi/Monitor>
#else
#include <AkonadiCore/TagModel>
#include <AkonadiCore/Monitor>
#endif
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
