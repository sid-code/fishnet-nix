{
  config,
  lib,
  ...
}: let
  inherit (lib) types mkOption mkEnableOption mkIf;
  cfg = config.services.fishnet;
in {
  options.services.fishnet = {
    enable = mkEnableOption "Fishnet";
    keyFile = mkOption {
      description = "File that contains your Fishnet key.";
      type = types.path;
    };
    cores = mkOption {
      description = "The number of CPU cores to use.";
      type = types.number;
      default = 3;
    };
    joinEvenIfNoBacklog = mkOption {
      description = ''
        Join even if no backlog of analyses needed.
        Set to false for laptops.
      '';
      type = types.bool;
      default = true;
    };
    extraOptions = mkOption {
      description = "Any extra CLI arguments to pass to fishnet.";
      type = types.str;
      default = "";
    };
  };
  config = mkIf cfg.enable {
    users.groups.fishnet.members = ["fishnet"];
    users.users.fishnet = {
      isSystemUser = true;
      home = "/var/fishnet";
      description = "Fishnet user";
      group = "fishnet";
      createHome = true;
    };

    systemd.services.fishnet = {
      description = "Distributed Stockfish analysis for lichess.org";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        User = "fishnet";
        ExecStart = pkgs.writeShellScript "fishnet-launcher" ''
          ${self.packages.${system}.fishnet}/bin/fishnet \
            ${cfg.extraOptions} \
            --no-conf \
            --key-file ${cfg.keyFile} \
            --cores ${builtins.toString cfg.cores} \
            --user-backlog ${
            if cfg.joinEvenIfNoBacklog
            then "0"
            else "short"
          } \
            --system-backlog ${
            if cfg.joinEvenIfNoBacklog
            then "0"
            else "long"
          }
        '';
      };
    };
  };
}
