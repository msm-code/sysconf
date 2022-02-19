{ config, lib, pkgs, ... }:
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      input = { "type:keyboard" = { xkb_layout = "pl"; }; };
      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
        in
        lib.mkOptionDefault {
          # Screenshot helper
          Print = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area";

          "${modifier}+Shift+o" = "exec loginctl lock-session";

          # Add support for 10th workspace
          "${modifier}+0" = "workspace number 10";
          "${modifier}+Shift+0" = "move container to workspace number 10";
        };

    };
  };

  programs.mako = {
    enable = true;
    defaultTimeout = 2000;
  };

  gtk = {
    enable = true;
    iconTheme.package = pkgs.gnome_themes_standard;
    iconTheme.name = "Adwaita";
  };

  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = "52.23020816947126";
    longitude = "21.011293104313307";
  };

  services.kanshi = {
    enable = true;
    profiles = {
      dualhome = {
        outputs = [
          {
            criteria = "Samsung Electric Company S24D330 0x00005B31";
            mode = "1920x1080@60Hz";
            position = "0,0";
          }
          {
            criteria = "Unknown 2369M BRSE19A003169";
            mode = "1920x1080@60Hz";
            position = "1920,0";
          }
        ];
      };
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 60;
        command = "swaymsg 'output * dpms off'";
        resumeCommand = "swaymsg 'output * dpms on'";
      }
      {
        timeout = 60 * 5;
        command = "loginctl lock-session";
      }
    ];
    events = [
      {
        event = "lock";
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
    ];
  };

  home.packages = with pkgs; [
    alacritty
    wdisplays
  ];
}
