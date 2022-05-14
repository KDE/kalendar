# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_qml_module(kalendar_contact_plugin URI "org.kde.kalendar.contact" VERSION 1.0)

target_sources(kalendar_contact_plugin PRIVATE
    contactplugin.cpp
    contactplugin.h
    addresseewrapper.cpp
    addresseewrapper.h
    addressmodel.cpp
    addressmodel.h
    emailmodel.h
    emailmodel.cpp
    globalcontactmodel.cpp
    globalcontactmodel.h
    contactmanager.h
    contactmanager.cpp
    contactcollectionmodel.cpp
    contactcollectionmodel.h
    resources.qrc
)

ecm_target_qml_sources(kalendar_contact_plugin SOURCES
    qml/ContactChooserPage.qml
    qml/ContactView.qml
)

ecm_target_qml_sources(kalendar_contact_plugin
    PRIVATE PATH private SOURCES
    qml/private/ContactListItem.qml
    qml/private/ContactPage.qml
    qml/private/ContactsPage.qml
    qml/private/Header.qml
    qml/private/PhoneNumberDialog.qml
)

ecm_qt_declare_logging_category(kalendar_contact_plugin
    HEADER kalendar_contact_debug.h
    IDENTIFIER KALENDAR_LOG
    CATEGORY_NAME org.kde.kalendar.contact
    DESCRIPTION "kalendar contact"
    EXPORT KALENDAR
)

target_link_libraries(kalendar_contact_plugin PRIVATE kalendar_lib)

ecm_qt_install_logging_categories(
    EXPORT KALENDAR
    FILE kalendar.contact.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

if (BUILD_TESTING)
    add_subdirectory(autotests)
endif()

add_subdirectory(applet)

ecm_finalize_qml_module(kalendar_contact_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)