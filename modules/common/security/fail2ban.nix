# Copyright 2024-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  ...
}:
let
  cfg = config.ghaf.security.fail2ban;
  inherit (lib)
    mkIf
    mkEnableOption
    types
    ;
in
{
  options.ghaf.security.fail2ban = {
    enable = mkEnableOption "Enable fail2ban";
    banaction = lib.mkOption {
      type = types.str;
      default = "iptables-ipset-proto6-allports";
      example = "iptables-multiport";
      description = ''
        Banaction for fail2ban
      '';
    };
    fwMarkNum = lib.mkOption {
      type = types.str;
      default = "70";
      description = "Firewall mark number to apply to banned IPs when using iptables-ipset-mark.";
    };
    blacklistName = lib.mkOption {
      type = types.str;
      default = "blacklist";
      description = ''
        Blacklist name for fail2ban
      '';
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      extraPackages = [ pkgs.ipset ];
      bantime = "30m";
      maxretry = 3;
      bantime-increment.enable = true;
      bantime-increment.factor = "2";
      banaction = "${cfg.banaction}[name=${cfg.blacklistName}]";
      jails = {
        # sshd is jailed by default
      };
    };

    # Only provide custom action file if user selects iptables-ipset-mark
    environment.etc."fail2ban/action.d/iptables-ipset-mark.conf".text =
      mkIf (cfg.banaction == "iptables-ipset-mark")
        ''
          [INCLUDES]
          before = iptables-ipset-proto6.conf

          [Definition]
          rule-jump = -m set --match-set <ipmset> src -j MARK --set-mark ${cfg.fwMarkNum}

          [Init]
          chain = PREROUTING
          iptables = iptables -t raw <lockingopt>

          [Init?family=inet6]
          chain = PREROUTING
          iptables = ip6tables -t raw <lockingopt>
        '';

  };
}
