{ config, pkgs, ... }:

let
  presence-monitor = pkgs.callPackage (
    { rustPlatform, sqlite }:

    rustPlatform.buildRustPackage rec {
      pname = "presence-monitor";
      version = "0.1.0";
      src = builtins.fetchGit {
        url = "https://cyberchaos.dev/yuka/presence-monitor/";
        ref = "main";
        rev = "a92642962fbd331ccac572e88a00f003ac219470";
      };
      cargoLock.lockFile = src + "/Cargo.lock";
      buildInputs = [ sqlite ];
    }
  ) {};

  configFile = pkgs.writeText "config.yaml" (builtins.toJSON {
    bind = "127.0.0.1:8000";
    database_url = "/var/lib/presence-monitor/db.sqlite";
    open_status_mac = "E8:94:F6:4F:CB:CC";

    probe = {
      iface = "enp3s0";
      source_v6_addr = "fe80::3285:a9ff:fe40:b2c9";
      source_v4_addr = "172.23.42.229";
    };
  });

  presence-web = pkgs.callPackage (
    { stdenv, nodejs, npmHooks, fetchNpmDeps }:

    stdenv.mkDerivation rec {
      pname = "presence-web";
      version = "0.0.0";

      src = builtins.fetchGit {
        url = "https://gitlab.com/luxferresum/presence-web/";
        rev = "b52ba8694bb1ad11269048734e2c06ed3a513400";
      };

      nativeBuildInputs = [ nodejs npmHooks.npmConfigHook ];

      npmDeps = fetchNpmDeps {
        inherit src;
        hash = "sha256-M7R83S54sRXcx+4QTQz4fXfBg6muSOkiUOoy8DUn288=";
      };

      buildPhase = ''
        runHook preBuild
        export HOME=$(mktemp -d)
        export NODE_OPTIONS="--openssl-legacy-provider"
        ln -s $node_modules/node_modules node_modules
        node_modules/.bin/ember build --environment production
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        cp -r dist $out
        runHook postInstall
      '';
    }
  ) {};

in {
  secrets.presence-monitor-env = {};

  systemd.services.presence-monitor = {
    wantedBy = [ "multi-user.target" ];
    environment.CONFIG = configFile;
    environment.RUST_LOG = "trace";
    serviceConfig = {
      EnvironmentFile = config.secrets.presence-monitor-env.path;
      ExecStartPre = "${pkgs.diesel-cli}/bin/diesel migration run --migration-dir ${presence-monitor.src}/migrations --database-url /var/lib/presence-monitor/db.sqlite";
      ExecStart = "${presence-monitor}/bin/presence-monitor";
      DynamicUser = true;
      StateDirectory = "presence-monitor";
      AmbientCapabilities = [ "CAP_NET_RAW" ];
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "core.afra-berlin.eu".locations."/presence/".return = "307 https://presence.afra-berlin.eu";
      "presence.afra-berlin.eu" = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/api/" = {
            proxyPass = "http://localhost:8000";
          };
          "/" = {
            alias = "${presence-web}/";
            tryFiles = "$uri $uri/ /index.html";
          };
        };
      };
    };
  };
}
