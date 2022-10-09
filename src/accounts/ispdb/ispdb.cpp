/*
    SPDX-FileCopyrightText: 2010 Omat Holding B.V. <info@omat.nl>
    SPDX-FileCopyrightText: 2014 Sandro Knauß <knauss@kolabsys.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// This code was taken from kmail-account-wizard

#include "ispdb.h"
#include <KLocalizedString>
#include <kio/jobclasses.h>

#include <QDebug>
#include <QDomDocument>

Ispdb::Ispdb(QObject *parent)
    : QObject(parent)
    , mDefaultIdentity(-1)
    , mServerType(DataBase)
    , mStart(true)
{
}

Ispdb::~Ispdb() = default;

void Ispdb::setEmail(const QString &address)
{
    KMime::Types::Mailbox box;
    box.fromUnicodeString(address);
    mAddr = box.addrSpec();
}

void Ispdb::setPassword(const QString &password)
{
    mPassword = password;
}

void Ispdb::start()
{
    qDebug() << mAddr.asString();
    // we should do different things in here. But lets focus in the db first.
    lookupInDb(false, false);
}

void Ispdb::lookupInDb(bool auth, bool crypt)
{
    setServerType(mServerType);
    startJob(lookupUrl(QStringLiteral("mail"), QStringLiteral("1.1"), auth, crypt));
}

void Ispdb::startJob(const QUrl &url)
{
    mData.clear();
    QMap<QString, QVariant> map;
    map[QStringLiteral("errorPage")] = false;

    KIO::TransferJob *job = KIO::get(url, KIO::NoReload, KIO::HideProgressInfo);
    job->setMetaData(map);
    connect(job, &KIO::TransferJob::result, this, &Ispdb::slotResult);
    connect(job, &KIO::TransferJob::data, this, &Ispdb::dataArrived);
}

QUrl Ispdb::lookupUrl(const QString &type, const QString &version, bool auth, bool crypt)
{
    QUrl url;
    const QString path = type + QStringLiteral("/config-v") + version + QStringLiteral(".xml");
    switch (mServerType) {
    case IspAutoConfig:
        url = QUrl(QStringLiteral("http://autoconfig.") + mAddr.domain.toLower() + QLatin1Char('/') + path);
        break;
    case IspWellKnow:
        url = QUrl(QStringLiteral("http://") + mAddr.domain.toLower() + QStringLiteral("/.well-known/autoconfig/") + path);
        break;
    case DataBase:
        url = QUrl(QStringLiteral("https://autoconfig.thunderbird.net/v1.1/") + mAddr.domain.toLower());
        break;
    }
    if (mServerType != DataBase) {
        if (crypt) {
            url.setScheme(QStringLiteral("https"));
        }

        if (auth) {
            url.setUserName(mAddr.asString());
            url.setPassword(mPassword);
        }
    }
    return url;
}

void Ispdb::slotResult(KJob *job)
{
    if (job->error()) {
        qDebug() << "Fetching failed" << job->errorString();
        bool lookupFinished = false;

        switch (mServerType) {
        case IspAutoConfig:
            mServerType = IspWellKnow;
            break;
        case IspWellKnow:
            lookupFinished = true;
            break;
        case DataBase:
            mServerType = IspAutoConfig;
            break;
        }

        if (lookupFinished) {
            Q_EMIT finished(false);
            return;
        }
        lookupInDb(false, false);
        return;
    }

    // qCDebug(ACCOUNTWIZARD_LOG) << mData;
    QDomDocument document;
    bool ok = document.setContent(mData);
    if (!ok) {
        qDebug() << "Could not parse xml" << mData;
        Q_EMIT finished(false);
        return;
    }

    parseResult(document);
}

void Ispdb::parseResult(const QDomDocument &document)
{
    QDomElement docElem = document.documentElement();
    QDomNodeList l = docElem.elementsByTagName(QStringLiteral("emailProvider"));

    if (l.isEmpty()) {
        Q_EMIT finished(false);
        return;
    }

    // only handle the first emailProvider entry
    QDomNode firstProvider = l.at(0);
    QDomNode n = firstProvider.firstChild();
    while (!n.isNull()) {
        QDomElement e = n.toElement();
        if (!e.isNull()) {
            // qCDebug(ACCOUNTWIZARD_LOG)  << qPrintable(e.tagName());
            const QString tagName(e.tagName());
            if (tagName == QLatin1String("domain")) {
                mDomains << e.text();
            } else if (tagName == QLatin1String("displayName")) {
                mDisplayName = e.text();
            } else if (tagName == QLatin1String("displayShortName")) {
                mDisplayShortName = e.text();
            } else if (tagName == QLatin1String("incomingServer") && e.attribute(QStringLiteral("type")) == QLatin1String("imap")) {
                Server s = createServer(e);
                if (s.isValid()) {
                    mImapServers.append(s);
                }
            } else if (tagName == QLatin1String("incomingServer") && e.attribute(QStringLiteral("type")) == QLatin1String("pop3")) {
                Server s = createServer(e);
                if (s.isValid()) {
                    mPop3Servers.append(s);
                }
            } else if (tagName == QLatin1String("outgoingServer") && e.attribute(QStringLiteral("type")) == QLatin1String("smtp")) {
                Server s = createServer(e);
                if (s.isValid()) {
                    mSmtpServers.append(s);
                }
            } else if (tagName == QLatin1String("identity")) {
                identity i = createIdentity(e);
                if (i.isValid()) {
                    mIdentities.append(i);
                    if (i.isDefault()) {
                        mDefaultIdentity = mIdentities.count() - 1;
                    }
                }
            }
        }
        n = n.nextSibling();
    }

    // comment this section out when you are tired of it...
    qDebug() << "------------------ summary --------------";
    qDebug() << "Domains" << mDomains;
    qDebug() << "Name" << mDisplayName << "(" << mDisplayShortName << ")";
    qDebug() << "Imap servers:";
    for (const Server &s : std::as_const(mImapServers)) {
        qDebug() << s.hostname << s.port << s.socketType << s.username << s.authentication;
    }
    qDebug() << "pop3 servers:";
    for (const Server &s : std::as_const(mPop3Servers)) {
        qDebug() << s.hostname << s.port << s.socketType << s.username << s.authentication;
    }
    qDebug() << "smtp servers:";
    for (const Server &s : std::as_const(mSmtpServers)) {
        qDebug() << s.hostname << s.port << s.socketType << s.username << s.authentication;
    }
    // end section.

    Q_EMIT finished(true);
}

Server Ispdb::createServer(const QDomElement &n)
{
    QDomNode o = n.firstChild();
    Server s;
    while (!o.isNull()) {
        QDomElement f = o.toElement();
        if (!f.isNull()) {
            const QString tagName(f.tagName());
            if (tagName == QLatin1String("hostname")) {
                s.hostname = replacePlaceholders(f.text());
            } else if (tagName == QLatin1String("port")) {
                s.port = f.text().toInt();
            } else if (tagName == QLatin1String("socketType")) {
                const QString type(f.text());
                if (type == QLatin1String("plain")) {
                    s.socketType = None;
                } else if (type == QLatin1String("SSL")) {
                    s.socketType = SSL;
                }
                if (type == QLatin1String("STARTTLS")) {
                    s.socketType = StartTLS;
                }
            } else if (tagName == QLatin1String("username")) {
                s.username = replacePlaceholders(f.text());
            } else if (tagName == QLatin1String("authentication") && s.authentication == 0) {
                const QString type(f.text());
                if (type == QLatin1String("password-cleartext") || type == QLatin1String("plain")) {
                    s.authentication = Plain;
                } else if (type == QLatin1String("password-encrypted") || type == QLatin1String("secure")) {
                    s.authentication = CramMD5;
                } else if (type == QLatin1String("NTLM")) {
                    s.authentication = NTLM;
                } else if (type == QLatin1String("GSSAPI")) {
                    s.authentication = GSSAPI;
                } else if (type == QLatin1String("client-ip-based")) {
                    s.authentication = ClientIP;
                } else if (type == QLatin1String("none")) {
                    s.authentication = NoAuth;
                } else if (type == QLatin1String("OAuth2")) {
                    s.authentication = OAuth2;
                }
            }
        }
        o = o.nextSibling();
    }
    return s;
}

identity Ispdb::createIdentity(const QDomElement &n)
{
    QDomNode o = n.firstChild();
    identity i;

    // type="kolab" version="1.0" is the only identity that is defined
    if (n.attribute(QStringLiteral("type")) != QLatin1String("kolab") || n.attribute(QStringLiteral("version")) != QLatin1String("1.0")) {
        qDebug() << "unknown type of identity element.";
    }

    while (!o.isNull()) {
        QDomElement f = o.toElement();
        if (!f.isNull()) {
            const QString tagName(f.tagName());
            if (tagName == QLatin1String("default")) {
                i.mDefault = f.text().toLower() == QLatin1String("true");
            } else if (tagName == QLatin1String("email")) {
                i.email = f.text();
            } else if (tagName == QLatin1String("name")) {
                i.name = f.text();
            } else if (tagName == QLatin1String("organization")) {
                i.organization = f.text();
            } else if (tagName == QLatin1String("signature")) {
                QTextStream stream(&i.signature);
                f.save(stream, 0);
                i.signature = i.signature.trimmed();
                if (i.signature.startsWith(QLatin1String("<signature>"))) {
                    i.signature = i.signature.mid(11, i.signature.length() - 23);
                    i.signature = i.signature.trimmed();
                }
            }
        }
        o = o.nextSibling();
    }

    return i;
}

QString Ispdb::replacePlaceholders(const QString &in)
{
    QString out(in);
    out.replace(QLatin1String("%EMAILLOCALPART%"), mAddr.localPart);
    out.replace(QLatin1String("%EMAILADDRESS%"), mAddr.asString());
    out.replace(QLatin1String("%EMAILDOMAIN%"), mAddr.domain);
    return out;
}

void Ispdb::dataArrived(KIO::Job *, const QByteArray &data)
{
    mData.append(data);
}

// The getters

QStringList Ispdb::relevantDomains() const
{
    return mDomains;
}

QString Ispdb::name(length l) const
{
    if (l == Long) {
        return mDisplayName;
    } else if (l == Short) {
        return mDisplayShortName;
    } else {
        return {}; // make compiler happy. Not me.
    }
}

QVector<Server> Ispdb::imapServers() const
{
    return mImapServers;
}

QVector<Server> Ispdb::pop3Servers() const
{
    return mPop3Servers;
}

QVector<Server> Ispdb::smtpServers() const
{
    return mSmtpServers;
}

int Ispdb::defaultIdentity() const
{
    return mDefaultIdentity;
}

QVector<identity> Ispdb::identities() const
{
    return mIdentities;
}

void Ispdb::setServerType(Ispdb::searchServerType type)
{
    if (type != mServerType || mStart) {
        mServerType = type;
        mStart = false;
        switch (mServerType) {
        case IspAutoConfig:
            Q_EMIT searchType(i18n("Lookup configuration: Email provider"));
            break;
        case IspWellKnow:
            Q_EMIT searchType(i18n("Lookup configuration: Trying common server name"));
            break;
        case DataBase:
            Q_EMIT searchType(i18n("Lookup configuration: Mozilla database"));
            break;
        }
    }
}

Ispdb::searchServerType Ispdb::serverType() const
{
    return mServerType;
}

QDebug operator<<(QDebug d, const Server &t)
{
    d << "authentication " << t.authentication;
    d << "socketType " << t.socketType;
    d << "hostname " << t.hostname;
    d << "username " << t.username;
    d << "port " << t.port;
    return d;
}

QDebug operator<<(QDebug d, const identity &t)
{
    d << " email " << t.email;
    d << " name " << t.name;
    d << " organization " << t.organization;
    d << " signature " << t.signature;
    d << " isDefault " << t.mDefault;
    return d;
}
