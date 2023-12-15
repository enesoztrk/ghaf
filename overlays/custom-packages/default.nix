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
    sha256 = "sha256:0w7kif7iv2rhai25x5j4qrac3h15grjpcpr2hnlsdlphgkx0qyd3";
  }))
    (import ./element-packet-forwarder)
    (import ./ghaf-dendrite)
  ];
}
