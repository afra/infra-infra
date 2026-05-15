{
  description = "AfRA Infra";
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }@inputs: {
    nixosConfigurations = {
      neocore = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/neocore/hardware-configuration.nix
          ./hosts/neocore/configuration.nix
        ];
      };
    };
  } // flake-utils.lib.eachDefaultSystem (system: let
    lib = nixpkgs.lib;
    pkgs = import nixpkgs { inherit system; };
  in {
    apps.deploy = lib.pipe self.nixosConfigurations [
      (lib.mapAttrs (name: _value: (flake-utils.lib.mkApp {
        drv = pkgs.writeShellScriptBin "deploy-${name}" ''
          ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot \
            --flake ${./.}#${name} \
            --target-host ${name}.space.afra-berlin.de \
            --use-remote-sudo \
            --log-format internal-json \
            -v \
            |& ${pkgs.nix-output-monitor}/bin/nom --json
        '';
      })))
    ];
  });
}