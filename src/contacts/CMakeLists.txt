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
    phonemodel.h
    phonemodel.cpp
    emailmodel.h
    emailmodel.cpp
    globalcontactmodel.cpp
    globalcontactmodel.h
    contactmanager.h
    contactmanager.cpp
    contactcollectionmodel.cpp
    contactcollectionmodel.h
    contacteditorbackend.h
    contacteditorbackend.cpp
    contactgroupeditor.h
    contactgroupeditor.cpp
    contactgroupwrapper.h
    contactgroupwrapper.cpp
    contactgroupmodel.h
    contactgroupmodel.cpp
    contactmetadata.cpp
    contactmetadata.h
    contactsmodel.cpp
    contactsmodel.h
    attributes/contactmetadataattribute_p.h
    attributes/contactmetadataattribute.cpp
    attributes/attributeregistrar.cpp
    resources.qrc
)

kconfig_add_kcfg_files(kalendar_contact_plugin GENERATE_MOC contactconfig.kcfgc)

ecm_target_qml_sources(kalendar_contact_plugin SOURCES
    qml/ContactChooserPage.qml
    qml/ContactView.qml
    qml/ContactApplication.qml
    qml/AddressBookCollectionHandler.qml
)

ecm_target_qml_sources(kalendar_contact_plugin
    PRIVATE PATH private SOURCES
    qml/private/ContactPage.qml
    qml/private/ContactEditorPage.qml
    qml/private/ContactGroupPage.qml
    qml/private/ContactGroupEditorPage.qml
    qml/private/ContactsPage.qml
    qml/private/ContactListItem.qml
    qml/private/Header.qml
    qml/private/MenuBar.qml
    qml/private/PhoneNumberDialog.qml
    qml/private/QrCodePage.qml
    qml/private/AddressBookMenu.qml
    qml/private/DeleteContactAction.qml
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