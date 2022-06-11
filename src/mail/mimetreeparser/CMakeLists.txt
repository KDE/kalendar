set(CMAKE_CXX_VISIBILITY_PRESET default)

find_package(Qt5 COMPONENTS REQUIRED Core Gui)
find_package(KF5Mime 4.87.0 CONFIG REQUIRED)
find_package(KF5Codecs CONFIG REQUIRED)
find_package(Gpgme REQUIRED)

include_directories(${GPGME_INCLUDE_DIRS})
add_library(sink_mimetreeparser STATIC
    objecttreeparser.cpp

    #Bodyformatter
    utils.cpp
    bodypartformatter_impl.cpp

    #Interfaces
    bodypartformatter.cpp

    #bodypartformatter.cpp
    bodypartformatterbasefactory.cpp
    cryptohelper.cpp
    messagepart.cpp
    #Stuff
    mimetreeparser_debug.cpp
    )

target_link_libraries(sink_mimetreeparser
PUBLIC
    KF5::Mime
PRIVATE
    crypto
    KF5::Codecs
    Qt5::Gui
    Gpgme::Gpgme
)

install(FILES
    objecttreeparser.h
    messagepart.h
    partmetadata.h
    DESTINATION ${INCLUDE_INSTALL_DIR}/sink/mimetreeparser COMPONENT Devel
)

add_subdirectory(autotests)
add_subdirectory(tests)
