{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    fishnetSource = {
      url = "git+https://github.com/lichess-org/fishnet?submodules=1";
      flake = false;
    };

    nnueNet = {
      url = "https://tests.stockfishchess.org/api/nn/nn-5af11540bbfe.nnue";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    naersk,
    fishnetSource,
    nnueNet,
  }: let
    supportedSystems = ["x86_64-linux"];
    forEachSystem = f:
      nixpkgs.lib.genAttrs supportedSystems
      (system:
        f {
          inherit system;
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    containers = forEachSystem ({
      system,
      pkgs,
    }: {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.10";
      localAddress = "192.168.100.11";
      hostAddress6 = "fc00::1";
      localAddress6 = "fc00::2";
      config = {
        config,
        lib,
        ...
      }: {
        imports = [self.nixosModules.${system}.default];

        services.fishnet = {
          enable = true;
          keyFile = pkgs.writeTextFile "fishnet.key" "invalid";
        };

        nix.settings.experimental-features = ["nix-command"];

        services.resolved.enable = true;
      };
    });
    nixosModules = forEachSystem ({
      system,
      pkgs,
    }: {
      default = {
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
            description = "The number of CPU cores to use";
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
        };
        config = mkIf cfg.enable {
          systemd.services.fishnet = {
            description = "Distributed Stockfish analysis for lichess.org";
            wantedBy = ["multi-user.target"];
            after = ["network.target"];
            serviceConfig = {
              User = "fishnet";
              ExecStart = pkgs.writeShellScript "fishnet-launcher" ''
                ${self.packages.${system}.fishnet}/bin/fishnet \
                  --no-conf \
                  --key-file ${cfg.keyFile} \
                  --cores ${cfg.cores} \
                  --user-backlog ${
                  if cfg.joinEvenIfNoBacklog
                  then 0
                  else "short"
                } \
                  --system-backlog ${
                  if cfg.joinEvenIfNoBacklog
                  then 0
                  else "long"
                }
              '';
            };
          };
        };
      };
    });

    packages = forEachSystem ({
      system,
      pkgs,
    }: let
      fishnet = (pkgs.callPackage naersk {}).buildPackage {
        src = fishnetSource;
        overrideMain = p: {
          patchPhase = ''
            cp ${nnueNet} Stockfish/src/nn-5af11540bbfe.nnue
          '';
        };
      };
    in {
      inherit fishnet;
      default = fishnet;
    });

    devShells = forEachSystem ({
      system,
      pkgs,
    }: {
      default = with pkgs;
        mkShell {
          buildInputs = [
            cargo
            rustc
            rustfmt
            pre-commit
            rustPackages.clippy
          ];
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
        };
    });
  };
}
