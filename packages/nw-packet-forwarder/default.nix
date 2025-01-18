# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenvNoCC,
  pkgs,
  lib,
  fetchFromGitHub,
  ...
}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "nw-packet-forwader";
  version = "feat/chromecast";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = pname;
    rev = version;
    sha256 = "sha256-+xoDl7npFg89YpFa1vHmTaMEkfjmG6JDsOjQJ1SFJ+s=";
  };

  cargoHash = "sha256-ZhE0ZiQ1Us+V4mxdhY2ZpcJsIIoQEN7tpG0Ydb3y3gU=";

  meta = with lib; {
    description = "Network packet forwarder";
    license = licenses.asl20;
    maintainers = with maintainers; [ tiiuae ];
  };
}