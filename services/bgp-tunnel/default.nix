{ pkgs, config, lib, ... }:

let
  ip = "2a0f:4ac0:af5a::1";
  ip4 = "195.39.247.225";
in {
  secrets.wireguard.owner = "systemd-network";

  environment.systemPackages = with pkgs; [ wireguard-tools ];

  networking.useNetworkd = true;

  networking.firewall.allowedUDPPorts = [ 51820 ];

  systemd.network = {
    netdevs."40-wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
        MTUBytes = "1500";
      };
      wireguardConfig = {
        PrivateKeyFile = config.secrets.wireguard.path;
        FirewallMark = 51820;
        ListenPort = 51820;
      };
      wireguardPeers = [
        {
          AllowedIPs = [ "0.0.0.0/0" "::/0" ];
          PublicKey = "kih/GnR4Bov/DM/7Rd21wK+PFQRUNH6sywVuNKkUAkk=";
          PersistentKeepalive = 21;
          Endpoint = "[2a0f:4ac0:ca6c::1]:51820";
        }
      ];
    };
    networks."40-wg0" = {
      name = "wg0";
      addresses = [
        { Address = "${ip}/128"; }
        { Address = "${ip4}/32"; }
      ];
      routes = [
        { Gateway = "::"; Table = 51820; }
        { Gateway = "0.0.0.0"; Table = 51820; }
      ];
      routingPolicyRules = [
        {
          # local routes
          Family = "both";
          SuppressPrefixLength = 0;
          Priority = 1000;
        }
        {
          # send wireguard to main table
          Family = "both";
          FirewallMark = 51820;
          Priority = 3000;
        }
        {
          # disallow any other routes for wireguard
          Family = "both";
          FirewallMark = 51820;
          Type = "unreachable";
          Priority = 3001;
        }
        {
          # take the default route in wireguard
          Family = "both";
          Table = 51820;
          Priority = 4000;
        }
      ];
    };
  };
}
