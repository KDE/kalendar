/*
    This file is part of Akonadi.
    SPDX-FileCopyrightText: 2003 Andreas Gungl <a.gungl@gmx.de>
    SPDX-FileCopyrightText: 2010 Klarälvdalens Datakonsult AB, a KDAB Group company <info@kdab.com>
    SPDX-FileCopyrightText: 2010 Leo Franchi <lfranchi@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include "messagestatus.h"

#include <Akonadi/MessageFlags>

#include <QString>

using namespace Akonadi;

/** The message status format. These can be or'd together.
    Note, that the StatusIgnored implies the
    status to be Read.
    This is done in isRead() and related getters.
    So we can preserve the state when switching a
    thread to Ignored and back. */
enum Status {
    StatusUnknown = 0x00000000,
    StatusUnread = 0x00000002, // deprecated
    StatusRead = 0x00000004,
    StatusDeleted = 0x00000010,
    StatusReplied = 0x00000020,
    StatusForwarded = 0x00000040,
    StatusQueued = 0x00000080,
    StatusSent = 0x00000100,
    StatusFlag = 0x00000200, // flag means important
    StatusWatched = 0x00000400,
    StatusIgnored = 0x00000800, // forces isRead()
    StatusToAct = 0x00001000,
    StatusSpam = 0x00002000,
    StatusHam = 0x00004000,
    StatusHasAttachment = 0x00008000,
    StatusHasInvitation = 0x00010000,
    StatusSigned = 0x00020000,
    StatusEncrypted = 0x00040000,
    StatusHasError = 0x00080000
};

MessageStatus::MessageStatus()
{
    mStatus = StatusUnknown;
}

bool MessageStatus::operator==(MessageStatus other) const
{
    return mStatus == other.mStatus;
}

bool MessageStatus::operator!=(MessageStatus other) const
{
    return mStatus != other.mStatus;
}

bool MessageStatus::operator&(MessageStatus other) const
{
    if (mStatus == StatusUnread) {
        return !(other.mStatus & StatusRead);
    }

    if (other.mStatus == StatusUnread) {
        return !(mStatus & StatusRead);
    }

    return mStatus & other.mStatus;
}

void MessageStatus::clear()
{
    mStatus = StatusUnknown;
}

void MessageStatus::set(MessageStatus other)
{
    Q_ASSERT(!(other.mStatus & StatusUnread));

    // Those static are exclusive, but we have to lock at the
    // internal representation because Ignored can manipulate
    // the result of the getter methods.
    if (other.mStatus & StatusRead) {
        setRead();
    }
    if (other.isDeleted()) {
        setDeleted();
    }
    if (other.isReplied()) {
        setReplied();
    }
    if (other.isForwarded()) {
        setForwarded();
    }
    if (other.isQueued()) {
        setQueued();
    }
    if (other.isSent()) {
        setSent();
    }
    if (other.isImportant()) {
        setImportant();
    }

    if (other.isWatched()) {
        setWatched();
    }
    if (other.isIgnored()) {
        setIgnored();
    }
    if (other.isToAct()) {
        setToAct();
    }
    if (other.isSpam()) {
        setSpam();
    }
    if (other.isHam()) {
        setHam();
    }
    if (other.hasAttachment()) {
        setHasAttachment();
    }
    if (other.hasInvitation()) {
        setHasInvitation();
    }
    if (other.isSigned()) {
        setSigned();
    }
    if (other.isEncrypted()) {
        setEncrypted();
    }
    if (other.hasError()) {
        setHasError();
    }
}

void MessageStatus::toggle(MessageStatus other)
{
    Q_ASSERT(!(other.mStatus & StatusUnread));

    if (other.isDeleted()) {
        setDeleted(!(mStatus & StatusDeleted));
    }
    if (other.isReplied()) {
        setReplied(!(mStatus & StatusReplied));
    }
    if (other.isForwarded()) {
        setForwarded(!(mStatus & StatusForwarded));
    }
    if (other.isQueued()) {
        setQueued(!(mStatus & StatusQueued));
    }
    if (other.isSent()) {
        setSent(!(mStatus & StatusSent));
    }
    if (other.isImportant()) {
        setImportant(!(mStatus & StatusFlag));
    }

    if (other.isWatched()) {
        setWatched(!(mStatus & StatusWatched));
    }
    if (other.isIgnored()) {
        setIgnored(!(mStatus & StatusIgnored));
    }
    if (other.isToAct()) {
        setToAct(!(mStatus & StatusToAct));
    }
    if (other.isSpam()) {
        setSpam(!(mStatus & StatusSpam));
    }
    if (other.isHam()) {
        setHam(!(mStatus & StatusHam));
    }
    if (other.hasAttachment()) {
        setHasAttachment(!(mStatus & StatusHasAttachment));
    }
    if (other.hasInvitation()) {
        setHasInvitation(!(mStatus & StatusHasInvitation));
    }
    if (other.isSigned()) {
        setSigned(!(mStatus & StatusSigned));
    }
    if (other.isEncrypted()) {
        setEncrypted(!(mStatus & StatusEncrypted));
    }
    if (other.hasError()) {
        setHasError(!(mStatus & StatusHasError));
    }
}

bool MessageStatus::isOfUnknownStatus() const
{
    return mStatus == StatusUnknown;
}

bool MessageStatus::isRead() const
{
    return (mStatus & StatusRead) || (mStatus & StatusIgnored);
}

bool MessageStatus::isDeleted() const
{
    return mStatus & StatusDeleted;
}

bool MessageStatus::isReplied() const
{
    return mStatus & StatusReplied;
}

bool MessageStatus::isForwarded() const
{
    return mStatus & StatusForwarded;
}

bool MessageStatus::isQueued() const
{
    return mStatus & StatusQueued;
}

bool MessageStatus::isSent() const
{
    return mStatus & StatusSent;
}

bool MessageStatus::isImportant() const
{
    return mStatus & StatusFlag;
}

bool MessageStatus::isWatched() const
{
    return mStatus & StatusWatched;
}

bool MessageStatus::isIgnored() const
{
    return mStatus & StatusIgnored;
}

bool MessageStatus::isToAct() const
{
    return mStatus & StatusToAct;
}

bool MessageStatus::isSpam() const
{
    return mStatus & StatusSpam;
}

bool MessageStatus::isHam() const
{
    return mStatus & StatusHam;
}

bool MessageStatus::hasAttachment() const
{
    return mStatus & StatusHasAttachment;
}

bool MessageStatus::hasInvitation() const
{
    return mStatus & StatusHasInvitation;
}

bool MessageStatus::isSigned() const
{
    return mStatus & StatusSigned;
}

bool MessageStatus::isEncrypted() const
{
    return mStatus & StatusEncrypted;
}

bool MessageStatus::hasError() const
{
    return mStatus & StatusHasError;
}

void MessageStatus::setRead(bool read)
{
    if (read) {
        mStatus |= StatusRead;
    } else {
        mStatus &= ~StatusRead;
    }
}

void MessageStatus::setDeleted(bool deleted)
{
    if (deleted) {
        mStatus |= StatusDeleted;
    } else {
        mStatus &= ~StatusDeleted;
    }
}

void MessageStatus::setReplied(bool replied)
{
    if (replied) {
        mStatus |= StatusReplied;
    } else {
        mStatus &= ~StatusReplied;
    }
}

void MessageStatus::setForwarded(bool forwarded)
{
    if (forwarded) {
        mStatus |= StatusForwarded;
    } else {
        mStatus &= ~StatusForwarded;
    }
}

void MessageStatus::setQueued(bool queued)
{
    if (queued) {
        mStatus |= StatusQueued;
    } else {
        mStatus &= ~StatusQueued;
    }
}

void MessageStatus::setSent(bool sent)
{
    if (sent) {
        mStatus &= ~StatusQueued;
        mStatus |= StatusSent;
    } else {
        mStatus &= ~StatusSent;
    }
}

void MessageStatus::setImportant(bool important)
{
    if (important) {
        mStatus |= StatusFlag;
    } else {
        mStatus &= ~StatusFlag;
    }
}

// Watched and ignored are mutually exclusive
void MessageStatus::setWatched(bool watched)
{
    if (watched) {
        mStatus &= ~StatusIgnored;
        mStatus |= StatusWatched;
    } else {
        mStatus &= ~StatusWatched;
    }
}

void MessageStatus::setIgnored(bool ignored)
{
    if (ignored) {
        mStatus &= ~StatusWatched;
        mStatus |= StatusIgnored;
    } else {
        mStatus &= ~StatusIgnored;
    }
}

void MessageStatus::setToAct(bool toAct)
{
    if (toAct) {
        mStatus |= StatusToAct;
    } else {
        mStatus &= ~StatusToAct;
    }
}

// Ham and Spam are mutually exclusive
void MessageStatus::setSpam(bool spam)
{
    if (spam) {
        mStatus &= ~StatusHam;
        mStatus |= StatusSpam;
    } else {
        mStatus &= ~StatusSpam;
    }
}

void MessageStatus::setHam(bool ham)
{
    if (ham) {
        mStatus &= ~StatusSpam;
        mStatus |= StatusHam;
    } else {
        mStatus &= ~StatusHam;
    }
}

void MessageStatus::setHasAttachment(bool withAttachment)
{
    if (withAttachment) {
        mStatus |= StatusHasAttachment;
    } else {
        mStatus &= ~StatusHasAttachment;
    }
}

void MessageStatus::setHasInvitation(bool withInvitation)
{
    if (withInvitation) {
        mStatus |= StatusHasInvitation;
    } else {
        mStatus &= ~StatusHasInvitation;
    }
}

void MessageStatus::setSigned(bool value)
{
    if (value) {
        mStatus |= StatusSigned;
    } else {
        mStatus &= ~StatusSigned;
    }
}

void MessageStatus::setEncrypted(bool value)
{
    if (value) {
        mStatus |= StatusEncrypted;
    } else {
        mStatus &= ~StatusEncrypted;
    }
}

void MessageStatus::setHasError(bool hasError)
{
    if (hasError) {
        mStatus |= StatusHasError;
    } else {
        mStatus &= ~StatusHasError;
    }
}

qint32 MessageStatus::toQInt32() const
{
    return mStatus;
}

void MessageStatus::fromQInt32(qint32 status)
{
    mStatus = status;
}

QString MessageStatus::statusStr() const
{
    QByteArray sstr;
    if (mStatus & StatusRead) {
        sstr += 'R';
    } else {
        sstr += 'U';
    }
    if (mStatus & StatusDeleted) {
        sstr += 'D';
    }
    if (mStatus & StatusReplied) {
        sstr += 'A';
    }
    if (mStatus & StatusForwarded) {
        sstr += 'F';
    }
    if (mStatus & StatusQueued) {
        sstr += 'Q';
    }
    if (mStatus & StatusToAct) {
        sstr += 'K';
    }
    if (mStatus & StatusSent) {
        sstr += 'S';
    }
    if (mStatus & StatusFlag) {
        sstr += 'G';
    }
    if (mStatus & StatusWatched) {
        sstr += 'W';
    }
    if (mStatus & StatusIgnored) {
        sstr += 'I';
    }
    if (mStatus & StatusSpam) {
        sstr += 'P';
    }
    if (mStatus & StatusHam) {
        sstr += 'H';
    }
    if (mStatus & StatusHasAttachment) {
        sstr += 'T';
    }

    return QLatin1String(sstr);
}

void MessageStatus::setStatusFromStr(const QString &aStr)
{
    mStatus = StatusUnknown;

    if (aStr.contains(QLatin1Char('U'))) {
        setRead(false);
    }
    if (aStr.contains(QLatin1Char('R'))) {
        setRead();
    }
    if (aStr.contains(QLatin1Char('D'))) {
        setDeleted();
    }
    if (aStr.contains(QLatin1Char('A'))) {
        setReplied();
    }
    if (aStr.contains(QLatin1Char('F'))) {
        setForwarded();
    }
    if (aStr.contains(QLatin1Char('Q'))) {
        setQueued();
    }
    if (aStr.contains(QLatin1Char('K'))) {
        setToAct();
    }
    if (aStr.contains(QLatin1Char('S'))) {
        setSent();
    }
    if (aStr.contains(QLatin1Char('G'))) {
        setImportant();
    }
    if (aStr.contains(QLatin1Char('W'))) {
        setWatched();
    }
    if (aStr.contains(QLatin1Char('I'))) {
        setIgnored();
    }
    if (aStr.contains(QLatin1Char('P'))) {
        setSpam();
    }
    if (aStr.contains(QLatin1Char('H'))) {
        setHam();
    }
    if (aStr.contains(QLatin1Char('T'))) {
        setHasAttachment();
    }
    if (aStr.contains(QLatin1Char('C'))) {
        setHasAttachment(false);
    }
}

QSet<QByteArray> MessageStatus::statusFlags() const
{
    QSet<QByteArray> flags;

    if (mStatus & StatusDeleted) {
        flags += MessageFlags::Deleted;
    } else {
        if (mStatus & StatusRead) {
            flags += MessageFlags::Seen;
        }
        if (mStatus & StatusReplied) {
            flags += MessageFlags::Answered;
        }
        if (mStatus & StatusFlag) {
            flags += MessageFlags::Flagged;
        }

        // non standard flags
        if (mStatus & StatusSent) {
            flags += MessageFlags::Sent;
        }
        if (mStatus & StatusQueued) {
            flags += MessageFlags::Queued;
        }
        if (mStatus & StatusReplied) {
            flags += MessageFlags::Replied;
        }
        if (mStatus & StatusForwarded) {
            flags += MessageFlags::Forwarded;
        }
        if (mStatus & StatusToAct) {
            flags += MessageFlags::ToAct;
        }
        if (mStatus & StatusWatched) {
            flags += MessageFlags::Watched;
        }
        if (mStatus & StatusIgnored) {
            flags += MessageFlags::Ignored;
        }
        if (mStatus & StatusHasAttachment) {
            flags += MessageFlags::HasAttachment;
        }
        if (mStatus & StatusHasInvitation) {
            flags += MessageFlags::HasInvitation;
        }
        if (mStatus & StatusSigned) {
            flags += MessageFlags::Signed;
        }
        if (mStatus & StatusEncrypted) {
            flags += MessageFlags::Encrypted;
        }
        if (mStatus & StatusSpam) {
            flags += MessageFlags::Spam;
        }
        if (mStatus & StatusHam) {
            flags += MessageFlags::Ham;
        }
        if (mStatus & StatusHasError) {
            flags += MessageFlags::HasError;
        }
    }

    return flags;
}

void MessageStatus::setStatusFromFlags(const QSet<QByteArray> &flags)
{
    mStatus = StatusUnknown;

    for (const QByteArray &flag : flags) {
        const QByteArray &upperedFlag = flag.toUpper();
        if (upperedFlag == MessageFlags::Deleted) {
            setDeleted();
        } else if (upperedFlag == MessageFlags::Seen) {
            setRead();
        } else if (upperedFlag == MessageFlags::Answered) {
            setReplied();
        } else if (upperedFlag == MessageFlags::Flagged) {
            setImportant();

            // non standard flags
        } else if (upperedFlag == MessageFlags::Sent) {
            setSent();
        } else if (upperedFlag == MessageFlags::Queued) {
            setQueued();
        } else if (upperedFlag == MessageFlags::Replied) {
            setReplied();
        } else if (upperedFlag == MessageFlags::Forwarded) {
            setForwarded();
        } else if (upperedFlag == MessageFlags::ToAct) {
            setToAct();
        } else if (upperedFlag == MessageFlags::Watched) {
            setWatched();
        } else if (upperedFlag == MessageFlags::Ignored) {
            setIgnored();
        } else if (upperedFlag == MessageFlags::HasAttachment) {
            setHasAttachment();
        } else if (upperedFlag == MessageFlags::HasInvitation) {
            setHasInvitation();
        } else if (upperedFlag == MessageFlags::Signed) {
            setSigned();
        } else if (upperedFlag == MessageFlags::Encrypted) {
            setEncrypted();
        } else if (upperedFlag == MessageFlags::Spam) {
            setSpam();
        } else if (upperedFlag == MessageFlags::Ham) {
            setHam();
        } else if (upperedFlag == MessageFlags::HasError) {
            setHasError();
        }
    }
}

const MessageStatus MessageStatus::statusUnread()
{
    MessageStatus st;
    st.mStatus = StatusUnread;
    return st;
}

const MessageStatus MessageStatus::statusRead()
{
    MessageStatus st;
    st.setRead();
    return st;
}

const MessageStatus MessageStatus::statusDeleted()
{
    MessageStatus st;
    st.setDeleted();
    return st;
}

const MessageStatus MessageStatus::statusReplied()
{
    MessageStatus st;
    st.setReplied();
    return st;
}

const MessageStatus MessageStatus::statusForwarded()
{
    MessageStatus st;
    st.setForwarded();
    return st;
}

const MessageStatus MessageStatus::statusQueued()
{
    MessageStatus st;
    st.setQueued();
    return st;
}

const MessageStatus MessageStatus::statusSent()
{
    MessageStatus st;
    st.setSent();
    return st;
}

const MessageStatus MessageStatus::statusImportant()
{
    MessageStatus st;
    st.setImportant();
    return st;
}

const MessageStatus MessageStatus::statusWatched()
{
    MessageStatus st;
    st.setWatched();
    return st;
}

const MessageStatus MessageStatus::statusIgnored()
{
    MessageStatus st;
    st.setIgnored();
    return st;
}

const MessageStatus MessageStatus::statusToAct()
{
    MessageStatus st;
    st.setToAct();
    return st;
}

const MessageStatus MessageStatus::statusSpam()
{
    MessageStatus st;
    st.setSpam();
    return st;
}

const MessageStatus MessageStatus::statusHam()
{
    MessageStatus st;
    st.setHam();
    return st;
}

const MessageStatus MessageStatus::statusHasAttachment()
{
    MessageStatus st;
    st.setHasAttachment();
    return st;
}

const MessageStatus MessageStatus::statusHasInvitation()
{
    MessageStatus st;
    st.setHasInvitation();
    return st;
}

const MessageStatus MessageStatus::statusSigned()
{
    MessageStatus st;
    st.setSigned();
    return st;
}

const MessageStatus MessageStatus::statusEncrypted()
{
    MessageStatus st;
    st.setEncrypted();
    return st;
}

const MessageStatus MessageStatus::statusHasError()
{
    MessageStatus st;
    st.setHasError();
    return st;
}

QDebug operator<<(QDebug d, const MessageStatus &t)
{
    d << "status " << t.statusStr();
    return d;
}
