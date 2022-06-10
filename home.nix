{ config, pkgs, lib, ... }:

let
  nvim-spell-en-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.vim.org/pub/vim/runtime/spell/en.utf-8.spl";
    sha256 = "0w1h9lw2c52is553r8yh5qzyc9dbbraa57w9q0r9v8xn974vvjpy";
  };

  nvim-spell-en-utf8-suggestions = builtins.fetchurl {
    url = "http://ftp.vim.org/pub/vim/runtime/spell/en.utf-8.sug";
    sha256 = "1v1jr4rsjaxaq8bmvi92c93p4b14x2y1z95zl7bjybaqcmhmwvjv";
  };

  # installs a vim plugin from git with a given tag / branch
  v-plug-git = ref: repo: pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "${lib.strings.sanitizeDerivationName repo}";
    version = ref;
    src = builtins.fetchGit {
      url = "https://github.com/${repo}.git";
      ref = ref;
    };
  };

  # always installs latest version
  v-plug = v-plug-git "HEAD";

  docstring-to-markdown = pkgs.python3Packages.buildPythonPackage rec {
    pname = "docstring-to-markdown";
    version = "0.9";

    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "0b810e6e16737d2d0ede6182f66f513f814a11fad1222e645fbc14acde78e171";
    };
  };

  jedi-language-server = pkgs.python3Packages.buildPythonPackage rec {
    pname = "jedi-language-server";
    version = "0.34.8";

    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "8cd2d5cc453ce3314c1cf4001d9590ae259b20b4ad6481ea2648a43162ba1566";
    };

    doCheck = false;
    propagatedBuildInputs = with pkgs; [
      python3Packages.pygls 
      python3Packages.jedi 
      docstring-to-markdown
    ];
  };


in {
  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
    path = "…";
  };

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "juanfraire";
  home.homeDirectory = "/Users/juanfraire";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
    (self: super: 
      {
        kitty = super.kitty.overrideAttrs (old: {
          patches = (old.patches or []) ++ [
            (super.fetchpatch {
              url = "https://raw.githubusercontent.com/NixOS/nixpkgs/9816857458874b4e0a9560f9296b3a6a341d3810/pkgs/applications/terminal-emulators/kitty/apple-sdk-11.patch";
              sha256 = "1fshai0prqmyqcq549xfb91i6akvb44ak6lmmjinv5c6rj37hr4a";
            })
          ];
        });
      }
    )
  ];

  programs.zsh = {
    enable = true;
    sessionVariables.EDITOR = "nvim";
    initExtra = ''
      export PATH=$HOME/bin:$PATH
      export TELEPORT_AUTH="okta"
      export TELEPORT_PROXY="teleport.internal.corp.traderepublic.com:443"

      . $HOME/.nix-profile/share/asdf-vm/asdf.sh
      . ~/.asdf/plugins/java/set-java-home.zsh
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [ "git asdf" ];
      theme = "robbyrussell";
    };
  };
  
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withRuby = true;
    withPython3 = true;
    coc.enable = true;
    coc.settings = { 
      suggest.echodocSupport =  true;
      suggest.maxCompleteItemCount=  20;
      coc.preferences.formatOnSaveFiletypes = [
        "javascript"
        "typescript"
        "typescriptreact"
        "json"
        "javascriptreact"
        "vue"
      ];
      eslint.filetypes = [
        "javascript"
        "typescript"
        "typescriptreact"
        "javascriptreact"
        "vue"
      ];
      diagnostic.errorSign = "•";
      diagnostic.warningSign = "•";
      diagnostic.infoSign =  "•";

      languageserver = {
        nix = {
          command = "rnix-lsp";
          filetypes = [ "nix" ]; 
        }; 
      }; 
    };

  # NEOVIM PACKAGES
    plugins = (with pkgs.vimPlugins; [
      tabular
      tcomment_vim
      vim-multiple-cursors
      vim-indent-guides
      vim-nix
      vim-javascript
      typescript-vim
      vim-jsx-typescript
      delimitMate
      vim-fugitive
      python-syntax
      vim-vue
      kotlin-vim
      vim-terraform


      (v-plug "hail2u/vim-css3-syntax")
      (v-plug "styled-components/vim-styled-components")
      (v-plug "github/copilot.vim")

      { plugin = vim-kitty-navigator;
        config = ''
          map ctrl+j ctrl+j kitten pass_keys.py neighboring_window bottom ctrl+j
          map ctrl+k kitten pass_keys.py neighboring_window top    ctrl+k
          map ctrl+h kitten pass_keys.py neighboring_window left   ctrl+h
          map ctrl+l kitten pass_keys.py neighboring_window right  ctrl+l
        '';
      }
      { plugin = coc-nvim;
        config = ''
          autocmd FileType typescript let b:coc_root_patterns = ['.eslintrc']
          autocmd FileType typescript.tsx let b:coc_root_patterns = ['.eslintrc']
          let g:coc_global_extensions = [
            \ 'coc-tsserver',
            \ 'coc-prettier',
            \ 'coc-eslint',
            \ 'coc-json',
            \ ]
          nmap <silent> gd <Plug>(coc-definition)
          nnoremap <silent> ,s :<C-u>CocList -I symbols<cr>
          nmap <silent> ,k <Plug>(coc-diagnostic-prev)
          nmap <silent> ,j <Plug>(coc-diagnostic-next)
          nmap <silent> ,d <Plug>(coc-codeaction)<CR>
          nnoremap <silent> ,, :call <SID>show_documentation()<CR>

          function! s:show_documentation()
            if (index(['vim','help'], &filetype) >= 0)
              execute 'h '.expand('<cword>')
            elseif (coc#rpc#ready())
              call CocActionAsync('doHover')
            else
              execute '!' . &keywordprg . " " . expand('<cword>')
            endif
          endfunction
        '';
      }
      coc-tsserver
      coc-eslint
      coc-prettier
      coc-json
      (v-plug "pappasam/coc-jedi")
      (v-plug "weirongxu/coc-kotlin")
      (v-plug "yaegassy/coc-volar")

      { plugin = vim-colors-solarized;
        config = ''
          set t_Co=256
          syntax enable
          set background=dark
          set colorcolumn=80
          set hlsearch
          colorscheme solarized
          hi! Normal ctermbg=NONE guibg=NONE
          hi! NonText ctermbg=NONE guibg=NONE guifg=NONE ctermfg=NONE
        '';
      }
      { plugin = vim-json;
        config = "let g:vim_json_syntax_conceal = 0";
      }
      { plugin = vim-mundo;
        config = "nnoremap <F5> :MundoToggle<CR>";
      }
      { plugin = fzf-vim;
        config = ''
          let g:fzf_layout = { 'window': '-tabnew' }
          nmap <silent> ,f :GFiles<CR>
        '';
      }
      { plugin = vim-surround;
        config = ''
          let g:surround_{char2nr('m')} = "\1Surround: \1\r\1\1"
          let g:surround_{char2nr('M')} = "\1S-Open: \1\r\2S-Close: \2"
        '';
      }
      { plugin = vim-indent-guides;
        config = "let g:indent_guides_enable_on_vim_startup = 1";
      }
      { plugin = vim-markdown;
        config = ''
          autocmd FileType markdown let g:indentLine_enabled=0
          autocmd FileType markdown setlocal conceallevel=0
          let g:vim_markdown_folding_disabled = 1
          let g:vim_markdown_conceal = 0
          let g:vim_markdown_fenced_languages = ['js=javascript', 'ts=typescript']
        '';
      }
      { plugin = lightline-vim;
        config = ''
          set laststatus=2
          let g:lightline = {
                \ 'colorscheme': 'solarized',
                \ 'mode_map': { 'c': 'NORMAL' },
                \ 'active': {
                \   'left': [ [ 'mode', 'paste' ], [ 'fugitive', 'filename' ] ]
                \ },
                \ 'component_function': {
                \   'modified': 'MyModified',
                \   'readonly': 'MyReadonly',
                \   'fugitive': 'MyFugitive',
                \   'filename': 'MyFilename',
                \   'fileformat': 'MyFileformat',
                \   'filetype': 'MyFiletype',
                \   'fileencoding': 'MyFileencoding',
                \   'mode': 'MyMode',
                \ },
                \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2"},
                \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" }
                  \ }

          function! MyModified()
            return &ft =~ 'help\|vimfiler\|mundo' ? "" : &modified ? '+' : &modifiable ? "" : '-'
          endfunction

          function! MyReadonly()
            return &ft !~? 'help\|vimfiler\|mundo' && &readonly ? "\ue0a2" : ""
          endfunction

          function! MyFilename()
            return ("" != MyReadonly() ? MyReadonly() . ' ' : "") .
                  \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
                  \  &ft == 'unite' ? unite#get_status_string() :
                  \  &ft == 'vimshell' ? vimshell#get_status_string() :
                  \ "" != expand('%:t') ? expand('%:t') : '[No Name]') .
                  \ ("" != MyModified() ? ' ' . MyModified() : "")
          endfunction

          function! MyFugitive()
            return &ft !~? 'vimfiler\|mundo' && exists('*fugitive#head') && strlen(fugitive#head()) ? "\ue0a0".fugitive#head() : ""
          endfunction

          function! MyFileformat()
            return winwidth('.') > 70 ? &fileformat : ""
          endfunction

          function! MyFiletype()
            return winwidth('.') > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ""
          endfunction

          function! MyFileencoding()
            return winwidth('.') > 70 ? (strlen(&fenc) ? &fenc : &enc) : ""
          endfunction

          function! MyMode()
            return winwidth('.') > 60 ? lightline#mode() : ""
          endfunction
        '';
      }
    ]);

    # NEOVIM CONFIGURATION
    extraConfig = ''
     " Encoding
     set encoding=UTF-8

     " 2 spaces for indenting
     set shiftwidth=2
     
     " 2 stops
     set tabstop=2

     " Disable mouse click to go to position
     set mouse-=a
     
     " Spaces instead of tabs
     set expandtab
     
     " Ignore files
     set wildignore+=*/bower_vendor_libs/**
     set wildignore+=*/vendor/**
     set wildignore+=*/node_modules/**
     set wildignore+=*/elm-stuff/**
     
     " Spell check
     set spell spelllang=en_us
     
     " Vim command line size
     set noshowmode
     
     " Numbers
     set number relativenumber
    '';
  };

  # SYSTEM PACKAGES
  home.packages = with pkgs; [
    # Misc
    jq
    fd
    dos2unix
    zsh-completions
    nix-zsh-completions
    tree
    coreutils
    nix-prefetch-github
    nixpkgs-fmt
    rnix-lsp
    direnv
    gnupg
    pandoc
    watchman
    bat
    ripgrep
    pre-commit
    asdf-vm

    # Python
    python2
    python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.requests
    poetry
    jedi-language-server
   
    # Ruby
    ruby

    # Hashi
    nodePackages.cdktf-cli
    tflint
    tfswitch

    # AWS
    aws-vault
    chamber
    awscli2
    aws-nuke
    awless
    eksctl

    # Node
    nodejs
    yarn
    nodePackages.node2nix

    # Docker
    docker
    docker-compose

    # K8s
    # kube3d # k3d
    # kind
    # krew
    # k9s
    # kail
    # kubectl
    # kubectl-example
    # kustomize
    # minikube
    # skaffold
    # kubeval
    # kompose
    # kubernetes-helm

    # CLIs
    _1password
    # teleport

    # Fonts
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
    fira-code
    # fira-mono
  ];

  home.file."${config.xdg.configHome}/nvim/spell/en.utf-8.spl".source = nvim-spell-en-utf8-dictionary;
  home.file."${config.xdg.configHome}/nvim/spell/en.utf-8.sug".source = nvim-spell-en-utf8-suggestions;

  programs.git = {
    enable = true;
    userName  = "Juan Gabriel Fraire Lopez";
    userEmail = "juan.lopez@traderepublic.com";
    extraConfig = {
      init.defaultBranch = "main";
      push.default = "current";
      pull.default = "current";
    };
    ignores = [''
      # General
      .DS_Store
      .AppleDouble
      .LSOverride

      # Icon must end with two \r
      Icon

      # Thumbnails
      ._*

      # Files that might appear in the root of a volume
      .DocumentRevisions-V100
      .fseventsd
      .Spotlight-V100
      .TemporaryItems
      .Trashes
      .VolumeIcon.icns
      .com.apple.timemachine.donotpresent

      # Directories potentially created on remote AFP share
      .AppleDB
      .AppleDesktop
      Network Trash Folder
      Temporary Items
      .apdisk
      .tool-versions
    ''];
    };

  #   programs.kitty = {
  #     enable = true;
  #     settings = {
  #       bold_font = "auto";
  #       italic_font = "auto";
  #       bold_italic_font = "auto";
  #       font_size = (if pkgs.stdenv.isDarwin then 14 else 12);
  #       strip_trailing_spaces = "smart";
  #       enable_audio_bell = "no";
  #       term = "xterm-256color";
  #       macos_titlebar_color = "background";
  #       macos_option_as_alt = "yes";
  #       scrollback_lines = 10000;
  #       # shell =  "/run/current-system/sw/bin/fish --login"; # TODO how to avoid hardcoding?
  #     };
  #     extraConfig = ''
  #       allow_hyperlinks yes
  #       allow_remote_control yes
  #       enable_audio_bell no
  #       tab_bar_style powerline
  #       enabled_layouts splits
  #     # open new split (window) with cmd+d retaining the cwd
  #       map cmd+d new_window_with_cwd
  #     # new split with default cwd
  #       map cmd+shift+d new_window
  #     # switch between next and previous splits
  #       map cmd+]        next_window
  #       map cmd+[        previous_window
  #     # jump to beginning and end of word
  #       map alt+left send_text all \x1b\x62
  #       map alt+right send_text all \x1b\x66
  #     # jump to beginning and end of line
  #       map cmd+left send_text all \x01
  #       map cmd+right send_text all \x05
  #     '';
  #   # font = {
  #   #   package = pkgs.jetbrains-mono;
  #   #   name = "JetBrains Mono";
  #   # };
  #   keybindings = {
  #     "ctrl+c" = "copy_or_interrupt";
  #   };
  # };
  programs.tmux = {
    enable = true;
    plugins = (with pkgs.tmuxPlugins; [
       { plugin = tmux-colors-solarized;
         extraConfig = "set -g @colors-solarized 'dark'";
       }
    ]);
    extraConfig = ''
      # $Id: screen-keys.conf,v 1.7 2010/07/31 11:39:13 nicm Exp $
      #
      # This configuration file binds many of the common GNU screen key bindings to
      # appropriate tmux key bindings. Note that for some key bindings there is no
      # tmux analogue and also that this set omits binding some commands available in
      # tmux but not in screen.
      #
      # Note this is only a selection of key bindings and they are in addition to the
      # normal tmux key bindings. This is intended as an example not as to be used
      # as-is.

      # Set the prefix to ^A.
      unbind C-b
      set -g prefix ^A
      bind a send-prefix

      # Disable timeout for escape key
      set-option -sg escape-time 0

      # Bind appropriate commands similar to screen.
      # lockscreen ^X x
      unbind ^X
      bind ^X lock-server
      unbind x
      bind x lock-server

      # screen ^C c
      unbind ^C
      bind ^C new-window -c '#{pane_current_path}'
      #bind c
      bind c new-window -c '#{pane_current_path}'

      unbind % # remove default binding since replacing
      bind v split-window -h -c '#{pane_current_path}'
      bind ^V split-window -h -c '#{pane_current_path}'
      bind h split-window -v -c '#{pane_current_path}'
      bind ^H split-window -v -c '#{pane_current_path}'

      # detach ^D d
      unbind ^D
      bind ^D detach

      # displays *
      unbind *
      bind * list-clients

      # next ^@ ^N sp n
      unbind ^@
      bind ^@ next-window
      unbind ^N
      bind ^N next-window
      unbind " "
      bind " " next-window
      unbind n
      bind n next-window

      # title A
      unbind A
      bind A command-prompt "rename-window %%"

      # other ^A
      unbind ^A
      bind ^A last-window

      # prev ^H ^P p ^?
      unbind ^H
      bind ^H previous-window
      unbind ^P
      bind ^P previous-window
      unbind p
      bind p previous-window
      unbind BSpace
      bind BSpace previous-window

      # windows ^W w
      unbind ^W
      bind ^W list-windows
      unbind w
      bind w list-windows

      # quit \
      #unbind \
      #bind \ confirm-before "kill-server"

      # kill K k
      unbind K
      bind K confirm-before "kill-window"
      unbind k
      bind k confirm-before "kill-window"

      # redisplay ^L l
      unbind ^L
      bind ^L refresh-client
      unbind l
      bind l refresh-client

      # :kB: focus up
      unbind Tab
      bind Tab select-pane -t:.+
      unbind BTab
      bind BTab select-pane -t:.-

      # " windowlist -b
      unbind '"'
      bind '"' choose-window

      # scrolling fix
      set -g terminal-overrides 'xterm*:smcup@:rmcup@'
      setw -g xterm-keys on

      # act like vim
      setw -g mode-keys vi

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind-key -r C-h select-window -t :-
      bind-key -r C-l select-window -t :+

      new-session

      unbind-key M-k      ; bind-key -n M-k   next-window
      unbind-key M-j      ; bind-key -n M-j   previous-window

      #set-window-option -g window-status-current-format ' #I:#W '
      #
      #Reload config
      bind R source-file ~/.tmux.conf \; display-message "Config reloaded..."

      # set first window to index 1 (not 0) to map more to the keyboard layout...
      set-option -g base-index 1
      set-window-option -g pane-base-index 1

      set -g default-terminal "screen-256color"

      # status bar colors etc
      set-option -g status-bg black
      set-option -g status-fg blue
      set-option -g status-interval 5
      set-option -g visual-activity on
      set-window-option -g monitor-activity on
      set-window-option -g window-status-current-fg white

      # statusbar settings - adopted from tmuxline.vim and vim-airline - Theme: murmur
      set -g status-justify "left"
      set -g status "on"
      set -g status-left-style "none"
      set -g message-command-style "fg=colour144,bg=colour237"
      set -g status-right-style "none"
      set -g pane-active-border-style "fg=colour27"
      set -g status-utf8 "on"
      set -g status-style "bg=colour234,none"
      set -g message-style "fg=colour144,bg=colour237"
      set -g pane-border-style "fg=colour237"
      set -g status-right-length "100"
      set -g status-left-length "100"
      setw -g window-status-activity-attr "none"
      setw -g window-status-activity-style "fg=colour27,bg=colour234,none"
      setw -g window-status-separator ""
      setw -g window-status-style "fg=colour39,bg=colour234,none"
      set -g status-left "#[fg=colour15,bg=colour27] #S #[fg=colour27,bg=colour234,nobold,nounderscore,noitalics]"
      set -g status-right "#[fg=colour237,bg=colour234,nobold,nounderscore,noitalics]#[fg=colour144,bg=colour237] %H:%M  %d/%m/%Y#[fg=colour27,bg=colour237,nobold,nounderscore,noitalics]#[fg=colour15,bg=colour27] #h "
      setw -g window-status-format "#[fg=colour39,bg=colour234] #I #[fg=colour39,bg=colour234] #W "
      setw -g window-status-current-format "#[fg=colour234,bg=colour237,nobold,nounderscore,noitalics]#[fg=colour144,bg=colour237] #I #[fg=colour144,bg=colour237] #W #[fg=colour237,bg=colour234,nobold,nounderscore,noitalics]"
    '';
  };
}
