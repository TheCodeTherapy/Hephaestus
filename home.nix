{ config, pkgs, ... }: {
  home.username = "marcogomez";
  home.homeDirectory = "/home/marcogomez";
  home.stateVersion = "24.11";

  home.file.".config/rofi/rounded.rasi".source = ./dotfiles/rofi/rounded.rasi;
  home.file.".config/rofi/config.rasi".text = ''
    @theme "rounded"
  '';

  home.file.".config/ghostty/config".source = ./dotfiles/ghostty/config;
  home.file.".config/ghostty/shaders/_crt.frag".source = ./dotfiles/ghostty/shaders/_crt.frag;
  home.file.".local/share/ghostty/themes/catppuccin-mocha".source = ./dotfiles/ghostty/themes/catppuccin-mocha;
  home.file.".config/Code/User/settings.json".source = ./dotfiles/vscode/settings.json;
  home.file.".raysessions/.keep".text = "";

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "i3";
    XKB_DEFAULT_LAYOUT = "us";
    XKB_DEFAULT_VARIANT = "intl";
    GDK_DPI_SCALE = "1.0";
    GDK_SCALE = "1";
    PAGER = "most";
    ROFI_CONFIG = "${config.home.homeDirectory}/.config/rofi/rounded.rasi";
    RAYSESSION_PATH = "${config.home.homeDirectory}/.raysessions";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Adwaita";
      cursor-size = 32;
      font-name = "JetBrainsMono Nerd Font 12";
      document-font-name = "JetBrainsMono Nerd Font 12";
      monospace-font-name = "JetBrainsMono Nerd Font 12";
    };
  };

  home.file.".config/neofetch/config.conf".text = ''
    print_info() {
      info title
      info underline
      info " ╭─" kernel
      info " ├─" distro
      info " ├─" users
      info " ├─󰏗" packages
      info " ╰─" shell
      echo
      info " ╭─" term
      info " ├─" de
      info " ├─" wm_theme
      info " ├─" wm
      info " ├─" term_font
      info " ├─" font
      info " ├─󰂫" theme
      info " ╰─󰂫" icons
      echo
      info " ╭─" model
      info " ├─󰍛" cpu
      info " ├─󰍹" gpu
      info " ├─" gpu_driver
      info " ├─" resolution
      info " ├─" memory
      info " ├─" disk
      info " ╰─󰄉" uptime
      info cols
    }
  '';



  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    shellAliases = {
      waystop = "hyprctl dispatch exit";
      wayreload = "hyprctl reload";
      ll = "ls -hl";
      la = "ls -hlA";
      update = "cd ~/Hephaestus && sudo nixos-rebuild switch --flake \".#threadripper\"";
    };
    initExtra = ''
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

      # Run neofetch on interactive login
      if [[ $- == *i* ]]; then
        echo && neofetch
      fi

      # Enable per-prefix history search using arrow keys
      bindkey '^[OA' history-substring-search-up   # Up
      bindkey '^[[A' history-substring-search-up   # Up
      bindkey '^[OB' history-substring-search-down # Down
      bindkey '^[[B' history-substring-search-down # Down

      # Set theme manually if using powerlevel10k
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };
}