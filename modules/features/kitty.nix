{ self, inputs, ... }: {

  flake.nixosModules.kitty = { pkgs, lib, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.myKitty
    ];
  };

  perSystem = { pkgs, lib, self', ... }: {

    packages.myKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
      inherit pkgs;

      font = {
        name = "JetBrainsMono Nerd Font";
        size = 11;
      };

      themeFile = "Catppuccin-Mocha";

      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
        confirm_os_window_close = 0;
        window_padding_width = 6;
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
