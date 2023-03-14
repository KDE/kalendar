# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

find_package(KF${QT_MAJOR_VERSION} ${KF_MIN_VERSION} OPTIONAL_COMPONENTS Plasma)

if (KF${QT_MAJOR_VERSION}Plasma_FOUND)
    plasma_install_package(package org.kde.kalendar.contact)
endif()
