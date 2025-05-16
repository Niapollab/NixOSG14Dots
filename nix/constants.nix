{ config, lib, ... }:

with lib;

{
  options.constants = {
    hostName = mkOption {
      default = "nixos";
      description = ''
        The hostname of the machine. This value is used in the NixOS configuration
        for the hostname of the machine.
      '';
    };
    mainUser = {
      nickname = mkOption {
        default = "user";
        description = ''
          The nickname of the main user. This value is used in various configurations
          where a shorter or informal name is preferable.
        '';
      };
      fullname = mkOption {
        default = "User";
        description = ''
          The full name of the main user. This value is used in configurations
          where a formal or complete name is required.
        '';
      };
    };
  };
}
