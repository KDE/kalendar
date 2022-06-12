/*
    Copyright (c) 2016 Christian Mollekopf <mollekopf@kolabsys.com>

    This library is free software; you can redistribute it and/or modify it
    under the terms of the GNU Library General Public License as published by
    the Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    This library is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
    License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to the
    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301, USA.
*/
#include "messageparser.h"

#include "../mimetreeparser/objecttreeparser.h"
#include <Akonadi/Item>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <QElapsedTimer>

#include "async.h"
#include "attachmentmodel.h"
#include "partmodel.h"

class MessagePartPrivate
{
public:
    std::shared_ptr<MimeTreeParser::ObjectTreeParser> mParser;
};

MessageParser::MessageParser(QObject *parent)
    : QObject(parent)
    , d(std::unique_ptr<MessagePartPrivate>(new MessagePartPrivate))
{
}

MessageParser::~MessageParser()
{
}

Akonadi::Item MessageParser::item() const
{
    return {};
}

void MessageParser::setItem(const Akonadi::Item &item)
{
    auto job = new Akonadi::ItemFetchJob(item);
    job->fetchScope().fetchFullPayload();
    connect(job, &Akonadi::ItemFetchJob::result, this, [this](KJob *job) {
        auto fetchJob = qobject_cast<Akonadi::ItemFetchJob *>(job);
        auto item = fetchJob->items().at(0);
        if (item.hasPayload<KMime::Message::Ptr>()) {
            const auto message = item.payload<KMime::Message::Ptr>();
            QElapsedTimer time;
            time.start();
            auto parser = std::make_shared<MimeTreeParser::ObjectTreeParser>();
            parser->parseObjectTree(message.data());
            qDebug() << "Message parsing took: " << time.elapsed();
            parser->decryptParts();
            qDebug() << "Message parsing and decryption/verification: " << time.elapsed();
            d->mParser = parser;
            Q_EMIT htmlChanged();
        } else {
            qWarning() << "This is not a mime item.";
        }
    });
}

QString MessageParser::rawContent() const
{
    return mRawContent;
}

bool MessageParser::loaded() const
{
    return bool{d->mParser};
}

QString MessageParser::structureAsString() const
{
    if (!d->mParser) {
        return QString();
    }
    return d->mParser->structureAsString();
}

QAbstractItemModel *MessageParser::parts() const
{
    if (!d->mParser) {
        return nullptr;
    }
    const auto model = new PartModel(d->mParser);
    return model;
}

QAbstractItemModel *MessageParser::attachments() const
{
    if (!d->mParser) {
        return nullptr;
    }
    const auto model = new AttachmentModel(d->mParser);
    return model;
}
