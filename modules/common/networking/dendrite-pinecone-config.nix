# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  # inherit (builtins) A B C;
  # inherit (lib) D E F;
  # inherit (lib.ghaf) G H I;
  cfg = config.ghaf.dendrite-pinecone;
  dendrite-pineconePkg = import ../../../packages/dendrite-pinecone/default.nix {inherit pkgs;};
  netvm-cfg = config.ghaf.virtualization.microvm.netvm;
in
  with lib; {
    imports = [
    ];

    options.ghaf.dendrite-pinecone = {
      enable = mkEnableOption "Enable dendrite pinecone module";
      
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

      serverIpAddr = mkOption {
       type = types.str;
          default = "";
          description = ''
            Dendrite Server Ip address
          '';
      
      };
    };

    config = mkIf cfg.enable {

   # lib.trivial.throwIf (cfg.externalNic == "")"";
    externalNicParam =
      [ { assertion = cfg.externalNic == "";
          message = "External Nic is must be set";
        }
      ];
    
    internallNicParam =
      [ { assertion = cfg.internalNic == "";
          message = "Internal Nic is must be set";
        }
      ];
        # ip forwarding functionality is needed for iptables
    netvm-cfg.boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # https://github.com/troglobit/smcroute?tab=readme-ov-file#linux-requirements
    netvm-cfg.boot.kernelPatches = [
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
    netvm-cfg.environment.systemPackages = [pkgs.smcroute];
    netvm-cfg.systemd.services."smcroute" = {
      description = "Static Multicast Routing daemon";
      bindsTo = ["sys-subsystem-net-devices-${cfg.externalNic}.device"];
      after = ["sys-subsystem-net-devices-${cfg.externalNic}.device"];
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
      '';

      netvm-cfg.serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.smcroute}/sbin/smcrouted -n -s -f /etc/smcroute.conf";
        #TODO sudo setcap cap_net_admin=ep ${pkgs.smcroute}/sbin/smcroute
        User = "root";
        # Automatically restart service when it exits.
        Restart = "always";
        # Wait a second before restarting.
        RestartSec = "5s";
      };
      wantedBy = ["multi-user.target"];
    };

    netvm-cfg.networking = {
      firewall.enable = true;
      firewall.extraCommands = "
        # Set the default policies
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Allow loopback traffic
        iptables -A INPUT -i lo -j ACCEPT

        # Forward incoming TCP traffic on port ${dendrite-pineconePkg.TcpPort} to internal network(element-vm)
        iptables -t nat -A PREROUTING -i ${cfg.externalNic} -p tcp --dport ${dendrite-pineconePkg.TcpPort} -j DNAT --to-destination  ${cfg.serverIpAddr}:${dendrite-pineconePkg.TcpPort}

        # Enable NAT for outgoing traffic
        iptables -t nat -A POSTROUTING -o ${cfg.externalNic} -p tcp --dport ${dendrite-pineconePkg.TcpPort} -j MASQUERADE

        # Enable NAT for outgoing traffic
        iptables -t nat -A POSTROUTING -o ${cfg.externalNic} -p tcp --sport ${dendrite-pineconePkg.TcpPort} -j MASQUERADE

        # Enable NAT for outgoing udp multicast traffic
        iptables -t nat -A POSTROUTING -o ${cfg.externalNic} -p udp -d ${dendrite-pineconePkg.McastUdpIp} --dport ${dendrite-pineconePkg.McastUdpPort} -j MASQUERADE

        # https://github.com/troglobit/smcroute?tab=readme-ov-file#usage
        iptables -t mangle -I PREROUTING -i ${cfg.externalNic} -d ${dendrite-pineconePkg.McastUdpIp} -j TTL --ttl-set 1
        # ttl value must be set to 1 for avoiding multicast looping
        iptables -t mangle -I PREROUTING -i ${cfg.internalNic} -d ${dendrite-pineconePkg.McastUdpIp} -j TTL --ttl-inc 1

        # Accept forwarding
        iptables -A FORWARD -j ACCEPT
      ";
    };


    };
  }
