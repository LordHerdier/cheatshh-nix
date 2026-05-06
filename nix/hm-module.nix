self:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.cheatshh;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.cheatshh = {
    enable = lib.mkEnableOption "cheatshh interactive cheatsheet manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "cheatshh.packages.\${system}.default";
      description = "The cheatshh package to use.";
    };

    settings = {
      copyCommand = lib.mkOption {
        type = lib.types.str;
        default = "pbcopy";
        example = "xclip -selection clipboard";
        description = ''
          Shell command used to copy a selected command to the clipboard.
          The command receives the text via stdin: `printf "text" | $copyCommand`.
        '';
      };

      displayGroupNumber = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = ''
          Number of groups shown in the whiptail dialog.
          Keep this small enough to fit the dialog, or whiptail may error.
        '';
      };

      manPages = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically display man pages in the fzf preview without passing -m.";
      };

      cheatshhHome = lib.mkOption {
        type = lib.types.str;
        default = "~/.config/cheatshh";
        description = ''
          Directory where commands.json and groups.json are stored.
          cheatshh.toml itself always lives in ~/.config/cheatshh regardless of this setting.
        '';
      };

      notes = lib.mkOption {
        type = lib.types.str;
        default = "tldr --color";
        example = "cheat";
        description = "Command used to display notes in the preview pane. The command is called as `$notes <command>`.";
      };

      fullDisplay = lib.mkOption {
        type = lib.types.enum [ "on" "off" ];
        default = "on";
        description = ''
          When "on", the fzf listing shows group/command pairs (e.g. git/commit).
          When "off", only top-level commands and group names are shown.
        '';
      };

      previewWidth = lib.mkOption {
        type = lib.types.int;
        default = 70;
        description = "Width of the fzf preview pane as a percentage of the terminal width.";
      };
    };

    colorScheme = {
      titleColor = lib.mkOption {
        type = lib.types.str;
        default = "\\033[0;36m";
        example = "\\033[0;32m";
        description = "ANSI escape code for titles in the preview pane (e.g. COMMAND/GROUP:).";
      };

      aboutColor = lib.mkOption {
        type = lib.types.str;
        default = "\\033[0;33m";
        example = "\\033[0;35m";
        description = "ANSI escape code for the about/command-name text in the preview pane.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Generate cheatshh.toml from the declared options.
    # cheats.sh only reads this file, never writes it, so a Nix-store symlink is safe.
    home.file.".config/cheatshh/cheatshh.toml".source =
      tomlFormat.generate "cheatshh.toml" {
        settings = {
          copy_command = cfg.settings.copyCommand;
          display_group_number = cfg.settings.displayGroupNumber;
          man_pages = cfg.settings.manPages;
          cheatshh_home = cfg.settings.cheatshhHome;
          notes = cfg.settings.notes;
          full_display = cfg.settings.fullDisplay;
          preview_width = cfg.settings.previewWidth;
        };
        color_scheme = {
          title_color = cfg.colorScheme.titleColor;
          about_color = cfg.colorScheme.aboutColor;
        };
      };

    # Seed the mutable data files on first activation only.
    # cheats.sh writes to these files at runtime, so we must never overwrite them.
    # Nix store files are read-only; chmod makes the copies writable.
    home.activation.cheatshhInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      _dir="$HOME/.config/cheatshh"
      $DRY_RUN_CMD mkdir -p "$_dir"
      if [[ ! -f "$_dir/commands.json" ]]; then
        $DRY_RUN_CMD cp "${self}/cheatshh/commands.json" "$_dir/commands.json"
        $DRY_RUN_CMD chmod u+w "$_dir/commands.json"
      fi
      if [[ ! -f "$_dir/groups.json" ]]; then
        $DRY_RUN_CMD cp "${self}/cheatshh/groups.json" "$_dir/groups.json"
        $DRY_RUN_CMD chmod u+w "$_dir/groups.json"
      fi
    '';
  };
}
