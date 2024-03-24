# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  lib,
  pkgs,
  microvm,
  configH,
  ...
}: let
  netvmPCIPassthroughModule = {
    microvm.devices = lib.mkForce (
      builtins.map (d: {
        bus = "pci";
        inherit (d) path;
      })
      configH.ghaf.hardware.definition.network.pciDevices
    );
  };

  netvmAdditionalFirewallConfig = let
    externalNic = let
      firstPciWifiDevice = lib.head configH.ghaf.hardware.definition.network.pciDevices;
    in "${firstPciWifiDevice.name}";

    internalNic = let
      vmNetworking = import ../../modules/microvm/virtualization/microvm/common/vm-networking.nix {
        vmName = microvm.name;
        inherit (microvm) macAddress;
      };
    in "${lib.head vmNetworking.networking.nat.internalInterfaces}";

    dendrite-pinecone = import ../../packages/dendrite-pinecone/default.nix {inherit pkgs;};
    elemen-vmIp = "192.168.100.253";
  in {
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
    environment.systemPackages = [pkgs.smcroute];
    systemd.services."smcroute" = {
      description = "Static Multicast Routing daemon";
      bindsTo = ["sys-subsystem-net-devices-${externalNic}.device"];
      after = ["sys-subsystem-net-devices-${externalNic}.device"];
      preStart = ''
              configContent=$(cat <<EOF
        mgroup from ${externalNic} group ${dendrite-pinecone.McastUdpIp}
        mgroup from ${internalNic} group ${dendrite-pinecone.McastUdpIp}
        mroute from ${externalNic} group ${dendrite-pinecone.McastUdpIp} to ${internalNic}
        mroute from ${internalNic} group ${dendrite-pinecone.McastUdpIp} to ${externalNic}
        EOF
        )
        filePath="/etc/smcroute.conf"
        touch $filePath
          chmod 200 $filePath
          echo "$configContent" > $filePath
          chmod 400 $filePath

        # wait until ${externalNic} has an ip
        while [ -z "$ip" ]; do
         ip=$(${pkgs.nettools}/bin/ifconfig ${externalNic} | ${pkgs.gawk}/bin/awk '/inet / {print $2}')
              [ -z "$ip" ] && ${pkgs.coreutils}/bin/sleep 1
        done
        exit 0
      '';

      serviceConfig = {
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

    networking = {
      firewall.enable = true;
      firewall.extraCommands = "
        # Set the default policies
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Allow loopback traffic
        iptables -A INPUT -i lo -j ACCEPT

        # Forward incoming TCP traffic on port ${dendrite-pinecone.TcpPort} to internal network(element-vm)
        iptables -t nat -A PREROUTING -i ${externalNic} -p tcp --dport ${dendrite-pinecone.TcpPort} -j DNAT --to-destination  ${elemen-vmIp}:${dendrite-pinecone.TcpPort}

        # Enable NAT for outgoing traffic
        iptables -t nat -A POSTROUTING -o ${externalNic} -p tcp --dport ${dendrite-pinecone.TcpPort} -j MASQUERADE

        # Enable NAT for outgoing traffic
        iptables -t nat -A POSTROUTING -o ${externalNic} -p tcp --sport ${dendrite-pinecone.TcpPort} -j MASQUERADE

        # Enable NAT for outgoing udp multicast traffic
        iptables -t nat -A POSTROUTING -o ${externalNic} -p udp -d ${dendrite-pinecone.McastUdpIp} --dport ${dendrite-pinecone.McastUdpPort} -j MASQUERADE

        # https://github.com/troglobit/smcroute?tab=readme-ov-file#usage
        iptables -t mangle -I PREROUTING -i ${externalNic} -d ${dendrite-pinecone.McastUdpIp} -j TTL --ttl-set 1
        # ttl value must be set to 1 for avoiding multicast looping
        iptables -t mangle -I PREROUTING -i ${internalNic} -d ${dendrite-pinecone.McastUdpIp} -j TTL --ttl-inc 1

        # Accept forwarding
        iptables -A FORWARD -j ACCEPT
      ";
    };

    # DNS host record has been added for element-vm static ip
    services.dnsmasq.settings.host-record = "element-vm,element-vm.ghaf,${elemen-vmIp}";
  };

  netvmAdditionalConfig = {
    # For WLAN firmwares
    hardware.enableRedistributableFirmware = true;

    networking = {
      # wireless is disabled because we use NetworkManager for wireless
      wireless.enable = lib.mkForce false;
      networkmanager = {
        enable = true;
        unmanaged = ["ethint0"];
      };
    };
    # noXlibs=false; needed for NetworkManager stuff
    environment.noXlibs = false;
    environment.etc."NetworkManager/system-connections/Wifi-1.nmconnection" = {
      text = ''
        [connection]
        id=Wifi-1
        uuid=33679db6-4cde-11ee-be56-0242ac120002
        type=wifi
        [wifi]
        mode=infrastructure
        ssid=SSID_OF_NETWORK
        [wifi-security]
        key-mgmt=wpa-psk
        psk=WPA_PASSWORD
        [ipv4]
        method=auto
        [ipv6]
        method=disabled
        [proxy]
      '';
      mode = "0600";
    };

    # Add simple wi-fi connection helper
    environment.systemPackages = lib.mkIf configH.ghaf.profiles.debug.enable [pkgs.wifi-connector-nmcli pkgs.tcpdump];

    services.openssh = configH.ghaf.security.sshKeys.sshAuthorizedKeysCommand;

    time.timeZone = "Asia/Dubai";
  };
in [netvmPCIPassthroughModule netvmAdditionalConfig]
