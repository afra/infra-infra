#!/usr/bin/env bash

set -eo pipefail
cd "$(dirname "$0")"

if ! command -v nix-build &> /dev/null
then
	echo "Nix installation could not be found. Please follow the instructions linked below."
	echo "https://nixos.org/manual/nix/unstable/installation/installing-binary.html"
	echo ""
	echo "Alternatively, you can ssh to one of the NixOS hosts and run the deployment there."
	echo "For this, make sure you have SSH agent forwarding enabled."
	exit
fi

mode="${1:-switch}"
host="${2:-core}"
target="${3:-$host.space.afra-berlin.de}"

if ! [ -d "hosts/$host" ]
then
	echo "Host $host does not exist. Choose from:"
	ls hosts
	exit
fi

echo "deploying $host to $target"
sleep 1

set -x
system_drv=$(
  nix-instantiate -A hosts.$host.config.system.build.toplevel \
    -I "$(nix-build nix/sources-dir.nix --no-out-link)" \
)

if [ -n "$BUILD_LOCAL" ]
then
	system=$(nix-store --realise $system_drv)
	nix-copy-closure --to $target $system
else
	nix-copy-closure --to $target $system_drv
	system=$(ssh $NIX_SSHOPTS $target "nix-store --realise $system_drv")
fi

ssh $NIX_SSHOPTS $target "sudo nix-env -p /nix/var/nix/profiles/system -i $system && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration $mode"
