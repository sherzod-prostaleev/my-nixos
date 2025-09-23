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

  # ⚡ X99 platformasi uchun eng zo'r gaming kernel - XanMod
  boot.kernelPackages = pkgs.linuxPackages_xanmod;

  # 🚀 CPU Performance optimizatsiya - Kernel parametrlari
  boot.kernelParams = [
    # CPU Performance optimizatsiya
    "processor.max_cstate=5"
    "intel_idle.max_cstate=5"
    "clocksource=tsc"
    "nohpet"
    "mitigations=off"
    "nowatchdog"
    "mce=ignore_ce"
    "tsc=reliable"
    "nmi_watchdog=0"
    "processor.ignore_ppc=1"

    # GPU optimizatsiya (RX 5700 XT)
    "amdgpu.ppfeaturemask=0xffffffff"
    "amdgpu.gpu_recovery=1"
    "amdgpu.dc=1"
    "amdgpu.vm_fault_stop=1"
    "amdgpu.vm_debug=0"
    "radeon.si_support=0"
    "radeon.cik_support=0"

    # I/O optimizatsiya
    "pci=pcie_bus_perf"
    "pcie_aspm=performance"

    # Memory optimizatsiya
    "transparent_hugepage=always"
    "page_alloc.shuffle=1"
  ];

  # 🎮 GPU drayverini ertaroq yuklash (Early KMS)
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.initrd.availableKernelModules = [ "amdgpu" "xhci_pci" "ahci" "usbhid" "sd_mod" ];

  # 💾 Unumdorlikni oshirish uchun tmpfs'da vaqtinchalik fayllar papkasini yaratish
  boot.tmp.useTmpfs = true; # Vaqtinchalik o'chirildi
  boot.tmp.tmpfsSize = "16G";

  # 📁 NTFS fayl tizimini qo'llab-quvvatlash
  boot.supportedFilesystems = [ "ntfs" ];

  # 🔧 Qo'shimcha kernel modullari
  boot.kernelModules = [ "msr" "cpufreq_performance" "tcp_bbr" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

  # 🖥️ Kompyuter nomi
  networking.hostName = "nixos";

  # 🌐 Tarmoqni yoqish
  networking.networkmanager.enable = true;

  # ⏰ Vaqt mintaqasi
  time.timeZone = "Asia/Tashkent";

  # 🌍 Xalqaro sozlamalar
  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.supportedLocales = [
    "ru_RU.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];

  # ⌨️ Klaviatura sozlamalari
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  # 🎯 X11 va GNOME sozlamalari
  services.xserver = {
    enable = true;
    # 🎮 AMD GPU drayverlari
    videoDrivers = [ "amdgpu" ];
  };

  # GNOME ish stoli muhiti (yangi joyda)
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  services.desktopManager.gnome.enable = true;

  # 💎 AMD GPU to'liq qo'llab-quvvatlash
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      mesa
      amdvlk
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      rocmPackages.clr.icd
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      driversi686Linux.amdvlk
      vulkan-loader
    ];
  };

  # 🔥 GPU va CPU monitoring uchun
  hardware.sensor.iio.enable = true;

  # 📡 Uskunalar uchun proshivkalarni yoqish
  hardware.enableRedistributableFirmware = true;

  # 🖨️ Skaner va printer
  hardware.sane.enable = true;
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # 🔊 Ovoz tizimi - Pipewire (tez va sifatli)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # Audio performance optimizatsiya
    extraConfig = {
      pipewire = {
        "99-optimizations.conf" = {
          "context.properties" = {
            "link.max-buffers" = 16;
            "log.level" = 2;
          };
        };
      };
    };
  };

  # 👤 Foydalanuvchi hisobi
  users.users.sher = {
    isNormalUser = true;
    description = "sher";
    extraGroups = [
      "networkmanager" "wheel" "video" "audio" "input"
      "gamemode" "kvm"
      "scanner" "lp"
    ];
    shell = pkgs.zsh;
  };

  # 🔐 GNOME Keyring
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;

  # 🌐 Firefox brauzerini yoqish
  programs.firefox.enable = true;

  # 💰 Litsenziyasi bepul bo'lmagan dasturlarga ruxsat berish
  nixpkgs.config.allowUnfree = true;

  # 🎮 O'yinlar uchun to'liq sozlamalar
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
        softrealtime = "auto";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.coreutils}/bin/echo 'GameMode started'";
        end = "${pkgs.coreutils}/bin/echo 'GameMode ended'";
      };
    };
  };

# BUTUNLAY O'CHIRISH KERAK:
# 🖥️ Virtualizatsiya - BU QISMINI BUTUNLAY OLIB TASHANG
# virtualisation.docker = {
#   enable = true;
#   storageDriver = "btrfs";
#   daemon.settings = {
#     storage-opts = [ "size=20G" ];
#   };
# };
# 
# virtualisation.libvirtd = {
#   enable = true;
#   qemu = {
#     package = pkgs.qemu_kvm;
#     runAsRoot = true;
#     swtpm.enable = true;
#   };
# };

  # ⚡ Tizimga o'rnatiladigan dasturlar ro'yxati
  environment.systemPackages = with pkgs; [
    # --- TIZIM VOSITALARI ---
    wget curl git htop btop neofetch
    unzip unrar p7zip tree killall
    pciutils usbutils lshw
    clinfo
    lact
    amdgpu_top
    cpupower-gui
    stress-ng
    vkmark
    glmark2

    # --- TERMINAL ---
    tmux
    gnome-terminal

    # --- DASTURLASH VOSITALARI ---
    vscode gcc cmake gnumake
    python3
    nodejs_20
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    rustc cargo go
    docker-compose

    # --- TARMOQ VOSITALARI ---
    filezilla
    rustdesk
    anydesk

    # --- BRAUZERLAR ---
    google-chrome
    chromium
    brave

    # --- MESSENJERLAR ---
    telegram-desktop
    discord

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
    libstrangle

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
    v4l-utils guvcview
    pavucontrol helvum

    # --- GRAFIKA MUHARRIRLARI ---
    gimp-with-plugins
    darktable
    audacity

    # --- FAYL MENEJERLARI ---
    nautilus

    # --- YUKLASH MENEJERLARI ---
    qbittorrent
    aria2
    yt-dlp

    # --- TIZIM MONITORINGI ---
    radeontop
    lm_sensors
    iotop
    nethogs

    # --- GNOME UCHUN QO'SHIMCHA VOSITALAR ---
    gnome-tweaks
    gnome-shell-extensions
    dconf-editor
    gnome-software
    gnome-boxes
    gnome-text-editor # <-- MATN MUHARRIRI
    baobab
    seahorse
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
    gnomeExtensions.tiling-assistant
  ];

  # 🧹 GNOME'dan olib tashlanadigan standart dasturlar
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    gnome-connections
    simple-scan
    totem
    yelp
    gnome-maps
    gnome-weather
    gnome-music
  ];

  services.gnome.core-apps.enable = false;

  # 🔤 Shriftlar
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      carlito
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-emoji
      jetbrains-mono
      cantarell-fonts
      source-code-pro
      ubuntu_font_family
      noto-fonts-cjk-sans
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Cantarell" "Liberation Sans" ];
        monospace = [ "JetBrains Mono" "Source Code Pro" ];
      };
    };
  };

  # 💾 SSD optimizatsiya
  services.fstrim.enable = true;
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # 🌡️ CPU haroratini boshqarish
  services.thermald.enable = true;

  # XATO TUZATILDI: systemd.extraConfig o'rniga systemd.settings.Manager ishlatish
  systemd.settings.Manager.DefaultLimitNOFILE = 1048576;

  # 🔗 ROCm libraries uchun symlink
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -     -     -      -   ${pkgs.rocmPackages.clr}"
  ];

  # ⚙️ AMD GPU overclock/undervolt uchun LACT
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  # 🚀 Kernel sysctl optimizatsiyalari
  boot.kernel.sysctl = {
    # Memory optimizatsiya
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.dirty_expire_centisecs" = 3000;

    # Network optimizatsiya
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_syncookies" = 1;

    # File system optimizatsiya
    "fs.file-max" = 2097152;
  };

  # ⚡ Quvvat boshqaruvi - CPU Performance mode
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  services.upower.enable = true;
  services.power-profiles-daemon.enable = false; # CPU performance uchun o'chiramiz

  # 💾 Xotirani yaxshiroq boshqarish uchun zram'ni yoqish
  zramSwap.enable = true;
  zramSwap.memoryPercent = 25;

  # 🛠️ Qo'shimcha dasturlar
  programs.mtr.enable = true;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  # 🐟 Shell sozlamalari
  programs.fish.enable = true;
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git" "kubectl" "npm" "node" "python" "rust" "golang"
        "vscode" "terraform" "ansible" "systemd" "sudo"
      ];
    };
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # 🌟 Starship terminal promp'i
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

  # 📂 GNOME Virtual File System
  services.gvfs.enable = true;

  # 🔒 Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 24800 ]; # SSH, HTTP, HTTPS, RustDesk
    allowedUDPPorts = [ 24800 ];
  };

  # 🎮 Gaming performance uchun environment variables
  environment.variables = {
    # Vulkan optimizatsiya
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json";

    # Wine optimizatsiya
    WINEDEBUG = "-all";
    WINEESYNC = "1";
    WINEFSYNC = "1";

    # Mesa optimizatsiya
    mesa_glthread = "true";

    # Gaming optimizatsiya
    DRI_PRIME = "1";
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_PATH = "/tmp/shadercache";

    # MangoHud
    # MANGOHUD = "1"; # Barcha dasturlarda chiqmasligi uchun o'chirildi
    # MANGOHUD_CONFIG = "cpu_temp,gpu_temp,core_load,ram,vram,fps,frame_timing"; # Bu ham o'chirildi
  };

  # 🚀 CPU performance uchun kernel scheduler optimizatsiya
  boot.kernelPatches = [{
    name = "cpu-scheduler-optimization";
    patch = null;
    extraConfig = ''
      SCHED_MC y
      SCHED_SMT y
      CPU_FREQ_DEFAULT_GOV_PERFORMANCE y
      PREEMPT_VOLUNTARY n
      PREEMPT y
      PREEMPT_COUNT y
    '';
  }];

  # 📦 NixOS optimizatsiyalari - TUZATILGAN VERSIYA
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      
      # Cache'ni to'liq to'g'irlash
      trusted-substituters = [
        "https://cache.nixos.org"
      ];
      
      substituters = [
        "https://cache.nixos.org"
      ];
      
      # Public key to'g'irlanadi
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system.stateVersion = "25.05";
}
