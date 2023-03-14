# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

if (BUILD_TESTING)
    add_subdirectory(tests)
    add_subdirectory(mime/tests)
    add_subdirectory(mimetreeparser/autotests)
    add_subdirectory(mimetreeparser/tests)
endif()

set(kalendar_mail_SRCS
    mailmanager.cpp
    mailmanager.h
    mailmodel.cpp
    mailmodel.h
    helper.h
    helper.cpp
    contactimageprovider.cpp
    contactimageprovider.h

    messagestatus.h
    messagestatus.cpp

    crypto.cpp
    mimetreeparser/messagepart.cpp
    mimetreeparser/bodypartformatter.cpp
    mimetreeparser/bodypartformatter_impl.cpp
    mimetreeparser/bodypartformatterbasefactory.cpp
    mimetreeparser/bodypartformatterbasefactory.cpp
    mimetreeparser/cryptohelper.cpp
    mimetreeparser/messagepart.cpp
    mimetreeparser/mimetreeparser_debug.cpp
    mimetreeparser/objecttreeparser.cpp
    mimetreeparser/utils.cpp
    mime/attachmentmodel.cpp
    mime/htmlutils.cpp
    mime/mailcrypto.cpp
    mime/mailtemplates.cpp
    mime/messageparser.cpp
    mime/partmodel.cpp

    crypto.h
    mimetreeparser/messagepart.h
    mimetreeparser/bodypartformatter.h
    mimetreeparser/bodypartformatterbasefactory.h
    mimetreeparser/bodypartformatterbasefactory.h
    mimetreeparser/cryptohelper.h
    mimetreeparser/messagepart.h
    mimetreeparser/objecttreeparser.h
    mimetreeparser/utils.h
    mime/attachmentmodel.h
    mime/htmlutils.h
    mime/mailcrypto.h
    mime/mailtemplates.h
    mime/messageparser.h
    mime/partmodel.h

)

ecm_qt_declare_logging_category(kalendar_mail_SRCS
    HEADER kalendar_mail_debug.h
    IDENTIFIER "KALENDAR_MAIL_LOG"
    CATEGORY_NAME org.kde.kalendar.mail
    DESCRIPTION "kalendar mail"
    EXPORT KALENDAR
)

ecm_qt_export_logging_category(
    IDENTIFIER "KALENDAR_MAIL_LOG"
    CATEGORY_NAME "org.kde.kalendar.mail"
    DESCRIPTION "Kalendar - mail"
    EXPORT KALENDAR
)

add_library(kalendar_mail_static STATIC ${kalendar_mail_SRCS})
set_target_properties(kalendar_mail_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(kalendar_mail_static PUBLIC kalendar_lib KPim${QT_MAJOR_VERSION}::MailCommon KPim${QT_MAJOR_VERSION}::AkonadiMime KF${QT_MAJOR_VERSION}::Codecs)

if(QT_MAJOR_VERSION STREQUAL "6")
    target_link_libraries(kalendar_mail_static PUBLIC Qt::Core5Compat)
endif()

ecm_add_qml_module(kalendar_mail_plugin URI "org.kde.kalendar.mail" VERSION 1.0)

target_sources(kalendar_mail_plugin PRIVATE
    mailplugin.cpp
    mailplugin.h
)

ecm_target_qml_sources(kalendar_mail_plugin SOURCES
    qml/MailSidebar.qml
    qml/FolderView.qml
    qml/MailViewer.qml
    qml/ConversationViewer.qml
    qml/MailApplication.qml
)
ecm_target_qml_sources(kalendar_mail_plugin
    PRIVATE PATH private SOURCES
    qml/private/AttachmentDelegate.qml
    qml/private/MailDelegate.qml
    qml/private/MenuBar.qml
    qml/private/GlobalMenuBar.qml
    qml/private/EditMenu.qml
)

ecm_target_qml_sources(kalendar_mail_plugin
    PRIVATE PATH mailboxselector SOURCES
    qml/mailboxselector/MailBoxList.qml
    qml/mailboxselector/MailBoxListPage.qml
)

ecm_target_qml_sources(kalendar_mail_plugin
    PRIVATE PATH mailpartview SOURCES
    qml/mailpartview/HtmlPart.qml
    qml/mailpartview/ICalPart.qml
    qml/mailpartview/MailPart.qml
    qml/mailpartview/MailPartModel.qml
    qml/mailpartview/MailPartView.qml
    qml/mailpartview/TextPart.qml
)

target_link_libraries(kalendar_mail_plugin PUBLIC kalendar_mail_static)

ecm_finalize_qml_module(kalendar_mail_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)
