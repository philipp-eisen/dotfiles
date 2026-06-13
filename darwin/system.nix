{ pkgs, inputs, username, ... }:

{
  nix.enable = false; # Determinate Nix owns the daemon and /etc/nix/nix.conf.

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    primaryUser = username;
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    stateVersion = 6;
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
  ];

  homebrew = {
    enable = true;
    user = username;

    global.brewfile = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "check";
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_ENV_HINTS = "1";
      };
    };

    taps = [
      "anomalyco/tap"
      "depot/tap"
      "f1bonacc1/tap"
      "hashicorp/tap"
      "neiii/bridle"
      "oven-sh/bun"
      "philipp-eisen/tap"
      "pulumi/tap"
      "steipete/tap"
      "supabase/tap"
    ];

    brews = [
      # Installed custom-tap formulae kept manual until their taps are trusted:
      # bridle, depot, opencode, padel-tui, supabase, terraform.
      "amass"
      "awscli"
      "azure-cli"
      "bat"
      "btop"
      "cmake"
      "dive"
      "doppler"
      "dotnet"
      "dotnet@8"
      "dum"
      "faudio"
      "sdl2"
      "ffmpeg"
      "fzf"
      "gh"
      "git-lfs"
      "gnupg"
      "go"
      "herdr"
      "jj"
      "livekit-cli"
      "llama.cpp"
      "llmfit"
      "mise"
      "mole"
      "mono"
      "mono-libgdiplus"
      "mpv"
      "neovim"
      "nmap"
      "node"
      "nuget"
      "openjdk"
      "pgsync"
      "pnpm"
      "portaudio"
      { name = "postgresql@15"; link = true; }
      "pybind11"
      "railway"
      "render"
      "ripgrep"
      "starship"
      "temporal"
      "tree"
      "uv"
      "visidata"
      "wget"
      "xcodegen"
      "zsh-syntax-highlighting"
    ];

    casks = [
      "1password-cli"
      "bruno"
      "codex"
      "gcloud-cli"
      "inkscape"
      "jordanbaird-ice"
      "mitmproxy"
      "ngrok"
      "orbstack"
      "tailscale-app"
      "wireshark-app"
    ];

    vscode = [
      "4ops.terraform"
      "anysphere.csharp"
      "anysphere.cursorpyright"
      "anysphere.remote-ssh"
      "bierner.markdown-mermaid"
      "bradlc.vscode-tailwindcss"
      "catppuccin.catppuccin-vsc"
      "charliermarsh.ruff"
      "dbaeumer.vscode-eslint"
      "eamodio.gitlens"
      "esbenp.prettier-vscode"
      "github.vscode-github-actions"
      "github.vscode-pull-request-github"
      "hashicorp.terraform"
      "hbenl.vscode-test-explorer"
      "humao.rest-client"
      "johnpapa.vscode-peacock"
      "k--kato.intellij-idea-keybindings"
      "kamikillerto.vscode-colorize"
      "knisterpeter.vscode-github"
      "littlefoxteam.vscode-python-test-adapter"
      "marimo-team.vscode-marimo"
      "mechatroner.rainbow-csv"
      "ms-azuretools.vscode-docker"
      "ms-dotnettools.vscode-dotnet-runtime"
      "ms-python.debugpy"
      "ms-python.python"
      "ms-toolsai.jupyter"
      "ms-toolsai.jupyter-renderers"
      "ms-toolsai.vscode-jupyter-cell-tags"
      "ms-toolsai.vscode-jupyter-slideshow"
      "ms-vscode-remote.remote-containers"
      "ms-vscode.test-adapter-converter"
      "redhat.vscode-yaml"
      "rust-lang.rust-analyzer"
      "shopify.theme-check-vscode"
      "sukumo28.wav-preview"
      "tamasfe.even-better-toml"
      "tauri-apps.tauri-vscode"
      "vitest.explorer"
      "vscodevim.vim"
      "wayou.vscode-todo-highlight"
      "yoavbls.pretty-ts-errors"
    ];

    extraConfig = ''
      uv "claranet4"
      uv "llm"
      npm "@anthropic-ai/claude-code"
      npm "@earendil-works/pi-coding-agent"
      npm "@hubspot/cli"
      npm "vercel"
    '';
  };
}
