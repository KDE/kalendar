# SPDX-FileCopyrightText: 2013 Sandro Knauß <mail@sandroknauss.de>
#
# SPDX-License-Identifier: BSD-3-Clause

set(MIMETREEPARSERRELPATH src/mail/mimetreeparser)
set(GNUPGHOME ${CMAKE_BINARY_DIR}/${MIMETREEPARSERRELPATH}/tests/gnupg_home)
add_definitions(-DGNUPGHOME="${GNUPGHOME}")

macro (ADD_GPG_CRYPTO_TEST _target _testname)
   if (UNIX)
      if (APPLE)
         set(_library_path_variable "DYLD_LIBRARY_PATH")
      elseif (CYGWIN)
         set(_library_path_variable "PATH")
      else (APPLE)
         set(_library_path_variable "LD_LIBRARY_PATH")
      endif (APPLE)

      if (APPLE)
         # DYLD_LIBRARY_PATH does not work like LD_LIBRARY_PATH
         # OSX already has the RPATH in libraries and executables, putting runtime directories in
         # DYLD_LIBRARY_PATH actually breaks things
         set(_ld_library_path "${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR}/")
      else (APPLE)
         set(_ld_library_path "${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR}/:${LIB_INSTALL_DIR}:${QT_LIBRARY_DIR}")
      endif (APPLE)
      set(_executable "$<TARGET_FILE:${_target}>")

      # use add_custom_target() to have the sh-wrapper generated during build time instead of cmake time
      add_custom_command(TARGET ${_target} POST_BUILD
        COMMAND ${CMAKE_COMMAND}
        -D_filename=${_executable}.shell -D_library_path_variable=${_library_path_variable}
        -D_ld_library_path="${_ld_library_path}" -D_executable=$<TARGET_FILE:${_target}>
        -D_gnupghome="${GNUPGHOME}"
        -P ${CMAKE_SOURCE_DIR}/cmake/modules/kdepim_generate_crypto_test_wrapper.cmake
      )

      set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${_executable}.shell" )
      add_test(NAME ${_testname} COMMAND ${_executable}.shell)

   else (UNIX)
      # under windows, set the property WRAPPER_SCRIPT just to the name of the executable
      # maybe later this will change to a generated batch file (for setting the PATH so that the Qt libs are found)
      set(_ld_library_path "${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR}\;${LIB_INSTALL_DIR}\;${QT_LIBRARY_DIR}")
      set(_executable "$<TARGET_FILE:${_target}>")

      # use add_custom_target() to have the batch-file-wrapper generated during build time instead of cmake time
      add_custom_command(TARGET ${_target} POST_BUILD
         COMMAND ${CMAKE_COMMAND}
         -D_filename="${_executable}.bat"
         -D_ld_library_path="${_ld_library_path}" -D_executable="${_executable}"
         -D_gnupghome="${GNUPGHOME}"
         -P ${CMAKE_SOURCE_DIR}/cmake/modules/kdepim_generate_crypto_test_wrapper.cmake
         )

      add_test(NAME ${_testname} COMMAND ${_executable}.bat)

   endif (UNIX)

   # can't be parallelized due to gpg-agent
   set_tests_properties(${_testname} PROPERTIES RUN_SERIAL TRUE)
endmacro (ADD_GPG_CRYPTO_TEST)

macro (ADD_GPG_CRYPTO_AKONADI_TEST _target _testname)
    set(_executable "$<TARGET_FILE:${_target}>")

    if (UNIX)
        if (APPLE)
            set(_library_path_variable "DYLD_LIBRARY_PATH")
        elseif (CYGWIN)
            set(_library_path_variable "PATH")
        else (APPLE)
            set(_library_path_variable "LD_LIBRARY_PATH")
        endif (APPLE)

        if (APPLE)
            # DYLD_LIBRARY_PATH does not work like LD_LIBRARY_PATH
            # OSX already has the RPATH in libraries and executables, putting runtime directories in
            # DYLD_LIBRARY_PATH actually breaks things
            set(_ld_library_path "${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR}/")
        else (APPLE)
            set(_ld_library_path "${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR}/:${LIB_INSTALL_DIR}:${QT_LIBRARY_DIR}")
        endif (APPLE)

        set(_posix "shell")
        set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${_executable}.${_posix}" )

        # use add_custom_target() to have the sh-wrapper generated during build time instead of cmake time
        add_custom_command(TARGET ${_target} POST_BUILD
            COMMAND ${CMAKE_COMMAND}
            -D_filename=${_executable}.${_posix} -D_library_path_variable=${_library_path_variable}
            -D_ld_library_path="${_ld_library_path}" -D_executable="${_executable}"
            -D_gnupghome="${GNUPGHOME}"
            -P ${CMAKE_SOURCE_DIR}/cmake/modules/kdepim_generate_crypto_test_wrapper.cmake
        )


    else (UNIX)
        # under windows, set the property WRAPPER_SCRIPT just to the name of the executable
        # maybe later this will change to a generated batch file (for setting the PATH so that the Qt libs are found)
        set(_ld_library_path "${LIBRARY_OUTPUT_PATH}/${CMAKE_CFG_INTDIR}\;${LIB_INSTALL_DIR}\;${QT_LIBRARY_DIR}")
        set(_posix "bat")

        # use add_custom_target() to have the batch-file-wrapper generated during build time instead of cmake time
        add_custom_command(TARGET ${_target} POST_BUILD
            COMMAND ${CMAKE_COMMAND}
            -D_filename="${_executable}.${_posix}"
            -D_ld_library_path="${_ld_library_path}" -D_executable="${_executable}"
            -D_gnupghome="${GNUPGHOME}"
            -P ${CMAKE_SOURCE_DIR}/cmake/modules/kdepim_generate_crypto_test_wrapper.cmake
        )

    endif ()

    if (NOT DEFINED _testrunner)
        find_program(_testrunner NAMES akonaditest akonaditest.exe)
        if (NOT _testrunner)
            message(WARNING "Could not locate akonaditest executable, isolated Akonadi tests will fail!")
        endif()
    endif()

    function(_defineTest name backend)
        set(backends ${ARGN})
        if (NOT DEFINED AKONADI_RUN_${backend}_ISOLATED_TESTS OR AKONADI_RUN_${backend}_ISOLATED_TESTS)
            LIST(LENGTH "${backends}" backendsLen)
            string(TOLOWER ${backend} lcbackend)
            LIST(FIND "${backends}" ${lcbackend} enableBackend)
            if (${backendsLen} EQUAL 0 OR ${enableBackend} GREATER -1)
                set(configFile ${CMAKE_CURRENT_SOURCE_DIR}/unittestenv/config.xml)
                if (AKONADI_TESTS_XML)
                    set(extraOptions -xml -o "${TEST_RESULT_OUTPUT_PATH}/${lcbackend}-${name}.xml")
                endif()
                set(_test_name akonadi-${lcbackend}-${name})
                add_test(NAME ${_test_name}
                            COMMAND ${_testrunner} -c "${configFile}" -b ${lcbackend}
                                    "${_executable}.${_posix}" ${extraOptions}
                )
                # Taken from ECMAddTests.cmake
                if (CMAKE_LIBRARY_OUTPUT_DIRECTORY)
                    if(CMAKE_HOST_SYSTEM MATCHES "Windows")
                        set(PATHSEP ";")
                    else() # e.g. Linux
                        set(PATHSEP ":")
                    endif()
                    set(_plugin_path $ENV{QT_PLUGIN_PATH})
                    set(_test_env
                        QT_PLUGIN_PATH=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}${PATHSEP}$ENV{QT_PLUGIN_PATH}
                        LD_LIBRARY_PATH=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}${PATHSEP}$ENV{LD_LIBRARY_PATH}
                    )
                    set_tests_properties(${_test_name} PROPERTIES ENVIRONMENT "${_test_env}")
                endif()
                set_tests_properties(${_test_name} PROPERTIES RUN_SERIAL TRUE) # can't be parallelized due to gpg-agent
            endif()
        endif()
    endfunction()

    find_program(MYSQLD_EXECUTABLE mysqld /usr/sbin /usr/local/sbin /usr/libexec /usr/local/libexec /opt/mysql/libexec /usr/mysql/bin)
    if (MYSQLD_EXECUTABLE AND NOT WIN32)
        _defineTest(${_testname} "MYSQL" ${CONFIG_BACKENDS})
    endif()

    find_program(POSTGRES_EXECUTABLE postgres)
    if (POSTGRES_EXECUTABLE AND NOT WIN32)
        _defineTest(${_testname} "PGSQL" ${CONFIG_BACKENDS})
    endif()

    _defineTest(${_testname} "SQLITE" ${CONFIG_BACKENDS})
endmacro (ADD_GPG_CRYPTO_AKONADI_TEST)
