# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  lib,
  config,
  ...
}:
let

  cfg = config.ghaf.graphics.labwc;
  useGivc = config.ghaf.givc.enable;
  ghaf-powercontrol = pkgs.callPackage ../../../packages/ghaf-powercontrol {
    ghafConfig = config.ghaf;
  };
  inherit (config.ghaf.services.audio) pulseaudioTcpControlPort;

  # Called by eww.yuck for updates and reloads
  ewwCmd = "${pkgs.eww}/bin/eww -c /etc/eww";

  ewwScripts = pkgs.callPackage ./ewwbar/config/scripts {
    inherit useGivc;
    inherit pulseaudioTcpControlPort;
  };

  variables = pkgs.callPackage ./ewwbar/config/variables {
    inherit ewwScripts;
  };

  widgets = pkgs.callPackage ./ewwbar/config/widgets {
    inherit useGivc;
    inherit (config.ghaf.givc) cliArgs;
    inherit ewwScripts;
    inherit pulseaudioTcpControlPort;
    inherit ghaf-powercontrol;
    inherit cfg;
  };

  windows = pkgs.callPackage ./ewwbar/config/windows {
    inherit useGivc;
  };

  mkPopupHandler =
    {
      name,
      stateFile,
      popupName,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.inotify-tools ];
      # Needed to prevent script from exiting prematurely
      bashOptions = [ ];
      text = ''
        mkdir -p ~/.config/eww
        echo 1 > ~/.config/eww/${stateFile} && sleep 0.5
        popup_timer_pid=0

        show_popup() {
            if [ "$popup_timer_pid" -ne 0 ]; then
              kill "$popup_timer_pid" 2>/dev/null
              popup_timer_pid=0
            fi

            if ! ${ewwCmd} active-windows | grep -q "${popupName}"; then
              ${ewwCmd} open ${popupName}
              ${ewwCmd} update ${popupName}-visible="true"
            fi
            (
              sleep 2
              ${ewwCmd} update ${popupName}-visible="false"
              sleep 0.1
              ${ewwCmd} close ${popupName}
            ) &

            popup_timer_pid=$!
        }

        inotifywait -m -e close_write ~/.config/eww/${stateFile} |
        while read -r; do
            show_popup > /dev/null 2>&1
        done
      '';
    };
in
{
  config = lib.mkIf cfg.enable {
    # Main eww config
    # This configuration is composed of three main parts:
    # - variables: Includes any necessary variables for the eww configuration.
    # - widgets: Defines the widgets that will be used in the windows (e.g. system tray, clock, etc.).
    # - windows: Specifies the windows that can be opened by the user or are opened by default (e.g. bar, calendar, etc.).
    environment.etc."eww/eww.yuck" = {
      text = ''
        (include "${variables}")
        (include "${widgets}")
        (include "${windows}")
      '';

      # The UNIX file mode bits
      mode = "0644";
    };
    # Main eww styling
    # The styling defined here will be applied to all windows generated by eww
    environment.etc."eww/eww.scss" = {
      text = pkgs.callPackage ./styles/ewwbar-style.nix { inherit (cfg.gtk) fontName; };

      # The UNIX file mode bits
      mode = "0644";
    };

    systemd.user.services = {
      ewwbar = {
        enable = true;
        description = "ewwbar";
        serviceConfig = {
          Type = "forking";
          ExecStart = "${ewwScripts.ewwbar-ctrl}/bin/ewwbar-ctrl start";
          ExecReload = "${ewwScripts.ewwbar-ctrl}/bin/ewwbar-ctrl reload";
          Restart = "always";
          RestartSec = "100ms";
        };
        startLimitIntervalSec = 0;
        wantedBy = [ "ghaf-session.target" ];
        partOf = [ "ghaf-session.target" ];
      };

      eww-brightness-popup = {
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${
            mkPopupHandler {
              name = "brightness-popup-handler";
              stateFile = "brightness";
              popupName = "brightness-popup";
            }
          }/bin/brightness-popup-handler";
          Restart = "on-failure";
        };
        after = [ "ewwbar.service" ];
        wantedBy = [ "ewwbar.service" ];
        partOf = [ "ghaf-session.target" ];
      };

      eww-display-trigger = {
        description = "eww-display-trigger";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > ~/.config/eww/display'";
        };
        after = [ "ewwbar.service" ];
      };

      eww-display-handler = {
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${ewwScripts.eww-display}/bin/eww-display";
          Restart = "on-failure";
        };
        after = [ "ewwbar.service" ];
        wantedBy = [ "ewwbar.service" ];
        partOf = [ "ghaf-session.target" ];
      };

      eww-volume-popup = {
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${
            mkPopupHandler {
              name = "volume-popup-handler";
              stateFile = "volume";
              popupName = "volume-popup";
            }
          }/bin/volume-popup-handler";
          Restart = "on-failure";
        };
        after = [ "ewwbar.service" ];
        wantedBy = [ "ewwbar.service" ];
        partOf = [ "ghaf-session.target" ];
      };

      eww-workspace-popup = {
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${
            mkPopupHandler {
              name = "workspace-popup-handler";
              stateFile = "workspace";
              popupName = "workspace-popup";
            }
          }/bin/workspace-popup-handler";
          Restart = "on-failure";
        };
        after = [ "ewwbar.service" ];
        wantedBy = [ "ewwbar.service" ];
        partOf = [ "ghaf-session.target" ];
      };

      eww-fullscreen-update = {
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${ewwScripts.eww-fullscreen-update}/bin/eww-fullscreen-update";
          Restart = "on-failure";
        };
        after = [ "ewwbar.service" ];
        wantedBy = [ "ewwbar.service" ];
        partOf = [ "ghaf-session.target" ];
      };

    };
  };
}
