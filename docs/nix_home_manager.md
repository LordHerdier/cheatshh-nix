# Nix Home Manager Module

This flake exposes a home-manager module that lets you configure cheatshh declaratively in Nix instead of editing `cheatshh.toml` by hand.

## Setup

Add the flake as an input and import the module:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    cheatshh.url = "github:AnirudhG07/cheatshh";
  };

  outputs = { nixpkgs, home-manager, cheatshh, ... }: {
    homeConfigurations.you = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        cheatshh.homeManagerModules.cheatshh
        {
          programs.cheatshh.enable = true;
        }
      ];
    };
  };
}
```

Enabling the module with no further options gives you the same defaults as the upstream `cheatshh.toml`.

## Options

### `programs.cheatshh.enable`
Type: `bool` — Default: `false`

Enable cheatshh and install the package.

---

### `programs.cheatshh.package`
Type: `package` — Default: `cheatshh.packages.${system}.default`

Override the cheatshh package to use.

---

### `programs.cheatshh.settings.copyCommand`
Type: `str` — Default: `"pbcopy"`

Shell command used to copy a selected command to the clipboard. The command receives the text on stdin:

```bash
printf "text" | $copyCommand
```

Common values:

| System | Value |
|---|---|
| macOS | `"pbcopy"` |
| Linux (X11) | `"xclip -selection clipboard"` |
| Linux (Wayland) | `"wl-copy"` |

---

### `programs.cheatshh.settings.displayGroupNumber`
Type: `int` — Default: `10`

Number of groups shown for reference in the whiptail dialog when adding or editing a command. Keep this small enough to fit the dialog without overflowing.

---

### `programs.cheatshh.settings.manPages`
Type: `bool` — Default: `false`

Automatically show man pages in the fzf preview pane. You can also toggle this per-invocation with the `-m` / `--man` flag.

---

### `programs.cheatshh.settings.cheatshhHome`
Type: `str` — Default: `"~/.config/cheatshh"`

Directory where `commands.json` and `groups.json` are stored. Use an absolute path to avoid issues. `cheatshh.toml` itself always lives in `~/.config/cheatshh` regardless of this setting.

---

### `programs.cheatshh.settings.notes`
Type: `str` — Default: `"tldr --color"`

Command used to display cheatsheet notes in the preview pane. Called as `$notes <command>`.

Common values:

```nix
settings.notes = "tldr --color";  # default
settings.notes = "cheat";
settings.notes = "curl cheat.sh";
settings.notes = "eg";
settings.notes = "bro";
```

---

### `programs.cheatshh.settings.fullDisplay`
Type: `"on"` or `"off"` — Default: `"on"`

Controls what appears in the fzf listing.

- `"on"` — shows ungrouped/bookmarked commands, group names, and `group/command` pairs
- `"off"` — shows only ungrouped/bookmarked commands and group names

---

### `programs.cheatshh.settings.previewWidth`
Type: `int` — Default: `70`

Width of the fzf preview pane as a percentage of the terminal width. The upstream default of `70` is recommended.

---

### `programs.cheatshh.colorScheme.titleColor`
Type: `str` — Default: `"\\033[0;36m"` (cyan)

ANSI escape code for the color of titles (e.g. `COMMAND/GROUP:`, `ABOUT:`) in the preview pane.

---

### `programs.cheatshh.colorScheme.aboutColor`
Type: `str` — Default: `"\\033[0;33m"` (yellow)

ANSI escape code for the color of descriptions and command names in the preview pane.

Common color codes:

| Color | Code |
|---|---|
| Cyan | `"\\033[0;36m"` |
| Yellow | `"\\033[0;33m"` |
| Green | `"\\033[0;32m"` |
| Red | `"\\033[0;31m"` |
| Blue | `"\\033[0;34m"` |
| Magenta | `"\\033[0;35m"` |
| White | `"\\033[0;37m"` |

## Full example

```nix
programs.cheatshh = {
  enable = true;
  settings = {
    copyCommand = "wl-copy";
    displayGroupNumber = 8;
    manPages = false;
    notes = "tldr --color";
    fullDisplay = "on";
    previewWidth = 70;
  };
  colorScheme = {
    titleColor = "\\033[0;32m";  # green
    aboutColor = "\\033[0;33m";  # yellow
  };
};
```

## How it works

- `cheatshh.toml` is generated from your options and placed at `~/.config/cheatshh/cheatshh.toml` as a Nix-store symlink. The app only reads this file, so the symlink is safe.
- `commands.json` and `groups.json` are seeded from the package defaults on first `home-manager switch` if they do not already exist. They are never overwritten, so commands you add at runtime are preserved across rebuilds.
