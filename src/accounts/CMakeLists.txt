# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

set(kalendar_accounts_SRCS
    mailaccounts.h
    newaccount.h
    mailaccounts.cpp
    newaccount.cpp

    setup/configfile.h
    setup/identity.h
    setup/key.h
    setup/ldap.h
    setup/resource.h
    setup/restoreldapsettingsjob.h
    setup/setupautoconfigkolabfreebusy.h
    setup/setupautoconfigkolabldap.h
    setup/setupautoconfigkolabmail.h
    setup/setupispdb.h
    setup/setupmanager.h
    setup/setupobject.h
    setup/transport.h
    setup/configfile.cpp
    setup/identity.cpp
    setup/key.cpp
    setup/ldap.cpp
    setup/resource.cpp
    setup/restoreldapsettingsjob.cpp
    setup/setupautoconfigkolabfreebusy.cpp
    setup/setupautoconfigkolabldap.cpp
    setup/setupautoconfigkolabmail.cpp
    setup/setupispdb.cpp
    setup/setupmanager.cpp
    setup/setupobject.cpp
    setup/transport.cpp

    ispdb/autoconfigkolabfreebusy.h
    ispdb/autoconfigkolabldap.h
    ispdb/autoconfigkolabmail.h
    ispdb/ispdb.h
    ispdb/autoconfigkolabfreebusy.cpp
    ispdb/autoconfigkolabldap.cpp
    ispdb/autoconfigkolabmail.cpp
    ispdb/ispdb.cpp
)

ecm_qt_declare_logging_category(kalendar_accounts_SRCS
    HEADER kalendar_accounts_debug.h
    IDENTIFIER "KALENDAR_ACCOUNTS_LOG"
    CATEGORY_NAME org.kde.kalendar.accounts
    DESCRIPTION "kalendar accounts wizzard"
    EXPORT KALENDAR
)

ecm_qt_export_logging_category(
    IDENTIFIER "KALENDAR_MAIL_LOG"
    CATEGORY_NAME "org.kde.kalendar.accounts"
    DESCRIPTION "Kalendar - accounts"
    EXPORT KALENDAR
)

add_library(kalendar_accounts_static STATIC ${kalendar_accounts_SRCS})
target_link_libraries(kalendar_accounts_static
PUBLIC
    kalendar_lib
    KF5::MailCommon
    KF5::AkonadiMime
    KF5::MailTransport
    KF5::MailTransportAkonadi
    KF5::Ldap
)

ecm_add_qml_module(kalendar_accounts_plugin URI "org.kde.kalendar.accounts" VERSION 1.0)

target_sources(kalendar_accounts_plugin PRIVATE
    accountsplugin.cpp
    accountsplugin.h
)

ecm_target_qml_sources(kalendar_accounts_plugin SOURCES
    qml/AddAccountPage.qml
    qml/FormPasswordInputDelegate.qml
    qml/FormTextInputDelegate.qml
)

target_link_libraries(kalendar_accounts_plugin PUBLIC kalendar_accounts_static)

ecm_finalize_qml_module(kalendar_accounts_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)