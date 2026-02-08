{
  pkgs,
  config,
  lib,
  extendModules,
  ...
}:

let
  # Work around recursion in the NixOS module system by first evaluating all modules excluding this one
  allOtherModules = extendModules {
    modules = [
      {
        disabledModules = [
          ./.
        ];
      }
    ];
  };
  privateVhosts = allOtherModules.config.services.nginx.virtualHosts;
  privateSslVhosts = lib.filterAttrs (
    _: host: host.onlySSL || host.addSSL || host.forceSSL
  ) privateVhosts;

in
{
  networking.firewall.allowedTCPPorts = [
    4443
  ];
  # Step 1: for each virtualHost ${name}, set up a new virtualHost public-${name}
  services.nginx.virtualHosts = lib.mapAttrs' (
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
        ++ lib.optional (name == "id.afra-berlin.eu") {
          #"/selfservice/".extraConfig = ''
          #  auth_request /validate;
          #'';
        }
        ++ [
          {
            "/validate" = {
              proxyPass = "http://[::1]:30746";
              extraConfig = ''
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
                # these return values are used by the @error401 call
                auth_request_set $auth_resp_jwt $upstream_http_x_vouch_jwt;
                auth_request_set $auth_resp_err $upstream_http_x_vouch_err;
                auth_request_set $auth_resp_failcount $upstream_http_x_vouch_failcount;
              '';
            };

            "@error401".extraConfig = ''
              return 302 https://vouch.afra-berlin.eu/login?url=$scheme://$http_host$request_uri&vouch-failcount=$auth_resp_failcount&X-Vouch-Token=$auth_resp_jwt&error=$auth_resp_err;
            '';
          }
        ]
      );
      extraConfig = lib.mkMerge (
        allOtherModules.options.services.nginx.virtualHosts.valueMeta.attrs.${name}.configuration.options.extraConfig.definitions
        ++ lib.optional (name != "id.afra-berlin.eu" && name != "vouch.afra-berlin.eu") ''
          error_page 401 = @error401;
          auth_request /validate;
        ''
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
