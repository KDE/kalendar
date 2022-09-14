# SPDX-FileCopyrightText: (C) 2022 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

{
  description = "A flake for kalendar";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem [ "aarch64-linux" "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          nativeBuildInputs = with pkgs; [
            cmake
            extra-cmake-modules
            qt5.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            mariadb
            gpgme

            qt5.qtbase
            qt5.qtquickcontrols2
            qt5.qtsvg
            qt5.qtlocation
            qt5.qtgraphicaleffects
            qt5.qtdeclarative

            libsForQt5.breeze-icons
            libsForQt5.qqc2-desktop-style
            libsForQt5.kirigami2
            libsForQt5.kdbusaddons
            libsForQt5.ki18n
            libsForQt5.kcalendarcore
            libsForQt5.kconfigwidgets
            libsForQt5.kwindowsystem
            libsForQt5.kcoreaddons
            libsForQt5.kcontacts
            libsForQt5.kitemmodels
            libsForQt5.kxmlgui
            libsForQt5.knotifications
            libsForQt5.kiconthemes
            libsForQt5.kservice
            libsForQt5.kmime
            libsForQt5.kpackage
            libsForQt5.kio
            libsForQt5.eventviews
            libsForQt5.calendarsupport
            libsForQt5.messagelib
            libsForQt5.mailcommon
            libsForQt5.pimcommon

            libsForQt5.akonadi
            libsForQt5.akonadi-search
            libsForQt5.akonadi-contacts
            libsForQt5.akonadi-calendar
            libsForQt5.kdepim-runtime
          ];

          packages.default = with pkgs; stdenv.mkDerivation rec {
            inherit nativeBuildInputs buildInputs;
            pname = "kalendar";
            version = "dev";
            src = ./.;
            propagatedUserEnvPkgs = [
              libsForQt5.akonadi
              libsForQt5.kdepim-runtime
            ];
            dontStrip = true;
            enableDebugging = true;
            separateDebugInfo = false;
            postFixup = ''
              wrapProgram "$out/bin/kalendar" \
                --set PATH ${lib.makeBinPath [
                  libsForQt5.akonadi
                  libsForQt5.kdepim-runtime
                ]} \
                --set QML_DISABLE_DISK_CACHE "1"
            '';
          };

          apps.default = mkApp {
            name = "kalendar";
            drv = packages.default;
          };

        in {
          inherit packages apps;
          devShell = pkgs.mkShell {
            inherit buildInputs;
            nativeBuildInputs = with pkgs; nativeBuildInputs ++[
              clang-tools
              libclang.python
              ninja
              gdb
              kdevelop
            ];
            name = "kalendar-shell";
            shellHook = ''
              export AKONADI_INSTANCE=devel
            '';
          };
        }
    );
}
