# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# This overlay customizes element-desktop
#
{ prev }:
prev.element-desktop.overrideAttrs (prevAttrs: {
  patches = [ ./element-main.patch ];
  postInstall =
    prevAttrs.postInstall or ""
    + ''
        # Copy en-us.json into the final output to avoid dangling symlinks
      cp $out/share/element/electron/lib/i18n/strings/en-us.json \
         $out/share/element/electron/lib/i18n/strings/en_US.json || true
    '';
})
