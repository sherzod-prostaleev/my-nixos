{ config, pkgs, lib, ... }:

{
  imports =
    [ # Uskunalarni skanerlash natijalarini qo'shish.
      ./hardware-configuration.nix
    ];

  # Bootloader (Yuklovchi)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "max";

  # X99 platformasi uchun optimallashtirilgan eng so'nggi Zen yadrosini ishlatish
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Yadro parametrlari (Kernel parameters)
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "mitigations=off"
    "amdgmu.ppfeaturemask=0xffffffff"
  ];

  # Yuqori ruxsatli yuklash ekrani uchun AMD GPU drayverini ertaroq yuklash (Early KMS)
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.availableKernelModules = [ "amdgpu" ];

  # Unumdorlikni oshirish uchun tmpfs'da vaqtinchalik fayllar papkasini yaratish
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "16G";

  # NTFS fayl tizimini qo'llab-quvvatlash
  boot.supportedFilesystems = [ "ntfs" ];

  # Kompyuter nomi
  networking.hostName = "nixos";

  # Tarmoqni yoqish (Wi-Fi bo'lmasa ham, simli tarmoq uchun kerak)
  networking.networkmanager.enable = true;

  # Vaqt mintaqasi
  time.timeZone = "Asia/Tashkent";

  # Xalqaro sozlamalar (Internationalisation)
  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.supportedLocales = [
    "ru_RU.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];

  # X11 oynalar tizimini GNOME bilan birga yoqish
  services.xserver.enable = true;

  # GNOME ish stoli muhitini yoqish
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true; # Wayland'ni yoqish
  services.xserver.desktopManager.gnome.enable = true;


  # GNOME bilan bog'liq xizmatlar
  services.gnome = {
    gnome-keyring.enable = true;
    gnome-browser-connector.enable = true;
  };
  programs.dconf.enable = true;

  # X11 uchun klaviatura sozlamalari (TTY va login ekrani uchun saqlab qolindi)
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  # AMD GPU (RX 5700 XT) sozlamalari
  services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      mesa
      amdvlk
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      driversi686Linux.amdvlk
    ];
  };


  # Uskunalar uchun proshivkalarni (firmware) yoqish
  hardware.enableRedistributableFirmware = true;


  # Skaner
  hardware.sane.enable = true;

  # Printer
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Ovoz tizimi uchun Pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Foydalanuvchi hisobi
  users.users.sher = {
    isNormalUser = true;
    description = "sher";
    extraGroups = [
      "networkmanager" "wheel" "video" "audio" "input"
      "gamemode" "docker" "libvirtd" "kvm" 
      "scanner" "lp"
    ];
  };


  # Tizimga kirganda GNOME Keyring'ni avtomatik ochish
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;

  # Firefox brauzerini yoqish
  programs.firefox.enable = true;

  # Litsenziyasi bepul bo'lmagan dasturlarga ruxsat berish
  nixpkgs.config.allowUnfree = true;

  # Flatpak
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # O'yinlar uchun sozlamalar
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 7;
        inhibit_screensaver = 1;
        defaultgov = "performance";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # Virtualizatsiya
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.libvirtd.enable = true;

  # Tizimga o'rnatiladigan dasturlar ro'yxati
  environment.systemPackages = with pkgs; [
    # --- TIZIM VOSITALARI ---
    wget curl git htop btop neofetch
    unzip unrar p7zip tree killall
    pciutils usbutils lshw
    clinfo
    lact 

    # --- TERMINAL ---
    kitty
    tmux

    # --- DASTURLASH VOSITALARI ---
    vscode vim gcc cmake gnumake
    python3Full
    nodejs_20
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    rustc cargo go
    docker-compose

    # --- MA'LUMOTLAR BAZASI VOSITALARI ---
    dbeaver-bin
    mysql-workbench
    pgadmin4

    # --- TARMOQ VOSITALARI ---
    filezilla
    rustdesk

    # --- BRAUZERLAR ---
    google-chrome
    chromium
    brave

    # --- MESSENJERLAR ---
    telegram-desktop

    # --- OFIS DASTURLARI ---
    libreoffice-fresh
    hunspell
    hunspellDicts.ru_RU
    hunspellDicts.en_US

    # --- O'YIN VOSITALARI ---
    lutris
    (bottles.override { removeWarningPopup = true; })
    wine-staging
    winetricks
    protontricks
    mangohud
    goverlay
    vkbasalt
    gamescope
    libstrangle # FPSni cheklash uchun

    # --- EMULATORLAR ---
    pcsx2
    dolphin-emu

    # --- MEDIA PLEYERLAR ---
    vlc mpv celluloid

    # --- VIDEO ISHLASH VA STRIMING ---
    obs-studio
    obs-studio-plugins.obs-vkcapture
    obs-studio-plugins.obs-vaapi
    obs-studio-plugins.obs-gstreamer
    obs-studio-plugins.obs-backgroundremoval
    ffmpeg-full

    # --- VEB-KAMERA VA MIKROFON VOSITALARI ---
    v4l-utils cheese guvcview
    pavucontrol helvum

    # --- GRAFIKA MUHARRIRLARI ---
    gimp-with-plugins
    inkscape
    darktable
    audacity

    # --- FAYL MENEJERLARI ---
    mc
    ranger

    # --- YUKLASH MENEJERLARI ---
    qbittorrent
    aria2
    yt-dlp
    fragments # GNOME uchun torrent klient

    # --- TIZIM MONITORINGI ---
    radeontop
    lm_sensors

    # --- GNOME UCHUN QO'SHIMCHA VOSITALAR ---
    gnome-tweaks
    gnome-shell-extensions
    dconf-editor
    gnome-software
    gnome-boxes
    baobab # Disk hajmini analiz qiluvchi vosita
    seahorse # GNOME kalitlar ombori (GUI)
    pdfsam-basic

    # --- GNOME SHELL KENGAYTMALARI ---
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.vitals
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-history
    gnomeExtensions.gsconnect
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.user-themes
  ];

  # GNOME'dan olib tashlanadigan standart dasturlar
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany # GNOME Web
    gnome-connections
    simple-scan
    totem # Videos
    yelp # Help
  ];

  # Shriftlar
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      carlito
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-emoji
      jetbrains-mono
      cantarell-fonts # GNOME standart shrifti
      source-code-pro
      ubuntu_font_family
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Cantarell" "Liberation Sans" ];
        monospace = [ "JetBrains Mono" "Source Code Pro" ];
      };
    };
  };

  # SSD uchun TRIM xizmatini yoqish
  services.fstrim.enable = true;

  # SSD uchun optimallashtirish
  fileSystems."/".options = [ "noatime" "nodiratime" ];

  # CPU haroratini boshqarish uchun thermald'ni yoqish
  services.thermald.enable = true;

  # O'yinlar uchun ochiq fayllar limitini oshirish
  systemd.extraConfig = ''
    DefaultLimitNOFILE=1048576
  '';
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=1048576
  '';

  # Most software has the HIP libraries hard-coded. You can work around it on NixOS by using:
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # This application allows you to overclock, undervolt, set fans curves of AMD GPUs on a Linux system. 
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];
  #services.lact.enable = true;


  # Yadro parametrlarini optimallashtirish
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
  };

  # Quvvat boshqaruvi
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Xotirani yaxshiroq boshqarish uchun zram'ni yoqish
  zramSwap.enable = true;

  # Qo'shimcha dasturlar
  programs.mtr.enable = true;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  programs.fish.enable = true; # Fish shell
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git" "docker" "kubectl" "npm" "node" "python" "rust" "golang"
        "vscode" "terraform" "ansible"
      ];
    };
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Starship (zamonaviy terminal promp'i)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$all$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  # GNOME Virtual File System (GVFS)
  services.gvfs.enable = true;

  # Firewall (Xavfsizlik devori)
  networking.firewall.enable = true;

  # Tizim versiyasi
  system.stateVersion = "25.05";
}
