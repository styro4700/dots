{ self, inputs, ... }: {
  flake.nixosModules.bomberUsers = { ... }: {
    users.users.root.hashedPasswordFile = "/persist/passwords/root";
    users.users.alice = {
      isNormalUser = true;
      description = "alice";
      extraGroups = [ "networkmanager" "wheel" ];
      uid = 1000;
      hashedPasswordFile = "/persist/passwords/alice";
    };

    environment.persistence."/persist".users.alice.directories = [
      "dots"
      "Documents"
      ".config/emacs/var" # no-littering
    ];
    environment.persistence."/persist".users.alice.files = [ ];

    home-manager.users.alice = {
      imports = [
        self.homeManagerModules.emacs
	self.homeManagerModules.latex
        self.homeManagerModules.bash
      ];

      home.stateVersion = "26.05";
    };
  };
}
