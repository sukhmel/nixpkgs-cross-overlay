# Definition of Nix packages compatible with flakes and traditional workflow.
let
  lockFile = import ./flake-lock.nix { src = ./..; };
in
{ localSystem ? builtins.currentSystem
, crossSystem ? null
, src ? lockFile.nixpkgs
, newSrc ? lockFile.nixpkgs-25-05
, config ? { }
, overlays ? [ ]
}:
let
  # Import local packages.
  pkgs = import src {
    inherit localSystem config;

    overlays = [
      # Setup cross overlay.
      (final: prev: {
        # get fresh rdkafka
        rdkafka = import newSrc {
          inherit localSystem config;
        }.rdkafka;
      })
      (import ./..)
    ];
  };
in
# Make cross system packages.
pkgs.mkCrossPkgs {
  inherit src newSrc localSystem crossSystem config;
  # Setup extra overlays.
  overlays = [
    (import lockFile.rust-overlay)
  ] ++ overlays;
}
