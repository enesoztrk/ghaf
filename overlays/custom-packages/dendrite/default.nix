# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: {

  dendrite = prev.dendrite.overrideAttrs (_prevAttrs: {
    src = final.pkgs.fetchFromGitHub {
    owner = "matrix-org";
    repo = "dendrite";
    rev = "v0.9.1";
    hash = "sha256-Hy3QuwAHmZSsjy5A/1mrmrxdtle466HsQtDat3tYS8s=";
  };
    subPackages = ["cmd/dendrite-demo-pinecone"];

    patches = [./0001-flags-for-turnserver-credentials-are-added.patch];
  });
})
