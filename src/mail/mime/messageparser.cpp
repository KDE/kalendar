// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

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
        const auto items = fetchJob->items();
        if (items.count() == 0) {
            qWarning() << "Empty fetch job result";
            return;
        }
        const auto item = items.at(0);
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
