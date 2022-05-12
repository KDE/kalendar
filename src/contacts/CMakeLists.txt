# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

set(kalendar_contact_plugin_SRCS
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

add_library(kalendar_contact_plugin SHARED ${kalendar_contact_plugin_SRCS})

target_link_libraries(kalendar_contact_plugin
    kalendar_lib
)

ecm_qt_declare_logging_category(kalendar_contact_plugin HEADER kalendar_contact_debug.h IDENTIFIER KALENDAR_LOG CATEGORY_NAME org.kde.kalendar.contact DESCRIPTION "kalendar contact" EXPORT KALENDAR)

ecm_qt_install_logging_categories(
        EXPORT KALENDAR
        FILE kalendar.contact.categories
        DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
        )


install(TARGETS kalendar_contact_plugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/kalendar/contact)
install(DIRECTORY qml/ DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/kalendar/contact)

ecm_generate_qmltypes(org.kde.kalendar.contact 1.0 DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/kalendar/contact)