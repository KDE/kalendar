<!--
SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
SPDX-License-Identifier: CC0-1.0
-->

# Kalendar

Kalendar is a Kirigami-based calendar application that uses Akonadi. It lets you add, edit and delete events from local and remote accounts of your choice, while keeping changes synchronised across your Plasma desktop or phone.

**Kalendar is still under heavy development, and has no stable releases yet.** We do, however, welcome suggestions! Get involved and join our Matrix channel: #kalendar:kde.org

## Screenshots

![Screenshot of Kalendar's month view](https://cdn.kde.org/screenshots/kalendar/month_view.png)
![Screenshot of Kalendar's task view](https://cdn.kde.org/screenshots/kalendar/task_view.png)
![Screenshot of Kalendar's week view](https://cdn.kde.org/screenshots/kalendar/week_view.png)
![Screenshot of Kalendar's schedule view](https://cdn.kde.org/screenshots/kalendar/schedule_view.png)
![Screenshot of Kalendar's schedule view on mobile](https://cdn.kde.org/screenshots/kalendar/mobile_view.png)

## Get it

Kalendar is available in the Arch AUR, in Fedora, and in openSUSE Tumbleweed using
the following two OBS repositories: https://build.opensuse.org/project/show/home:KaratekHD:kirigami
and https://build.opensuse.org/project/show/home:andresbs:plasma-mobile

Installation for Fedora 

```
sudo dnf install kalendar
```

Please note that this is pre-release software and that you may encounter bugs, crashes, or errors.

## Build

**Kalendar requires KFrameworks 5.86 to be installed.** This package version is fairly recent and may not yet be available in your distribution of choice, meaning Kalendar might not work.

**We also strongly recommend you install the `kdepim-runtime` package before starting Kalendar** -- this will provide you with the ability to add calendars from online resources. Having this package will also let Kalendar's backend automatically create a default local calendar. 

If you have already installed and started Kalendar and are now installing `kdepim-runtime`, make sure to run `akonadictl restart`; this will enable online resources and the local calendar after installing `kdepim-runtime`.

KDE Neon dependencies:
```
git cmake build-essential gettext extra-cmake-modules qtbase5-dev qtdeclarative5-dev libqt5svg5-dev qtquickcontrols2-5-dev qml-module-org-kde-kirigami2 kirigami2-dev libkf5i18n-dev gettext libkf5coreaddons-dev qml-module-qtquick-layouts qml-module-qtlocation qml-module-qt-labs-qmlmodels qtlocation5-dev qml-module-qtpositioning qtpositioning5-dev libkf5mime-dev libkf5calendarsupport-dev libkf5akonadicontact-dev libkf5akonadi-dev libkf5windowsystem-dev libkf5package-dev libkf5calendarcore-dev libkf5configwidgets-dev libkf5contacts-dev libkf5people-dev libkf5eventviews-dev libkf5notifications-dev kdepim-runtime ninja-build
```

```
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=~/.local/kde -GNinja
ninja
```

## License

This project is licensed under GPL-3.0-or-later. Some files are licensed under
more permissive licenses. New contributions are expected to be under the
LGPL-2.1-or-later license.
