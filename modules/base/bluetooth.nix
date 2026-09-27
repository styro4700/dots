{ self, inputs, ... }: {
  flake.bluetoothEnabled = true;

  flake.nixosModules.bluetooth = { pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true; # GTK tray applet + pairing UI
  };
}
