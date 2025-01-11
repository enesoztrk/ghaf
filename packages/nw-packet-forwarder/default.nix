# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenvNoCC,
  pkgs,
  lib,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "nw-packet-forwader";
  version = "feat/chromecast";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = pname;
    rev = version;
    sha256 = "1iga3320mgi7m853la55xip514a3chqsdi1a1rwv25lr9b1p7vd3";
  };

  cargoSha256 = "17ldqr3asrdcsh4l29m3b5r37r5d0b3npq1lrgjmxb6vlx6a36qh";

  meta = with stdenv.lib; {
    description = "Packet forwarder app to forward necessary packets between network interfaces";
    homepage = "https://github.com/tiiuae/nw-packet-forwader/";
    license = licenses.Apache_2_0;
    maintainers = with maintainers; [ tiiuae ];};
}