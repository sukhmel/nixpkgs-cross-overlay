{
  description = "Rust cross-compilatilon utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-25-05.url = "github:NixOS/nixpkgs/nixos-25.05";
    rust-overlay = {
      url = "github:nihirash/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-25-05
    , rust-overlay
    , flake-utils
    , treefmt-nix
    }: flake-utils.lib.eachDefaultSystem
      (system:
      let
        # Setup nixpkgs.
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            (import rust-overlay)
            (import ./.)
            (final: prev: {
              # get fresh rdkafka
              rdkafka = builtins.trace ''overlaying rdkafka'' import nixpkgs-25-05 {
                inherit system;
              }.rdkafka;
            })
          ];
        };

        # Eval the treefmt modules from ./treefmt.nix
        treefmtPkgs = import nixpkgs { inherit system; };
        treefmt = (treefmt-nix.lib.evalModule treefmtPkgs ./treefmt.nix).config.build;

        # List of supported cross systems
        supportedCrossSystems = [
          null
          { config = "x86_64-unknown-linux-gnu"; useLLVM = false; isStatic = false; }
          { config = "x86_64-unknown-linux-musl"; useLLVM = true; isStatic = false; }
          { config = "x86_64-unknown-linux-musl"; useLLVM = true; isStatic = false; }
          { config = "x86_64-unknown-linux-musl"; useLLVM = true; isStatic = true; }
          { config = "x86_64-unknown-linux-musl"; useLLVM = false; isStatic = false; }
          { config = "aarch64-unknown-linux-gnu"; useLLVM = false; isStatic = false; }
          { config = "aarch64-unknown-linux-musl"; useLLVM = true; isStatic = false; }
          { config = "aarch64-unknown-linux-musl"; useLLVM = true; isStatic = true; }
          { config = "aarch64-unknown-linux-musl"; useLLVM = false; isStatic = false; }
          { config = "riscv64-unknown-linux-gnu"; useLLVM = false; isStatic = false; }
        ];

        mkDevShellName = name: crossSystem:
          let
            useLLVM =
              if crossSystem.useLLVM
              then "&useLLVM=true"
              else "";
            isStatic =
              if crossSystem.isStatic
              then "&isStatic=true"
              else "";
          in
          if crossSystem != null then
            "${name}?target=${crossSystem.config}${useLLVM}${isStatic}"
          else
            "default";

        foreachCrossSystem = (name: f:
          pkgs.lib.lists.foldr
            (crossSystem: output:
              output // {
                "${mkDevShellName name crossSystem}" = (f crossSystem);
              })
            { }
            supportedCrossSystems);
      in
      {
        # for `nix fmt`
        formatter = treefmt.wrapper;
        # for `nix flake check`
        checks.formatting = treefmt.check self;

        devShells = foreachCrossSystem "crossShell" (crossSystem:
          import ./shell.nix {
            localSystem = system; inherit crossSystem;
          });

        packages =
          # Targets for CI.
          foreachCrossSystem "pkgs"
            (crossSystem:
              import ./tests {
                inherit pkgs;
                localSystem = system;
                crossSystems = [ crossSystem ];
                src = nixpkgs;
              })
          # Other targets.
          // rec {
            pkgsAll = import ./tests {
              inherit pkgs;
              localSystem = system;
              crossSystems = supportedCrossSystems;
              src = nixpkgs;
            };

            pushAll = with pkgs; writeShellApplication {
              name = "push-all";
              runtimeInputs = [ cachix nix ];
              text = ''cachix push nixpkgs-cross-overlay "${pkgsAll}"'';
            };
          };
      })
    # System independent modules.
    // {
      # The usual flake attributes can be defined here, including system-
      # agnostic ones like nixosModule and system-enumerating ones, although
      # those are more easily expressed in perSystem.
      overlays =
        let
          nixpkgs-cross-overlay = import ./.;
          rust-overlay' = (import rust-overlay);
        in
        {
          default = nixpkgs-cross-overlay;
          rust-overlay = rust-overlay';
          # Export as a flake overlay including all dependent overlays.
          full = final: prev:
            (rust-overlay' final prev) // (nixpkgs-cross-overlay final prev);
        };
    };
}
