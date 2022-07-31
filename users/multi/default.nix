{ pkgs, ... }:

{
  users.users.multi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWtfUhmD0hgr2u4EOfFUWsrtfxl9IZ9LGjqLjL/QzeN multi@flywheel"
    ];
    shell = pkgs.bash;
  };
}
