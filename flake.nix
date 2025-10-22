{
  description = "Windows XP Total Conversion for XFCE - LogonUI LightDM Greeter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Overlay for adding our packages to nixpkgs
      overlay = final: prev: {
        wintc-comgtk = self.packages.${final.system}.wintc-comgtk;
        wintc-shcommon = self.packages.${final.system}.wintc-shcommon;
        wintc-shlang = self.packages.${final.system}.wintc-shlang;
        wintc-winbrand = self.packages.${final.system}.wintc-winbrand;
        wintc-comctl = self.packages.${final.system}.wintc-comctl;
        wintc-msgina = self.packages.${final.system}.wintc-msgina;
        wintc-logonui = self.packages.${final.system}.logonui;
      };
    in
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

        # Helper function to build wintc libraries with proper structure
        mkWintcLib = { pname, sourceDir, buildInputs ? [], meta ? {} }: pkgs.stdenv.mkDerivation {
          inherit pname version;

          src = ./.;

          sourceRoot = ".";

          nativeBuildInputs = commonBuildInputs;
          buildInputs = buildInputs;

          cmakeFlags = [
            "-DBUILD_SHARED_LIBS=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DWINTC_SKU=${sku}"
            "-DWINTC_PKGMGR=nix"
            "-DWINTC_PKGMGR_EXT=nix"
            "-DWINTC_USE_LOCAL_LIBS=OFF"
          ];

          configurePhase = ''
            runHook preConfigure
            
            cd ${sourceDir}
            
            cmake -B build \
              -DCMAKE_INSTALL_PREFIX=$out \
              $cmakeFlags
            
            runHook postConfigure
          '';

          buildPhase = ''
            runHook preBuild
            
            cd ${sourceDir}
            cmake --build build -j$NIX_BUILD_CORES
            
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            
            cd ${sourceDir}
            cmake --install build
            
            runHook postInstall
          '';

          meta = meta // {
            platforms = pkgs.lib.platforms.linux;
          };
        };

        # Base library: wintc-comgtk
        wintc-comgtk = mkWintcLib {
          pname = "wintc-comgtk";
          sourceDir = "shared/comgtk";
          buildInputs = with pkgs; [ glib gtk3 ];
          meta = {
            description = "Windows Total Conversion common GLib/GTK utilities";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-shcommon
        wintc-shcommon = mkWintcLib {
          pname = "wintc-shcommon";
          sourceDir = "shared/shcommon";
          buildInputs = with pkgs; [ glib gtk3 wintc-comgtk ];
          meta = {
            description = "Windows Total Conversion common shell utilities library";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-shlang
        wintc-shlang = mkWintcLib {
          pname = "wintc-shlang";
          sourceDir = "shared/shlang";
          buildInputs = with pkgs; [ glib gtk3 gettext wintc-comgtk wintc-shcommon ];
          meta = {
            description = "Windows Total Conversion shell language string utilities";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-winbrand
        wintc-winbrand = mkWintcLib {
          pname = "wintc-winbrand";
          sourceDir = "shared/winbrand";
          buildInputs = with pkgs; [ glib gtk3 gdk-pixbuf wintc-comgtk ];
          meta = {
            description = "Windows Total Conversion Windows branding library";
            license = pkgs.lib.licenses.unfree; # Contains Windows assets
          };
        };

        # wintc-comctl
        wintc-comctl = mkWintcLib {
          pname = "wintc-comctl";
          sourceDir = "shared/comctl";
          buildInputs = with pkgs; [
            glib
            gtk3
            gdk-pixbuf
            wintc-comgtk
            wintc-shcommon
            wintc-shlang
          ];
          meta = {
            description = "Windows Total Conversion common controls library";
            license = pkgs.lib.licenses.gpl2;
          };
        };

        # wintc-msgina
        wintc-msgina = mkWintcLib {
          pname = "wintc-msgina";
          sourceDir = "shared/msgina";
          buildInputs = with pkgs; [
            glib
            gtk3
            gdk-pixbuf
            lightdm
            wintc-comgtk
            wintc-comctl
            wintc-winbrand
          ];
          meta = {
            description = "Windows Total Conversion GINA library";
            license = pkgs.lib.licenses.unfree; # Contains Windows assets
          };
        };

        # Main package: logonui
        logonui = mkWintcLib {
          pname = "wintc-logonui";
          sourceDir = "base/logonui";
          buildInputs = with pkgs; [
            glib
            gtk3
            gdk-pixbuf
            lightdm
            wintc-comgtk
            wintc-comctl
            wintc-msgina
          ];
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
    ) // {
      # Overlay for use in other flakes
      overlays.default = overlay;
      
      # NixOS module
      nixosModules.default = import ./nixos-module.nix;
    };
}
