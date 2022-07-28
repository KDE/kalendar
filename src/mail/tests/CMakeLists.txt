# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-3-Clause

include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)
include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
)

include_directories(${GPGME_INCLUDE_DIRS})

include(ECMAddTests)
find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Core Test WebEngine)

add_executable(cryptotest cryptotest.cpp)
add_gpg_crypto_test(cryptotest cryptotest)
target_link_libraries(cryptotest
    kalendar_lib
    kalendar_mail_plugin
    Qt5::Core
    Qt5::Test
    Qt5::WebEngine
    Qt5::WebEngineWidgets
    KF5::MailCommon
    KF5::AkonadiMime
)
