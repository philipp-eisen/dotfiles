{
  description = "Phil's portable shell setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      mkHome = { system, username ? "phil", modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true; # permit unfree-licensed packages
          };
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
