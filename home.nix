{ config, pkgs, ... }:

{
  home.username = "seb";
  home.homeDirectory = "/Users/seb";
  home.stateVersion = "23.11";

  home.packages = [
    # Indexing / search dependencies
    pkgs.fd
    (pkgs.ripgrep.override {withPCRE2 = true;})

    # Font / icon config
    # Added FiraCode as an example, it's not used in the config example.
    pkgs.emacs-all-the-icons-fonts
    pkgs.fontconfig
    (pkgs.nerdfonts.override {fonts = [ "FiraCode" ];})

    pkgs.nixfmt # :lang nix
  ];

  # Required to autoload fonts from packages installed via Home Manager
  fonts.fontconfig.enable = true;

  # Note that session variables and path can be a bit wonky to get going. To be
  # on the safe side, logging out and in again usually works.
  # Otherwise, to fast-track changes, run:
  # . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
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

  # Note! This must match $DOOMDIR
  xdg.configFile."doom".source = ./doom;

  # Note! This must match $EMACSDIR
  xdg.configFile."emacs".source = builtins.fetchGit {
    url = "https://github.com/doomemacs/doomemacs.git";
    rev = "03d692f129633e3bf0bd100d91b3ebf3f77db6d1";
  };
}
