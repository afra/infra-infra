{ config, pkgs, ... }:

let
  presence-monitor = pkgs.callPackage (
    { rustPlatform, sqlite }:

    rustPlatform.buildRustPackage rec {
      pname = "presence-monitor";
      version = "0.1.0";
      src = builtins.fetchGit {
        url = "https://git.yuka.dev/yuka/presence-monitor/";
        ref = "main";
        rev = "db577ed36f70ca5e16ab7c542fef831842d5779d";
      };
      cargoLock = {
        lockFile = src + "/Cargo.lock";
        outputHashes = {
          "pnet-0.28.0" = "142ic90ysw7gdz2qr8sbf8c9b635ralgvk2h88a7rdpqpiv64s61";
        };
      };
      buildInputs = [ sqlite ];
    }
  ) {};

  configFile = pkgs.writeText "Rocket.toml" ''
    [global]
    address = "127.0.0.1"

    [global.probe]
    iface = "enp3s0"
    source_v6_addr = "fe80::3285:a9ff:fe40:b2c9"
    source_v4_addr = "172.23.42.229"

    [global.databases]
    sqlite_presence_monitor = { url = "/var/lib/presence-monitor/db.sqlite" }
  '';
in {
  secrets.presence-monitor-env = {};

  systemd.services.presence-monitor = {
    wantedBy = [ "multi-user.target" ];
    environment.ROCKET_CONFIG = configFile;
    serviceConfig = {
      EnvironmentFile = config.secrets.presence-monitor-env.path;
      ExecStart = "${presence-monitor}/bin/presence-monitor";
      DynamicUser = true;
      StateDirectory = "presence-monitor";
      AmbientCapabilities = [ "CAP_NET_RAW" ];
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts.default = {
      locations."/presence/api/" = {
        proxyPass = "http://localhost:8000/";
      };
    };
  };
}