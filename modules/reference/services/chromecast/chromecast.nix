# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.reference.services.chromecast;
  inherit (config.ghaf.reference) services;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  SsdpMcastPort = "1900";
  SsdpMcastIp = "239.255.255.250";
in
{
  options.ghaf.reference.services.chromecast = {
    enable = mkEnableOption "Enable chromecast service";

    externalNic = mkOption {
      type = types.str;
      default = "";
      description = ''
        External network interface
      '';
    };
    internalNic = mkOption {
      type = types.str;
      default = "";
      description = ''
        Internal network interface
      '';
    };


  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.externalNic != "";
        message = "External Nic must be set";
      }
      {
        assertion = cfg.internalNic != "";
        message = "Internal Nic must be set";
      }

    ];
    environment.systemPackages =  lib.optionals config.ghaf.profiles.debug.enable [ pkgs.tcpdump ];

    services.avahi={

      enable =true;
      reflector =true;
      openFirewall=true;
    };

    services.smcroute = {
      enable = true;
      bindingNic = "${cfg.externalNic}";
      rules = ''
        mgroup from ${cfg.externalNic} group ${SsdpMcastIp}
        mgroup from ${cfg.internalNic} group ${SsdpMcastIp}
        mroute from ${cfg.externalNic} group ${SsdpMcastIp} to ${cfg.internalNic}
        mroute from ${cfg.internalNic} group ${SsdpMcastIp} to ${cfg.externalNic}
      '';
    };
    networking = {
      firewall.enable = true;
      firewall.extraCommands = "
        # Set the default policies
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Allow loopback traffic
        iptables -I INPUT -i lo -j ACCEPT


        # Enable NAT for outgoing udp multicast traffic
        iptables -t nat -I POSTROUTING -o ${cfg.externalNic} -p udp -d ${SsdpMcastIp} --dport ${SsdpMcastPort} -j MASQUERADE

        # https://github.com/troglobit/smcroute?tab=readme-ov-file#usage
        iptables -t mangle -I PREROUTING -i ${cfg.externalNic} -d ${SsdpMcastIp} -j TTL --ttl-set 1
        # ttl value must be set to 1 for avoiding multicast looping
        iptables -t mangle -I PREROUTING -i ${cfg.internalNic} -d ${SsdpMcastIp} -j TTL --ttl-inc 1

        # Accept forwarding
        iptables -A FORWARD -j ACCEPT
      ";
    };
  };
}
