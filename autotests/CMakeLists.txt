# SPDX-FileCopyrightText: (C) 2022 Claudio Cambra <claudio.cambra@gmail.com>
#
# SPDX-License-Identifier: BSD-2-Clause


include(ECMMarkAsTest)
include(ECMAddTests)

set( KDEPIMLIBS_RUN_ISOLATED_TESTS TRUE )

enable_testing(true)

include_directories(${kalendar_CURRENT_BINARY_DIR})
include_directories(${kalendar_BINARY_DIR})
include_directories(${kalendar_BINARY_DIR}/src)

set (commonAkonadiTest_LIBS
    Qt::Test
    Qt::Core
    KF${QT_MAJOR_VERSION}::ConfigCore
    KF${QT_MAJOR_VERSION}::CalendarCore
    KPim${QT_MAJOR_VERSION}::CalendarSupport
    KPim${QT_MAJOR_VERSION}::AkonadiCore
    KPim${QT_MAJOR_VERSION}::AkonadiCalendar
    KPim${QT_MAJOR_VERSION}::EventViews
)

set(filterTest_SRCS
    filtertest.cpp
    ../src/filter.cpp
    ../src/utils.cpp
)

set(incidenceOccurrenceModelTest_SRCS
    incidenceoccurrencemodeltest.cpp
    ../src/models/incidenceoccurrencemodel.cpp
    ../src/filter.cpp
    ../src/utils.cpp
    ../src/utils.h
)

set(todoSortFilterProxyModelTest_SRCS
    todosortfilterproxymodeltest.cpp
    ../src/models/todosortfilterproxymodel.cpp
    ../src/filter.cpp
    ../src/utils.cpp
)

ecm_qt_declare_logging_category(incidenceOccurrenceModelTest_SRCS HEADER kalendar_debug.h IDENTIFIER KALENDAR_LOG CATEGORY_NAME org.kde.kalendar DESCRIPTION "kalendar" EXPORT KALENDAR)

add_executable(filtertest ${filterTest_SRCS})
add_test(NAME filtertest COMMAND filtertest)
ecm_mark_as_test(filtertest)
target_link_libraries(filtertest ${commonAkonadiTest_LIBS})

# the tests need the ical resource, which we might not have at this point (e.g. on the CI)
find_program(AKONADI_ICAL_RESOURCE NAMES akonadi_ical_resource)
if (UNIX)
    add_akonadi_isolated_test_advanced(incidenceoccurrencemodeltest.cpp "${incidenceOccurrenceModelTest_SRCS}" "${commonAkonadiTest_LIBS}")
    add_akonadi_isolated_test_advanced(todosortfilterproxymodeltest.cpp "${todoSortFilterProxyModelTest_SRCS}" "${commonAkonadiTest_LIBS}")
endif()
