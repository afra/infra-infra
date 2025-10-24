{ pkgs, lib, modulesPath, ... }:

{
  users.users.yuka = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbzUmOJuuAYn/3ODyw3WKjz7SnKjMq4iHE+mEpwVVmw cardno:27_343_732"
    ];
  };
}
