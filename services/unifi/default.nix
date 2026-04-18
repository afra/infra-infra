{ pkgs, lib, ... }:

{
  services.unifi.enable = true;
  services.unifi.unifiPackage = pkgs.unifi;
  services.unifi.mongodbPackage = pkgs.mongodb-ce;
  nixpkgs.config.allowUnfree = true;
  systemd.services.unifi.wantedBy = lib.mkForce [];

  networking.firewall.interfaces.eno1.allowedTCPPorts = [ 8080 ];
  networking.firewall.interfaces.eno1.allowedUDPPorts = [ 3478 10001 ];

}
