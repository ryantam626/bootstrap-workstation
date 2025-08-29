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
}
