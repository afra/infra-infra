{ config, pkgs, lib, ... }:

let
  # https://github.com/NixOS/nixpkgs/pull/144674
  snapcast = pkgs.snapcast.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ pkgs.libpulseaudio ];
  });

in {
  imports = [
    ./hardware-configuration.nix
    ../../common
    #../../services/pulseaudio
    #../../services/snapcast-server
    #../../services/snapcast-client
    #../../services/mpd
    #../../services/nfs-server
    ../../services/bgp-tunnel
    #../../services/unifi
    ../../services/presence-monitor
    ../../services/dns
    #../../services/minetest
    #../../services/mosquitto
    #../../services/grafana
    #../../services/influxdb2
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/disk/by-id/usb-Intenso_Rainbow_Line_15033100005508-0:0";

  networking.interfaces.enp3s0.useDHCP = true;

  #fileSystems."/mnt" =
  #  { device = "tank";
  #    fsType = "zfs";
  #    options = ["nofail"];
  #  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;

  zramSwap.enable = true;

  #boot.supportedFilesystems = [ "zfs" ];
  #networking.hostId = "bdd1349f";

  #services.samba = {
  #  package = pkgs.sambaFull;
  #  enable = true;
  #  securityType = "user";
  #  extraConfig = ''
  #    hosts allow = 172.23.42.0 localhost
  #    hosts deny = 0.0.0.0/0
  #  '';
  #  shares = {
  #    storage = {
  #      path = "/data";
  #      browseable = "yes";
  #      "read only" = "no";
  #      "guest ok" = "yes";
  #      "create mask" = "0644";
  #      "directory mask" = "0755";
  #    };
  #  };
  #};

  security.acme = {
    defaults.email = "afra@yuka.dev";
    acceptTerms = true;
  };

  services.nginx = {
  #  enable = true;
  #  virtualHosts."core.afra-berlin.eu" = {
  #    locations."/".root = ./html;
  #    enableACME = true;
  #    forceSSL = true;
  #  };
  #  virtualHosts."afra-berlin.eu" = {
  #    enableACME = true;
  #    forceSSL = true;
  #  };
    virtualHosts."core.space.afra-berlin.de" = {
      locations."/".return = "307 https://core.afra-berlin.eu$request_uri";
    };
  #  virtualHosts."afra-core.yuka.dev" = {
  #    enableACME = true;
  #    forceSSL = true;
  #    locations."/".return = "307 https://core.afra-berlin.eu$request_uri";
  #  };
  };

  networking.firewall.allowedTCPPorts = [ 443 ];

  #hardware.pulseaudio.extraConfig = ''
  #  set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo+input:analog-stereo
  #  set-sink-port alsa_output.pci-0000_00_1b.0.analog-stereo analog-output-lineout
  #  set-source-port alsa_input.pci-0000_00_1b.0.analog-stereo analog-input-linein
  #  load-module module-loopback source=alsa_input.pci-0000_00_1b.0.analog-stereo sink=Snapcast
  #  set-default-sink Snapcast
  #'';

  #systemd.services.snapclient.serviceConfig.ExecStart = lib.mkForce "${snapcast}/bin/snapclient -h core.lan --player pulse -s alsa_output.pci-0000_00_1b.0.analog-stereo";

  system.stateVersion = "23.11";
}

# wireguard pubkey: ImxmLMTnlFiEehfA0j/WMfYhKle8XpOKrIPDAd+y3SA=
