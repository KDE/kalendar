# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

cmake_minimum_required(VERSION 3.16)

# KDE Applications version, managed by release script.
set(RELEASE_SERVICE_VERSION_MAJOR "23")
set(RELEASE_SERVICE_VERSION_MINOR "07")
set(RELEASE_SERVICE_VERSION_MICRO "70")
set(RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")

project(kalendar VERSION ${RELEASE_SERVICE_VERSION})

set(QT_MIN_VERSION "5.15.2")
set(KF_MIN_VERSION "5.96.0")
set(PIM_VERSION "5.21.0")

include(FeatureSummary)

################# set KDE specific information #################
find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
set(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    ${ECM_MODULE_PATH}
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules
)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMAddTests)
include(ECMCoverageOption)
include(ECMQtDeclareLoggingCategory)
include(ECMSetupVersion)
include(ECMGenerateHeaders)
include(ECMPoQmTools)
include(KDEGitCommitHooks)
include(KDEClangFormat)
include(ECMDeprecationSettings)
include(ECMGenerateQmlTypes)
include(ECMQmlModule)

file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h *.c)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX KALENDAR
    SOVERSION ${PROJECT_VERSION_MAJOR}
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/src/config-kalendar.h"
)

set(KF_MAJOR_VERSION ${QT_MAJOR_VERSION})

################# Find dependencies #################
find_package(Qt${QT_MAJOR_VERSION} ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    DBus
    Gui
    Svg
    Test
    Qml
    QuickControls2
    QuickTest
)

if (QT_MAJOR_VERSION STREQUAL "6")
    find_package(Qt6Core5Compat REQUIRED)
endif()

find_package(KF${QT_MAJOR_VERSION} ${KF_MIN_VERSION} REQUIRED COMPONENTS
    CalendarCore
    ConfigWidgets
    Contacts
    CoreAddons
    DBusAddons
    I18n
    IconThemes
    ItemModels
    Kirigami2
    KIO
    QQC2DesktopStyle
    WindowSystem
    XmlGui
)
find_package(KF${QT_MAJOR_VERSION}KirigamiAddons 0.7.2 REQUIRED)
find_package(Gpgme REQUIRED)
set_package_properties(KF${QT_MAJOR_VERSION}QQC2DesktopStyle PROPERTIES
    TYPE RUNTIME
)

find_package(KPim${QT_MAJOR_VERSION}Akonadi ${PIM_VERSION} REQUIRED)
find_package(KPim${QT_MAJOR_VERSION}AkonadiCalendar ${PIM_VERSION} REQUIRED)
find_package(KPim${QT_MAJOR_VERSION}AkonadiContact ${PIM_VERSION} REQUIRED)
find_package(KPim${QT_MAJOR_VERSION}CalendarSupport ${PIM_VERSION} REQUIRED)
find_package(KPim${QT_MAJOR_VERSION}EventViews ${PIM_VERSION} REQUIRED)
find_package(KPim${QT_MAJOR_VERSION}MailCommon ${PIM_VERSION} REQUIRED)
find_package(KPim${QT_MAJOR_VERSION}AkonadiMime ${PIM_VERSION} REQUIRED)

option(USE_UNITY_CMAKE_SUPPORT "Use UNITY cmake support (speedup compile time)" OFF)

set(COMPILE_WITH_UNITY_CMAKE_SUPPORT OFF)
if (USE_UNITY_CMAKE_SUPPORT)
    set(COMPILE_WITH_UNITY_CMAKE_SUPPORT ON)
    add_definitions(-DUNITY_CMAKE_SUPPORT)
endif()

################# build and install #################

ki18n_install(po)

ecm_set_disabled_deprecation_versions(QT 5.15.2  KF 5.104.0)
add_definitions(-DQT_STRICT_ITERATORS)
add_subdirectory(src)

if (BUILD_TESTING)
    add_subdirectory(autotests)
endif()

if (BUILD_FLATPAK)
    install(PROGRAMS org.kde.kalendar.desktop DESTINATION ${KDE_INSTALL_APPDIR} RENAME org.kde.kontact.kalendar.desktop)
else()
    install(PROGRAMS org.kde.kalendar.desktop DESTINATION ${KDE_INSTALL_APPDIR})
endif()
install(FILES org.kde.kalendar.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})
install(FILES org.kde.kalendar.svg DESTINATION ${KDE_INSTALL_FULL_ICONDIR}/hicolor/scalable/apps)

ecm_qt_install_logging_categories(
        EXPORT KALENDAR
        FILE kalendar.categories
        DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
        )

kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
