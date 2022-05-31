# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_qml_module(kalendar_mail_plugin URI "org.kde.kalendar.mail" VERSION 1.0)

target_sources(kalendar_mail_plugin PRIVATE
    mailplugin.cpp
    mailplugin.h
    mailmanager.cpp
    mailmanager.h
    mailmodel.cpp
    mailmodel.h
)

ecm_target_qml_sources(kalendar_mail_plugin SOURCES
    qml/MailSidebar.qml
    qml/FolderView.qml
)

#ecm_target_qml_sources(kalendar_contact_plugin
#    PRIVATE PATH private SOURCES
#    qml/private/ContactListItem.qml
#    qml/private/ContactPage.qml
#    qml/private/ContactsPage.qml
#    qml/private/Header.qml
#    qml/private/PhoneNumberDialog.qml
#    qml/private/QrCodePage.qml
#)

ecm_qt_declare_logging_category(kalendar_contact_plugin
    HEADER kalendar_mail_debug.h
    IDENTIFIER KALENDAR_MAIL_LOG
    CATEGORY_NAME org.kde.kalendar.mail
    DESCRIPTION "kalendar mail"
    EXPORT KALENDAR
)

target_link_libraries(kalendar_mail_plugin PRIVATE kalendar_lib KF5::MailCommon KF5::AkonadiMime)

ecm_qt_install_logging_categories(
    EXPORT KALENDAR
    FILE kalendar.contact.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

#if (BUILD_TESTING)
#    add_subdirectory(autotests)
#endif()

ecm_finalize_qml_module(kalendar_mail_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)