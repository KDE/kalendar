# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

find_package(KF5 ${KF5_MIN_VERSION} OPTIONAL_COMPONENTS Plasma)

if (KF5Plasma_FOUND)
    plasma_install_package(package org.kde.kalendar.contact)
endif()
