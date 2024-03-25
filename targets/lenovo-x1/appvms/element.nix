{pkgs, ...}: {
  name = "element";
  packages = [pkgs.dendrite pkgs.tcpdump pkgs.element-desktop];
  macAddress = "02:00:00:03:08:01";
  ramMb = 512;
  cores = 1;
    
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
    firewall.allowedTCPPorts = [49001];
    };
      time.timeZone = "Asia/Dubai";
    }
  ];
  borderColor = "#337aff";
}