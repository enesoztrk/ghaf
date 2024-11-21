{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.smcroute;
in
{
  options.services.smcroute = {
    enable = lib.mkEnableOption "smcroute";
    confFile = lib.mkOption {
      type = lib.types.path;
      example = "/var/lib/smcroute/smcroute.conf";
      description = ''
        Ignore all other smcroute options and load configuration from this file.
      '';
    };

    bindingNic = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "";
      description = ''
      Binding NIC
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "net-admin";
      example = "net-admin";
      description = ''
        System service user
      '';
    };

    rules = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = ''
        https://github.com/troglobit/smcroute?tab=readme-ov-file#usage
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.bindingNic != "";
        message = "Binding Nic must be set";
      }
    ];

  # Allow proxy-admin group to manage specific systemd services without a password
    security = {
      polkit = {
        enable = true;
        debug = true;
        # Polkit rules for allowing proxy-user to run proxy related systemctl 
        # commands without sudo and password requirement 
        extraConfig = ''
          polkit.addRule(function(action, subject) {
              if ((action.id == "org.freedesktop.systemd1.manage-units" &&
                   (action.lookup("unit") == "smcroute.service") &&
                  subject.user == "${cfg.user}") {
                  return polkit.Result.YES;
              }
          });
        '';
      };

    };

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

    services.smcroute.confFile = lib.mkDefault (
      pkgs.writeText "smcroute.conf" ''

        ${lib.concatStringsSep "\n" (lib.optionals (cfg.rules != null) [ cfg.rules ])}
      ''
    );

    systemd.services."smcroute" = {
      description = "Static Multicast Routing daemon";
      bindsTo = [ "sys-subsystem-net-devices-${cfg.bindingNic}.device" ];
      after = [ "sys-subsystem-net-devices-${cfg.bindingNic}.device" ];
      preStart = ''
        # wait until ${cfg.bindingNic} has an ip
        sleep 5
        while [ -z "$ip" ]; do
         ip=$(${pkgs.nettools}/bin/ifconfig ${cfg.bindingNic} | ${pkgs.gawk}/bin/awk '/inet / {print $2}')
              [ -z "$ip" ] && ${pkgs.coreutils}/bin/sleep 1
        done
        exit 0
      '';

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.smcroute}/sbin/smcrouted -n -s -f ${cfg.confFile}";
        User = "${cfg.user}";
        # Restart the service if it fails
        Restart = "on-failure";
        # Wait a second before restarting.
        RestartSec = "5s";
      };
      wantedBy = [ "multi-user.target" ];
    };

  };

}
