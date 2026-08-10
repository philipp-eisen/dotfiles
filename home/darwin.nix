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

  home.packages = [ pkgs.duti ];

  programs.zsh.shellAliases = {
    hms = "home-manager switch --flake ~/dev/repos/dotfiles#phil@mac";
    dms = "sudo darwin-rebuild switch --flake ~/dev/repos/dotfiles#phil";
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

  # Keep Caps Lock mapped to Escape. The usage codes are keyboard Caps Lock
  # (0x700000039) and keyboard Escape (0x700000029).
  home.activation.configureCapsLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mapping_key="com.apple.keyboard.modifiermapping.0-0-0"
    mapping='<dict><key>HIDKeyboardModifierMappingSrc</key><integer>30064771129</integer><key>HIDKeyboardModifierMappingDst</key><integer>30064771113</integer></dict>'

    /usr/bin/defaults -currentHost write NSGlobalDomain "$mapping_key" -array "$mapping"
    /usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771113}]}' >/dev/null
  '';

  # Make IntelliJ the default application for source code, scripts,
  # developer configuration, and code-oriented documentation.
  home.activation.configureIntelliJFileAssociations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    idea_app="/Applications/IntelliJ IDEA.app"
    idea_bundle_id="com.jetbrains.intellij"

    if [ ! -d "$idea_app" ]; then
      echo "warning: $idea_app is missing; IntelliJ file associations were not applied" >&2
    elif [ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$idea_app/Contents/Info.plist")" != "$idea_bundle_id" ]; then
      echo "warning: $idea_app has an unexpected bundle ID; IntelliJ file associations were not applied" >&2
    else
      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "$idea_app"

      failed_extensions=""
      for extension in \
        c h cc cpp cxx hpp hxx inl m mm swift metal \
        cs csx fs fsx fsproj vb vbs \
        java groovy gradle kt kts scala sc clj cljs cljc edn \
        js jsx mjs cjs ts tsx mts cts vue svelte astro \
        html htm xhtml css scss sass less styl pug \
        py pyw pyi ipynb go rs rb erb rake php lua pl pm \
        ex exs erl hrl dart r jl ml mli hs lhs idr elm zig nim sol move \
        asm s v sv svh vhd vhdl qml \
        sh bash zsh fish command ps1 bat cmd \
        json jsonc json5 yaml yml toml xml xsd xsl xslt \
        properties ini cfg conf env editorconfig gitignore \
        nix tf tfvars hcl rego dhall bicep cue cmake make mk bazel bzl dockerfile \
        sql graphql gql proto thrift avsc raml prisma \
        md mdx rst adoc tex \
        hbs handlebars mustache ejs njk liquid twig \
        http rest feature patch diff ipr iws iml
      do
        ${lib.getExe pkgs.duti} -s "$idea_bundle_id" "$extension" all 2>/dev/null || true
        handler="$(${lib.getExe pkgs.duti} -x "$extension" 2>/dev/null | /usr/bin/tail -n 1)"
        if [ "$handler" != "$idea_bundle_id" ]; then
          failed_extensions="$failed_extensions $extension"
        fi
      done

      if [ -n "$failed_extensions" ]; then
        echo "warning: macOS refused these IntelliJ associations:$failed_extensions" >&2
      fi
    fi
  '';

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
