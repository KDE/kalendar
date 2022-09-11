# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

set(kalendar_calendar_SRCS)

ecm_qt_declare_logging_category(kalendar_calendar_SRCS
    HEADER kalendar_calendar_debug.h
    IDENTIFIER "KALENDAR_CALENDAR_LOG"
    CATEGORY_NAME org.kde.kalendar.calendar
    DESCRIPTION "kalendar calendar"
    EXPORT KALENDAR
)

ecm_qt_export_logging_category(
    IDENTIFIER "KALENDAR_CALENDAR_LOG"
    CATEGORY_NAME "org.kde.kalendar.calendar"
    DESCRIPTION "Kalendar - calendar"
    EXPORT KALENDAR
)

add_library(kalendar_calendar_static STATIC ${kalendar_calendar_SRCS})
target_link_libraries(kalendar_calendar_static PUBLIC kalendar_lib)

ecm_add_qml_module(kalendar_calendar_plugin URI "org.kde.kalendar.calendar" VERSION 1.0)

target_sources(kalendar_calendar_plugin PRIVATE
    calendarplugin.cpp
    calendarplugin.h
)

ecm_target_qml_sources(kalendar_calendar_plugin SOURCES
    qml/CalendarApplication.qml
)

ecm_target_qml_sources(kalendar_calendar_plugin
    PRIVATE PATH private SOURCES
    qml/private/MenuBar.qml
    qml/private/GlobalMenuBar.qml
)

target_link_libraries(kalendar_calendar_plugin PUBLIC kalendar_calendar_static)

ecm_finalize_qml_module(kalendar_calendar_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS ON)