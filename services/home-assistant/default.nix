{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "met"
      "wled"
      "mqtt"
      "tasmota"
      # "history"
      # "zha"
    ];
    extraPackages = python3Packages: with python3Packages; [
      psycopg2
      pysnmp
    ];
    config = {
      default_config = {};
      # recorder.db_url = "postgresql://@/hass";
      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "172.23.42.229";
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    }];
  };

  services.nginx = {
    enable = true;
    virtualHosts."hass.afra-berlin.eu" = {
      enableACME = true;
      forceSSL = true;
      acmeRoot = "/var/lib/acme/acme-challenges";
      extraConfig = ''
        proxy_buffering off;
      '';
      locations = {
        "/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;
        };
      };
    };
  };
}
