# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This overlay customizes ghaf packages
#
_: {
  nixpkgs.overlays = [
    (import ./gala)
    (import ./systemd)
    (import ./waypipe)
    (import ./weston)
    (import ./wifi-connector)
    (import ./qemu)
    (import ./nm-launcher)
    (import ./labwc)
    (import ( 
    fetchTarball {
    url = "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
    sha256 = "sha256:02hfyiwwr30ij87jg78arklm5rkrbxygpxbiy6y9lsn9f0ch2jqm";
  }))
    (import ./element-packet-forwarder)
    (import ./dendrite)
  ];
}
