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
      "spaceapi"
      "ping"
      "shelly"
    ];
    extraPackages = python3Packages: with python3Packages; [
      psycopg2
      pysnmp
      gtts
    ];
    config = {
      default_config = {};
      automation = "!include automations.yaml";
      scene = "!include scenes.yaml";
      script = "!include scripts.yaml";
      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };
      homeassistant = {
        auth_providers = [
          {
            type = "trusted_networks";
            trusted_networks = [
              "0.0.0.0/0"
              "::/0"
            ];
            allow_bypass_login = true;

          }
          {
            type = "homeassistant";
          }
        ];
      };
      spaceapi = {
        space = "AfRA Berlin";
        logo = "https://afra-berlin.de/dokuwiki/lib/exe/fetch.php?t=1426288945&w=128&h=128&tok=561205&media=afra-logo.png";
        url = "https://afra-berlin.de";
        location = {
          address = "Margaretenstr. 30, 10317 Berlin, Germany";
          #lon = 13.4961541;
          #lat = 52.5082224;
        };
        contact = {
          email = "info@afra-berlin.de";
          ml = "afra@afra-berlin.de";
          issue_mail = "info@afra-berlin.de";
        };
        issue_report_channels = ["issue_mail"];
        state.entity_id = "binary_sensor.172_23_42_230";
      };
    };
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://172.23.42.222:1883";
      };
      #permit_join = true;
      serial = {
        port = "/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2286745-if00";
        adapter = "deconz";
      };
      frontend = {
        port = 24035;
        host = "::1";
      };
      advanced = {
        channel = 20;
      };
      homeassistant.enabled = true;
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "172.23.42.222";
      acl = [ "pattern readwrite #" ];
      omitPasswordAuth = true;
      settings.allow_anonymous = true;
    }];
  };
  networking.firewall.interfaces.eno1.allowedTCPPorts = [ 1883 ];

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
        "=/service-worker.js".extraConfig = ''
          return 404;
        '';
      };
    };
  };
}
