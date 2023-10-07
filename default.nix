{
  naersk,
  callPackage,
  fishnetSource,
  nnueNet,
  ...
}:
(callPackage naersk {}).buildPackage {
  src = fishnetSource;
  overrideMain = p: {
    patchPhase = ''
      cp ${nnueNet} Stockfish/src/nn-5af11540bbfe.nnue
    '';
  };
}
