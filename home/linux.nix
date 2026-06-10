{ config, pkgs, lib, ... }:

{
  # Required on non-NixOS distros (Ubuntu/Debian VMs): fixes XDG paths,
  # sources the nix profile, makes desktop entries work, etc.
  targets.genericLinux.enable = true;

  programs.zsh.shellAliases = {
    ls = "ls --color=auto"; # GNU ls
  };

  home.sessionVariables = {
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/pnpm"
  ];

  # On a VM you may want gcloud from nixpkgs instead of the brew cask:
  # home.packages = [ pkgs.google-cloud-sdk ];
}
