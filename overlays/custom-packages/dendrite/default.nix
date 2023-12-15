# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: {

  dendrite = prev.dendrite.overrideAttrs (_prevAttrs: {
    src = final.pkgs.fetchFromGitHub {
    owner = "matrix-org";
    repo = "dendrite";
    rev = "v123.9.1";
    hash = "sha256-Hy3QuwAHmZSsjy5A/1mrmrxdtle466HsQtDat3tYS8s=";
  };
    #patches = [./turnserver-crendentials-flags.patch];
    vendorSha256 = null;
    subPackages = ["cmd/dendrite-demo-pinecone"];

  });
})

