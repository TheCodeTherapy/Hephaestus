{
  description = "A very basic flake";

  inputs = {
    # Pinned commit that has kernel v6.14.2 and NVidia driver v570.133.07
    nixpkgs.url = "github:NixOS/nixpkgs/2631b0b7abcea6e640ce31cd78ea58910d31e650";
    # Home Manager that follows the same nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager } @attrs: {
    nixosConfigurations.threadripper = nixpkgs.lib.nixosSystem rec {
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager
      ];

      specialArgs = {
        inputs = attrs;
      };

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          doCheckByDefault = false;
        };
      };

      system = "x86_64-linux";
    };
  };
}
