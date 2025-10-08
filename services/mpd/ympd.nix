{ config, pkgs, ... }:

{
  services.ympd = {
    enable = true;
    webPort = 8062;
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "core.afra-berlin.eu".locations."/ympd/".return = "307 https://ympd.afra-berlin.eu";
      "ympd.afra-berlin.eu" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.ympd.webPort}/";
          proxyWebsockets = true;
          # extraConfig = ''
          #   allow 172.23.42.0/24;
          #   allow fd00::/8;
          #   deny all;
          # '';
        };
      };
    };
  };
}
