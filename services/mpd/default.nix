{ pkgs, config, ... }:

{
  imports = [
    #./mympd.nix
    ./ympd.nix
  ];

  services.mpd = {
    enable = true;
    network.listenAddress = "any";
    settings = {
      audio_output = [{
        type = "pulse";
        name = "pulse audio";
        server = "loud.space.afra-berlin.de";
      }];
    };
    openFirewall = false;
  };

  networking.firewall.interfaces.eno1.allowedTCPPorts = [ config.services.mpd.settings.port ];
}
