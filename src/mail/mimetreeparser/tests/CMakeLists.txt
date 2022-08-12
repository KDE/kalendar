# SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
# SPDX-License-Identifier: BSD-3-Clause

add_subdirectory(gnupg_home)
add_definitions( -DMAIL_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/../testdata" )
include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)
include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    )
include_directories(${GPGME_INCLUDE_DIRS})

include(ECMAddTests)

add_executable(mimetreeparsertest mimetreeparsertest.cpp)
add_gpg_crypto_test(mimetreeparsertest mimetreeparsertest)
target_link_libraries(mimetreeparsertest
    Qt5::Core
    Qt5::Test
    KF5::Mime
    kalendar_lib
    KF5::MailCommon
    KF5::AkonadiMime
    kalendar_mail_plugin
)

add_executable(gpgerrortest gpgerrortest.cpp)
target_link_libraries(gpgerrortest
    Qt5::Core
    Qt5::Test
    KF5::Mime
    kalendar_lib
    KF5::MailCommon
    KF5::AkonadiMime
    kalendar_mail_plugin
)
add_test(NAME gpgerrortest COMMAND $<TARGET_FILE:gpgerrortest>)
