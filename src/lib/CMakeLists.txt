# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause


add_library(kalendar_lib STATIC)
target_sources(kalendar_lib PRIVATE
    colorproxymodel.cpp
    sortedcollectionproxymodel.cpp
    colorproxymodel.h
    sortedcollectionproxymodel.h
)
set_property(TARGET kalendar_lib PROPERTY POSITION_INDEPENDENT_CODE ON)

target_include_directories(kalendar_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(kalendar_lib PUBLIC
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::QuickControls2
    Qt::Svg
    KF6::I18n
    KF6::CoreAddons
    KF6::CalendarCore
    KPim6::AkonadiCore
    KPim6::AkonadiCalendar
    KPim6::AkonadiContact
    KF6::ConfigWidgets
    KF6::Contacts
    KF6::ItemModels
    KPim6::CalendarUtils
)
