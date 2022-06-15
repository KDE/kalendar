// SPDX-FileCopyrightText: 2016 Sandro Knauß <knauss@kolabsys.com>
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef __MIMETREEPARSER_ENUMS_H__
#define __MIMETREEPARSER_ENUMS_H__

namespace MimeTreeParser
{

/**
 * The display update mode: Force updates the display immediately, Delayed updates
 * after some time (150ms by default)
 */
enum UpdateMode { Force = 0, Delayed };

/** Flags for the encryption state. */
typedef enum { KMMsgEncryptionStateUnknown, KMMsgNotEncrypted, KMMsgPartiallyEncrypted, KMMsgFullyEncrypted, KMMsgEncryptionProblematic } KMMsgEncryptionState;

/** Flags for the signature state. */
typedef enum { KMMsgSignatureStateUnknown, KMMsgNotSigned, KMMsgPartiallySigned, KMMsgFullySigned, KMMsgSignatureProblematic } KMMsgSignatureState;

}

#endif
