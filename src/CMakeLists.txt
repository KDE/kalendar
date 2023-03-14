# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_subdirectory(lib)
add_subdirectory(quick)
add_subdirectory(contacts)
add_subdirectory(mail)
add_subdirectory(calendar)
add_subdirectory(components)

add_executable(kalendar)

set(kalendar_SRCS
    about.cpp
    about.h
    models/actionsmodel.cpp
    models/actionsmodel.h
    models/attachmentsmodel.cpp
    models/attachmentsmodel.h
    models/attendeesmodel.cpp
    models/attendeesmodel.h
    calendarmanager.cpp
    calendarmanager.h
    filter.cpp
    filter.h
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
    utils.h
    utils.cpp
)
qt_add_dbus_adaptor(kalendar_SRCS org.kde.calendar.Calendar.xml kalendarapplication.h KalendarApplication)
set_source_files_properties(models/todosortfilterproxymodel.cpp PROPERTIES SKIP_UNITY_BUILD_INCLUSION ON)

target_sources(kalendar PRIVATE
    ${kalendar_SRCS})

ecm_qt_declare_logging_category(kalendar
    HEADER kalendar_debug.h
    IDENTIFIER KALENDAR_LOG
    CATEGORY_NAME org.kde.kalendar
    DESCRIPTION "kalendar"
    EXPORT KALENDAR
)

set(kalendar_LIBS
    kalendar_lib
    KF${QT_MAJOR_VERSION}::DBusAddons
    KF${QT_MAJOR_VERSION}::CalendarCore
    KPim${QT_MAJOR_VERSION}::AkonadiCore
    KPim${QT_MAJOR_VERSION}::AkonadiCalendar
    KPim${QT_MAJOR_VERSION}::AkonadiContact
    KPim${QT_MAJOR_VERSION}::AkonadiAgentBase
    KPim${QT_MAJOR_VERSION}::AkonadiXml
    KPim${QT_MAJOR_VERSION}::CalendarSupport
    KF${QT_MAJOR_VERSION}::WindowSystem
    KF${QT_MAJOR_VERSION}::ConfigWidgets
    KPim${QT_MAJOR_VERSION}::AkonadiWidgets
    KF${QT_MAJOR_VERSION}::Contacts
    KF${QT_MAJOR_VERSION}::ItemModels
    KF${QT_MAJOR_VERSION}::XmlGui
    KPim${QT_MAJOR_VERSION}::EventViews
    )

target_link_libraries(kalendar
    ${kalendar_LIBS}
)

if (COMPILE_WITH_UNITY_CMAKE_SUPPORT)
    set_target_properties(kalendar PROPERTIES UNITY_BUILD ON)
endif()
kconfig_add_kcfg_files(kalendar GENERATE_MOC kalendarconfig.kcfgc)
install(TARGETS kalendar ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
