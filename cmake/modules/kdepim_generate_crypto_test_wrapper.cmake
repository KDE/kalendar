# SPDX-FileCopyrightText: 2006 Alexander Neundorf <neundorf@kde.org>
# SPDX-FileCopyrightText: 2013 Sandro Knauß <mail@sandroknauss.de>
#
# SPDX-License-Identifier: BSD-3-Clause


if (UNIX)

file(WRITE "${_filename}"
"#!/bin/sh
# created by cmake, don't edit, changes will be lost

# don't mess with a gpg-agent already running on the system
unset GPG_AGENT_INFO

# _gnupghome will contain a socket, and the path to that has a length limit of 108 chars
# which that is easily reached. Therefore shorten this by copying this to a temporary dir.
# This has the convenient side-effect that modifications to the content are not propagated
# to other tests.
tmp_dir=`mktemp -d -t messagelib-test-gnupg-home.XXXXXXXX` || exit 1
cp -rf ${_gnupghome}/* $tmp_dir

${_library_path_variable}=${_ld_library_path}\${${_library_path_variable}:+:\$${_library_path_variable}} GNUPGHOME=$tmp_dir \"${_executable}\" \"$@\"
_result=$?

_pid=`echo GETINFO pid | GNUPGHOME=$tmp_dir gpg-connect-agent | grep 'D' | cut -d' ' -f2`
if [ ! -z \"\$_pid\" ]; then
    echo KILLAGENT | GNUPGHOME=$tmp_dir gpg-connect-agent > /dev/null
    sleep .3
    if ps -p \"\$_pid\" > /dev/null; then
       echo \"Waiting for gpg-agent to terminate (PID: $_pid)...\"
       while kill -0 \"\$_pid\"; do
           sleep 1
       done
    fi
fi
rm -rf $tmp_dir
exit \$_result
")

# make it executable
# since this is only executed on UNIX, it is safe to call chmod
exec_program(chmod ARGS ug+x \"${_filename}\" OUTPUT_VARIABLE _dummy )

else (UNIX)

file(TO_NATIVE_PATH "${_ld_library_path}" win_path)
file(TO_NATIVE_PATH "${_gnupghome}" win_gnupghome)

file(WRITE "${_filename}"
"
set PATH=${win_path};$ENV{PATH}
set GNUPGHOME=${win_gnupghome};$ENV{GNUPGHOME}
gpg-agent --daemon \"${_executable}\" %*
")

endif (UNIX)
