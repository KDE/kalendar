# SPDX-FileCopyrightText: 2023 Joshua Goins <josh@redstrate.com>
# SPDX-FileCopyrightText: 2023 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(calutilstest.cpp
    TEST_NAME calutilstest
    LINK_LIBRARIES kalendar_calendar_static Qt::Test
    NAME_PREFIX "kalendar-calendar-"
)

ecm_add_test(remindersmodeltest.cpp
    TEST_NAME remindersmodeltest
    LINK_LIBRARIES kalendar_calendar_static Qt::Test
    NAME_PREFIX "kalendar-calendar-"
)

ecm_add_test(filtertest.cpp
    TEST_NAME filtertest
    LINK_LIBRARIES kalendar_calendar_static Qt::Test
    NAME_PREFIX "kalendar-calendar-"
)

# the tests need the ical resource, which we might not have at this point (e.g. on the CI)
find_program(AKONADI_ICAL_RESOURCE NAMES akonadi_ical_resource)
if (UNIX)
    add_akonadi_isolated_test_advanced(incidenceoccurrencemodeltest incidenceoccurrencemodeltest.cpp kalendar_calendar_static Qt::Test)
    add_akonadi_isolated_test_advanced(todosortfilterproxymodeltest todosortfilterproxymodeltest.cpp kalendar_calendar_static Qt::Test)
endif()
