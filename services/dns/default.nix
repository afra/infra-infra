{ ... }:

{
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  services.bind = {
    enable = true;
    zones = [
      {
        name = "afra-berlin.eu.";
        master = true;
        file = ./afra-berlin.eu.zone;
      }
    ];
  };

  networking.resolvconf.useLocalResolver = false;
}
