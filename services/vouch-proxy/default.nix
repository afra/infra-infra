{
  config,
  lib,
  pkgs,
  sources,
  ...
}:

{
  secrets.vouch-proxy-env = { };
  systemd.services.vouch-proxy =
    let
      settings = {
        vouch = {
          listen = "[::1]";
          port = 30746;

          # TODO this allows everybody that can authenticate to kanidm, so no
          # further scoping possible atm.
          allowAllUsers = true;
          cookie.domain = "afra-berlin.eu";
        };
        oauth =
          let
            kanidmOrigin = config.services.kanidm.serverSettings.origin;
          in
          rec {
            provider = "oidc";
            client_id = "vouch";
            auth_url = "${kanidmOrigin}/ui/oauth2";
            token_url = "${kanidmOrigin}/oauth2/token";
            user_info_url = "${kanidmOrigin}/oauth2/openid/${client_id}/userinfo";
            scopes = [ "email" ];
            callback_url = "https://vouch.afra-berlin.eu/auth";
            code_challenge_method = "S256";
          };
      };
      configFile = (pkgs.formats.yaml { }).generate "config.yml" settings;
    in
    {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = config.secrets.vouch-proxy-env.path;
        ExecStart = "${lib.getExe pkgs.vouch-proxy} -config ${configFile}";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        WorkingDirectory = "/var/lib/vouch-proxy";
        StateDirectory = "vouch-proxy";
        RuntimeDirectory = "vouch-proxy";
        StartLimitBurst = 3;
      };
    };

  services.nginx.virtualHosts."vouch.afra-berlin.eu" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://[::1]:30746";
    };
  };
}
