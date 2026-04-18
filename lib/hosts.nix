{ sources, pkgs }:

with pkgs.lib;

rec {
  hostsDir = ../hosts;

  hostNames = attrNames (
    filterAttrs (
      name: type: type == "directory"
    ) (
      builtins.readDir hostsDir
    )
  );

  hostConfig = hostName: { config, ... }: {
    _module.args = {
      inherit hosts groups;
    };
    imports = [
      (import (hostsDir + "/${hostName}/configuration.nix"))
      ../modules
    ];
    networking = {
      inherit hostName;
    };
  };

  hosts = listToAttrs (
    map (
      hostName: nameValuePair hostName (
        import (pkgs.path + "/nixos") {
          configuration = hostConfig hostName;
          specialArgs = { inherit sources; };
        }
      )
    ) hostNames
  );

  groupNames = unique (
    concatLists (
      mapAttrsToList (
        name: host: host.config.deploy.groups
      ) hosts
    )
  );

  groups = listToAttrs (
    map (
      groupName: nameValuePair groupName (
        filter (
          host: elem groupName host.config.deploy.groups
        ) (
          attrValues hosts
        )
      )
    ) groupNames
  );
}
