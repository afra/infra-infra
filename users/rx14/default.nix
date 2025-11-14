{ pkgs, lib, modulesPath, ... }:

{
  users.users.rx14 = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINzIvxKqVbz9tQ4M06+7gZvY1gZHgQan+L/x0YHb+5mUAAAABHNzaDo="
    ];
  };
}
