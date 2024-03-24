# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{pkgs, ...}:{
  name = "element";
  packages = [pkgs.element-desktop pkgs.dendrite-pinecone pkgs.netcat-gnu pkgs.tcpdump];
  # TODO create a repository of mac addresses to avoid conflicts
  macAddress = "02:00:00:03:08:01";
  ramMb = 3072;
  cores = 4;
  extraModules = [
    {
    systemd.services."dendrite-pinecone" = {
      description = "Dendrite is a second-generation Matrix homeserver with Pinecone which is a next-generation P2P overlay network";
      enable = true;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.dendrite-pinecone}/bin/dendrite-demo-pinecone";
        Restart = "on-failure";
        RestartSec = "2";
      };
      wantedBy = ["multi-user.target"];
      };

      systemd.network = {
          enable = true;
          networks."10-ethint0" = {
            matchConfig.MACAddress = macAddress;
            addresses = [
              {
                addressConfig.Address = "192.168.100.253/24";
              }
            ];
            linkConfig.ActivationPolicy = "always-up";
          };
      };



      # Enable pulseaudio for user ghaf
      sound.enable = true;
      hardware.pulseaudio.enable = true;
      users.extraUsers.ghaf.extraGroups = ["audio"];

      time.timeZone = "Asia/Dubai";

      microvm.qemu.extraArgs = [
        # Connect sound device to hosts pulseaudio socket
        "-audiodev"
        "pa,id=pa1,server=unix:/run/pulse/native"
        # Add HDA sound device to guest
        "-device"
        "intel-hda"
        "-device"
        "hda-duplex,audiodev=pa1"
        # Lenovo X1 integrated usb webcam
        "-device"
        "qemu-xhci"
        "-device"
        "usb-host,hostbus=3,hostport=8"
      ];
      microvm.devices = [];

   
    }
  ];
  borderColor = "#ff5733";
}
