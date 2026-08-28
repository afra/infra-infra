{
  description = "AfRA Infra";
  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.spaceapi-logo-proxy = {
    url = "git+https://codeberg.org/afra/spaceapi-logo-proxy.git";
    inputs.nixpkgs.follows = "nixpkgs";
  };

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
          ${pkgs.nixos-rebuild}/bin/nixos-rebuild "''${1:-switch}" \
            --flake ${./.}#${name} \
            --target-host ${name}.afra-berlin.eu \
            --build-host ${name}.afra-berlin.eu \
            --use-remote-sudo \
            --log-format internal-json \
            -v \
            |& ${pkgs.nix-output-monitor}/bin/nom --json
        '';
      })))
    ];
  });
}