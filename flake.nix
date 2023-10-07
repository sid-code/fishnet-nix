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
          pkgs = import nixpkgs {
            inherit system;
            overlays = [(final: prev: {fishnet = prev.fishnet;})];
          };
        });
  in {
    nixosModules = forEachSystem ({
      system,
      pkgs,
    }: {
      default = pkgs.callPackage ./module.nix {
        inherit system;
      };
    });

    packages = forEachSystem ({
      system,
      pkgs,
    }: let
      fishnet = pkgs.callPackage ./default.nix {
        inherit fishnetSource nnueNet naersk;
      };
    in {
      inherit fishnet;
      default = fishnet;
    });

    devShells = forEachSystem ({
      system,
      pkgs,
    }: {
      default = pkgs.callPackage ./shell.nix {};
    });
  };
}
