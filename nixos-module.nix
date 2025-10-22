# NixOS Module for Windows XP TC LogonUI
# 
# This module provides a convenient way to integrate the LogonUI greeter
# into your NixOS configuration.
#
# Usage:
#   Add this to your flake.nix inputs:
#     xfce-winxp-tc.url = "github:foglar/xfce-winxp-tc";
#   
#   Then in your NixOS configuration:
#     imports = [ xfce-winxp-tc.nixosModules.default ];
#     services.xfce-winxp-tc.logonui.enable = true;

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xfce-winxp-tc.logonui;
in {
  options.services.xfce-winxp-tc.logonui = {
    enable = mkEnableOption "Windows XP Total Conversion LogonUI greeter for LightDM";

    package = mkOption {
      type = types.package;
      default = pkgs.wintc-logonui or (throw "wintc-logonui package not found. Make sure to add the xfce-winxp-tc overlay.");
      description = "The LogonUI package to use";
    };

    sku = mkOption {
      type = types.str;
      default = "xpclient-pro";
      description = "Windows XP SKU to emulate (e.g., xpclient-pro, xpclient-per)";
    };
  };

  config = mkIf cfg.enable {
    # Enable LightDM with the LogonUI greeter
    services.xserver = {
      enable = mkDefault true;
      displayManager.lightdm = {
        enable = true;
        greeters.gtk.enable = false; # Disable default GTK greeter
      };
    };

    # Install the LogonUI package
    environment.systemPackages = [ cfg.package ];

    # Configure LightDM to use the wintc-logonui greeter
    # Note: This might need adjustment based on actual package output
    services.xserver.displayManager.lightdm.greeter.enable = true;
    
    # Additional configuration hints for users
    warnings = mkIf cfg.enable [
      ''
        The Windows XP TC LogonUI is now installed. To use it as your greeter,
        you may need to manually configure LightDM by editing:
          /etc/lightdm/lightdm.conf
        
        Set the greeter-session to: wintc-logonui
        
        The greeter desktop file should be at:
          ${cfg.package}/share/xgreeters/wintc-logonui.desktop
      ''
    ];
  };
}
