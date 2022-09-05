// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "filter.h"

qint64 Filter::collectionId() const
{
    return m_collectionId;
}

QStringList Filter::tags() const
{
    return m_tags;
}

QString Filter::name() const
{
    return m_name;
}

void Filter::setCollectionId(qint64 collectionId)
{
    if (m_collectionId == collectionId) {
        return;
    }
    m_collectionId = collectionId;
    Q_EMIT collectionIdChanged();
}

void Filter::setTags(QStringList tags)
{
    if (m_tags == tags) {
        return;
    }
    m_tags = tags;
    Q_EMIT tagsChanged();
}

void Filter::setName(const QString &name)
{
    if (m_name == name) {
        return;
    }
    m_name = name;
    Q_EMIT nameChanged();
}

void Filter::toggleFilterTag(const QString tagName)
{
    if (!m_tags.contains(tagName)) {
        m_tags.append(tagName);
        Q_EMIT tagsChanged();
    } else {
        m_tags.removeAll(tagName);
        Q_EMIT tagsChanged();
    }
}

void Filter::removeTag(const QString &tagName)
{
    m_tags.removeAll(tagName);
    Q_EMIT tagsChanged();
}

void Filter::reset()
{
    setName({});
    setTags({});
    setCollectionId(-1);
}
