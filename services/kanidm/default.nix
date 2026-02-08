{ lib, sources, pkgs, config, ... }:

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

  secrets.kanidm-selfservice-env = {};
  systemd.services.kanidm-selfservice = let
    kanidm-selfservice = pkgs.callPackage (
      { rustPlatform }:

      rustPlatform.buildRustPackage {
        pname = "kanidm-selfservice";
        version = "0.1.0";

        src = sources.kanidm-selfservice;

        cargoLock.lockFile = sources.kanidm-selfservice + "/Cargo.lock";

        meta.mainProgram = "kanidm-selfservice";
      }
    ) {};

    settings = {
      base_url = "https://id.afra-berlin.eu";
      signup_text = "Welcome to AfRA! Make sure to add a credential in the next step and successfully save your new settings. Otherwise your account can still be taken by someone else!";
      bind_addr = "[::1]:8502";
      add_mail_domain = "id.afra-berlin.eu";
    };

    settingsFormat = pkgs.formats.toml { };
    configFile = settingsFormat.generate "config.toml" settings;
  in {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = config.secrets.kanidm-selfservice-env.path;
      ExecStart = "${lib.getExe kanidm-selfservice} ${configFile}";
      DynamicUser = true;
    };
  };

  services.nginx = {
    virtualHosts."id.afra-berlin.eu" = {
      forceSSL = true;
      enableACME = true;
      locations."/selfservice/" = {
        proxyPass = "http://[::1]:8502";
      };
      locations."/" = {
        proxyPass = "https://${config.services.kanidm.serverSettings.bindaddress}";
        extraConfig = ''
          proxy_ssl_verify off;
        '';
      };
    };
  };
}
