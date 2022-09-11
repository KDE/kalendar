# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

set(kalendar_components_SRCS)

ecm_qt_declare_logging_category(kalendar_components_SRCS
    HEADER kalendar_components_debug.h
    IDENTIFIER "KALENDAR_components_LOG"
    CATEGORY_NAME org.kde.kalendar.components
    DESCRIPTION "kalendar components"
    EXPORT KALENDAR
)

ecm_qt_export_logging_category(
    IDENTIFIER "KALENDAR_components_LOG"
    CATEGORY_NAME "org.kde.kalendar.components"
    DESCRIPTION "Kalendar - components"
    EXPORT KALENDAR
)

add_library(kalendar_components_static STATIC ${kalendar_components_SRCS})
target_link_libraries(kalendar_components_static PUBLIC kalendar_lib)

ecm_add_qml_module(kalendar_components_plugin URI "org.kde.kalendar.components" VERSION 1.0)

target_sources(kalendar_components_plugin PRIVATE
    componentsplugin.cpp
    componentsplugin.h
)

ecm_target_qml_sources(kalendar_components_plugin SOURCES
    # Shell components
    qml/KalendarApp.qml
    qml/BottomToolBar.qml

    # In window-menu components
    qml/KActionFromAction.qml
    qml/ViewMenu.qml
    qml/EditMenu.qml
    qml/FileMenu.qml
    qml/SettingsMenu.qml
    qml/WindowMenu.qml
    qml/HelpMenu.qml

    # global menu components
    qml/NativeMenuItemFromAction.qml
    qml/NativeFileMenu.qml
    qml/NativeEditMenu.qml
    qml/NativeWindowMenu.qml
    qml/NativeViewMenu.qml
    qml/NativeSettingsMenu.qml
    qml/NativeHelpMenu.qml
)

target_link_libraries(kalendar_components_plugin PUBLIC kalendar_components_static)

ecm_finalize_qml_module(kalendar_components_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)