let
  sources = import ./nix/sources.nix;

  pkgs = import sources.nixpkgs {
    system = if builtins ? currentSystem then builtins.currentSystem else "x86_64-linux";
  };
in {
  inherit pkgs;
}
  // (import ./lib/hosts.nix { inherit sources pkgs; })
