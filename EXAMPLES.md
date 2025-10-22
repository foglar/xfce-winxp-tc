# Examples for Using Windows XP TC LogonUI on NixOS

This document provides practical examples for integrating the LogonUI greeter into various NixOS configurations.

## Example 1: Basic NixOS Configuration with Flake

A minimal flake-based NixOS configuration using the LogonUI greeter:

**flake.nix:**
```nix
{
  description = "My NixOS configuration with Windows XP LogonUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    xfce-winxp-tc.url = "github:foglar/xfce-winxp-tc";
  };

  outputs = { self, nixpkgs, xfce-winxp-tc }: {
    nixosConfigurations.mypc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        xfce-winxp-tc.nixosModules.default
        {
          # Apply the overlay
          nixpkgs.overlays = [ xfce-winxp-tc.overlays.default ];
          
          # Enable the LogonUI greeter
          services.xfce-winxp-tc.logonui.enable = true;
          
          # Basic system configuration
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          
          networking.hostName = "mypc";
          
          # Enable X11 with XFCE
          services.xserver = {
            enable = true;
            desktopManager.xfce.enable = true;
          };
          
          # Define a user account
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
          
          system.stateVersion = "24.05";
        }
      ];
    };
  };
}
```

## Example 2: Using with Home Manager

Integrate LogonUI with Home Manager for a complete Windows XP experience:

**flake.nix:**
```nix
{
  description = "NixOS with Home Manager and Windows XP theme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xfce-winxp-tc.url = "github:foglar/xfce-winxp-tc";
  };

  outputs = { self, nixpkgs, home-manager, xfce-winxp-tc }: {
    nixosConfigurations.mypc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        xfce-winxp-tc.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ xfce-winxp-tc.overlays.default ];
          
          # System configuration
          services.xfce-winxp-tc.logonui = {
            enable = true;
            sku = "xpclient-pro";
          };
          
          services.xserver = {
            enable = true;
            desktopManager.xfce.enable = true;
          };
          
          # Home Manager configuration
          home-manager.users.alice = { pkgs, ... }: {
            home.stateVersion = "24.05";
            
            # You can add Windows XP themes and settings here
            xsession.enable = true;
            
            # Additional XP-style configurations can be added
            # when theme packages are also available in the future
          };
        }
      ];
    };
  };
}
```

## Example 3: Development and Testing

For developers who want to test the greeter:

**Shell for building:**
```bash
# Enter development shell
nix develop github:foglar/xfce-winxp-tc

# Inside the shell, you have access to all build tools
cmake --version
pkg-config --list-all | grep gtk
```

**Build and test locally:**
```bash
# Build all packages
nix build github:foglar/xfce-winxp-tc#logonui

# Check the output
ls -lah result/

# Test the greeter (requires root and X11)
# sudo lightdm --test-mode --debug
```

## Example 4: Custom SKU Configuration

If you want to use a different Windows XP edition:

```nix
{
  services.xfce-winxp-tc.logonui = {
    enable = true;
    sku = "xpclient-per";  # Personal Edition instead of Professional
  };
}
```

Available SKUs include:
- `xpclient-pro` - Windows XP Professional (default)
- `xpclient-per` - Windows XP Personal
- `xpclient-linux` - Linux Edition
- `xpclient-mce` - Media Center Edition
- `xpclient-tabletpc` - Tablet PC Edition
- And many more server editions

## Example 5: Integration with Existing Configuration

If you already have a NixOS configuration and want to add the LogonUI:

**In your existing flake.nix, add the input:**
```nix
inputs = {
  # ... your existing inputs
  xfce-winxp-tc.url = "github:foglar/xfce-winxp-tc";
};
```

**In your configuration module:**
```nix
{ config, pkgs, xfce-winxp-tc, ... }:
{
  imports = [
    xfce-winxp-tc.nixosModules.default
  ];
  
  nixpkgs.overlays = [ xfce-winxp-tc.overlays.default ];
  
  services.xfce-winxp-tc.logonui.enable = true;
}
```

## Example 6: Using Without the Module

If you prefer not to use the module and want direct control:

```nix
{ pkgs, xfce-winxp-tc, ... }:
{
  nixpkgs.overlays = [ xfce-winxp-tc.overlays.default ];
  
  environment.systemPackages = with pkgs; [
    wintc-logonui
    # Optionally include individual libraries
    wintc-comgtk
    wintc-msgina
  ];
  
  services.xserver = {
    enable = true;
    displayManager.lightdm = {
      enable = true;
      greeters.gtk.enable = false;
    };
  };
  
  # You may need to manually configure LightDM's greeter-session
  environment.etc."lightdm/lightdm.conf".text = ''
    [Seat:*]
    greeter-session=wintc-logonui
  '';
}
```

## Example 7: Testing in a VM

To test the configuration in a VM before deploying:

```bash
# Build a VM with the configuration
nixos-rebuild build-vm --flake .#mypc

# Run the VM
./result/bin/run-mypc-vm
```

## Troubleshooting Examples

### Check if the greeter is installed:
```bash
nix build github:foglar/xfce-winxp-tc#logonui
ls -la result/share/xgreeters/
cat result/share/xgreeters/wintc-logonui.desktop
```

### Verify LightDM configuration:
```bash
# On your system
cat /etc/lightdm/lightdm.conf | grep greeter-session
```

### Check build logs:
```bash
nix build github:foglar/xfce-winxp-tc#logonui --print-build-logs
```

## Additional Resources

- Main documentation: [NIX_USAGE.md](NIX_USAGE.md)
- NixOS Module: [nixos-module.nix](nixos-module.nix)
- GitHub Actions workflow: [.github/workflows/nix-build.yml](.github/workflows/nix-build.yml)
- Project Wiki: https://github.com/rozniak/xfce-winxp-tc/wiki

## Contributing

If you have additional examples or improvements, please contribute them back to the repository!
