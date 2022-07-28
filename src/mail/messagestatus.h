/*  -*- mode: C++ -*-
    This file is part of Akonadi.
    SPDX-FileCopyrightText: 2005 Andreas Gungl <a.gungl@gmx.de>
    SPDX-FileCopyrightText: 2010 Klarälvdalens Datakonsult AB, a KDAB Group company <info@kdab.com>
    SPDX-FileCopyrightText: 2010 Leo Franchi <lfranchi@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
#pragma once

#include <QDebug>
#include <QSet>

class QString;

//---------------------------------------------------------------------------
/**
  @short Akonadi KMime Message Status.
  @author Andreas Gungl <a.gungl@gmx.de>

  The class encapsulates the handling of the different flags
  which describe the status of a message.
  The flags themselves are not intended to be used outside this class.

  In the status pairs Watched/Ignored and Spam/Ham, there both
  values can't be set at the same time, however they can
  be unset at the same time.

  Note that this class does not sync with the Akonadi storage. It is
  used as an in-memory helper when manipulating Akonadi items.

  @since 4.6.
*/
class MessageStatus
{
    Q_GADGET
    Q_PROPERTY(bool isOfUnknownStatus READ isOfUnknownStatus)
    Q_PROPERTY(bool isRead READ isRead WRITE setRead)
    Q_PROPERTY(bool isDeleted READ isDeleted WRITE setDeleted)
    Q_PROPERTY(bool isReplied READ isReplied WRITE setReplied)
    Q_PROPERTY(bool isForwarded READ isForwarded WRITE setForwarded)
    Q_PROPERTY(bool isQueued READ isQueued WRITE setQueued)
    Q_PROPERTY(bool isSent READ isSent WRITE setSent)
    Q_PROPERTY(bool isImportant READ isImportant WRITE setImportant)
    Q_PROPERTY(bool isWatched READ isWatched WRITE setWatched)
    Q_PROPERTY(bool isIgnored READ isIgnored WRITE setIgnored)
    Q_PROPERTY(bool isSpam READ isSpam WRITE setSpam)
    Q_PROPERTY(bool isHam READ isHam WRITE setHam)
    Q_PROPERTY(bool isToAct READ isToAct WRITE setToAct)
    Q_PROPERTY(bool hasAttachment READ hasAttachment WRITE setHasAttachment)
    Q_PROPERTY(bool hasInvitation READ hasInvitation WRITE setHasInvitation)
    Q_PROPERTY(bool isEncrypted READ isEncrypted WRITE setEncrypted)
    Q_PROPERTY(bool isSigned READ isSigned WRITE setSigned)
    Q_PROPERTY(bool hasError READ hasError WRITE setHasError)

public:
    /** Constructor - sets status initially to unknown. */
    MessageStatus();

    /** Compare the status with that from another instance.
        @return true if the stati are equal, false if different.
        @param other message status to compare with current object
    */
    bool operator==(MessageStatus other) const;

    /** Compare the status with that from another instance.
        @return true if the stati are equal, false if different.
        @param other message status to compare with current object
    */
    bool operator!=(MessageStatus other) const;

    /** Check, if some of the flags in the status match
        with those flags from another instance.
        @return true if at least one flag is set in both stati.
        @param other message status to compare objects' flags
    */
    bool operator&(MessageStatus other) const;

    /** Clear all status flags, this resets to unknown. */
    void clear();

    /** Set / add stati described by another MessageStatus object.
        This can be used to merge in multiple stati at once without
        using the single setter methods.
        However, internally the setters are used anyway to ensure the
        integrity of the resulting status.
        @param other message status to set
    */
    void set(MessageStatus other);

    /** Toggle one or more stati described by another MessageStatus object.
        Internally the setters are used to ensure the integrity of the
        resulting status.
        @param other message status to toggle
    */
    void toggle(MessageStatus other);

    /* ----- getters ----------------------------------------------------- */

    /** Check for Unknown status.
        @return true if status is unknown.
    */
    Q_REQUIRED_RESULT bool isOfUnknownStatus() const;

    /** Check for Read status. Note that ignored messages are read.
        @return true if status is read.
    */
    Q_REQUIRED_RESULT bool isRead() const;

    /** Check for Deleted status.
        @return true if status is deleted.
    */
    Q_REQUIRED_RESULT bool isDeleted() const;

    /** Check for Replied status.
        @return true if status is replied.
    */
    Q_REQUIRED_RESULT bool isReplied() const;

    /** Check for Forwarded status.
        @return true if status is forwarded.
    */
    Q_REQUIRED_RESULT bool isForwarded() const;

    /** Check for Queued status.
        @return true if status is queued.
    */
    Q_REQUIRED_RESULT bool isQueued() const;

    /** Check for Sent status.
        @return true if status is sent.
    */
    Q_REQUIRED_RESULT bool isSent() const;

    /** Check for Important status.
        @return true if status is important.
    */
    Q_REQUIRED_RESULT bool isImportant() const;

    /** Check for Watched status.
        @return true if status is watched.
    */
    Q_REQUIRED_RESULT bool isWatched() const;

    /** Check for Ignored status.
        @return true if status is ignored.
    */
    Q_REQUIRED_RESULT bool isIgnored() const;

    /** Check for ToAct status.
        @return true if status is action item.
    */
    Q_REQUIRED_RESULT bool isToAct() const;

    /** Check for Spam status.
        @return true if status is spam.
    */
    Q_REQUIRED_RESULT bool isSpam() const;

    /** Check for Ham status.
        @return true if status is not spam.
    */
    Q_REQUIRED_RESULT bool isHam() const;

    /** Check for Attachment status.
        @return true if status indicates an attachment.
    */
    Q_REQUIRED_RESULT bool hasAttachment() const;

    /** Check for Invitation status.
        @return true if status indicates an invitation.
    */
    Q_REQUIRED_RESULT bool hasInvitation() const;

    /** Check for Signed status.
        @return true if status is signed.
    */
    Q_REQUIRED_RESULT bool isSigned() const;

    /** Check for Encrypted status.
        @return true if status is encrypted.
    */
    Q_REQUIRED_RESULT bool isEncrypted() const;

    /** Check for error status.
        @return true if status indicates an error.
    */
    Q_REQUIRED_RESULT bool hasError() const;

    /* ----- setters ----------------------------------------------------- */

    /**
     * Set the status to read
     * @param read new read status
     */
    void setRead(bool read = true);

    /** Set the status for deleted.
        @param deleted Set (true) or unset (false) this status flag.
    */
    void setDeleted(bool deleted = true);

    /** Set the status for replied.
        @param replied Set (true) or unset (false) this status flag.
    */
    void setReplied(bool replied = true);

    /** Set the status for forwarded.
        @param forwarded Set (true) or unset (false) this status flag.
    */
    void setForwarded(bool forwarded = true);

    /** Set the status for queued.
        @param queued Set (true) or unset (false) this status flag.
    */
    void setQueued(bool queued = true);

    /** Set the status for sent.
        @param sent Set (true) or unset (false) this status flag.
    */
    void setSent(bool sent = true);

    /** Set the status for important.
        @param important Set (true) or unset (false) this status flag.
    */
    void setImportant(bool important = true);

    /** Set the status to watched.
        @param watched Set (true) or unset (false) this status flag.
    */
    void setWatched(bool watched = true);

    /** Set the status to ignored.
        @param ignored Set (true) or unset (false) this status flag.
    */
    void setIgnored(bool ignored = true);

    /** Set the status to action item.
        @param toAct Set (true) or unset (false) this status flag.
    */
    void setToAct(bool toAct = true);

    /** Set the status to spam.
        @param spam Set (true) or unset (false) this status flag.
    */
    void setSpam(bool spam = true);

    /** Set the status to not spam.
        @param ham Set (true) or unset (false) this status flag.
    */
    void setHam(bool ham = true);

    /** Set the status for an attachment.
        @param hasAttachment Set (true) or unset (false) this status flag.
    */
    void setHasAttachment(bool hasAttachment = true);

    /** Set the status for an invitation.
        @param hasInvitation Set (true) or unset (false) this status flag.
    */
    void setHasInvitation(bool hasInvitation = true);

    /** Set the status to signed.
        @param value Set (true) or unset (false) this status flag.
    */
    void setSigned(bool value = true);

    /** Set the status to encrypted.
        @param value Set (true) or unset (false) this status flag.
    */
    void setEncrypted(bool value = true);

    /** Set the status to error.
        @param value Set (true) or unset (false) this status flag.
    */
    void setHasError(bool value = true);

    /* ----- state representation  --------------------------------------- */

    /** Get the status as a whole e.g. for storage in an index.
     D on't manipulte the *index via this value, this bypasses
     all integrity checks in the setter methods.
     @return The status encoded in bits.
     */
    Q_REQUIRED_RESULT qint32 toQInt32() const;

    /** Set the status as a whole e.g. for reading from an index.
        Don't manipulte the index via this value, this bypasses
        all integrity checks in the setter methods.
        @param status The status encoded in bits to be set in this instance.
    */
    void fromQInt32(qint32 status);

    /** Convert the status to a string representation.
        @return A string containing coded uppercase letters
                which describe the status.

        @note This code is legacy for the KMail1 indexes
    */
    Q_REQUIRED_RESULT QString statusStr() const;

    /** Set the status based on a string representation.
        @param aStr The status string to be analyzed.
                    Normally it is a string obtained using
                    getStatusStr().

        @note This code is legacy for the KMail1 indexes
    */
    void setStatusFromStr(const QString &aStr);

    /** Get the status as a whole e.g. for storage as IMAP flags.
        @return The status encoded in flags.
    */
    Q_REQUIRED_RESULT QSet<QByteArray> statusFlags() const;

    /** Set the status as a whole e.g. for reading from IMAP flags.
        @param flags set of flags for status as a whole
    */
    void setStatusFromFlags(const QSet<QByteArray> &flags);

    /* ----- static accessors to simple states --------------------------- */

    /** Return a special status that expresses Unread.
        This status can only be used for comparison with other states.
    */
    static const MessageStatus statusUnread();

    /** Return a predefined status initialized as Read as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Read.
    */
    static const MessageStatus statusRead();

    /** Return a predefined status initialized as Deleted as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Deleted.
    */
    static const MessageStatus statusDeleted();

    /** Return a predefined status initialized as Replied as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Replied.
    */
    static const MessageStatus statusReplied();

    /** Return a predefined status initialized as Forwarded as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Forwarded.
    */
    static const MessageStatus statusForwarded();

    /** Return a predefined status initialized as Queued as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Queued.
    */
    static const MessageStatus statusQueued();

    /** Return a predefined status initialized as Sent as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Sent.
    */
    static const MessageStatus statusSent();

    /** Return a predefined status initialized as Important as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Important.
    */
    static const MessageStatus statusImportant();

    /** Return a predefined status initialized as Watched as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Watched.
    */
    static const MessageStatus statusWatched();

    /** Return a predefined status initialized as Ignored as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Ignored.
    */
    static const MessageStatus statusIgnored();

    /** Return a predefined status initialized as Action Item as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as ToAct.
    */
    static const MessageStatus statusToAct();

    /** Return a predefined status initialized as Spam as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Spam.
    */
    static const MessageStatus statusSpam();

    /** Return a predefined status initialized as Ham as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Ham.
    */
    static const MessageStatus statusHam();

    /** Return a predefined status initialized as Attachment as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Attachment.
    */
    static const MessageStatus statusHasAttachment();

    /** Return a predefined status initialized as Invitation as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Invitation.
    */
    static const MessageStatus statusHasInvitation();

    /** Return a predefined status initialized as Signed as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Signed.
    */
    static const MessageStatus statusSigned();

    /** Return a predefined status initialized as Encrypted as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Encrypted.
    */
    static const MessageStatus statusEncrypted();

    /** Return a predefined status initialized as Error as is useful
        e.g. when providing a state for comparison.
        @return A reference to a status instance initialized as Error.
    */
    static const MessageStatus statusHasError();

private:
    quint32 mStatus;
};

QDebug operator<<(QDebug d, const MessageStatus &t);
