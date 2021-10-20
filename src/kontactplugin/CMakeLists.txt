########### next target ###############
add_library(kontact_kalendarplugin MODULE)

qt_add_dbus_interfaces(kontact_kalendar_PART_SRCS ${kalendar_SOURCE_DIR}/src/org.kde.kalendar.part.xml)
target_sources(kontact_kalendarplugin PRIVATE kalendar_uniqueapp.cpp kalendarplugin.cpp ${kontact_kalendar_PART_SRCS})

target_link_libraries(kontact_kalendarplugin KF5::I18n KF5::KontactInterface KF5::XmlGui KF5::WindowSystem Qt5::Core Qt5::Gui Qt5::DBus)

kcoreaddons_desktop_to_json(kontact_kalendarplugin "kalendarplugin.desktop"  SERVICE_TYPES kcmodule.desktop)


########### install files ###############

install(TARGETS kontact_kalendarplugin DESTINATION ${KDE_INSTALL_PLUGINDIR}/kontact5)

install(FILES kalendarplugin.desktop DESTINATION ${KDE_INSTALL_KSERVICES5DIR}/kontact)

