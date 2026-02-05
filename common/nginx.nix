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

  # Step 1: for each virtualHost ${name}, set up a new virtualHost public-${name}
  services.nginx.virtualHosts =
    let
      # Work around recursion in the NixOS module system by first evaluating all modules excluding this one
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
        # Listen on port 4443
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
        # Re-use the ACME certificate from the original vhost
        useACMEHost = name;
        onlySSL = true;
        serverName = name;
        locations = lib.mkMerge (
          # Copy the location definitions from the existing vhost...
          allOtherModules.options.services.nginx.virtualHosts.valueMeta.attrs.${name}.configuration.options.locations.definitions
          # ... And merge them with our new config
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

  # Step 2: Detect all external traffic and send it into nginx on :4443 instead of :443
  # The public- vhosts are listening on port 4443 and can take extra actions for external users
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
