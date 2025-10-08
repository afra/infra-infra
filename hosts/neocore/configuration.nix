{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common
    ../../services/bgp-tunnel
    ../../services/presence-monitor
    ../../services/dns
    ../../services/mpd
    ../../services/home-assistant
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    mirroredBoots = [
      {
        devices = [ "/dev/disk/by-id/wwn-0x5002538d4207830a" ]; # sda
        path = "/boot-fallback";
      }
      {
        devices = [ "/dev/disk/by-id/wwn-0x500253884009606d" ]; # sdb
        path = "/boot-fallback";
      }
    ];
  };

  # ZFS stuff
  boot.supportedFilesystems = [ "zfs" ];
  # don't use latest kernel for better zfs support
  boot.kernelPackages = pkgs.linuxPackages;
 
  networking.hostName = "neocore"; # Define your hostname.
  networking.hostId = "5d6f942d";

  networking.interfaces.eno1.useDHCP = true;

  # remote disk unlock
  boot.kernelModules = ["tg3"];
  boot.initrd.kernelModules = ["tg3"];
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/etc/ssh/initrd_ssh_host_rsa_key" ];
      authorizedKeys = lib.flatten (lib.mapAttrsToList (_: v: v.openssh.authorizedKeys.keys) config.users.users);
    };
    postCommands = ''
      zpool import -a
      echo "zfs load-key -a; killall zfs; exit" >> /root/.profile
    '';
  };

  security.acme = {
    defaults.email = "afra@yuka.dev";
    acceptTerms = true;
  };

  system.stateVersion = "25.05";
}

# wireguard pubkey: ImxmLMTnlFiEehfA0j/WMfYhKle8XpOKrIPDAd+y3SA=
