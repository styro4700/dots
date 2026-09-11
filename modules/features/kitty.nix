{ self, inputs, ... }: {

  flake.nixosModules.kitty = {
    # enables ncurses-based stuff (emacs, tmux, ...) to resolve $TERM,
    # they dont open otherwise
    environment.enableAllTerminfo = true;
  };

  perSystem = { pkgs, lib, self', ... }: {

    packages.myKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
      inherit pkgs;

      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };

      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
        confirm_os_window_close = 0;
        window_padding_width = 6;
        hide_window_decorations = true;
      };

      keybindings = {
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+t" = "new_tab";
      };

      # anything the module doesn't have a typed option for yet
      extraConfig = ''
        # raw kitty.conf lines
      '';
    };

  };

}
