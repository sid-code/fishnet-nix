# fishnet-nix

[Fishnet](https://github.com/lichess-org/fishnet) is how Lichess runs
Stockfish for server-side analysis of games. Anyone can contribute CPU
time to this.

This repository contains Nix expressions to configure NixOS to
configure and start Fishnet.

# Usage as a flake

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/sid-code/fishnet-nix/badge)
](https://flakehub.com/flake/sid-code/fishnet-nix)

Add fishnet-nix to your `flake.nix`:

```nix
{
  inputs = {
    fishnet-nix.url = "https://flakehub.com/f/sid-code/YourFlakeName/*.tar.gz";
    # ...
  }

  outputs = {self, fishnet-nix, ...}@inputs: {
    # ...
  };
}
```

Then, in a NixOS module:

```nix
{inputs, pkgs, ...}:
{
  imports = [inputs.fishnet-nix.nixosModules.x86_64-linux.default];
  config = {
    services.fishnet = {
      enable = true;
      keyFile = "<path to your key file>";
      cores = 12; # The number of CPU cores to use.
      joinEvenIfNoBacklog = false; # Do this if you're on a laptop.
    };
  };
}
```
