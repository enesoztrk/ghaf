# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: {

  dendrite = prev.dendrite.overrideAttrs (_prevAttrs: {
    src = final.pkgs.fetchFromGitHub {
    owner = "matrix-org";
    repo = "dendrite";
    rev = "a2bed259dd765bd0b9781cd65594343d22c07986";
    hash = "sha256-Hy3QuwAHmZSsjy5A/1mrmrxdtle466HsQtDat3tYS8s=";
  };
      patches = [./turnserver-crendentials-flags.patch];

    subPackages = ["cmd/dendrite-demo-pinecone"];

  });
})
