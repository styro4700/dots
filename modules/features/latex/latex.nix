{ self, inputs, ... }: {

  flake.nixosModules.latex = { config, pkgs, lib, ... }: {
    environment.systemPackages = [
        (pkgs.texliveSmall.withPackages (ps: with ps; [
	  latexmk
	  mathtools
	  physics
	  siunitx
	  mhchem
	  listings
	  xetex
	  polyglossia
	  preview
	  dvisvgm
      ]))
      pkgs.zathura
    ];

    environment.etc."yasnippets/LaTeX-mode".source = ./snippets/LaTeX-mode;

    custom.emacsPackage = lib.mkDefault
      self.packages.${pkgs.stdenv.hostPlatform.system}.myEmacsLatex;
  };

  perSystem = { pkgs, ... }: {
    packages.myEmacsLatex = pkgs.emacsWithPackagesFromUsePackage {
      config = pkgs.runCommand "init.el" { } ''
        cat ${../emacs/init.el} ${./latex.el} > $out
      '';
      defaultInitFile = true;
      package = pkgs.emacs-pgtk;
      alwaysEnsure = true;
      alwaysTangle = true;
    };
  };

}
