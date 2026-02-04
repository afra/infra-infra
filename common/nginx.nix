{
  config,
  lib,
  extendModules,
  ...
}:

{
  services.nginx = {
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };
  networking.firewall.allowedTCPPorts = lib.optionals config.services.nginx.enable [
    80
    443
    4443
  ];

  services.nginx.virtualHosts =
    let
      allOtherModules = extendModules {
        modules = [
          {
            disabledModules = [ ./nginx.nix ];
          }
        ];
      };
      privateVhosts = allOtherModules.config.services.nginx.virtualHosts;
      privateSslVhosts = lib.filterAttrs (
        _: host: host.onlySSL || host.addSSL || host.forceSSL
      ) privateVhosts;
    in
    lib.mapAttrs' (
      name: host:
      lib.nameValuePair "public-${name}" {
        listen = [
          {
            addr = "[::]";
            port = 4443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 4443;
            ssl = true;
          }
        ];
        useACMEHost = name;
        onlySSL = true;
        serverName = name;
        locations = lib.mkMerge (
          allOtherModules.options.services.nginx.virtualHosts.valueMeta.attrs.${name}.configuration.options.locations.definitions
          ++ [
            {
              "/hello".extraConfig = ''
                add_header Content-Type text/plain;
                return 200 'welcome to afra';
              '';
            }
          ]
        );
      }
    ) privateSslVhosts;

  networking.nftables.tables."nginx-public" = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority 0; policy accept;
        iifname "wg0" fib daddr . iif type local tcp dport 443 redirect to :4443
      }
    '';
  };
}
