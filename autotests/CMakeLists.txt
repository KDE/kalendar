# SPDX-FileCopyrightText: (C) 2022 Claudio Cambra <claudio.cambra@gmail.com>
#
# SPDX-License-Identifier: BSD-2-Clause

enable_testing()

include_directories(${kalendar_CURRENT_BINARY_DIR})
include_directories(${kalendar_BINARY_DIR})
include_directories(${kalendar_BINARY_DIR}/src)

set (commonAkonadiTest_LIBS
    Qt::Test
    Qt::Core
    KF5::ConfigCore
    KF5::CalendarCore
    KF5::CalendarSupport
    KF5::AkonadiCore
    KF5::AkonadiCalendar
    KF5::EventViews
)

set(incidenceOccurrenceModelTest_SRCS
    incidenceoccurrencemodeltest.cpp
    ../src/models/incidenceoccurrencemodel.cpp
)

set(todoSortFilterProxyModelTest_SRCS
    todosortfilterproxymodeltest.cpp
    ../src/models/todosortfilterproxymodel.cpp
)

ecm_qt_declare_logging_category(incidenceOccurrenceModelTest_SRCS HEADER kalendar_debug.h IDENTIFIER KALENDAR_LOG CATEGORY_NAME org.kde.kalendar DESCRIPTION "kalendar" EXPORT KALENDAR)

# the tests need the ical resource, which we might not have at this point (e.g. on the CI)
find_program(AKONADI_ICAL_RESOURCE NAMES akonadi_ical_resource)
if (UNIX)
    add_akonadi_isolated_test_advanced(incidenceoccurrencemodeltest.cpp "${incidenceOccurrenceModelTest_SRCS}" "${commonAkonadiTest_LIBS}")
    add_akonadi_isolated_test_advanced(todosortfilterproxymodeltest.cpp "${todoSortFilterProxyModelTest_SRCS}" "${commonAkonadiTest_LIBS}")
endif()
