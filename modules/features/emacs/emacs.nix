{ self, inputs, ... }: {

  flake.nixosModules.emacs = { config, pkgs, lib, ... }: {
    options.custom.emacsPackage = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.myEmacs;
      description = "Which built Emacs package the host's daemon runs.";
    };

    config.services.emacs = {
      enable = true;
      package = config.custom.emacsPackage;
      defaultEditor = true;
    };

    config.environment.shellAliases = {
      e = "emacsclient -c -a ''"; # GUI
      et = "emacsclient -nw -a ''"; # terminal
    };
  };

  perSystem = { pkgs, ... }: {
    overlays = [ inputs.emacs-overlay.overlays.default ];

    packages.myEmacs = pkgs.emacsWithPackagesFromUsePackage {
      config = ./init.el;
      defaultInitFile = true;
      package = pkgs.emacs-pgtk;
      alwaysEnsure = true;
      alwaysTangle = true;
    };
  };
}
