{ pkgs, config, ... }:

{
  imports = [
    #./mympd.nix
    ./ympd.nix
  ];

  services.mpd = {
    enable = true;
    network.listenAddress = "any";
    extraConfig = ''
      audio_output {
        type "pulse"
        name "pulse audio"
        server "loud.space.afra-berlin.de"
      }
    '';
  };

  networking.firewall.interfaces.eno1.allowedTCPPorts = [ config.services.mpd.network.port ];
}
