# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: {
  # Waypipe with vsock and window borders
  dendrite = prev.dendrite.overrideAttrs (_prevAttrs: {
    src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "dendrite";
    rev = "v0.9.1";
    hash = "sha256-Hy3QuwAHmZSsjy5A/1mrmrxdtle466HsQtDat3tYS8s=";
  };
    dendrite.subPackages = ["cmd/dendrite-demo-pinecone"];

    #patches = [./waypipe-window-borders.patch];
  });
})
