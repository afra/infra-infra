{ pkgs, ... }:

{
  users.users.fiona = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmS7XHbnZLmm0S6PP9u8UKHaKD2iRpijpb4HTz4yIJe fiona@afra"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
}
