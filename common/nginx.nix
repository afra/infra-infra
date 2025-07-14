{ config, lib, ... }:

{
  services.nginx = {
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };
  networking.firewall.allowedTCPPorts = lib.optionals config.services.nginx.enable [ 80 443 ];
}
