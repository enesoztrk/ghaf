# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.reference.programs.element-desktop;
  isDendritePineconeEnabled =
    if (lib.hasAttr "services" config.ghaf.reference) then
      config.ghaf.reference.services.dendrite
    else
      false;

in
{
  options.ghaf.reference.programs.element-desktop = {
    enable = lib.mkEnableOption "element-desktop program settings";
  };
  config = lib.mkIf cfg.enable {
    environment.etc."element-cfg/config.json" = {
      mode = "0666"; # read/write for all users
      text = ''
        {
          "default_server_config": {
            "m.homeserver": {
              "base_url": "https://matrix-client.matrix.org",
              "server_name": "matrix.org"
            },
            "m.identity_server": {
              "base_url": "https://vector.im"
            }
          },
          "disable_custom_urls": false,
          "disable_guests": true,
          "disable_login_language_selector": false,
          "disable_3pid_login": false,
          "force_verification": false,
          "brand": "Element",
          "integrations_ui_url": "https://scalar.vector.im/",
          "integrations_rest_url": "https://scalar.vector.im/api",
          "integrations_widgets_urls": [
            "https://scalar.vector.im/_matrix/integrations/v1",
            "https://scalar.vector.im/api",
            "https://scalar-staging.vector.im/_matrix/integrations/v1",
            "https://scalar-staging.vector.im/api",
            "https://scalar-staging.riot.im/scalar/api"
          ],
          "default_widget_container_height": 280,
          "default_country_code": "GB",
          "show_labs_settings": false,
          "features": {},
          "default_federate": true,
          "default_theme": "light",
          "room_directory": {
            "servers": [
              "matrix.org"
            ]
          },
          "enable_presence_by_hs_url": {
            "https://matrix.org": false,
            "https://matrix-client.matrix.org": false
          },
          "setting_defaults": {
            "breadcrumbs": true
          },
          "jitsi": {
            "preferred_domain": "meet.element.io"
          },
          "element_call": {
            "url": "https://call.element.io",
            "participant_limit": 8,
            "brand": "Element Call"
          },
          "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx"
        }
      '';

    };

    systemd.tmpfiles.rules = [
      "d /home/appuser/element-cfg 0755 appuser appuser -"
      # create profile as a subdirectory
      "d /home/appuser/element-cfg/profile 0755 appuser appuser -"
    ];
    systemd.services = {

      # The element-gps listens for WebSocket connections on localhost port 8000 from element-desktop
      # When a new connection is received, it executes the gpspipe program to get GPS data from GPSD and forwards it over the WebSocket
      element-gps = {
        description = "Element-gps is a GPS location provider for Element websocket interface.";
        enable = true;
        # Make sure this service is started after gpsd is running
        requires = [ "gpsd.service" ];
        after = [ "gpsd.service" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.element-gps}/bin/main.py";
          Restart = "on-failure";
          RestartSec = "2";
        };
        wantedBy = [ "multi-user.target" ];
      };

      "dendrite-pinecone" = pkgs.lib.mkIf isDendritePineconeEnabled {
        description = "Dendrite is a second-generation Matrix homeserver with Pinecone which is a next-generation P2P overlay network";
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.dendrite-pinecone}/bin/dendrite-demo-pinecone";
          Restart = "on-failure";
          RestartSec = "2";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };

    networking = pkgs.lib.mkIf isDendritePineconeEnabled {
      firewall.allowedTCPPorts = [ pkgs.dendrite-pinecone.TcpPortInt ];
      firewall.allowedUDPPorts = [ pkgs.dendrite-pinecone.McastUdpPortInt ];
    };

  };
}
