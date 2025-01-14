{ config, lib, pkgs, ... }:
let
  sway-audio-idle-inhibit = pkgs.callPackage ../pkgs/sway-audio-idle-inhibit.nix { };
in
{
  wayland.windowManager.sway = {
    enable = true;
    extraConfig = ''
      for_window [class="^Chromium-browser$"] inhibit_idle fullscreen
      set $WOBSOCK $XDG_RUNTIME_DIR/wob.sock
      exec rm -f $WOBSOCK && mkfifo $WOBSOCK && tail -f $WOBSOCK | ${pkgs.wob}/bin/wob
      exec ${sway-audio-idle-inhibit}/bin/sway-audio-idle-inhibit
    '';
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
    config = {
      modifier = "Mod4";
      menu = "${pkgs.wofi}/bin/wofi --show drun -G -I";
      terminal = "alacritty";
      input = { "type:keyboard" = { xkb_layout = "pl"; }; };
      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
        in
        lib.mkOptionDefault {
          # Screenshot helper
          Print = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot copy area";

          XF86AudioRaiseVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ +5% && pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' > $WOBSOCK";
          XF86AudioLowerVolume = "exec pactl set-sink-volume @DEFAULT_SINK@ -5% && pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print substr($5, 1, length($5)-1)}' > $WOBSOCK";
          XF86AudioMute = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          XF86AudioMicMute = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          XF86AudioPlay = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          XF86AudioStop = "exec ${pkgs.playerctl}/bin/playerctl stop";
          XF86AudioNext = "exec ${pkgs.playerctl}/bin/playerctl next";
          XF86AudioPrev = "exec ${pkgs.playerctl}/bin/playerctl previous";

          #XF86MonBrightnessDown = "exec brightnessctl set 5%- | sed -En 's/.*\(([0-9]+)%\).*/\1/p' > $WOBSOCK";
          #XF86MonBrightnessUp  = "exec brightnessctl set +5% | sed -En 's/.*\(([0-9]+)%\).*/\1/p' > $WOBSOCK";

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
    iconTheme.package = pkgs.gnome-themes-extra;
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
        exec = [
          "${pkgs.sway}/bin/swaymsg workspace 1, move workspace to DP-1"
        ];
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
        timeout = 60 * 5;
        command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
        resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
      }
      {
        timeout = 60 * 10;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        timeout = 60 * 60;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
    events = [
      {
        event = "after-resume";
        command = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
      }

      {
        event = "before-sleep";
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
    ];
  };

  home.packages = with pkgs; [
    alacritty
    wdisplays
    wl-clipboard
  ];
}
