# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause


add_executable(kalendar
    about.cpp
    about.h
    actionsmodel.cpp
    actionsmodel.h
    agentconfiguration.cpp
    agentconfiguration.h
    attachmentsmodel.cpp
    attachmentsmodel.h
    attendeesmodel.cpp
    attendeesmodel.h
    calendarmanager.cpp
    calendarmanager.h
    commandbarfiltermodel.cpp
    commandbarfiltermodel.h
    contactsmanager.cpp
    contactsmanager.h
    extratodomodel.cpp
    extratodomodel.h
    hourlyincidencemodel.cpp
    hourlyincidencemodel.h
    incidenceoccurrencemodel.cpp
    incidenceoccurrencemodel.h
    incidencetreemodel.cpp
    incidencetreemodel.h
    incidencetreemodel_p.h
    incidencewrapper.cpp
    incidencewrapper.h
    infinitecalendarviewmodel.cpp
    infinitecalendarviewmodel.h
    itemtagsmodel.cpp
    itemtagsmodel.h
    kalendarapplication.cpp
    kalendarapplication.h
    main.cpp
    monthmodel.cpp
    monthmodel.h
    multidayincidencemodel.cpp
    multidayincidencemodel.h
    recurrenceexceptionsmodel.cpp
    recurrenceexceptionsmodel.h
    remindersmodel.cpp
    remindersmodel.h
    tagmanager.cpp
    tagmanager.h
    timezonelistmodel.cpp
    timezonelistmodel.h
    todomodel.cpp
    todomodel.h
    todomodel_p.h
    todosortfilterproxymodel.cpp
    todosortfilterproxymodel.h
    resources.qrc)

ecm_qt_declare_logging_category(kalendar HEADER kalendar_debug.h IDENTIFIER KALENDAR_LOG CATEGORY_NAME org.kde.kalendar DESCRIPTION "kalendar" EXPORT KALENDAR)


target_link_libraries(kalendar
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Svg
    Qt5::Location
    Qt5::DBus
    KF5::I18n
    KF5::CoreAddons
    KF5::DBusAddons
    KF5::CalendarCore
    KF5::AkonadiCore
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
kconfig_add_kcfg_files(kalendar GENERATE_MOC kalendarconfig.kcfgc)
install(TARGETS kalendar ${KF5_INSTALL_TARGETS_DEFAULT_ARGS})
