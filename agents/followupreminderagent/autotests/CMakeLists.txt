set(followupreminderagent_test_SRCS)
qt_add_dbus_interface(followupreminderagent_test_SRCS ../org.freedesktop.Notifications.xml notifications_interface)
qt_add_dbus_interface(followupreminderagent_test_SRCS ../org.freedesktop.DBus.Properties.xml dbusproperties)

set(autotest_categories_followupreminderagent_SRCS)
ecm_qt_declare_logging_category(autotest_categories_followupreminderagent_SRCS HEADER followupreminderagent_debug.h IDENTIFIER FOLLOWUPREMINDERAGENT_LOG CATEGORY_NAME org.kde.pim.followupreminderagent)

# Convenience macro to add unit tests.
macro( followupreminder_agent _source )
    set( _test ${_source} ${followupreminderagent_test_SRCS} ${autotest_categories_followupreminderagent_SRCS})
    get_filename_component( _name ${_source} NAME_WE )
    ecm_add_test(${_test} ${_name}.h
        TEST_NAME ${_name}
        NAME_PREFIX "followupreminder-"
        LINK_LIBRARIES followupreminderagent Qt::Test KF5::AkonadiCore Qt::Widgets KF5::I18n KF5::XmlGui KF5::Service
        )
endmacro()

followupreminder_agent(followupreminderinfotest.cpp)
followupreminder_agent(followupremindernoanswerdialogtest.cpp)
followupreminder_agent(followupreminderconfigtest.cpp)
