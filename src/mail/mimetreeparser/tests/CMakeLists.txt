add_subdirectory(gnupg_home)
add_definitions( -DMAIL_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/../../testdata" )
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
    sink_mimetreeparser
    Qt5::Core
    Qt5::Test
    KF5::Mime
)

add_executable(gpgerrortest gpgerrortest.cpp)
target_link_libraries(gpgerrortest
    sink_mimetreeparser
    Qt5::Core
    Qt5::Test
    KF5::Mime
    Gpgme::Gpgme
)
add_test(NAME gpgerrortest COMMAND $<TARGET_FILE:gpgerrortest>)
