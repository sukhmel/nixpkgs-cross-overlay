final: prev: {
  # Applies some patches on the nix packages to better cross-compilation support.
  #
  # deprecated: use `nixpgs` directly.
  mkCrossPkgs =
    { src
    , newSrc ? null
    , localSystem
    , crossSystem ? null
    , config ? { }
    , overlays ? [ ]
    }:

    let
      crossOverlay = import ./.;
      rdkafkaOverlay = (final: prev: {
        # get fresh rdkafka
        rdkafka =
          if newSrc != null
          then (import newSrc {
            inherit localSystem crossSystem config;
          }).rdkafka
          else prev.rdkafka;
      });
    in
    import src {
      inherit localSystem crossSystem config;
      overlays = [ crossOverlay rdkafkaOverlay ] ++ overlays;
    };
} // (import ./lib final prev)
