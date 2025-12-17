{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, haskellNix }@inputs:
    flake-utils.lib.eachSystem [ "aarch64-linux" ] (system:
      let
        overlays = [ haskellNix.overlay ];

        pkgs = import nixpkgs {
          inherit system overlays;
          inherit (haskellNix) config;
        };

        project = pkgs.haskell-nix.cabalProject' {
          src = ./.;
          compiler-nix-name = "ghc910";

          shell = {
            tools = {
              cabal = {};
              fourmolu = {};
              hlint = {};
              haskell-language-server = {};
            };

            buildInputs = with pkgs; [ nixpkgs-fmt ];
          };
        };

        flake = project.flake { };

      in
        pkgs.lib.recursiveUpdate flake {
          inherit project;

          packages.default = flake.packages."hello-haskell:exe:hello-haskell";

          hydraJobs.required = pkgs.releaseTools.aggregate {
            name = "required";
            constituents = pkgs.lib.collect pkgs.lib.isDerivation flake.hydraJobs;
          };
        });
}
