# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

qt5_add_resources(kalendar_SRCS resources.qrc)
add_executable(kalendar main.cpp monthmodel.cpp weekmodel.cpp ${kalendar_SRCS})
target_link_libraries(kalendar Qt5::Core Qt5::Gui Qt5::Qml Qt5::Quick Qt5::QuickControls2 Qt5::Svg KF5::I18n KF5::Package KF5::CalendarCore)
install(TARGETS kalendar ${KF5_INSTALL_TARGETS_DEFAULT_ARGS})
