// SPDX-FileCopyrightText: 2016 Christian Mollekopf <mollekopf@kolabsys.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include "mailcrypto.h"
#include <KMime/Message>
#include <QByteArray>
#include <QStringList>
#include <functional>

struct Attachment {
    QString name;
    QString filename;
    QByteArray mimeType;
    bool isInline;
    QByteArray data;
};

struct Recipients {
    QStringList to;
    QStringList cc;
    QStringList bcc;
};

namespace MailTemplates
{
void reply(const KMime::Message::Ptr &origMsg,
           const std::function<void(const KMime::Message::Ptr &result)> &callback,
           const KMime::Types::AddrSpecList &me = {});
void forward(const KMime::Message::Ptr &origMsg, const std::function<void(const KMime::Message::Ptr &result)> &callback);
QString plaintextContent(const KMime::Message::Ptr &origMsg);
QString body(const KMime::Message::Ptr &msg, bool &isHtml);
KMime::Message::Ptr createMessage(KMime::Message::Ptr existingMessage,
                                  const QStringList &to,
                                  const QStringList &cc,
                                  const QStringList &bcc,
                                  const KMime::Types::Mailbox &from,
                                  const QString &subject,
                                  const QString &body,
                                  bool htmlBody,
                                  const QList<Attachment> &attachments,
                                  const std::vector<Crypto::Key> &signingKeys = {},
                                  const std::vector<Crypto::Key> &encryptionKeys = {},
                                  const Crypto::Key &attachedKey = {});

KMime::Message::Ptr
createIMipMessage(const QString &from, const Recipients &recipients, const QString &subject, const QString &body, const QString &attachment);
};
