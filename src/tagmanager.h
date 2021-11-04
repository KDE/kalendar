// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once
#include <QObject>
#include <akonadi_version.h>
#if AKONADI_VERSION >= QT_VERSION_CHECK(5, 18, 41)
#include <Akonadi/Monitor>
#include <Akonadi/TagModel>
#else
#include <AkonadiCore/Monitor>
#include <AkonadiCore/TagModel>
#endif
#include <KDescendantsProxyModel>
#include <QSortFilterProxyModel>

class TagManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QSortFilterProxyModel *tagModel READ tagModel NOTIFY tagModelChanged)

public:
    TagManager(QObject *parent = nullptr);
    ~TagManager() override = default;

    QSortFilterProxyModel *tagModel();
    Q_INVOKABLE void createTag(const QString &name);
    Q_INVOKABLE void renameTag(Akonadi::Tag tag, const QString &newName);
    Q_INVOKABLE void deleteTag(Akonadi::Tag tag);

Q_SIGNALS:
    void tagModelChanged();

private:
    QSortFilterProxyModel *m_tagModel = nullptr;
};
