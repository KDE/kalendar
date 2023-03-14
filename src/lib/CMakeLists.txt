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
    KF${QT_MAJOR_VERSION}::I18n
    KF${QT_MAJOR_VERSION}::CoreAddons
    KF${QT_MAJOR_VERSION}::CalendarCore
    KPim${QT_MAJOR_VERSION}::AkonadiCore
    KPim${QT_MAJOR_VERSION}::AkonadiCalendar
    KPim${QT_MAJOR_VERSION}::AkonadiContact
    KPim${QT_MAJOR_VERSION}::AkonadiAgentBase
    KPim${QT_MAJOR_VERSION}::AkonadiXml
    KF${QT_MAJOR_VERSION}::ConfigWidgets
    KF${QT_MAJOR_VERSION}::Contacts
    KF${QT_MAJOR_VERSION}::ItemModels
    KPim${QT_MAJOR_VERSION}::EventViews
)
