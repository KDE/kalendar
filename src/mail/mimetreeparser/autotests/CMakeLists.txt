# SPDX-FileCopyrightText: 2017 Christian Mollekopf <mollekopf@kolabsys.com>
# SPDX-License-Identifier: BSD-3-Clause

set(AUTOMOC ON)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
add_definitions(-DMAIL_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/../testdata" )

include(ECMAddTests)
include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)

function(add_mimetreeparser_class_unittest _name _additionalSource)
    add_executable(${_name} ${_name}.cpp setupenv.cpp ${_additionalSource})
    target_link_libraries(${_name} PRIVATE
        Qt5::Test
        kalendar_mail_static
    )
    target_include_directories(${_name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..)
    add_test(NAME ${_name} COMMAND $<TARGET_FILE:${_name}>)
endfunction()

function(add_mimetreeparser_crypto_unittest _name)
    add_executable(${_name} ${_name}.cpp setupenv.cpp)
    if (QT_MAJOR_VERSION STREQUAL "6")
        target_link_libraries(${_name} PRIVATE QGpgmeQt6 Qt6::Core5Compat)
    else()
        target_link_libraries(${_name} PRIVATE Gpgme::Gpgme)
    endif()
    target_include_directories(${_name} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/..
        ${GPGME_INCLUDE_DIRS}
    )
    target_link_libraries(${_name} PRIVATE
        Qt5::Test
        kalendar_mail_static
    )
    add_gpg_crypto_test(${_name} mimetreeparser-${_name})
endfunction()

add_mimetreeparser_crypto_unittest(attachmenttest)
add_mimetreeparser_class_unittest(cryptohelpertest "../cryptohelper.cpp")
