{ pkgs, lib, modulesPath, ... }:

{
  users.users.lilian = {
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS8lvGzaF4s+AayVaSg4pgRwEAWq1fR+eu6rOm1Qw5P cardno:19_302_044"
    ];
  };
  programs.fish.enable = true;
}
