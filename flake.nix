{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, nixpkgs-stable, home-manager, nixos-hardware, flake-utils, agenix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = (with pkgs; [
            nixpkgs-fmt
          ]);
        };
        checks = {
          format = pkgs.runCommand "check-format"
            {
              buildInputs = [ pkgs.nixpkgs-fmt ];
            }
            ''
              ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
              touch $out
            '';
        };
      }) // {
      nixosConfigurations = nixpkgs.lib.mapAttrs
        (hostname: { system, modulesExtra, ... }: nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({
              nix.registry.nixpkgs.flake = nixpkgs;
            })
            agenix.nixosModules.age
            ./machines/${hostname}/${hostname}.nix
          ] ++ modulesExtra;
        })
        (import ./machines inputs);
    };
}
