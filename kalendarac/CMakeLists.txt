# SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
#
# SPDX-License-Identifier: BSD-2-Clause

set(kalendarac_SRCS
    kalendaralarmclient.cpp
    alarmnotification.cpp
    notificationhandler.cpp
    kalendaracmain.cpp
    )

qt5_add_dbus_adaptor(kalendarac_SRCS org.kde.kalendarac.xml kalendaralarmclient.h KalendarAlarmClient)

add_executable(kalendarac ${kalendarac_SRCS} ${RESOURCES})

target_link_libraries(kalendarac
    KF5::CoreAddons
    KF5::ConfigCore
    KF5::CalendarCore
    KF5::DBusAddons
    KF5::AkonadiCore
    KF5::CalendarSupport
    KF5::I18n
    KF5::Notifications
    Qt5::Core
    Qt5::DBus
    )

install(TARGETS
    kalendarac ${KDE_INSTALL_TARGETS_DEFAULT_ARGS}
    )

install(FILES
    org.kde.kalendarac.desktop
    DESTINATION ${KDE_INSTALL_AUTOSTARTDIR}
    )

install(FILES kalendarac.notifyrc DESTINATION ${KNOTIFYRC_INSTALL_DIR})

set(SERV_EXEC ${KDE_INSTALL_FULL_BINDIR}/kalendarac)
configure_file(org.kde.kalendarac.service.in ${CMAKE_CURRENT_BINARY_DIR}/org.kde.kalendarac.service)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.kde.kalendarac.service DESTINATION ${KDE_INSTALL_FULL_DBUSSERVICEDIR})

