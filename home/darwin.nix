{ config, pkgs, lib, ... }:

{
  # nix-darwin declares Homebrew packages; this keeps shell integration and PATH
  # ordering explicit in the user session.
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
    hms = "sudo darwin-rebuild switch --flake ~/dev/repos/dotfiles#phil";
    ls = "ls -G"; # BSD ls
    nf = "osascript -e 'display notification \"The command finished\" with title \"Done\"'";
    chrome = "/usr/bin/open -a \"/Applications/Google Chrome.app\" --args";
    c = "open -a \"Cursor\"";
    v = "open -a \"Visual Studio Code\"";
    idea = "\"/Applications/IntelliJ IDEA.app/Contents/MacOS/idea\"";
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
    "${config.home.homeDirectory}/Library/Android/sdk/platform-tools"
    "${config.home.homeDirectory}/Library/Android/sdk/tools"
    "${config.home.homeDirectory}/Library/pnpm"
    "${config.home.homeDirectory}/.spicetify"
    "${config.home.homeDirectory}/.codeium/windsurf/bin"
  ];

  # IntelliJ stores this preference in a versioned configuration directory.
  # Merge only the managed value so other IDE settings remain writable.
  home.activation.configureIntelliJProjectTabs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 <<'PY'
    import os
    import plistlib
    import re
    import xml.etree.ElementTree as ET
    from pathlib import Path

    jetbrains_root = Path("${config.home.homeDirectory}") / "Library/Application Support/JetBrains"
    options_dirs = set(jetbrains_root.glob("IntelliJIdea*/options"))

    app_info = Path("/Applications/IntelliJ IDEA.app/Contents/Info.plist")
    if app_info.exists():
        with app_info.open("rb") as source:
            version = str(plistlib.load(source).get("CFBundleShortVersionString", ""))
        version_match = re.match(r"(\d{4}\.\d+)", version)
        if version_match:
            options_dirs.add(
                jetbrains_root / f"IntelliJIdea{version_match.group(1)}" / "options"
            )

    for options_dir in sorted(options_dirs):
        options_dir.mkdir(parents=True, exist_ok=True)
        settings_path = options_dir / "ide.general.xml"

        if settings_path.exists():
            tree = ET.parse(settings_path)
            application = tree.getroot()
        else:
            application = ET.Element("application")
            tree = ET.ElementTree(application)

        general_settings = application.find("./component[@name='GeneralSettings']")
        if general_settings is None:
            general_settings = ET.SubElement(
                application, "component", {"name": "GeneralSettings"}
            )

        project_opening = general_settings.find(
            "./option[@name='confirmOpenNewProject2']"
        )
        if project_opening is None:
            project_opening = ET.SubElement(
                general_settings,
                "option",
                {"name": "confirmOpenNewProject2"},
            )

        if project_opening.get("value") == "0":
            continue

        project_opening.set("value", "0")
        ET.indent(tree, space="  ")
        temporary_path = settings_path.with_suffix(".xml.tmp")
        tree.write(temporary_path, encoding="unicode", xml_declaration=False)
        with temporary_path.open("a") as output:
            output.write("\n")
        os.replace(temporary_path, settings_path)
    PY
  '';

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
