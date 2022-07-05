{ pkgs, ... }:

{
  users.users.zotan = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWDArL4+m9kUmLyWcmUby5+CVrmBThP0KbQWep32+BF laura@zotan.network"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}
