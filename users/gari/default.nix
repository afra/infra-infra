{ pkgs, ... }:

{
  users.users.gari = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUAdTFPHjJlkODiOpgCi9M/m///1SGjdwAb8qKXX+mB darwin"
    ];
  };
}
