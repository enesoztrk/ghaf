# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:
# account for the development time login with sudo rights
let
  cfg = config.ghaf.users.services;
  inherit (lib)
    mkEnableOption
    mkOption
    optionals
    mkIf
    types
    ;
      isNetVM = "net-vm" == config.system.name;
  isBusinessVM = "business-vm" == config.system.name;
  isNetGroupCreated= (isNetVM);
  isNetUserCreated= (isNetVM);
  netUserName = "net-admin";
in
{
  #TODO Extend this to allow definition of multiple users
  options.ghaf.users.services = {
    
     enable = mkOption {
      description = "Default service users Setup";
      type = types.bool;
      default = true;
    };
    netUser = mkOption {
      default = "${netUserName}";
      type = with types; str;
      description = ''
        A default user for network operations.
      '';
    };

  };

  config = mkIf cfg.enable {
    users = {
  # Conditional group creation
    groups={
        ${netUserName}={};
    };
    

    # Conditional user creation
    users ={

    ${netUserName} = {
      #isSystemUser = true;
      isNormalUser =true;
      password="test";
      description = "System user for managing network operations";
      group = "${netUserName}"; # Assign to the dynamically created group
    };
    };
    
    };


  };
}
