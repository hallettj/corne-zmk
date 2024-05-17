{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }:
    let
      eachSystem = callback: nixpkgs.lib.genAttrs systems (system: callback (zmk-pkgs system) (pkgs system));
      systems = nixpkgs.lib.attrNames zmk-nix.packages;
      pkgs = system: nixpkgs.legacyPackages.${system};
      zmk-pkgs = system: zmk-nix.legacyPackages.${system} // zmk-nix.packages.${system};

      zephyrDepsHash = "sha256-E/IoN2l7MLdolkXHvfq28oC9Twf6PODbl079yykk7UQ=";
      src = nixpkgs.lib.sourceFilesBySuffices self [ ".conf" ".keymap" ".yml" ];
    in
    {
      packages = eachSystem (zmk-pkgs: pkgs: rec {
        default = firmware;

        firmware = (zmk-pkgs.buildSplitKeyboard {
          name = "corne-firmware";
          inherit src zephyrDepsHash;

          board = "nice_nano_v2";
          shield = "corne_%PART%";

          nativeBuildInputs = with pkgs; [ dtc ];

          meta = {
            description = "ZMK firmware";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        });

        settings-reset = zmk-pkgs.buildKeyboard {
          name = "settings-reset";
          inherit src zephyrDepsHash;

          board = "nice_nano_v2";
          shield = "settings_reset";

          nativeBuildInputs = with pkgs; [ dtc ];

          meta = {
            description = "ZMK firmware settings reset";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        flash = zmk-pkgs.flash.override { inherit firmware; };
        update = zmk-pkgs.update;
      });

      devShells = eachSystem (zmk-pkgs: pkgs: {
        default = zmk-nix.devShells.${pkgs.system}.default;
      });
    };
}
