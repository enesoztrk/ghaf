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
  ChromeCastPort1="8008";
    ChromeCastPort2="8009";

  SsdpMcastPort = "1900";
  SsdpMcastIp = "239.255.255.250";


  getNetVmEntry = builtins.filter (x: x.name == "net-vm") config.ghaf.networking.hosts.entries;
  netVmInternalIp = lib.head (builtins.map (x: x.ip) getNetVmEntry);
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
  #  environment.systemPackages =  lib.optionals config.ghaf.profiles.debug.enable [ pkgs.tcpdump nw-packet-forwarder];
    environment.systemPackages =  [ pkgs.tcpdump];


    services.nw-packet-forwarder = {
      enable = true;
      externalNic = cfg.externalNic;
      internalNic = cfg.internalNic;
      chromecast = true;
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

    # Redirect incoming Chromecast traffic based on source ports (8008 and 8009)
    iptables -t nat -I PREROUTING -i ${cfg.externalNic} -p tcp --sport ${ChromeCastPort1} -j DNAT --to-destination 192.168.100.100:${ChromeCastPort1}
    iptables -t nat -I PREROUTING -i ${cfg.externalNic} -p tcp --sport ${ChromeCastPort2} -j DNAT --to-destination 192.168.100.100:${ChromeCastPort2}

    # Forward incoming TCP traffic on ports 8008 and 8009 to the internal NIC
    iptables -I FORWARD -i ${cfg.externalNic} -o ${cfg.internalNic} -p tcp --sport ${ChromeCastPort1} -j ACCEPT
    iptables -I FORWARD -i ${cfg.externalNic} -o ${cfg.internalNic} -p tcp --sport ${ChromeCastPort2} -j ACCEPT

    # Enable NAT for outgoing 8008 and 8009 Chromecast traffic
    iptables -t nat -I POSTROUTING -o ${cfg.externalNic} -p tcp --dport ${ChromeCastPort1} -j MASQUERADE
    iptables -t nat -I POSTROUTING -o ${cfg.externalNic} -p tcp --dport ${ChromeCastPort2} -j MASQUERADE

    # TTL adjustments to avoid multicast loops
    iptables -t mangle -I PREROUTING -i ${cfg.externalNic} -d ${SsdpMcastIp} -j TTL --ttl-set 1
    iptables -t mangle -I PREROUTING -i ${cfg.internalNic} -d ${SsdpMcastIp} -j TTL --ttl-inc 1
    # Enable NAT for outgoing udp multicast traffic
        iptables -t nat -I POSTROUTING -o ${cfg.externalNic} -p udp -d ${SsdpMcastIp} --dport ${SsdpMcastPort} -j MASQUERADE
";

    };
  };
}
