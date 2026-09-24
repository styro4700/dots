{ self, inputs, ... }: {

  flake.homeManagerModules.emacs = { config, pkgs, lib, ... }: {
    options.custom.emacs = {
      package = lib.mkOption {
        type = lib.types.package;
	default = self.packages.${pkgs.stdenv.hostPlatform.system}.myEmacs;
	description = ''
	  Which built Emacs package this user's daemon runs. Importing
	  homeManagerModules.latex overrides this to the LaTeX build.
      	  '';
        };

      daemon.enable = lib.mkOption {
        type = lib.types.bool;
	default = true;
	description = ''
	  Whether to run Emacs as this user's systemd daemon. Disable
	  it if you prefer to launch Emacs manually.
	'';
      };
    };

    config = {
      home.packages = [ config.custom.emacs.package ];

      services.emacs = {
        enable = config.custom.emacs.daemon.enable;
	package = config.custom.emacs.package;
	defaultEditor = true;
      };

      home.shellAliases = {
        e = "emacsclient -c -a ''";
	et = "emacsclient -nw -a ''";
      };
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
