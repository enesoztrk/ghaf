# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.host.networking;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionals
    ;
  sshKeysHelper = pkgs.callPackage ../common/ssh-keys-helper.nix { inherit config; };
  inherit (config.ghaf.networking) hosts;
  inherit (config.networking) hostName;
in
{
  options.ghaf.host.networking = {
    enable = mkEnableOption "Host networking";
    bridgeName = mkOption {
      type = lib.types.str;
      description = "Name of the bridge interface.";
      default = "virbr0";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      enableIPv6 = false;
      useNetworkd = true;
      interfaces."${cfg.bridgeName}".useDHCP = false;
    };

    # TODO Remove host networking
    systemd.network =
      let
        tracedInterface = builtins.trace "HostNW: ${builtins.toJSON cfg.bridgeName}" cfg.bridgeName;
      in
      {
        netdevs."10-${cfg.bridgeName}".netdevConfig = {
          Kind = "bridge";
          Name = tracedInterface;
          #      MACAddress = "02:00:00:02:02:02";
        };
        networks."10-${cfg.bridgeName}" = {
          matchConfig.Name = cfg.bridgeName;
          networkConfig.DHCPServer = false;
          addresses = [ { Address = "${hosts.${hostName}.ipv4}/24"; } ];
          gateway = optionals (builtins.hasAttr "net-vm" config.microvm.vms) [ "${hosts."net-vm".ipv4}" ];
        };
        # Connect VM tun/tap device to the bridge
        # TODO configure this based on IF the netvm is enabled
        networks."11-netvm" = {
          matchConfig.Name = "tap-*";
          networkConfig.Bridge = cfg.bridgeName;
        };
      };

    environment.etc = {
      ${config.ghaf.security.sshKeys.getAuthKeysFilePathInEtc} = sshKeysHelper.getAuthKeysSource;
    };

    services.openssh = config.ghaf.security.sshKeys.sshAuthorizedKeysCommand;
  };
}
