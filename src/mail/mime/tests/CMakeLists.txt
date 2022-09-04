# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-3-Clause

add_definitions( -DMAIL_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/../testdata" )

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/..)

include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)

add_executable(mailtemplatetest mailtemplatetest.cpp)

add_gpg_crypto_test(mailtemplatetest mailtemplatetest)
target_link_libraries(mailtemplatetest
    Qt5::Test
    kalendar_mail_static
)
