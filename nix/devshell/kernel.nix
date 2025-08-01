# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      mkKernelShell =
        {
          platform,
          arch ? "",
          linux,
          extraPackages ? [ ],
          shellHook ? "",
        }:
        pkgs.mkShell {
          name = "Kernel-${platform} devshell";
          packages = [
            pkgs.ncurses
            pkgs.pkg-config
            pkgs.kernel-hardening-checker
          ]
          ++ extraPackages;

          inputsFrom = [ linux ];

          shellHook = ''
            export src=${linux.src}
            if [ -d "$src" ]; then
              # Jetpack's kernel named "source-patched" or likewise, workaround it
              linuxDir=$(stripHash ${linux.src})
            else
              linuxDir="linux-${linux.version}"
            fi
            if [ ! -d "$linuxDir" ]; then
              unpackPhase
              patchPhase
            fi
            cd "$linuxDir"
            # extra post-patching for NVidia
            ${shellHook}

            export PS1="[ghaf-kernel-${platform}-devshell:\w]$ "
          '';
          # use "eval $checkPhase" - see https://discourse.nixos.org/t/nix-develop-and-checkphase/25707
          checkPhase = "cp ../modules/hardware/${platform}/kernel/configs/ghaf_host_hardened_baseline-${arch} ./.config && make -j$(nproc)";
        };
    in
    {
      #TODO: use devshell not devShells
      # also is this needed with nix develop doing all of these tasks
      devShells.kernel-x86 = mkKernelShell {
        platform = "x86_64-generic";
        arch = "x86";
        inherit (pkgs) linux;
      };
      devShells.kernel-jetson-orin = mkKernelShell {
        platform = "jetson-orin";
        linux = inputs.jetpack-nixos.legacyPackages.${system}.kernel;
        extraPackages = [ pkgs.gawk ];
        shellHook = ''
          patchShebangs scripts/
        '';
      };
    };
}
