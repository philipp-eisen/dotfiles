{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11";

  # Lets you run `home-manager switch` without `nix run` after first activation.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # daily drivers
    bat
    btop
    gh
    git-lfs
    jujutsu # jj
    neovim
    ripgrep
    tree
    wget
    visidata

    # languages / package managers (node itself comes via mise)
    go
    uv
    bun
    pnpm

    # infra
    kubectl
    kubectx # also provides kubens
    opentofu # terraform fork; free license -> comes prebuilt from the binary cache
    awscli2

    # misc
    gnupg

    # candidates to add when needed:
    # cmake dive doppler nmap postgresql_15 pulumi temporal-cli llama-cpp
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    CLICOLOR = "1";
    DOCKER_BUILDKIT = "1";
    GOPATH = "${config.home.homeDirectory}/go";
    GOBIN = "${config.home.homeDirectory}/go/bin";
    PYTHONBREAKPOINT = "ipdb.set_trace";
    PYDEVD_USE_CYTHON = "NO";
    PYENV_VIRTUALENV_DISABLE_PROMPT = "1";
    GRPC_PYTHON_BUILD_SYSTEM_OPENSSL = "1";
    GRPC_PYTHON_BUILD_SYSTEM_ZLIB = "1";
    USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
    CLOUDSDK_PYTHON = "python3";
    GOOSE_CLI_THEME = "ansi";
  };

  programs.zsh = {
    enable = true;

    autosuggestion = {
      enable = true;
      highlight = "fg=blue";
    };
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "npm"
        "gitfast"
        "docker"
        "jsontools"
        "sudo"
        "catimg"
        "git"
        "z"
        "web-search"
      ];
      extraConfig = ''
        COMPLETION_WAITING_DOTS="true"
        AUTOSWITCH_DEFAULT_PYTHON="/usr/bin/python3"
      '';
    };

    # Optional: to add the autoswitch_virtualenv plugin:
    # plugins = [{
    #   name = "autoswitch_virtualenv";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "MichaelAquilina";
    #     repo = "zsh-autoswitch-virtualenv";
    #     rev = "<tag>";
    #     hash = "";  # leave empty, run switch, copy the hash from the error
    #   };
    #   file = "autoswitch_virtualenv.plugin.zsh";
    # }];

    shellAliases = {
      vim = "nvim";

      # kubernetes
      k = "kubectl";
      kpf = "kubectl port-forward";
      ktx = "kubectx";
      kns = "kubens";

      # infra
      t = "tofu";
      a = "argo -n argo";

      # python
      pa = "source .venv/bin/activate";

      # git / github
      gpn = "git push --no-verify";
      gcn = "git commit --no-verify";
      gmm = "git fetch && git merge origin/main";
      "git.clean_remote_deleted" = "git fetch --all -p; git branch -vv | grep \": gone]\" | awk '{ print $1 }' | xargs -n 1 git branch -D";
      "git.clean_locally_merged" = "git branch --merged | egrep -v \"(^\\*|master|main|dev|prod)\" | xargs git branch -d";
      "git.clean" = "git.clean_remote_deleted && git.clean_locally_merged";
      "gh.merge" = "gh pr merge --squash --auto";
      ghc = "gh pr create --fill";
      ghv = "gh pr view --web || (gh pr create --fill && gh pr view --web) || gh repo view --web";
      "gh.sync" = "git fetch && git rebase origin/main";

      # misc
      ff = "rg . | fzf | cut -d \":\" -f 1";
      curl-time = "curl -o /dev/null -s -w \"DNS: %{time_namelookup}s\\nTCP: %{time_connect}s\\nTLS: %{time_appconnect}s\\nTotal: %{time_total}s\\n\"";
      claude = "claude --dangerously-skip-permissions";
    };

    envExtra = ''
      # rustup, if present
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    '';

    initContent = ''
      # Secrets live OUTSIDE this repo — copy ~/.secrets.zsh between machines
      # (or replace with sops-nix later).
      [ -f ~/.secrets.zsh ] && source ~/.secrets.zsh

      # extra completions
      fpath+=~/.zfunc
      autoload -Uz compinit && compinit

      # bun completions, if present
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

      disable r

      pyclean () {
          find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
      }
    '';
  };

  # prompt — config tracked as plain toml in this repo
  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = ../starship.toml;

  # fuzzy finder + zsh keybindings (ctrl-r history, ctrl-t files)
  programs.fzf.enable = true;

  # polyglot runtime version manager (node, python, ...)
  programs.mise.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;

    settings.user = {
      name = "Philipp Eisen";
      email = "8607233+philipp-eisen@users.noreply.github.com";
    };

    settings.alias = {
      # list files which have changed since REVIEW_BASE
      files = "!git diff --name-only $(git merge-base HEAD \"$REVIEW_BASE\")";
      stat = "!git diff --stat $(git merge-base HEAD \"$REVIEW_BASE\")";
      rsm = "reset --mixed HEAD~1";
      tmp = "commit --no-verify -a -m \"TMP - revert me\"";
      st = "status -sb";
      co = "checkout";
      c = "commit -v";
      a = "add -p";
      i = "!git add -N . && git add -p";
      wip = "commit -mwip";
      pp = "!git fetch && git merge --no-edit && git push";
      trash = "!f() { branch=$(git symbolic-ref --short HEAD); git reset --hard \"origin/$branch\" ;} ;f";
      sync = "fetch origin main:main";
      leaderboard = "shortlog -s -n --no-merges";
      branches = "for-each-ref --sort=committerdate refs/heads/ --format=%(authordate:short)%09%1B[0;33m%(refname:short)%1B[m%09";
      touched = "diff --relative --name-only main...";
    };

    settings = {
      init.defaultBranch = "main";
      rebase.autoStash = true;
      pull.ff = "only";
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      color.ui = "auto";
      rerere.enabled = true;
      core.autocrlf = "input";
      format.pretty = "%Cred%h%Creset %C(bold blue)%<(14)%an%Creset %s %Cgreen(%ar) %Creset %C(yellow)%d%Creset";
      diff = {
        tool = "vimdiff";
        algorithm = "histogram";
        colorMoved = "default";
      };
      merge.tool = "vimdiff";
      credential."https://github.com".helper = [ "" "!gh auth git-credential" ];
      credential."https://gist.github.com".helper = [ "" "!gh auth git-credential" ];
    };
  };
}
