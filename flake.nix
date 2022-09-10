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

            libsForQt5.qt5.qtbase
            libsForQt5.qt5.qtquickcontrols2
            libsForQt5.qt5.qtsvg
            libsForQt5.qt5.qtlocation
            libsForQt5.qt5.qtdeclarative

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
          packages = {
            kalendar = pkgs.stdenv.mkDerivation rec {
              inherit nativeBuildInputs buildInputs;
              pname = "kalendar";
              version = "dev";
              src = ./.;
              propagatedUserEnvPkgs = with pkgs; [
                libsForQt5.akonadi
                libsForQt5.kdepim-runtime
              ];
            };
          };
          apps = {
            kalendar = mkApp {
              name = "Kalendar";
              drv = packages.kalendar;
            };
          };
        in {
          inherit packages apps;
          defaultPackage = packages.kalendar;
          defaultApp = apps.kalendar;
          devShell = pkgs.mkShell {
            inherit buildInputs;
            nativeBuildInputs = with pkgs; nativeBuildInputs ++[
              clang-tools
              libclang.python
            ];
            name = "kalendar-shell";
            shellHook = ''
              export AKONADI_INSTANCE=devel
            '';
          };
        }
    );
}
