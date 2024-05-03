# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  # inherit (builtins) A B C;
  # inherit (lib) D E F;
  # inherit (lib.ghaf) G H I;
  cfg = config.ghaf.common.networking.dendrite-pinecone;
  
 # dendrite-pineconePkg = import ../../../packages/dendrite-pinecone/default.nix {inherit pkgs;};
in
  with lib; {
    imports = [
    ];

    options.ghaf.common.networking.dendrite-pinecone = {
      enable = mkEnableOption "Enable dendrite pinecone module";
      
      externalNic = mkOption {
       type = types.str;
          default = "";
          description = ''
              External network interface 
            '';
      
      };
      internalNic = mkOption {
       type = types.str;
          default = "";
          description = ''
              Internal network interface 
            '';
      
      };

      serverIpAddr = mkOption {
       type = types.str;
          default = "";
          description = ''
            Dendrite Server Ip address
          '';
      
      };
    };

    config = mkIf cfg.enable {

  assertions = [
        {
          assertion = cfg.externalNic != "";
          message = "External Nic is must be set";
        }
        { assertion = cfg.internalNic != "";
          message = "Internal Nic is must be set";
        }
      ];


    ghaf.virtualization.microvm.netvm.extraModules = [
      {
  
      }
    ];    
    };
  }
