{ spaceapi-logo-proxy, pkgs, ... }:
{
  systemd.services.spaceapi-logo-proxy = {
    wantedBy = [ "multi-user.target" ];
    environment = {
      SPACEAPI_URL="https://hass.afra-berlin.eu/api/spaceapi";
      BIND_ADDR="[::1]:3383";
    };
    serviceConfig = {
      ExecStart = "${spaceapi-logo-proxy.packages.${pkgs.system}.default}/bin/spaceapi-logo-proxy";
      DynamicUser = true;
    };
  };

  afraPublicExposedVirtualHosts = [
    "spaceapi.afra-berlin.eu"
  ];

  services.nginx = {
    enable = true;
    virtualHosts."spaceapi.afra-berlin.eu" = {
      enableACME = true;
      forceSSL = true;
      acmeRoot = "/var/lib/acme/acme-challenges";
      extraConfig = ''
        proxy_buffering off;
      '';
      locations = {
        "/" = {
          proxyPass = "http://[::1]:3383";
        };
        "/v1/status.json" = {
          return = "301 /";
        };
      };
    };
  };
}
