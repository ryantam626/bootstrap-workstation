{ lib, config, pkgs, ... }:

let
  username = "rtam";
  git-author-name = "Ryan Tam";
  git-email = "ryantam626@gmail.com";
in {
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";


  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
   pkgs.jq
   pkgs.curl
   pkgs.cascadia-code
   pkgs.kmonad
   pkgs.go-task
   pkgs.wl-clipboard
   (pkgs.stdenv.mkDerivation rec {
    pname = "uv";
    version = "latest";
    src = pkgs.fetchurl {
    url = "https://github.com/astral-sh/uv/releases/download/0.8.14/uv-x86_64-unknown-linux-gnu.tar.gz";
    sha256 = "954add045f29f93191523175e4aea066996840e86c1b6339dee25f48b15b5ddb";
    };
    installPhase = ''
    mkdir -p $out/bin
    cp uv $out/bin/
    chmod +x $out/bin/uv
    '';
    })
  pkgs.go_1_24
  pkgs.gnome46Extensions."user-theme@gnome-shell-extensions.gcampax.github.com"
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/rtam/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "/home/${username}/.nix-profile/bin/zsh";
  };

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;

    fzf.enable = true;
    fzf.enableZshIntegration = true;
    lsd.enable = true;
    lsd.enableZshIntegration = false;
    zoxide.enable = true;
    zoxide.enableZshIntegration = true;

    git = {
      enable = true;
      userEmail = "${git-email}";
      userName = "${git-author-name}";
      extraConfig = {
        push = {
          default = "current";
          autoSetupRemote = true;
        };
        stash = {
          showPatch = true;
        };
        rebase = {
          autosquash = true;
        };
        pull = {
          rebase = true;
        };
        rerere = {
          enabled = true;
        };
        core = {
          pager = "less -+F";
        };
      };
    };
    zsh = {
      enable = true;
      syntaxHighlighting = { enable = true; };
      initContent = let initExtraFirst = lib.mkOrder 500 ''
	# Add whatever you want here to be at the top of zshrc
      ''; initExtra = lib.mkOrder 1000 ''
        eval "$(task --completion zsh)"

        # Edit current line
        autoload -U edit-command-line
        zle -N edit-command-line
        bindkey '^[e' edit-command-line
      ''; in lib.mkMerge [ initExtraFirst initExtra ];
      shellAliases = {
        copy = "wl-copy";
        clc = "git rev-parse HEAD | copy";
        "gc-" = "git checkout -";
        gcn = "git commit --no-verify";
        gcor = "gco $(grecent | fzf)";
        gcm = "git checkout $(git_main_branch)";
        grecent =
          "git for-each-ref --sort=-committerdate --count=20 --format='%(refname:short)' refs/heads/";
        gsh = "git show";
        rbm = "git rebase $(git_main_branch) -i";
        rt = "gb | grep rt.";
        vim = "nvim";
      };
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [ "git" "zoxide" ];
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      extraConfig = ''
        luafile ${./dotfiles/nvim/nvim.lua}
      '';
    };
    tmux = let
      tmux-nord = pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "nord";
        version = "0.3.0";
        src = pkgs.fetchFromGitHub {
          owner = "nordtheme";
          repo = "tmux";
          rev = "v0.3.0";
          hash = "sha256-s/rimJRGXzwY9zkOp9+2bAF1XCT9FcyZJ1zuHxOBsJM=";
        };
      }; in {
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      enable = true;
      terminal = "screen-256color";
      keyMode = "vi";
      prefix = "C-a";
      historyLimit = 100000;
      plugins = with pkgs; [
        tmuxPlugins.sensible
        tmux-nord
        {
          plugin = tmuxPlugins.yank;
          extraConfig = ''
            set -g @yank_selection_mouse 'clipboard'
            set -g @override_copy_command 'wl-copy'
          '';
        }
        {
          plugin = tmuxPlugins.tmux-thumbs;
          extraConfig = ''
            set -g @thumbs-key v
            set -g @thumbs-position left
            set -g @thumbs-command 'wl-copy'
          '';
        }
      ];
      extraConfig = ''
        # Split panes using Prefix+- and Prefix+_ instead of Prefix+" and Prefix+%
        bind-key _ split-window -h -c '#{pane_current_path}'
        bind-key - split-window -v -c '#{pane_current_path}'
        unbind-key '"'
        unbind-key '%'

        # Pane nav
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'"
        bind-key -n 'M-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        bind-key -n 'M-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        bind-key -n 'M-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        bind-key -n 'M-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

        bind-key -T copy-mode-vi 'M-h' select-pane -L
        bind-key -T copy-mode-vi 'M-j' select-pane -D
        bind-key -T copy-mode-vi 'M-k' select-pane -U
        bind-key -T copy-mode-vi 'M-l' select-pane -R

        # Create window with Ctrl+T instead of Prefix+c
        bind -n C-t new-window
        unbind-key 'c'

        # Alt+[ for copy mode
        bind -n M-[ copy-mode

        # Move to new window with Alt+Shift+H/L
        bind-key -n M-H previous-window
        bind-key -n M-L next-window

        # Setup 'v' to begin selection as in Vim
        bind-key -T copy-mode-vi v send -X begin-selection

        # make colors inside tmux look the same as outside of tmux
        # see https://github.com/tmux/tmux/issues/696
        # see https://stackoverflow.com/a/41786092
        set-option -ga terminal-overrides ",xterm-256color:Tc"
        # bg color of active pane, https://www.color-hex.com/color-palette/1029048, darkest
        setw -g window-active-style 'bg=#292e39'
      '';
    };
  };

  systemd.user.services.kmonad = {
    Unit = {
      Description = "KMonad keyboard remapper";
      Documentation = "https://github.com/kmonad/kmonad";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kmonad}/bin/kmonad %h/bootstrap-workstation/dotfiles/kmonad/star-laptop.kbd";
      Restart = "on-failure";
      RestartSec = 3;

      PrivateNetwork = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [ "/dev/uinput" ];
    };
  };

  systemd.user.services."kmonad-ducky" = {
    Unit = {
      Description = "KMonad keyboard remapper for ducky keyboard";
      Documentation = "https://github.com/kmonad/kmonad";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kmonad}/bin/kmonad %h/bootstrap-workstation/dotfiles/kmonad/ducky.kbd";
      Restart = "on-failure";
      RestartSec = 3;

      PrivateNetwork = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [ "/dev/uinput" ];
    };
  };

  home.file = {
    ".local/share/wallpapers".source = ./wallpapers;
    ".local/share/themes/rtam".source = ./dotfiles/themes/rtam;
    ".local/share/gnome-shell/extensions/disable-workspace-animation@ethnarque".source = "${pkgs.gnomeExtensions.disable-workspace-animation}/share/gnome-shell/extensions/disable-workspace-animation@ethnarque";
    ".local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com".source = "${pkgs.gnome46Extensions."user-theme@gnome-shell-extensions.gcampax.github.com"}/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com";
  };

  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;

      disabled-extensions = [
        "ubuntu-dock@ubuntu.com"
      ];

      enabled-extensions = [
        "disable-workspace-animation@ethnarque"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];

    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "rtam";
    };

    "org/gnome/desktop/interface" = {
      cursor-theme = "Nordzy-cursors-white";
      cursor-size = 24;
    };

    "org/gnome/desktop/wm/preferences" = {
      theme = "Nordzy-cursors-white";
    };

    "org/gnome/shell" = {
      cursor-theme = "Nordzy-cursors-white";
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      delay = lib.hm.gvariant.mkUint32 201;
      repeat-interval = lib.hm.gvariant.mkUint32 27;
    };
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 5;
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/${username}/.local/share/wallpapers/dunkirk.png";
      picture-uri-dark = "file:///home/${username}/.local/share/wallpapers/dunkirk.png";
      picture-options = "zoom";
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      switch-to-workspace-5 = ["<Super>5"];

      move-to-workspace-1 = ["<Super><Shift>1"];
      move-to-workspace-2 = ["<Super><Shift>2"];
      move-to-workspace-3 = ["<Super><Shift>3"];
      move-to-workspace-4 = ["<Super><Shift>4"];
      move-to-workspace-5 = ["<Super><Shift>5"];

      switch-to-workspace-left = [];
      switch-to-workspace-right = [];
    };

    "org/gnome/shell/keybindings" = let empty = lib.hm.gvariant.mkEmptyArray "s"; in {
      switch-to-application-1 = empty;
      switch-to-application-2 = empty;
      switch-to-application-3 = empty;
      switch-to-application-4 = empty;
      switch-to-application-5 = empty;
      open-new-window-application-1 = empty;
      open-new-window-application-2 = empty;
      open-new-window-application-3 = empty;
      open-new-window-application-4 = empty;
      open-new-window-application-5 = empty;
    };
  };

  home.pointerCursor = {
    name = "Nordzy-cursors-white";
    package = pkgs.nordzy-cursor-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
