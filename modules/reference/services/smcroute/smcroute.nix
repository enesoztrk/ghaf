{ config, lib, pkgs, ... }:
let
  cfg = config.services.smcroute;
in {
  options.services.smcroute = {
    enable = lib.mkEnableOption "smcroute";
    confFile = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/smcroute/smcroute.conf";
      description = ''
        Ignore all other smcroute options and load configuration from this file.
      '';
    };
  
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [ pkgs.smcroute ];

    # ip forwarding functionality is needed for iptables
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # https://github.com/troglobit/smcroute?tab=readme-ov-file#linux-requirements
    boot.kernelPatches = [
      {
        name = "multicast-routing-config";
        patch = null;
        extraStructuredConfig = with lib.kernel; {
          IP_MULTICAST = yes;
          IP_MROUTE = yes;
          IP_PIMSM_V1 = yes;
          IP_PIMSM_V2 = yes;
          IP_MROUTE_MULTIPLE_TABLES = yes; # For multiple routing tables
        };
      }
    ];


    services.smcroute.confFile = lib.mkDefault (pkgs.writeText "smcroute.conf" ''
     
    '');
        systemd.services."smcroute" = {
      description = "Static Multicast Routing daemon";
    /*   bindsTo = [ "sys-subsystem-net-devices-${cfg.externalNic}.device" ];
      after = [ "sys-subsystem-net-devices-${cfg.externalNic}.device" ];
      preStart = ''
              configContent=$(cat <<EOF
        mgroup from ${cfg.externalNic} group ${dendrite-pineconePkg.McastUdpIp}
        mgroup from ${cfg.internalNic} group ${dendrite-pineconePkg.McastUdpIp}
        mroute from ${cfg.externalNic} group ${dendrite-pineconePkg.McastUdpIp} to ${cfg.internalNic}
        mroute from ${cfg.internalNic} group ${dendrite-pineconePkg.McastUdpIp} to ${cfg.externalNic}
        EOF
        )
        filePath="/etc/smcroute.conf"
        touch $filePath
          chmod 200 $filePath
          echo "$configContent" > $filePath
          chmod 400 $filePath

        # wait until ${cfg.externalNic} has an ip
        while [ -z "$ip" ]; do
         ip=$(${pkgs.nettools}/bin/ifconfig ${cfg.externalNic} | ${pkgs.gawk}/bin/awk '/inet / {print $2}')
              [ -z "$ip" ] && ${pkgs.coreutils}/bin/sleep 1
        done
        exit 0
      ''; */

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.smcroute}/sbin/smcrouted -n -s -f ${cfg.confFile}";
        #TODO sudo setcap cap_net_admin=ep ${pkgs.smcroute}/sbin/smcroute
        # TODO: Add proper AmbientCapabilities= or CapabilityBoundingSet=,
        #       preferably former and then change user to something else than
        #       root.
        User = "root";
        # Automatically restart service when it exits.
        Restart = "always";
        # Wait a second before restarting.
        RestartSec = "5s";
      };
      wantedBy = [ "multi-user.target" ];
    };

  };

}