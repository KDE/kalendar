# SPDX-FileCopyrightText: 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_qml_module(kalendar_mail_plugin URI "org.kde.kalendar.mail" VERSION 1.0)

target_sources(kalendar_mail_plugin PUBLIC
    mailplugin.cpp
    mailplugin.h
    mailmanager.cpp
    mailmanager.h
    mailmodel.cpp
    mailmodel.h

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
)

ecm_target_qml_sources(kalendar_mail_plugin SOURCES
    qml/MailSidebar.qml
    qml/FolderView.qml
    qml/MailViewer.qml
    qml/ConversationViewer.qml
)
ecm_target_qml_sources(kalendar_mail_plugin
    PRIVATE PATH private SOURCES
    qml/private/AttachmentDelegate.qml
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

ecm_qt_declare_logging_category(kalendar_contact_plugin
    HEADER kalendar_mail_debug.h
    IDENTIFIER KALENDAR_MAIL_LOG
    CATEGORY_NAME org.kde.kalendar.mail
    DESCRIPTION "kalendar mail"
    EXPORT KALENDAR
)

target_link_libraries(kalendar_mail_plugin PRIVATE kalendar_lib KF5::MailCommon KF5::AkonadiMime Qt5::WebEngineWidgets)

ecm_qt_install_logging_categories(
    EXPORT KALENDAR
    FILE kalendar.contact.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

if (BUILD_TESTING)
    add_subdirectory(tests)
    add_subdirectory(mime/tests)
    add_subdirectory(mimetreeparser/autotests)
    add_subdirectory(mimetreeparser/tests)
endif()

ecm_finalize_qml_module(kalendar_mail_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)