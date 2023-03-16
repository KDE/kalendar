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
