# NixOS Usage Guide for LogonUI

This document explains how to use the Nix flake to build and install the Windows XP Total Conversion LogonUI greeter for LightDM on NixOS.

## Prerequisites

- NixOS system or Nix package manager with flakes enabled
- LightDM display manager

## Quick Start

### Building LogonUI

To build the logonui package:

```bash
nix build github:foglar/xfce-winxp-tc#logonui
```

Or if you've cloned the repository:

```bash
nix build .#logonui
```

The built package will be available in the `result` symlink.

### Building All Packages

To build all packages (all libraries and logonui):

```bash
nix build github:foglar/xfce-winxp-tc
```

### Development Environment

To enter a development shell with all necessary dependencies:

```bash
nix develop github:foglar/xfce-winxp-tc
```

Or locally:

```bash
nix develop
```

## Available Packages

The flake provides the following packages:

- `wintc-comgtk` - Common GLib/GTK utilities (base library)
- `wintc-shcommon` - Common shell utilities library
- `wintc-shlang` - Shell language string utilities
- `wintc-winbrand` - Windows branding library
- `wintc-comctl` - Common controls library
- `wintc-msgina` - GINA library for authentication
- `logonui` - Main LogonUI greeter application (default package)

You can build any individual package:

```bash
nix build .#wintc-comgtk
nix build .#wintc-msgina
# etc.
```

## NixOS Configuration

To use the LogonUI greeter in your NixOS configuration:

### Method 1: Using the NixOS module (Recommended)

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    xfce-winxp-tc.url = "github:foglar/xfce-winxp-tc";
  };

  outputs = { self, nixpkgs, xfce-winxp-tc }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # Import the xfce-winxp-tc module
        xfce-winxp-tc.nixosModules.default
        {
          # Use the overlay to make packages available
          nixpkgs.overlays = [ xfce-winxp-tc.overlays.default ];
          
          # Enable the LogonUI greeter
          services.xfce-winxp-tc.logonui = {
            enable = true;
            sku = "xpclient-pro"; # Optional, this is the default
          };
        }
      ];
    };
  };
}
```

### Method 2: Manual installation using the flake

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    xfce-winxp-tc.url = "github:foglar/xfce-winxp-tc";
  };

  outputs = { self, nixpkgs, xfce-winxp-tc }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        {
          # Make the logonui package available
          environment.systemPackages = [
            xfce-winxp-tc.packages.x86_64-linux.logonui
          ];
          
          # Configure LightDM to use the greeter
          services.xserver.displayManager.lightdm = {
            enable = true;
            greeters.gtk.enable = false;
            # Note: You may need to manually configure LightDM to use wintc-logonui
            # by editing /etc/lightdm/lightdm.conf or using extraConfig
          };
        }
      ];
    };
  };
}
```

### Method 3: System-wide installation with nix profile

Build and install to your system profile:

```bash
nix profile install github:foglar/xfce-winxp-tc#logonui
```

Then configure LightDM in your `configuration.nix`:

```nix
{
  services.xserver = {
    enable = true;
    displayManager.lightdm = {
      enable = true;
      greeters.gtk.enable = false;
    };
  };
  
  # Add the greeter to system packages
  environment.systemPackages = with pkgs; [
    # ... other packages ...
  ];
}
```

You'll need to configure LightDM to use the `wintc-logonui` greeter by setting it in the LightDM configuration.

## Customization

The flake builds with the default SKU `xpclient-pro`. To build with a different SKU, you can modify the `flake.nix` file and change the `sku` variable.

Available SKUs include:
- `xpclient-pro` (default)
- `xpclient-per`
- `xpclient-linux`
- `xpclient-mce`
- `xpclient-tabletpc`
- And many more (see the main CMakeLists.txt for full list)

## Troubleshooting

### Flakes not enabled

If you get an error about experimental features, enable flakes:

```bash
# Temporary
nix --experimental-features "nix-command flakes" build .#logonui

# Permanent - add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

### Build failures

If a build fails, try building with verbose output:

```bash
nix build .#logonui --print-build-logs
```

### Testing the greeter

You can test the greeter without installing it system-wide using `lightdm --test-mode` (requires root):

```bash
sudo lightdm --test-mode --debug
```

## Dependencies

The LogonUI greeter depends on:

**System libraries:**
- GTK+ 3
- GLib 2.0
- GDK-Pixbuf
- LightDM (liblightdm-gobject)

**Internal wintc libraries:**
- wintc-comgtk
- wintc-comctl
- wintc-msgina
- wintc-winbrand
- wintc-shcommon
- wintc-shlang

All dependencies are automatically handled by the Nix flake.

## License

Note that some components include Windows assets which are proprietary. The source code itself is GPL 2.0 licensed. When using this in production, be aware of the licensing implications.

## Contributing

To make changes to the build:

1. Clone the repository
2. Enter the development shell: `nix develop`
3. Make your changes
4. Test the build: `nix build .#logonui --print-build-logs`
5. Submit a pull request

## GitHub Actions

The repository includes GitHub Actions workflows that automatically test the build on every push. You can see the build status in the Actions tab of the repository.
