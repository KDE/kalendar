# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_subdirectory(lib)
add_subdirectory(contacts)

add_executable(kalendar)

set(kalendar_SRCS
    about.cpp
    about.h
    models/actionsmodel.cpp
    models/actionsmodel.h
    agentconfiguration.cpp
    agentconfiguration.h
    models/attachmentsmodel.cpp
    models/attachmentsmodel.h
    models/attendeesmodel.cpp
    models/attendeesmodel.h
    calendarmanager.cpp
    calendarmanager.h
    models/commandbarfiltermodel.cpp
    models/commandbarfiltermodel.h
    models/hourlyincidencemodel.cpp
    models/hourlyincidencemodel.h
    models/incidenceoccurrencemodel.cpp
    models/incidenceoccurrencemodel.h
    incidencewrapper.cpp
    incidencewrapper.h
    models/infinitecalendarviewmodel.cpp
    models/infinitecalendarviewmodel.h
    models/itemtagsmodel.cpp
    models/itemtagsmodel.h
    kalendarapplication.cpp
    kalendarapplication.h
    main.cpp
    models/monthmodel.cpp
    models/monthmodel.h
    models/multidayincidencemodel.cpp
    models/multidayincidencemodel.h
    models/recurrenceexceptionsmodel.cpp
    models/recurrenceexceptionsmodel.h
    models/remindersmodel.cpp
    models/remindersmodel.h
    tagmanager.cpp
    tagmanager.h
    models/timezonelistmodel.cpp
    models/timezonelistmodel.h
    models/todosortfilterproxymodel.cpp
    models/todosortfilterproxymodel.h
    resources.qrc
)
qt_add_dbus_adaptor(kalendar_SRCS org.kde.calendar.Calendar.xml kalendarapplication.h KalendarApplication)
set_source_files_properties(models/todosortfilterproxymodel.cpp PROPERTIES SKIP_UNITY_BUILD_INCLUSION ON)

target_sources(kalendar PRIVATE
    ${kalendar_SRCS})

ecm_qt_declare_logging_category(kalendar HEADER kalendar_debug.h IDENTIFIER KALENDAR_LOG CATEGORY_NAME org.kde.kalendar DESCRIPTION "kalendar" EXPORT KALENDAR)

set(kalendar_LIBS
    kalendar_lib
    KF5::DBusAddons
    KF5::CalendarCore
    KF5::AkonadiCore
    KF5::AkonadiCalendar
    KF5::AkonadiContact
    KF5::AkonadiAgentBase
    KF5::AkonadiXml
    KF5::CalendarSupport
    KF5::WindowSystem
    KF5::ConfigWidgets
    KF5::AkonadiWidgets
    KF5::Contacts
    KF5::ItemModels
    KF5::XmlGui
    KF5::EventViews
    )

target_link_libraries(kalendar
    ${kalendar_LIBS}
)

if (COMPILE_WITH_UNITY_CMAKE_SUPPORT)
    set_target_properties(kalendar PROPERTIES UNITY_BUILD ON)
endif()
kconfig_add_kcfg_files(kalendar GENERATE_MOC kalendarconfig.kcfgc)
install(TARGETS kalendar ${KF5_INSTALL_TARGETS_DEFAULT_ARGS})
