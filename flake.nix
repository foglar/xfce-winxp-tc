{
  description = "Windows XP Total Conversion for XFCE - LogonUI LightDM Greeter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Common build inputs for all wintc libraries
        commonBuildInputs = with pkgs; [
          cmake
          pkg-config
          glib
          gtk3
          gdk-pixbuf
        ];

        # Version info - can be customized
        version = "1.0.0";
        sku = "xpclient-pro";

        # Base library: wintc-comgtk
        wintc-comgtk = pkgs.stdenv.mkDerivation {
          pname = "wintc-comgtk";
          version = version;

          src = ./shared/comgtk;

          nativeBuildInputs = commonBuildInputs;
          buildInputs = with pkgs; [ glib gtk3 ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            # Copy cmake-inc directory needed for build
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
          '';

          meta = {
            description = "Windows Total Conversion common GLib/GTK utilities";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-shcommon
        wintc-shcommon = pkgs.stdenv.mkDerivation {
          pname = "wintc-shcommon";
          version = version;

          src = ./shared/shcommon;

          nativeBuildInputs = commonBuildInputs;
          buildInputs = with pkgs; [ glib gtk3 wintc-comgtk ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
          '';

          meta = {
            description = "Windows Total Conversion common shell utilities library";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-shlang
        wintc-shlang = pkgs.stdenv.mkDerivation {
          pname = "wintc-shlang";
          version = version;

          src = ./shared/shlang;

          nativeBuildInputs = commonBuildInputs ++ [ pkgs.gettext ];
          buildInputs = with pkgs; [ glib gtk3 wintc-comgtk wintc-shcommon ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
          '';

          meta = {
            description = "Windows Total Conversion shell language string utilities";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-winbrand
        wintc-winbrand = pkgs.stdenv.mkDerivation {
          pname = "wintc-winbrand";
          version = version;

          src = ./shared/winbrand;

          nativeBuildInputs = commonBuildInputs;
          buildInputs = with pkgs; [ glib gtk3 gdk-pixbuf wintc-comgtk ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
          '';

          meta = {
            description = "Windows Total Conversion Windows branding library";
            license = pkgs.lib.licenses.unfree; # Contains Windows assets
          };
        };

        # wintc-comctl
        wintc-comctl = pkgs.stdenv.mkDerivation {
          pname = "wintc-comctl";
          version = version;

          src = ./shared/comctl;

          nativeBuildInputs = commonBuildInputs;
          buildInputs = with pkgs; [
            glib
            gtk3
            gdk-pixbuf
            wintc-comgtk
            wintc-shcommon
            wintc-shlang
          ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
          '';

          meta = {
            description = "Windows Total Conversion common controls library";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-msgina
        wintc-msgina = pkgs.stdenv.mkDerivation {
          pname = "wintc-msgina";
          version = version;

          src = ./shared/msgina;

          nativeBuildInputs = commonBuildInputs;
          buildInputs = with pkgs; [
            glib
            gtk3
            gdk-pixbuf
            lightdm
            wintc-comgtk
            wintc-comctl
            wintc-winbrand
          ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
          '';

          meta = {
            description = "Windows Total Conversion GINA library";
            license = pkgs.lib.licenses.unfree; # Contains Windows assets
          };
        };

        # Main package: logonui
        logonui = pkgs.stdenv.mkDerivation {
          pname = "wintc-logonui";
          version = version;

          src = ./base/logonui;

          nativeBuildInputs = commonBuildInputs;
          buildInputs = with pkgs; [
            glib
            gtk3
            gdk-pixbuf
            lightdm
            wintc-comgtk
            wintc-comctl
            wintc-msgina
          ];

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          preConfigure = ''
            mkdir -p ../packaging
            cp -r ${./packaging/cmake-inc} ../packaging/cmake-inc
            # Copy tools needed for version generation
            mkdir -p ../tools/bldutils
            cp -r ${./tools/bldutils} ../tools/
          '';

          postInstall = ''
            # Ensure greeter desktop file is in the correct location
            mkdir -p $out/share/xgreeters
            if [ -f $out/share/xgreeters/wintc-logonui.desktop ]; then
              echo "Greeter desktop file installed successfully"
            fi
          '';

          meta = {
            description = "Windows Total Conversion logon user interface for LightDM";
            license = pkgs.lib.licenses.unfree; # Contains Windows assets
            mainProgram = "logonui";
          };
        };

      in {
        packages = {
          inherit wintc-comgtk wintc-shcommon wintc-shlang wintc-winbrand wintc-comctl wintc-msgina logonui;
          default = logonui;
        };

        # Development shell for building
        devShells.default = pkgs.mkShell {
          buildInputs = commonBuildInputs ++ [
            pkgs.lightdm
            pkgs.gettext
          ];
          
          shellHook = ''
            echo "Windows XP TC LogonUI Development Environment"
            echo "Available packages: wintc-comgtk, wintc-shcommon, wintc-shlang, wintc-winbrand, wintc-comctl, wintc-msgina, logonui"
          '';
        };

        # Apps for easy testing
        apps.default = {
          type = "app";
          program = "${logonui}/sbin/logonui";
        };
      }
    );
}
