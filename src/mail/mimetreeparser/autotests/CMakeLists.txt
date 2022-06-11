include_directories(../)
include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${GPGME_INCLUDE_DIRS})

set(AUTOMOC ON)

set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
add_definitions( -DMAIL_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/../../testdata" )

include(ECMAddTests)
include(${CMAKE_SOURCE_DIR}/cmake/modules/add_gpg_crypto_test.cmake)

macro(add_mimetreeparser_class_unittest _name _additionalSource)
    add_executable(${_name} ${_name}.cpp setupenv.cpp ${_additionalSource})
    target_link_libraries(${_name}
        sink_mimetreeparser
        Qt5::Test
        KF5::Mime
    )
    add_test(NAME ${_name} COMMAND $<TARGET_FILE:${_name}>)
endmacro ()

macro(add_mimetreeparser_crypto_unittest _name)
    add_executable(${_name} ${_name}.cpp setupenv.cpp)
    target_link_libraries(${_name}
        sink_mimetreeparser
        Qt5::Test
        KF5::Mime
        Gpgme::Gpgme
    )
    add_gpg_crypto_test(${_name} mimetreeparser-${_name})
endmacro ()

add_mimetreeparser_crypto_unittest(attachmenttest)
add_mimetreeparser_class_unittest(cryptohelpertest "../cryptohelper.cpp")
