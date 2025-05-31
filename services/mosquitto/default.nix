{ config, pkgs, ... }:

{
  services.mosquitto = {
    enable = true;
    listeners = [ {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
    } ];
  };

  # TODO: is this needed at all?
  networking.firewall.interfaces.enp3s0.allowedTCPPorts = [ 1883 ];
  networking.firewall.interfaces.enp3s0.allowedUDPPorts = [ 1883 ];
}
