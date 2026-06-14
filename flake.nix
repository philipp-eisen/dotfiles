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

        # x86_64 Linux VM.
        "phil@vm" = mkHome {
          system = "x86_64-linux";
          modules = [ ./home/common.nix ./home/linux.nix ];
        };

        # ARM Linux VM.
        "phil@armvm" = mkHome {
          system = "aarch64-linux";
          modules = [
            ./home/common.nix
            ./home/linux.nix
            ({ lib, ... }: {
              programs.zsh.shellAliases.hms =
                lib.mkForce "home-manager switch --flake ~/dev/repos/dotfiles#phil@armvm";
            })
          ];
        };
      };
    };
}
