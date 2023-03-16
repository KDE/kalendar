# SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
#
# SPDX-License-Identifier: BSD-2-Clause

ecm_add_qml_module(akonadi_quick_plugin URI "org.kde.akonadi" VERSION 1.0)

target_sources(akonadi_quick_plugin PRIVATE
    akonadiquickplugin.cpp
    akonadiquickplugin.h
    agentconfiguration.cpp
    agentconfiguration.h
    collectioncomboboxmodel.cpp
    collectioncomboboxmodel.h
    collectionpickermodel.cpp
    collectionpickermodel.h
    collection.cpp
    collection.h
    mimetypes.cpp
    mimetypes.h
    tagmanager.cpp
    tagmanager.h
)

ecm_target_qml_sources(akonadi_quick_plugin SOURCES
    qml/CollectionComboBox.qml
    qml/MobileCollectionComboBox.qml
    qml/AgentConfigurationForm.qml
)

ecm_qt_declare_logging_category(akonadi_quick_plugin
    HEADER akonadi_quick_debug.h
    IDENTIFIER AKONADI_QUICK_LOG
    CATEGORY_NAME org.kde.akonadi.quick
    DESCRIPTION "Akonadi QtQuick Plugin"
    EXPORT KALENDAR
)

target_link_libraries(akonadi_quick_plugin PRIVATE kalendar_lib KF${QT_MAJOR_VERSION}::WindowSystem)

ecm_qt_install_logging_categories(
    EXPORT KALENDAR
    FILE akonadi.quick.categories
    DESTINATION ${KDE_INSTALL_LOGGINGCATEGORIESDIR}
)

ecm_finalize_qml_module(akonadi_quick_plugin
    DESTINATION ${KDE_INSTALL_QMLDIR}
    BUILD_SHARED_LIBS OFF)
