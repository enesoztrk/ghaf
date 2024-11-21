# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf mkForce;
  cfg = config.ghaf.reference.services;
  isNetVM = "net-vm" == config.system.name;
  isBusinessVM = "business-vm" == config.system.name;
  isNetGroupCreated= (isNetVM);
  isNetUserCreated= (isNetVM);
  netUserName = "net-admin";
  netSysGroupName = "net";

in
{
  imports = [
    ./dendrite-pinecone/dendrite-pinecone.nix
    ./dendrite-pinecone/dendrite-config.nix
    ./proxy-server/3proxy-config.nix
    ./smcroute/smcroute.nix
    ./ollama/ollama.nix
  ];
  options.ghaf.reference.services = {
    enable = mkEnableOption "Ghaf reference services";
    dendrite = mkEnableOption "dendrite-pinecone service";
    proxy-business = mkEnableOption "Enable the proxy server service";
    ollama = mkEnableOption "ollama service";
  };
  config = mkIf cfg.enable {

    # Conditional group creation
    users.groups.${netSysGroupName} = mkIf isNetGroupCreated {
    };

    # Conditional user creation
    users.users.${netUserName} = mkIf isNetVM {
      isSystemUser = true;
      description = "System user for managing network operations";
      group = "${netSysGroupName}"; # Assign to the dynamically created group
    };
    
    services.smcroute = mkIf (isNetVM){
        user = mkForce "${netUserName}";
    };
    ghaf.reference.services = {
      dendrite-pinecone.enable = mkForce (cfg.dendrite && isNetVM);
      proxy-server.enable = mkForce (cfg.proxy-business && isNetVM);

    };
  };
}
