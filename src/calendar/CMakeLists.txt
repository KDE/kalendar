# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

set(kalendar_calendar_SRCS
    remindersmodel.h
    remindersmodel.cpp
    utils.h
    utils.cpp

    calendarmanager.cpp
    calendarmanager.h
    calendarapplication.cpp
    calendarapplication.h
    filter.cpp
    filter.h
    incidencewrapper.cpp
    incidencewrapper.h
    mousetracker.cpp
    mousetracker.h

    models/attachmentsmodel.cpp
    models/attachmentsmodel.h
    models/attendeesmodel.cpp
    models/attendeesmodel.h
    models/hourlyincidencemodel.cpp
    models/hourlyincidencemodel.h
    models/incidenceoccurrencemodel.cpp
    models/incidenceoccurrencemodel.h
    models/infinitecalendarviewmodel.cpp
    models/infinitecalendarviewmodel.h
    models/itemtagsmodel.cpp
    models/itemtagsmodel.h
    models/monthmodel.cpp
    models/monthmodel.h
    models/multidayincidencemodel.cpp
    models/multidayincidencemodel.h
    models/recurrenceexceptionsmodel.cpp
    models/recurrenceexceptionsmodel.h
    models/timezonelistmodel.cpp
    models/timezonelistmodel.h
    models/todosortfilterproxymodel.cpp
    models/todosortfilterproxymodel.h
)

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
qt_add_dbus_adaptor(kalendar_calendar_SRCS org.kde.calendar.Calendar.xml calendarapplication.h CalendarApplication)

add_library(kalendar_calendar_static STATIC ${kalendar_calendar_SRCS})
kconfig_add_kcfg_files(kalendar_calendar_static GENERATE_MOC calendarconfig.kcfgc)
set_target_properties(kalendar_calendar_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(kalendar_calendar_static PUBLIC
    kalendar_lib
    KF${QT_MAJOR_VERSION}::WindowSystem
)


ecm_add_qml_module(kalendar_calendar_plugin URI "org.kde.kalendar.calendar" VERSION 1.0)

target_sources(kalendar_calendar_plugin PRIVATE
    calendarplugin.cpp
    calendarplugin.h
)

set_source_files_properties(models/todosortfilterproxymodel.cpp PROPERTIES SKIP_UNITY_BUILD_INCLUSION ON)

ecm_target_qml_sources(kalendar_calendar_plugin SOURCES
    qml/incidenceeditor/ReminderDelegate.qml
    qml/incidenceeditor/PriorityComboBox.qml
    qml/BottomToolBar.qml
)

target_link_libraries(kalendar_calendar_plugin PUBLIC kalendar_calendar_static)

ecm_finalize_qml_module(kalendar_calendar_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS ON)

if (BUILD_TESTING)
    add_subdirectory(autotests)
endif()

#### Binary

add_executable(kalendar-calendar main.cpp resources.qrc)
target_link_libraries(kalendar-calendar
    PRIVATE
        kalendar_calendar_static
        Qt::Widgets
        Qt::Quick
        Qt::QuickControls2
        KF${QT_MAJOR_VERSION}::I18n
        KF${QT_MAJOR_VERSION}::CoreAddons
        KF${QT_MAJOR_VERSION}::DBusAddons
        KF${QT_MAJOR_VERSION}::WindowSystem
        KF${QT_MAJOR_VERSION}::ConfigGui
)
install(TARGETS kalendar-calendar ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.kalendar.calendar.desktop DESTINATION ${KDE_INSTALL_APPDIR})