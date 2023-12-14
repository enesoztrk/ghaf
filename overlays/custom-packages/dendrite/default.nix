# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
(final: prev: {

  dendrite = prev.dendrite.overrideAttrs (_prevAttrs: {
      
      version = "0.9.1";
  vendorHash = "sha256-M7ogR1ya+sqlWVQpaXlvJy9YwhdM4XBDw8e2ZBPvEGY=";

  
    #patches = [./turnserver-crendentials-flags.patch];

    subPackages = ["cmd/dendrite-demo-pinecone"];

  });
})
