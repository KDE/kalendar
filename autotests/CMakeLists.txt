# SPDX-FileCopyrightText: (C) 2022 Claudio Cambra <claudio.cambra@gmail.com>
#
# SPDX-License-Identifier: BSD-2-Clause

enable_testing()

include_directories(${kalendar_CURRENT_BINARY_DIR})
include_directories(${kalendar_BINARY_DIR})
include_directories(${kalendar_BINARY_DIR}/src)

set(incidenceOccurrenceModelTest_SRCS
    incidenceoccurrencemodeltest.cpp
    ../src/models/incidenceoccurrencemodel.cpp
)
ecm_qt_declare_logging_category(incidenceOccurrenceModelTest_SRCS HEADER kalendar_debug.h IDENTIFIER KALENDAR_LOG CATEGORY_NAME org.kde.kalendar DESCRIPTION "kalendar" EXPORT KALENDAR)

set (incidenceOccurrenceModelTest_LIBS
    Qt::Test
    Qt5::Core
    KF5::ConfigCore
    KF5::CalendarCore
    KF5::AkonadiCore
    KF5::AkonadiCalendar
)

# the tests need the ical resource, which we might not have at this point (e.g. on the CI)
find_program(AKONADI_ICAL_RESOURCE NAMES akonadi_ical_resource)
# if (AKONADI_ICAL_RESOURCE)
    add_akonadi_isolated_test_advanced(incidenceoccurrencemodeltest.cpp "${incidenceOccurrenceModelTest_SRCS}" "${incidenceOccurrenceModelTest_LIBS}")
# endif()
