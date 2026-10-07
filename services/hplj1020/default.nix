{ pkgs, ... }:

{
  services.udev.extraRules = let
    foo2zjs-repo = pkgs.fetchFromGitHub {
      owner = "koenkooi";
      repo = "foo2zjs";
      rev = "e04290de6b7a30d588f3411fd9834618e09f7b9b";
      hash = "sha256-CXoPZ/oR7KeYx0p05Jl4lhmPmWN+tm/+xUDgyrTx1VE=";
    };
    firmware = pkgs.runCommand "hplj1020-fw" {
      nativeBuildInputs = [ pkgs.foo2zjs ];
    } ''
      mkdir $out
      arm2hpdl ${foo2zjs-repo}/sihp1020.img > $out/sihp1020.dl
    '';

    loadFirmwareScript = pkgs.writeShellScript "load-hp1020-firmware" ''
      sleep 2
      ${pkgs.cups}/bin/lp -d HP_LaserJet_1020 -o raw "${firmware}/$out/sihp1020.dl"
    '';
  in ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="03f0", ATTR{idProduct}=="2b17", RUN+="${loadFirmwareScript}"
  '';

  services.avahi = {
    enable = true;
    nssmdns4 = true;        # for IPv4 (use nssmdns6 for IPv6)
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [ foo2zjs ];
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };
}
