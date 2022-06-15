// Copyright 2009 Thomas McGuire <mcguire@kde.org>
// SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL

#pragma once

#include <QObject>

namespace MimeTreeParser
{

class CryptoHelperTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testPMFDEmpty();
    void testPMFDWithNoPGPBlock();
    void testPGPBlockType();
    void testDeterminePGPBlockType();
    void testEmbededPGPBlock();
    void testClearSignedMessage();
    void testMultipleBlockMessage();
};

}
