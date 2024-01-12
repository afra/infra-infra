{ lib, pkgs, ... }:

{
  imports = [
    ../modules
    ../users
    ./nginx.nix
  ];

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernelParams = [ "quiet" ];

  nix.gc.automatic = lib.mkDefault true;
  nix.gc.options = lib.mkDefault "--delete-older-than 1d";
  nix.settings.trusted-users = [ "root" "@wheel" ];
  environment.variables.EDITOR = "vim"; # fight me :-)

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = lib.mkDefault "no";
    StreamLocalBindUnlink = lib.mkDefault "yes";
  };
  security.sudo.wheelNeedsPassword = false;

  nftables.enable = true;
  nftables.forwardPolicy = lib.mkDefault "drop";

  networking.domain = lib.mkDefault "lan";
  networking.useDHCP = lib.mkDefault false;

  programs.mtr.enable = true;

  environment.systemPackages = with pkgs; [
    alacritty.terminfo
    kitty.terminfo
    rxvt_unicode.terminfo
    termite.terminfo
    bat
    bottom
    eza
    fd
    git
    htop
    nload
    ripgrep
    rsync
    tcpdump
    tmux
    vim
    wget
    jq
    iperf
    pv
    lsof
  ];

  programs.bash.shellAliases = {
    ".." = "cd ..";
    use = "nix-shell -p";
    cat = "bat --style=header";
    grep = "rg";
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    tree = "eza -T";
  };
}
