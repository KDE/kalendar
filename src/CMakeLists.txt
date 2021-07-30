# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

add_executable(kalendar about.cpp main.cpp agentconfiguration.cpp incidenceoccurrencemodel.cpp calendarmanager.cpp multidayincidencemodel.cpp incidencewrapper.cpp remindersmodel.cpp attendeesmodel.cpp recurrenceexceptionsmodel.cpp attachmentsmodel.cpp resources.qrc)

target_link_libraries(kalendar
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickControls2
    Qt5::Svg
    KF5::I18n
    KF5::Package
    KF5::CoreAddons
    KF5::CalendarCore
    KF5::AkonadiCore
    KF5::AkonadiAgentBase
    KF5::AkonadiXml
    KF5::CalendarSupport
    KF5::WindowSystem
    KF5::ConfigWidgets
    KF5::AkonadiWidgets
)
install(TARGETS kalendar ${KF5_INSTALL_TARGETS_DEFAULT_ARGS})
