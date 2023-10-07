{
  mkShell,
  cargo,
  rustc,
  rustfmt,
  pre-commit,
  rustPackages,
  rustPlatform,
  ...
}:
mkShell {
  buildInputs = [
    cargo
    rustc
    rustfmt
    pre-commit
    rustPackages.clippy
  ];
  RUST_SRC_PATH = rustPlatform.rustLibSrc;
}
