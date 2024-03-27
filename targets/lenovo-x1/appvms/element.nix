{pkgs, ...}:
let
  dendriteTcpPort = 49000;
  dendriteUdpPort = 60606;
in{
  name = "element";
  packages = [pkgs.dendrite pkgs.tcpdump pkgs.element-desktop];
  macAddress = "02:00:00:03:08:01";
  ramMb = 3072;
  cores = 4;
  extraModules = [
    {
      systemd.network = {
          enable = true;
          networks."10-ethint0" = {
             DHCP = pkgs.lib.mkForce "no";
             matchConfig.Name = "ethint0";
            addresses = [
              {
                addressConfig.Address = "192.168.100.253/24";
              }
            ];
             routes = [ { routeConfig.Gateway = "192.168.100.1"; }];
            linkConfig.RequiredForOnline = "routable";
            linkConfig.ActivationPolicy = "always-up";
          };
      };

    networking = {
    firewall.allowedTCPPorts = [dendriteTcpPort];
    firewall.allowedUDPPorts = [dendriteUdpPort];
    };
      time.timeZone = "Asia/Dubai";
    }
  ];
  borderColor = "#337aff";
}