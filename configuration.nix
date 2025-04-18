{ pkgs, config, lib, inputs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.overlays = [
    (import ./overlays/brave-wrapper.nix)
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.marcogomez = import ./home.nix;



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Boot                                                                   │
  # └────────────────────────────────────────────────────────────────────────┘

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernelParams = [ "nvidia_drm.fbdev=1" "nvidia-drm.modeset=1" ];



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Nix Settings                                                           │
  # └────────────────────────────────────────────────────────────────────────┘

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    trusted-users = ["root" "marcogomez"];

    substituters = [
      "https://nix-shell.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs.cachix.org"
    ];

    trusted-public-keys = [
      "nix-shell.cachix.org-1:kat3KoRVbilxA6TkXEtTN9IfD4JhsQp1TPUHg652Mwc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Hardware Settings                                                      │
  # └────────────────────────────────────────────────────────────────────────┘

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true; # Modesetting is required.
    powerManagement.enable = false; # Experimental, can cause sleep/suspend to fail.
    powerManagement.finegrained = false; # Experimental, turns off GPU when not in use.
    nvidiaSettings = true; # Nvidia settings menu accessible via `nvidia-settings`
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = false;
    gsp.enable = true;
    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = false;
  };



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Services                                                               │
  # └────────────────────────────────────────────────────────────────────────┘

  # OpenSSH server
  services.openssh.enable = true;

  # Display manager
  users.users.greeter = {
    isSystemUser = true;
    description = "greetd login";
    shell = pkgs.bashInteractive;
    home = "/var/empty";
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.hyprland}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };


  # Pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire = {
      "10-default" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [ 48000 96000 192000 ];
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 128;
        };
      };
    };
  };

  services.udisks2.enable = true;

  # XDG Frontend
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };
  xdg.mime.enable = true;



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ System Settings                                                        │
  # └────────────────────────────────────────────────────────────────────────┘

  # Timezone
  time.timeZone = "Europe/London";

  # Locale
  i18n.defaultLocale = "en_GB.utf8";

  # Limits
  security.pam.loginLimits = [
    { domain = "@realtime"; item = "rtprio"; type = "soft"; value = "95"; }
    { domain = "@realtime"; item = "rtprio"; type = "hard"; value = "95"; }
    { domain = "@realtime"; item = "memlock"; type = "soft"; value = "unlimited"; }
    { domain = "@realtime"; item = "memlock"; type = "hard"; value = "unlimited"; }
  ];

  security.polkit.enable = true;



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Networking                                                             │
  # └────────────────────────────────────────────────────────────────────────┘

  networking.hostName = "threadripper";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;


  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Environment Settings                                                   │
  # └────────────────────────────────────────────────────────────────────────┘

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  # Variables
  environment.sessionVariables = {
    # Nvidia
     __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_DRM_NO_ATOMIC = "1"; # optional
    NVD_BACKEND = "direct";

    # Wayland
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    BRAVE_ENABLE_WAYLAND = "1";

    # GTK
    GTK_THEME = "adw-gtk3-dark";
    GTK_USE_PORTAL = "1";

    # Qt
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt5ct";  # Applies to both Qt5 and Qt6
    QT_STYLE_OVERRIDE = "kvantum";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # Cursors
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";

  };

  # 🖥️ System Packages
  environment.systemPackages = with pkgs; [
    # Basic stuff
    wget git git-lfs neovim llvm autoconf automake cmake ninja gettext gnumake
    meson clang gcc nasm curl gnupg most lsb-release gawk zsh tmux tree gnutar
    jq unzip ffmpeg bc fzf ripgrep zsh zsh-completions zsh-syntax-highlighting
    zsh-autosuggestions neofetch ghostty fd libtool bzip2 zip zlib plocate SDL
    SDL2 sdl3 fluidsynth timidity mesa libGLU glew mpg123 mpv btop libjpeg vlc
    libgme libsndfile libvpx flatpak cloudflared gh docker swww yt-dlp waybar
    docker-compose nvidia-container-toolkit imagemagick ffmpeg firefox  ardour
    prismlauncher dialog wl-clipboard vscode code-cursor raysession brave grim
    google-chrome oversteer obs-studio blender slurp prismlauncher winetricks
    protonup-ng gimp swappy discord-canary rofi-wayland glslang libdrm lazygit
    procs libdisplay-info xdg-utils shared-mime-info mime-types imv
    desktop-file-utils  kdePackages.polkit-kde-agent-1 kdePackages.dolphin
    kdePackages.kdenlive kdePackages.kservice

    # Theming
    noto-fonts-emoji noto-fonts
    qt5.qtwayland libsForQt5.qt5ct libsForQt5.qtstyleplugin-kvantum
    qt6.qtwayland qt6ct qt6Packages.qtstyleplugin-kvantum kdePackages.qt6ct
    adw-gtk3 gnome-themes-extra papirus-icon-theme catppuccin-kvantum
    gsettings-desktop-schemas lxappearance themechanger

    # Custom raysession wrapper with Wayland tweaks
    (pkgs.raysession.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/raysession \
          --set QT_QPA_PLATFORM wayland \
          --prefix QT_QPA_PLATFORM_PLUGIN_PATH : "${pkgs.qt5.qtbase}/lib/qt-5/plugins/platforms"
      '';
    }))

    # Python tooling
    (python3.withPackages (python-pkgs: with python-pkgs; [
      pandas
      pynvim
      ipython
    ]))

    # Google Cloud SDK extras
    (pkgs.google-cloud-sdk.withExtraComponents (
      with pkgs.google-cloud-sdk.components; [
        docker-credential-gcr
        beta
        alpha
        gsutil
        gke-gcloud-auth-plugin
        terraform-tools
        cloud-datastore-emulator
        cloud-firestore-emulator
        cloud-spanner-emulator
        pubsub-emulator
      ]
    ))
  ];



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Programs                                                               │
  # └────────────────────────────────────────────────────────────────────────┘

  # Enable the Wayland compositor
  programs.hyprland.enable = true;

  # Enable ZSH
  programs.zsh.enable = true;



  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ User Settings                                                          │
  # └────────────────────────────────────────────────────────────────────────┘

  users.users.marcogomez = {
    uid = 1000;
    isNormalUser = true;
    packages = with pkgs; [];
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" "audio" "realtime" ];
    linger = true;
  };

  users.groups.plocate = {};


  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Version                                                                │
  # └────────────────────────────────────────────────────────────────────────┘
  system.stateVersion = "24.11";
}