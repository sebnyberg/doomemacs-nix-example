# doomemacs-nix-example

Example of Doom Emacs + Nix Flakes + Home Manager.

## How to use

* Copy over relevant sections of the flake / home.nix to your own setup.
* Replace `./doom/` contents with your config
* Run `home-manager switch --flake .`
* Restart the terminal or `source ~/.nix-profile/etc/profile.d/hm-session-vars.sh`
* Ensure that `$DOOMDIR` etc. pont to the right location, then run `doom install`
* Continuously run `home-manager switch --flake` and `doom sync` when your environment changes

## Background

There is a community project that aims to simplify Doom in Nix at
[nix-community/nix-doom-emacs](https://github.com/nix-community/nix-doom-emacs),
but as of writing (early 2024), it has been broken for more than a year.

Most of the discussions about using Doom and Nix seem to conclude that the
pragmatic approach is to let Doom do its thing outside of Nix.

For example, `hlissner`, the creator of Doom,
[runs a script to download Doom](https://github.com/hlissner/dotfiles/blob/089f1a9da9018df9e5fc200c2d7bef70f4546026/modules/editors/emacs.nix)
but does not sync or install Doom as part of his Nix configuration. There are
plenty more dotfile repo examples that use this approach.

## Doom's installation process

In order to set up Doom for Nix, it's good to understand how Doom is normally installed:

1. Install Emacs
2. Download Doom to `~/.config/emacs` (used to be `~/.emacs.d`)
3. Run `doom install`, or rather `~/.config/emacs/bin/doom install`
4. Run `doom sync` after changes to env-vars or Doom configuration.

Step 1 and 2 can be performed with Nix. Additionally, doom configuration files
whose location are specified by `$DOOMDIR` (containing `packages.el` etc.) can
also be managed by Nix. Any time the files change, reload your configuration.

Step 3 and 4 does installation of a bunch of Emacs packages to `$DOOMLOCALDIR`.
The synchronization additionally initializes a profile at
`$DOOMPROFILELOADFILE`. If Emacs and Doom was setup using Nix, then the default
location of both these locations will be symlinked nix-store targets that are
read-only, causing Doom installation and sync to fail.

### Installation with Nix

Set the following environment variables:

```bash
EMACSDIR=$XDG_CONFIG_HOME/emacs
PATH=$PATH:$EMACSDIR/bin
DOOMDIR=$XDG_CONFIG_HOME/doom
DOOMLOCALDIR=$XDG_DATA_HOME/doom
DOOMPROFILELOADFILE=$XDG_STATE_HOME/doom-profiles-load.el
```

> *Note: these XDG variables come from the most recent
> [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).
> If you're on Mac - don't fret! Home-manager makes these available to us anyway.*

Then, using Nix:

- Install Emacs
- Download Doom Emacs to `$EMACSDIR`
- Symlink personal Doom configuration to `$DOOMDIR`

Then drop into a Nix shell with the environment variables above available, and
run `doom install` + `doom sync`. Due to `$DOOMLOCALDIR` and
`$DOOMPROFILELOADFILE`, the mutable output of these commands will end up outside
the Nix-controlled area of disk.

## Nix example

This repository has a standalone Nix flake example that only sets up a basic
Doom Emacs installation using home-manager.

Please note that:

1. Any time your Doom configuration or environment variables change in a
   significant way, you must re-build the current home-manager generation, and
   run `doom sync`
2. As you add packages to your Doom configuration, you must also add
   corresponding system packages to Nix (just as you normally would). I suggest
   running `doom doctor` continously to spot possible problems.

> *If someone has a good way to continuously run doom sync, please let me know.
> I found [this setup](https://discourse.nixos.org/t/advice-needed-installing-doom-emacs/8806/8)
> on the Doom Emacs Discourse, but haven't had time to make it work yet.*

Please see [./home.nix](home.nix).

## How this example was set up

In case someone wants to reproduce, below are the steps I took to set up this
example.

Set up Home-manager + flake.nix + home.nix:

```bash
# Home-manager manual:
# https://archive.is/WEjGr#sec-install-standalone
# Since this is a Git repo, this command will fail and complain about a missing
# flake.nix. That's fine. It will still give us "home-manager" in our path.
nix run home-manager/release-23.11 -- init --switch $(pwd)
git add .
home-manager switch --flake $(pwd)
```

Add Emacs29:

```nix
# ... inside home.nix
  home.sessionVariables = {
    DOOMDIR = "${config.xdg.configHome}/doom";
    EMACSDIR = "${config.xdg.configHome}/emacs";
    DOOMLOCALDIR = "${config.xdg.dataHome}/doom";
    DOOMPROFILELOADFILE = "${config.xdg.stateHome}/doom-profiles-load.el";
  };
  home.sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];

  programs.home-manager.enable = true;
  programs.zsh.enable = true;
  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs29;

  # Note! This must correspond to $EMACSDIR
  xdg.configFile."emacs".source = builtins.fetchGit {
    url = "https://github.com/doomemacs/doomemacs.git";
    rev = "03d692f129633e3bf0bd100d91b3ebf3f77db6d1";
  };
# ...
```

Re-build the configuration:

```bash
# Reload home-manager configuration
home-manager switch --flake .

# Ensure that session has been re-started so that $PATH, $DOOMDIR etc all have
# the expected values. Logging out/in usually works, restarting the terminal
# usually works, but sourcing the session vars always works:
source ~/.nix-profile/etc/profile.d/hm-session-vars.sh

# Run doom install once. This will generate an initial user configuration at
# $DOOMDIR. I'll copy these files into this repo and start managing them using
# Nix instead. If this fails, double and triple-check $PATH, $EMACSDIR etc.
doom install
doom sync
emacs
```

Doom Emacs now runs, but with various issues. Next I copy the default doom
configuration:

```nix
# ...inside home.nix
  xdg.configFile."doom".source = ./doom;
# ...
```

```bash
mv $DOOMDIR .
git add doom
home-manager switch --flake .

# Check that the symlink is in place
# Output:
# lrwxr-xr-x  1 seb  staff    75B Jan  4 11:38 /Users/seb/.config/doom -> /nix/store/iy3bfhsnbhnbkjswj1a9bp0lq18db55a-home-manager-files/.config/doom
ls -lah ~/.config/doom
```

To test a change, I un-commented `;; nix` inside `init.el`, then

```bash
home-manager switch --flake .
# nix grep looks ok
# Output:
#       nix               ; I hereby declare "nix geht mehr!"
grep "nix" ~/.config/doom/init.el

# Doom sync should pull down some nix packages..
# And it did!
doom sync
```

Finally, run `doom doctor` to spot various packages that are missing and use Nix
Search to find candidates that might help. Please note that there will be
platform-specific requirements that I have omitted from this example for
brevity.

```nix
# ... snip
  home.packages = [
    # Indexing / search dependencies
    pkgs.fd
    (pkgs.ripgrep.override {withPCRE2 = true;})

    # Font / icon config
    # Added FiraCode as an example, it's not used in config.el.
    pkgs.emacs-all-the-icons-fonts
    pkgs.fontconfig
    (pkgs.nerdfonts.override {fonts = [ "FiraCode" ];})

    pkgs.nixfmt # :lang nix
  ];

  # Required to autoload fonts from packages installed via Home Manager
  fonts.fontconfig.enable = true;
# ...
```
