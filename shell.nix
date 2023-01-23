{ localSystem ? builtins.currentSystem
, crossSystem ? null
}:
let
  pkgs = import ./utils/nixpkgs.nix {
    inherit localSystem crossSystem;
  };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs.pkgsBuildHost; [
    cmake
    pkg-config
    protobuf
    rustToolchain
    git
    dprint
    # Will add some dependencies like libiconv
    rustBuildHostDependencies
  ];

  buildInputs = with pkgs; [
    # List of tested native libraries.
    rdkafka
    rocksdb
    libopus
    bash
    bashInteractive
    coreutils
    # Enable cross-compilation support.
    rustCrossHook
  ] # Build also all cargo deps
  ++ cargoDeps.all;

  shellHook = "${pkgs.crossBashPrompt}";

  # Make it buildable, to make it possible to upload it to cache
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out
    echo "''${buildInputs}"        > $out/inputs.txt
  '';
}