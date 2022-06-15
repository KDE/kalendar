// SPDX-FileCopyrightText: 2010 Klaralvdalens Datakonsult AB, a KDAB Group company, info@kdab.com
// SPDX-FileCopyCopyright: 2010 Leo Franchi <lfranchi@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later

#include "setupenv.h"

#include <QStandardPaths>

#include <QDir>
#include <QFile>

void MimeTreeParser::Test::setupEnv()
{
    qputenv("LC_ALL", "C");
    qputenv("KDEHOME", QFile::encodeName(QDir::homePath() + QString::fromLatin1("/.qttest")).constData());
    QStandardPaths::setTestModeEnabled(true);
}
