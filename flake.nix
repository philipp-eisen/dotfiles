{
  description = "Phil's portable shell setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
    let
      username = "phil";
      mkPkgs = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkHome = { system, username ? "phil", modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          modules = [
            {
              home.username = username;
              home.homeDirectory =
                if nixpkgs.lib.hasSuffix "-darwin" system
                then "/Users/${username}"
                else "/home/${username}";
            }
          ] ++ modules;
        };
    in
    {
      darwinConfigurations = {
        phil = nix-darwin.lib.darwinSystem {
          modules = [
            ./darwin/system.nix
            home-manager.darwinModules.home-manager
            {
              nixpkgs.pkgs = mkPkgs "aarch64-darwin";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = {
                imports = [ ./home/common.nix ./home/darwin.nix ];
              };
            }
          ];
          specialArgs = { inherit inputs username; };
        };
      };

      homeConfigurations = {
        "phil@mac" = mkHome {
          system = "aarch64-darwin";
          modules = [ ./home/common.nix ./home/darwin.nix ];
        };

        # Adjust system (e.g. aarch64-linux) and username to match the VM.
        "phil@vm" = mkHome {
          system = "x86_64-linux";
          modules = [ ./home/common.nix ./home/linux.nix ];
        };
      };
    };
}
