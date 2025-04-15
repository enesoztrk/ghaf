# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:
let
  cfg = config.ghaf.reference.profiles.mvp-user-trial;
in
{
  options.ghaf.reference.profiles.mvp-user-trial = {
    enable = lib.mkEnableOption "Enable the mvp configuration for apps and services";
  };

  config = lib.mkIf cfg.enable {
    ghaf = {
      # Enable below option for session lock feature
      graphics = {
        #might be too optimistic to hide the boot logs
        #just yet :)
        # boot.enable = lib.mkForce true;
        labwc = {
          autologinUser = lib.mkForce null;
        };
      };
      # Enable shared directories for the selected VMs
      virtualization.microvm-host.sharedVmDirectory.vms = [
        "business-vm"
        "comms-vm"
        "chrome-vm"
      ];

      virtualization.microvm.appvm = {
        enable = true;
        vms = {
          chrome = {
            enable = true;
            extraNetworking = {
              ipv4 = "192.168.100.250";
              interfaceName = "chromeNic";
            };
          };
          gala = {
            enable = true;
            extraNetworking = {
              ipv4 = "192.168.100.251";
              interfaceName = "galaNic";
              mac = "DE:AD:BE:EF:00:01";
            };
          };
          zathura.enable = true;
          comms.enable = true;
          business.enable = true;
        };
      };

      virtualization.microvm.netvm.extraNetworking = {
        interfaceName = builtins.trace "hello" "enesNic";
        ipv4 = "192.168.100.200";
      };
      reference = {
        appvms.enable = true;

        services = {
          enable = true;
          dendrite = true;
          proxy-business = lib.mkForce config.ghaf.virtualization.microvm.appvm.vms.business.enable;
          google-chromecast = true;
          alpaca-ollama = true;
          wireguard-gui = true;
        };

        personalize = {
          keys.enable = true;
        };

        desktop.applications.enable = true;
      };

      profiles = {
        laptop-x86 = {
          enable = true;
          netvmExtraModules = [
            ../services
            ../personalize
            { ghaf.reference.personalize.keys.enable = true; }
          ];
          guivmExtraModules = [
            ../services
            ../programs
            ../personalize
            { ghaf.reference.personalize.keys.enable = true; }
          ];
        };
      };

      # Enable logging
      logging = {
        enable = true;
        server.endpoint = "https://loki.ghaflogs.vedenemo.dev/loki/api/v1/push";
        listener.address = config.ghaf.networking.hosts.admin-vm.ipv4;
      };
    };
  };
}
