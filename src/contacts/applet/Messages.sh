#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

$XGETTEXT `find . -name '*.js' -o -name '*.qml'` -o $podir/plasma_applet_org.kde.kalendar.contact.pot
