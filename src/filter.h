// SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <QObject>

/**
 * This class is used to enable cross-compatible filtering of data in models.
 */
class Filter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qint64 collectionId READ collectionId WRITE setCollectionId NOTIFY collectionIdChanged)
    Q_PROPERTY(QStringList tags READ tags WRITE setTags NOTIFY tagsChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)

public:
    qint64 collectionId() const;
    QStringList tags() const;
    QString name() const;

public Q_SLOTS:
    void setCollectionId(const qint64 collectionId);
    void setTags(const QStringList tags);
    void setName(const QString &name);

    void toggleFilterTag(const QString tagName);
    void reset();
    void removeTag(const QString &tagName);

Q_SIGNALS:
    void collectionIdChanged();
    void tagsChanged();
    void nameChanged();

private:
    qint64 m_collectionId = -1;
    QStringList m_tags;
    QString m_name;
};
