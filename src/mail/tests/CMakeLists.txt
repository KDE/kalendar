# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-3-Clause

include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)

add_executable(cryptotest cryptotest.cpp)
target_include_directories(cryptotest PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/..>
    ${CMAKE_CURRENT_BINARY_DIR}
    ${GPGME_INCLUDE_DIRS}
)
add_gpg_crypto_test(cryptotest cryptotest)
target_link_libraries(cryptotest
    Qt5::Test
    kalendar_mail_static
)
