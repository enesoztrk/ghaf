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
  
  netvmAdditionalFirewallConfig = {
  
  # ip forwarding functionality is needed for iptables
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

     networking = {
      firewall.enable = true;
      firewall.extraCommands = "

      iptables -P INPUT DROP    
      iptables -P FORWARD ACCEPT
      iptables -P OUTPUT ACCEPT 
      # Allow loopback traffic
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A OUTPUT -o lo -j ACCEPT
  
  # Iterate over the list of network device names
  ${lib.concatMapStringsSep "\n" (device: ''
     # Create a custom chain for DNAT
      iptables -t nat -N dendrite-dnat-${device}

     # Forward incoming TCP traffic on port 49000 to dendrite NIC (${device} to ethint0)
      iptables -t nat -A dendrite-dnat-${device} -i ${device} -p tcp --dport 49000 -j DNAT --to-destination 192.168.100.253:49000

     # Hook the custom chain into the PREROUTING chain
      iptables -t nat -A PREROUTING -j dendrite-dnat-${device}

     # Create a custom chain for SNAT
      iptables -t nat -N dendrite-snat-${device}

     # Enable NAT for outgoing traffic
      iptables -t nat -A dendrite-snat-${device} -o ${device} -p tcp --dport 49000 -j MASQUERADE

     # Enable NAT for incoming traffic
      iptables -t nat -A dendrite-snat-${device} -o ${device} -p tcp --sport 49000 -j MASQUERADE

     # Hook the custom chain into the POSTROUTING chain
      iptables -t nat -A POSTROUTING -j dendrite-snat-${device}
  '') (map (device: device.name) configH.ghaf.hardware.definition.network.pciDevices)}
      ";
    };
  };

  netvmAdditionalConfig = {
    # Add the waypipe-ssh public key to the microvm
    microvm = {
      shares = [
        {
          tag = configH.ghaf.security.sshKeys.waypipeSshPublicKeyName;
          source = configH.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
          mountPoint = configH.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
        }
      ];
    };
    fileSystems.${configH.ghaf.security.sshKeys.waypipeSshPublicKeyDir}.options = ["ro"];

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
    # Waypipe-ssh key is used here to create keys for ssh tunneling to forward D-Bus sockets.
    # SSH is very picky about to file permissions and ownership and will
    # accept neither direct path inside /nix/store or symlink that points
    # there. Therefore we copy the file to /etc/ssh/get-auth-keys (by
    # setting mode), instead of symlinking it.
    environment.etc.${configH.ghaf.security.sshKeys.getAuthKeysFilePathInEtc} = import ./getAuthKeysSource.nix {
      inherit pkgs;
      config = configH;
    };
    # Add simple wi-fi connection helper
    environment.systemPackages = lib.mkIf configH.ghaf.profiles.debug.enable [pkgs.wifi-connector-nmcli];

    services.openssh = configH.ghaf.security.sshKeys.sshAuthorizedKeysCommand;

    time.timeZone = "Asia/Dubai";

    

  };
in [./sshkeys.nix netvmPCIPassthroughModule netvmAdditionalConfig netvmAdditionalFirewallConfig]
