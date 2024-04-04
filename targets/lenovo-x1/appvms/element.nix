# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{pkgs, ...}: let
  dendriteTcpPort = 49000;
  dendriteUdpPort = 60606;
  dendrite-pinecone = pkgs.callPackage ../../../packages/dendrite-pinecone {};
in {
  name = "element";

  packages = [dendrite-pinecone pkgs.tcpdump pkgs.element-desktop pkgs.element-gps pkgs.gpsd];
  macAddress = "02:00:00:03:08:01";
  ramMb = 4096;
  cores = 4;
  extraModules = [
    {
       # Enable pulseaudio for user ghaf to access mic
      sound.enable = true;
      hardware.pulseaudio.enable = true;
      users.extraUsers.ghaf.extraGroups = ["audio"];

      environment.systemPackages = [
            pkgs.pamixer
      ];
      hardware.pulseaudio.extraConfig = ''
                          load-module module-combine-sink
                          set-sink-volume @DEFAULT_SINK@ 60000
      '';
      systemd.network = {
        enable = true;
        networks."10-ethint0" = {
         # DHCP = pkgs.lib.mkForce "no";
          #networkConfig.DNS = ["192.168.100.1"]; 
          #networkConfig.Domains = "ghaf"; 
          matchConfig.Name = "ethint0";
          addresses = [
            {
              addressConfig.Address = "192.168.100.253/24";
            }
          ];
          routes = [{routeConfig.Gateway = "192.168.100.1";}];
          linkConfig.RequiredForOnline = "routable";
          linkConfig.ActivationPolicy = "always-up";
          networkConfig.LinkLocalAddressing = "ipv4";
        };
      };

      networking = {
        firewall.allowedTCPPorts = [dendriteTcpPort];
        firewall.allowedUDPPorts = [dendriteUdpPort];
      };

      time.timeZone = "Asia/Dubai";

      systemd.services."dendrite-pinecone" = {
        description = "Dendrite is a second-generation Matrix homeserver with Pinecone which is a next-generation P2P overlay network";
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${dendrite-pinecone}/bin/dendrite-demo-pinecone";
          Restart = "on-failure";
          RestartSec = "2";
        };
        wantedBy = ["multi-user.target"];
      };

      services.gpsd = {
        enable = true;
        devices = ["/dev/ttyUSB0"];
        readonly = true;
        debugLevel = 2;
        listenany = true;
        extraArgs = ["-n"]; # Do not wait for a client to connect before polling
      };

      systemd.services.element-gps = {
        description = "Element-gps is a GPS location provider for Element websocket interface.";
        enable = true;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.element-gps}/bin/main.py";
          Restart = "on-failure";
          RestartSec = "2";
        };
        wantedBy = ["multi-user.target"];
      };

      microvm.qemu.extraArgs = [
        # Lenovo X1 integrated usb webcam
        "-device"
        "qemu-xhci"
        "-device"
        "usb-host,hostbus=3,hostport=8"
        # External USB GPS receiver
        "-device"
        "usb-host,vendorid=0x067b,productid=0x23a3"
        # Connect sound device to hosts pulseaudio socket
        "-audiodev"
        "pa,id=pa1,server=unix:/run/pulse/native"
        # Add HDA sound device to guest
        "-device"
        "intel-hda"
        "-device"
        "hda-duplex,audiodev=pa1"
      ];
    }
  ];
  borderColor = "#337aff";
}
