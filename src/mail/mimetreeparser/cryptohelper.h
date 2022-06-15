// SPDX-FileCopyrightText: 2015 Sandro Knauß <knauss@kolabsys.com>
// SPDX-FileCopyrightText: 2001,2002 the KPGP authors
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QByteArray>
#include <QList>

namespace MimeTreeParser
{

enum PGPBlockType {
    UnknownBlock = -1, // BEGIN PGP ???
    NoPgpBlock = 0,
    PgpMessageBlock = 1, // BEGIN PGP MESSAGE
    MultiPgpMessageBlock = 2, // BEGIN PGP MESSAGE, PART X[/Y]
    SignatureBlock = 3, // BEGIN PGP SIGNATURE
    ClearsignedBlock = 4, // BEGIN PGP SIGNED MESSAGE
    PublicKeyBlock = 5, // BEGIN PGP PUBLIC KEY BLOCK
    PrivateKeyBlock = 6 // BEGIN PGP PRIVATE KEY BLOCK (PGP 2.x: ...SECRET...)
};

class Block
{
public:
    Block(const QByteArray &m);

    Block(const QByteArray &m, PGPBlockType t);

    QByteArray text() const;
    PGPBlockType type() const;
    PGPBlockType determineType() const;

    QByteArray msg;
    PGPBlockType mType;
};

/** Parses the given message and splits it into OpenPGP blocks and
    Non-OpenPGP blocks.
*/
QList<Block> prepareMessageForDecryption(const QByteArray &msg);

} // namespace MimeTreeParser

Q_DECLARE_TYPEINFO(MimeTreeParser::Block, Q_MOVABLE_TYPE);
