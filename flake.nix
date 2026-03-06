{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zmk-nix.url = "github:lilyinstarlight/zmk-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      eachSystem =
        callback:
        nixpkgs.lib.genAttrs systems (
          system:
          callback {
            inherit system;
            zmk-pkgs = zmk-pkgs system;
            pkgs = pkgs system;
          }
        );
      systems = nixpkgs.lib.attrNames zmk-nix.packages;
      pkgs = system: nixpkgs.legacyPackages.${system};
      zmk-pkgs = system: zmk-nix.legacyPackages.${system} // zmk-nix.packages.${system};

      # Make sure to set this to nixpkgs.lib.fakeHash after making changes to
      # west.yml to avoid getting stale dependencies.
      zephyrDepsHash = "sha256-Uw3Vrb2AjKcVUIatBywr+emfPQoXql0UZYVH3VQgUTE=";

      src = nixpkgs.lib.sourceFilesBySuffices self [
        ".board"
        ".cmake"
        ".conf"
        ".defconfig"
        ".dts"
        ".dtsi"
        ".json"
        ".keymap"
        ".overlay"
        ".shield"
        ".yml"
        "_defconfig"
      ];
    in
    {
      packages = eachSystem (
        {
          zmk-pkgs,
          pkgs,
          system,
        }:
        rec {
          corne-firmware = (
            zmk-pkgs.buildSplitKeyboard {
              name = "corne-firmware";
              inherit src zephyrDepsHash;

              board = "nice_nano@2.0.0//zmk";
              shield = "corne_%PART%";
              enableZmkStudio = false;

              meta = {
                description = "ZMK firmware";
                license = nixpkgs.lib.licenses.mit;
                platforms = nixpkgs.lib.platforms.all;
              };
            }
          );

          corne-mini-firmware = (
            zmk-pkgs.buildSplitKeyboard {
              name = "corne-mini-firmware";
              inherit src zephyrDepsHash;

              # Since a ZMK refactor on 2026-02-12 it is necessary to specify
              # the board variant using the //zmk suffix in order for the
              # nice_view_adapter and nice_view shield overlays to set up
              # correctly.
              board = "nice_nano@2.0.0//zmk";
              shield = "corne_%PART% nice_view_adapter nice_view";
              extraCmakeFlags = [ "-DEXTRA_CONF_FILE=/build/source/config/corne_display.conf" ];
              enableZmkStudio = false;

              meta = {
                description = "ZMK firmware";
                license = nixpkgs.lib.licenses.mit;
                platforms = nixpkgs.lib.platforms.all;
              };
            }
          );

          settings-reset = zmk-pkgs.buildKeyboard {
            name = "settings-reset";
            inherit src zephyrDepsHash;

            board = "nice_nano_v2";
            shield = "settings_reset";

            meta = {
              description = "ZMK firmware settings reset";
              license = nixpkgs.lib.licenses.mit;
              platforms = nixpkgs.lib.platforms.all;
            };
          };

          flash-corne = zmk-pkgs.flash.override { firmware = corne-firmware; };
          flash-corne-mini = zmk-pkgs.flash.override { firmware = corne-mini-firmware; };

          # Call `nix run .#update` to update ZMK.
          # (This is not currently working)
          update = zmk-pkgs.update.overrideAttrs (
            final: prev: {
              # Since I'm using one ZephyrDepsHash for all of my firmwares, this
              # variable only needs to be set to the Nix flake package attribute
              # name of one firmware.
              UPDATE_NIX_ATTR_PATH = "corne-firmware";
            }
          );
        }
      );

      devShells = eachSystem (
        {
          zmk-pkgs,
          pkgs,
          system,
        }:
        {
          default = zmk-nix.devShells.${system}.default;
        }
      );
    };
}
