{ inputs, pkgs, config, ... }:

{
  services.kanidm.enableServer = true;
  services.kanidm.serverSettings = let
    cert = config.security.acme.certs."id.afra-berlin.eu".directory;
  in {
    bindaddress = "[::1]:29443";
    domain = "id.afra-berlin.eu";
    origin = "https://id.afra-berlin.eu";
    tls_chain = cert + "/fullchain.pem";
    tls_key = cert + "/key.pem";
    trust_x_forward_for = true;
  };

  services.kanidm.enableClient = true;
  services.kanidm.clientSettings.uri = config.services.kanidm.serverSettings.origin;

  services.kanidm.package = pkgs.kanidm_1_8;

  systemd.services.kanidm.serviceConfig = {
    SupplementaryGroups = ["nginx"];
  };

  services.nginx = {
    virtualHosts."id.afra-berlin.eu" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "https://${config.services.kanidm.serverSettings.bindaddress}";
        extraConfig = ''
          proxy_ssl_verify off;
        '';
      };
    };
  };
}
