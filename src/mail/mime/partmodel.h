// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>

#include <QAbstractItemModel>
#include <QModelIndex>

#include <memory>

namespace MimeTreeParser
{
class ObjectTreeParser;
}
class PartModelPrivate;

class PartModel : public QAbstractItemModel
{
    Q_OBJECT
    Q_PROPERTY(bool showHtml READ showHtml WRITE setShowHtml NOTIFY showHtmlChanged)
    Q_PROPERTY(bool containsHtml READ containsHtml NOTIFY containsHtmlChanged)
    Q_PROPERTY(bool trimMail READ trimMail WRITE setTrimMail NOTIFY trimMailChanged)
    Q_PROPERTY(bool isTrimmed READ isTrimmed NOTIFY trimMailChanged)
public:
    PartModel(std::shared_ptr<MimeTreeParser::ObjectTreeParser> parser);
    ~PartModel();

    static std::pair<QString, bool> trim(const QString &text);

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        ContentRole,
        IsEmbeddedRole,
        IsEncryptedRole,
        IsSignedRole,
        IsErrorRole,
        SecurityLevelRole,
        EncryptionSecurityLevelRole,
        SignatureSecurityLevelRole,
        SignatureDetails,
        EncryptionDetails,
        ErrorType,
        ErrorString,
        SenderRole,
        DateRole
    };

    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    QModelIndex parent(const QModelIndex &index) const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    int columnCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;

    void setShowHtml(bool html);
    bool showHtml() const;
    bool containsHtml() const;

    void setTrimMail(bool trim);
    bool trimMail() const;
    bool isTrimmed() const;

Q_SIGNALS:
    void showHtmlChanged();
    void trimMailChanged();
    void containsHtmlChanged();

private:
    std::unique_ptr<PartModelPrivate> d;
};

class SignatureInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QByteArray keyId MEMBER keyId CONSTANT)
    Q_PROPERTY(bool keyMissing MEMBER keyMissing CONSTANT)
    Q_PROPERTY(bool keyRevoked MEMBER keyRevoked CONSTANT)
    Q_PROPERTY(bool keyExpired MEMBER keyExpired CONSTANT)
    Q_PROPERTY(bool sigExpired MEMBER sigExpired CONSTANT)
    Q_PROPERTY(bool crlMissing MEMBER crlMissing CONSTANT)
    Q_PROPERTY(bool crlTooOld MEMBER crlTooOld CONSTANT)

    Q_PROPERTY(QString signer MEMBER signer CONSTANT)
    Q_PROPERTY(QStringList signerMailAddresses MEMBER signerMailAddresses CONSTANT)
    Q_PROPERTY(bool signatureIsGood MEMBER signatureIsGood CONSTANT)
    Q_PROPERTY(bool keyIsTrusted MEMBER keyIsTrusted CONSTANT)

public:
    bool keyRevoked = false;
    bool keyExpired = false;
    bool sigExpired = false;
    bool keyMissing = false;
    bool crlMissing = false;
    bool crlTooOld = false;
    QByteArray keyId;

    QString signer;
    QStringList signerMailAddresses;
    bool signatureIsGood = false;
    bool keyIsTrusted = false;
};
