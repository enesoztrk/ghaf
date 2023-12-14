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
    sha256 = "sha256:1mgf2alrarhl21ixmrpgx189hc04qifz2lyiz4b0g1kvqfi5c4lg";
  }))
    (import ./element-packet-forwarder)
    (import ./dendrite)
  ];
}
