# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_executable(kalendar about.cpp main.cpp agentconfiguration.cpp incidenceoccurrencemodel.cpp monthviewmodel.cpp calendarmanager.cpp multidayincidencemodel.cpp incidencewrapper.cpp remindersmodel.cpp attendeesmodel.cpp recurrenceexceptionsmodel.cpp attachmentsmodel.cpp contactsmanager.cpp todomodel.cpp incidencetreemodel.cpp todosortfilterproxymodel.cpp kalendarapplication.cpp resources.qrc)

target_link_libraries(kalendar
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Svg
    Qt5::Location
    KF5::I18n
    KF5::Package
    KF5::CoreAddons
    KF5::CalendarCore
    KF5::AkonadiCore
    KF5::AkonadiContact
    KF5::AkonadiAgentBase
    KF5::AkonadiXml
    KF5::CalendarSupport
    KF5::WindowSystem
    KF5::ConfigWidgets
    KF5::AkonadiWidgets
    KF5::People
    KF5::Contacts
    KF5::ItemModels
    KF5::XmlGui
    KF5::EventViews # for reading KOrganizer calendar colors

)
kconfig_add_kcfg_files(kalendar GENERATE_MOC kalendarconfig.kcfgc)
install(TARGETS kalendar ${KF5_INSTALL_TARGETS_DEFAULT_ARGS})
