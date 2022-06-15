# SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
# SPDX-License-Identifier: BSD-3-Clause

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    ${GPGME_INCLUDE_DIRS}
)

set(AUTOMOC ON)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
add_definitions(-DMAIL_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/../../testdata" )

include(ECMAddTests)
include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)

find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Core Test)

function(add_mimetreeparser_class_unittest _name _additionalSource)
    add_executable(${_name} ${_name}.cpp setupenv.cpp ${_additionalSource})
    target_link_libraries(${_name}
        Qt5::Core
        Qt5::Test
        KF5::Mime
        kalendar_lib
        KF5::MailCommon
        KF5::AkonadiMime
        Qt5::WebEngineWidgets
        kalendar_mail_plugin
    )
    add_test(NAME ${_name} COMMAND $<TARGET_FILE:${_name}>)
endfunction()

function(add_mimetreeparser_crypto_unittest _name)
    add_executable(${_name} ${_name}.cpp setupenv.cpp)
    add_gpg_crypto_test(${_name} mimetreeparser-${_name})
    target_link_libraries(${_name}
        Qt5::Core
        Qt5::Test
        KF5::Mime
        kalendar_lib
        Gpgme::Gpgme
        KF5::MailCommon
        KF5::AkonadiMime
        Qt5::WebEngineWidgets
        kalendar_mail_plugin
    )
endfunction()

add_mimetreeparser_crypto_unittest(attachmenttest)
add_mimetreeparser_class_unittest(cryptohelpertest "../cryptohelper.cpp")
