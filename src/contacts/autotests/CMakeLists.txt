# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_test(emailmodeltest.cpp
    TEST_NAME emailmodeltest
    LINK_LIBRARIES kalendar_contact_static Qt::Test
    NAME_PREFIX "kalendar-contact-"
)

ecm_add_test(imppmodeltest.cpp
    TEST_NAME imppmodeltest
    LINK_LIBRARIES kalendar_contact_static Qt::Test
    NAME_PREFIX "kalendar-contact-"
)
