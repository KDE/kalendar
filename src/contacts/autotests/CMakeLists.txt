# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(kalendar_contact STATIC
    ../addresseewrapper.cpp
    ../addresseewrapper.h
    ../addressmodel.cpp
    ../addressmodel.h
    ../emailmodel.h
    ../emailmodel.cpp
    ../phonemodel.h
    ../phonemodel.cpp
    ../globalcontactmodel.cpp
    ../globalcontactmodel.h
    ../contactmanager.h
    ../contactmanager.cpp
    ../contactcollectionmodel.cpp
    ../contactcollectionmodel.h
)

target_include_directories(kalendar_contact INTERFACE "$<INSTALL_INTERFACE:${KALENDAR_CONTACT_INCLUDE_INSTALL_DIR}>")

target_link_libraries(kalendar_contact PRIVATE kalendar_lib)

ecm_qt_declare_logging_category(kalendar_contact
    HEADER kalendar_contact_debug.h
    IDENTIFIER KALENDAR_LOG
    CATEGORY_NAME org.kde.kalendar.contact
    DESCRIPTION "kalendar contact"
    EXPORT KALENDAR
)

ecm_add_test(emailmodeltest.cpp
    TEST_NAME emailmodeltest
    LINK_LIBRARIES kalendar_contact kalendar_lib Qt::Test
    NAME_PREFIX "kalendar-contact-"
)
