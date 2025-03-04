# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ inputs, ... }:
{
  flake.nixosModules = {
    givc-adminvm.imports = [
      inputs.givc.nixosModules.admin
      ./common.nix
      ./adminvm.nix
    ];
    givc-host.imports = [
      inputs.givc.nixosModules.host
      inputs.givc.nixosModules.tls
      ./common.nix
      ./host.nix
    ];
    givc-guivm.imports = [
      inputs.givc.nixosModules.sysvm
      ./common.nix
      ./guivm.nix
    ];
    givc-netvm.imports = [
      inputs.givc.nixosModules.sysvm
      ./common.nix
      ./netvm.nix
    ];
    givc-audiovm.imports = [
      inputs.givc.nixosModules.sysvm
      ./common.nix
      ./audiovm.nix
    ];
    givc-appvm.imports = [
      inputs.givc.nixosModules.appvm
      ./common.nix
      ./appvm.nix
    ];
  };
}
