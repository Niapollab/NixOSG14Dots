{ config, pkgs, lib, ... }:

{
  imports = [
    "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/asus/zephyrus/ga402x/amdgpu"
    "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/asus/zephyrus/ga402x/nvidia"
    ./constants.nix
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot = {
    kernel = {
      sysctl = {
        "vm.dirty_bytes" = 4 * 1024 * 1024;
        "vm.dirty_background_bytes" = 4 * 1024 * 1024;
      };
    };
    # kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxPackages_6_12;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
    plymouth = {
      enable = true;
    };
    initrd.verbose = false;
    consoleLogLevel = 0;
    kernelParams = [
      "amd_iommu=on"
      "boot.shell_on_fail"
      "loglevel=3"
      "quiet"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "splash"
      "udev.log_priority=3"
    ];
  };

  # Memory
  zramSwap.enable = true;
  swapDevices = [{
    device = "/swapfile";
    size = 24 * 1024;
  }];

  # Network settings
  networking = {
    networkmanager.enable = true;
    hostName = config.constants.hostName;
    firewall = {
      # Prevent Docker bypasses NixOS firewall exposing ports on the external interface
      # Required: virtualization.docker.extraOptions = "--iptables=false --ip6tables=false";
      # See: https://github.com/NixOS/nixpkgs/issues/111852
      extraCommands = ''
        iptables -N DOCKER-ISOLATION-STAGE-1
        iptables -N DOCKER-ISOLATION-STAGE-2
        iptables -N DOCKER
        iptables -N FALLBACK-FW

        iptables -A FORWARD -j DOCKER-ISOLATION-STAGE-1
        iptables -A DOCKER-ISOLATION-STAGE-1 -i docker0 ! -o docker0 -j DOCKER-ISOLATION-STAGE-2
        iptables -A DOCKER-ISOLATION-STAGE-1 -j RETURN

        iptables -A DOCKER-ISOLATION-STAGE-2 -o docker0 -j DROP
        iptables -A DOCKER-ISOLATION-STAGE-2 -j RETURN

        iptables -A FORWARD -j DOCKER
        iptables -A DOCKER -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        iptables -A DOCKER -i docker0 -j ACCEPT
        iptables -A DOCKER -j RETURN

        iptables -A FORWARD -j FALLBACK-FW
        iptables -A FALLBACK-FW -j DROP

        iptables -t nat -N DOCKER-POSTROUTING

        iptables -t nat -A POSTROUTING -j DOCKER-POSTROUTING
        iptables -t nat -A DOCKER-POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
        iptables -t nat -A DOCKER-POSTROUTING -j RETURN
      '';
      # Fix problems with Nekoray DNS resolving
      # See: https://github.com/MatsuriDayo/nekoray/issues/1437
      checkReversePath = false;
    };
  };

  hardware = {
    # Enable scanning support
    sane.enable = true;
    # Fix issue with screen flickering
    asus.zephyrus.ga402x.amdgpu.psr.enable = false;
    # Enable Nvidia containers in Docker
    nvidia-container-toolkit.enable = true;
    # Bluetooth settings
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    fira-code
  ];

  # Set your time zone
  time.timeZone = "Europe/Moscow";

  # TTY console settings
  console = {
    packages = with pkgs; [ terminus_font ];
    font = "ter-v32n";
    keyMap = "ruwin_alt_sh-UTF-8";
  };

  # PTY console settings
  # It necessary if default terminal was deleted
  xdg.terminal-exec = {
    enable = true;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "ru_RU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "ru_RU.UTF-8";
      LC_IDENTIFICATION = "ru_RU.UTF-8";
      LC_MEASUREMENT = "ru_RU.UTF-8";
      LC_MONETARY = "ru_RU.UTF-8";
      LC_NAME = "ru_RU.UTF-8";
      LC_NUMERIC = "ru_RU.UTF-8";
      LC_PAPER = "ru_RU.UTF-8";
      LC_TELEPHONE = "ru_RU.UTF-8";
      LC_TIME = "ru_RU.UTF-8";
    };
  };

  security.rtkit.enable = true;

  # Sets QT theme
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users = {
      ${config.constants.mainUser.nickname} = {
        isNormalUser = true;
        description = config.constants.mainUser.fullname;
        extraGroups = [
          "networkmanager"
          "wheel"
          "docker"
          "lp"
          "scanner"
          "libvirtd"
          "qemu-libvirtd"
        ];
      };
    };
  };

  # List of programs
  programs = {
    firefox.enable = true;
    steam.enable = true;
    zsh.enable = true;
    direnv.enable = true;
    virt-manager.enable = true;
    nautilus-open-any-terminal = {
      enable = true;
      terminal = "alacritty";
    };
    git = {
      enable = true;
      lfs.enable = true;
    };
  };

  # List of services
  services = {
    printing.enable = true;
    libinput.enable = true;
    zerotierone.enable = true;
    earlyoom.enable = true;
    blueman.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager = {
        gnome = {
          enable = true;
          # Override GDM interface settings
          extraGSettingsOverridePackages = [ pkgs.mutter ];
          extraGSettingsOverrides = ''
            [org.gnome.mutter]
            experimental-features=['scale-monitor-framebuffer']
            [org.gnome.desktop.interface]
            scaling-factor=2
            accent-color='pink'
            cursor-theme='Bibata-Modern-Ice'
          '';
        };
      };
      xkb = {
        model = "pc105";
        layout = "us,ru";
        options = "grp:win_space_toggle";
      };
      excludePackages = [
        pkgs.xterm
      ];
    };
    # Enable sound with pipewire.
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };

  # Virtualization
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        vhostUserPackages = with pkgs; [ virtiofsd ];
      };
    };
    docker = {
      enable = true;
      storageDriver = "btrfs";
      extraOptions = "--iptables=false --ip6tables=false";
    };
  };

  # Allow unfree packages and unstable channel
  nixpkgs = {
    config = {
      allowUnfree = true;
      packageOverrides = pkgs: {
        unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
          config.allowUnfree = true;
        };
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    localBinInPath = true;
    systemPackages = with pkgs; [
      (papirus-icon-theme.override { color = "pink"; })
      (unstable.vscode.override { commandLineArgs = "--ozone-platform=wayland"; }).fhs
      adw-gtk3
      alacritty
      aria2
      bat
      bibata-cursors
      brightnessctl
      btop
      delta
      eza
      fastfetch
      fzf
      gimp
      gnome-mines
      gnome-tweaks
      gnomeExtensions.blur-my-shell
      gnomeExtensions.caffeine
      gnomeExtensions.fuzzy-app-search
      gnomeExtensions.just-perfection
      gnomeExtensions.pano
      gnomeExtensions.tray-icons-reloaded
      imhex
      inkscape
      jadx
      jq
      looking-glass-client
      ltrace
      micro
      mission-center
      mitmproxy
      ncdu
      nekoray
      obs-studio
      pokeget-rs
      qbittorrent
      remmina
      rnote
      scrcpy
      shotcut
      smile
      tenacity
      tlrc
      unstable.ayugram-desktop
      unstable.devenv
      unstable.ghidra
      unstable.nwg-look
      unstable.vesktop
      vlc
      wireshark
      zoxide
    ];
    gnome = {
      excludePackages = with pkgs; [
        # Browser
        epiphany
        gnome-connections
        gnome-console
        gnome-logs
        gnome-maps
        gnome-music
        gnome-music
        gnome-tour
        # Video player
        totem
        # Gnome manual viewer
        yelp
      ];
    };
    sessionVariables = {
      # See https://gitlab.gnome.org/GNOME/mutter/-/issues/2969
      # And https://discussion.fedoraproject.org/t/window-appears-with-a-delay/136157/16
      # Use integrated GPU for gnome-shell
      __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
      __GLX_VENDOR_LIBRARY_NAME = "mesa";
      GSK_RENDERER = "gl";

      XCURSOR_THEME = "Bibata-Modern-Ice";

      # Fix scale in Java applications
      # _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2";

      # Support 256 colors in TTY
      TERM = "xterm-256color";
      COLORTERM = "truecolor";
    };
    shellAliases = {
      system-prune = "nix-store --gc";
      system-rebuild = "sudo nixos-rebuild switch";
      system-update = "system-rebuild --upgrade";

      nix-try = "nix-shell --run \"$SHELL\" --packages";
      nix-try-unstable = "nix-shell -I 'nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz' --run \"$SHELL\" --packages";

      goto-multi-user = "sudo systemctl isolate multi-user.target; exit";
      goto-graphical = "sudo systemctl isolate graphical.target; exit";

      fastfetch = "${pkgs.pokeget-rs}/bin/pokeget random --shiny --hide-name | ${pkgs.fastfetch}/bin/fastfetch --file-raw -";
      neofetch = "fastfetch";

      nvidia-passthrough = "sudo modprobe -r nvidia_drm nvidia_uvm nvidia_modeset nvidia && sudo modprobe vfio vfio_iommu_type1 vfio_pci && sudo virsh nodedev-detach pci_0000_01_00_0 && sudo virsh nodedev-detach pci_0000_01_00_1";
      nvidia-reattach = "sudo virsh nodedev-reattach pci_0000_01_00_1 && sudo virsh nodedev-reattach pci_0000_01_00_0 && sudo modprobe -r vfio_pci vfio_iommu_type1 vfio && sudo modprobe nvidia_drm nvidia_uvm nvidia_modeset nvidia";
      nvidia-run = "__GLX_VENDOR_LIBRARY_NAME=nvidia __NV_PRIME_RENDER_OFFLOAD=1";
    };
  };

  # Extra options
  nix = {
    extraOptions = ''
      extra-substituters = https://devenv.cachix.org https://nixpkgs-python.cachix.org
      extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU=
    '';
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11";
}
