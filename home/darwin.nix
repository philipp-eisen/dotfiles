{ config, pkgs, lib, ... }:

{
  # Homebrew stays in charge of casks / GUI apps (orbstack, tailscale, gcloud, ...)
  programs.zsh.profileExtra = ''
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # brew shellenv prepends /opt/homebrew/bin; put nix back in front so
    # nix-managed tools take precedence over brew duplicates
    export PATH="$HOME/.nix-profile/bin:$PATH"

    # OrbStack command-line tools and integration
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  '';

  programs.zsh.oh-my-zsh.plugins = [ "macos" ];

  programs.zsh.shellAliases = {
    ls = "ls -G"; # BSD ls
    nf = "osascript -e 'display notification \"The command finished\" with title \"Done\"'";
    chrome = "/usr/bin/open -a \"/Applications/Google Chrome.app\" --args";
    c = "open -a \"Cursor\"";
    v = "open -a \"Visual Studio Code\"";
    oo = "cursor $(find . '/' | fzf)";
    brew_x86 = "/usr/local/Homebrew/bin/brew";
  };

  programs.zsh.initContent = ''
    # brew-provided completions
    fpath+=/opt/homebrew/share/zsh/site-functions

    # gcloud (installed via brew cask)
    [ -f /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc ] && \
      source /opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc

    # brew kegs that need to shadow system binaries -> explicit prepends
    export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
  '';

  home.sessionVariables = {
    ANDROID_SDK = "${config.home.homeDirectory}/Library/Android/sdk";
    PNPM_HOME = "${config.home.homeDirectory}/Library/pnpm";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/Library/Android/sdk/emulator"
    "${config.home.homeDirectory}/Library/Android/sdk/tools"
    "${config.home.homeDirectory}/Library/pnpm"
    "${config.home.homeDirectory}/.spicetify"
    "${config.home.homeDirectory}/.codeium/windsurf/bin"
  ];

  # commit signing via 1Password (app path only exists on macOS)
  programs.git.signing = {
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKpEn4IC7PqfRs0oLPriDVGNnvlY/SWAyfCWkK4W5yto";
    signByDefault = true;
  };
  programs.git.settings = {
    gpg.format = "ssh";
    gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
}
