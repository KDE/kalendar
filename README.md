<!--
SPDX-FileCopyrightText: 2021 Carl Schwan <carl@carlschwan.eu>
SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
SPDX-License-Identifier: CC0-1.0
-->

# Kalendar

Kalendar is a Kirigami-based calendar and task management application that uses Akonadi. It lets you add, edit and delete events and tasks from local and remote accounts of your choice, while keeping changes synchronised across your Plasma desktop or phone.

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

## Build

**Kalendar requires KFrameworks 5.88 and version 21.12 of the KDE PIM-related dependencies (e.g. Akonadi, kdepim-runtime) to be installed.** This package version is fairly recent and may not yet be available in your distribution of choice, meaning Kalendar might not work.

**We also strongly recommend you install the `kdepim-runtime` package before starting Kalendar** -- this will provide you with the ability to add calendars from online resources. Having this package will also let Kalendar's backend automatically create a default local calendar. 

If you have already installed and started Kalendar and are now installing `kdepim-runtime`, make sure to run `akonadictl restart`; this will enable online resources and the local calendar after installing `kdepim-runtime`.

KDE Neon dependencies:
```
git cmake build-essential gettext extra-cmake-modules qtbase5-dev qtdeclarative5-dev libqt5svg5-dev qtquickcontrols2-5-dev qml-module-org-kde-kirigami2 kirigami2-dev libkf5i18n-dev gettext libkf5coreaddons-dev qml-module-qtquick-layouts qml-module-qtlocation qml-module-qt-labs-qmlmodels qtlocation5-dev qml-module-qtpositioning qtpositioning5-dev libkf5mime-dev libkf5calendarsupport-dev libkf5akonadicontact-dev libkf5akonadi-dev libkf5windowsystem-dev libkf5package-dev libkf5calendarcore-dev libkf5configwidgets-dev libkf5contacts-dev libkf5people-dev libkf5eventviews-dev libkf5notifications-dev libkf5qqc2desktopstyle-dev kdepim-runtime ninja-build
```

```
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=~/.local/kde -GNinja
ninja
```

## Frequently asked questions

### Does Kalendar support Google/Exchange/Nextcloud calendars?

Yes. We support:

- CalDAV calendars (e.g. Nextcloud)
- Google calendars
- Exchange calendars
- iCal calendar files (.ics)
- iCal calendar folders
- Kolab groupware servers
- Open-Xchange groupware servers

#### Will support for Todoist/Proton Calendar/etc. be added?

Online event and task services such as Todoist that have non-standard implementations of things such as tasks and calendars depend on someone taking the time to write specific code to support them. That doesn't mean this will never happen, but it will depend on how popular these services are and on someone being willing to maintain support for them.

Proton Calendar specifically is problematic, and it is impossible for us to support until Proton provides a way for us to interact and interface with the calendar (i.e. through the bridge application). 

#### Does Kalendar work with Plasma's digital clock calendar widget?

Yes. This can be configured by right-clicking on the digital clock -> Configure digital clock... -> Calendar -> enable PIM Events Plugin

This should reveal a new section in the widget settings, letting you configure which calendars' events will be visible in the widget.

#### Does Kalendar use Akonadi?

Yes. It is what allows us to support all the services that we support, and provides the core functionality of Kalendar (fetching, editing, creating, and deleting events from remote resources).

#### Why all the dependencies?

While we’re actively working on reducing our number of external dependencies, these removals often take time and require reimplementing things in a new way, which is not always easy.

Other dependencies we require are there so we don’t bloat Kalendar by copying functionality that can be provided by an external package also used by other applications.

#### Will Kalendar replace KOrganizer?

For the time being, no.

KOrganizer has an incredibly expansive feature set, which makes it a powerful tool for power users. Kalendar is instead focused on providing an approachable calendar for Plasma. You can expect great usability and a visually appealing interface that works on both desktop and mobile.

The intention is for the two apps to co-exist and for you to have the choice of using the one best suited to your needs. If you really need the advanced and expansive feature-set of KOrganizer, you will want to use that. If you want a versatile calendar application that is nice to use and you can comfortably use on your desktop and on your phone, Kalendar will fill that role well!

#### Will there be a flatpak?

We are actively discussing this, but it is not as easy for Kalendar as for other applications due to our reliance on an external service in Akonadi. We will eventually find a solution for this, but it may take some time.

#### How can I install Kalendar on Ubuntu/Kubuntu/Debian? Is there a deb package?

This is unfortunately out of our hands -- we have packages on Neon, but will almost certainly not be compatible with Ubuntu. If you'd like Kalendar on Ubuntu, Kubuntu, or another Debian derivative, ask the your distribution's packagers (nicely!) if they'd like to package Kalendar.

## License

This project is licensed under GPL-3.0-or-later. Some files are licensed under
more permissive licenses. New contributions are expected to be under the
LGPL-2.1-or-later license.
