{ self, inputs, ... }: {
  
 flake.nixosModules.bomberHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports =
      [ (modulesPath + "/installer/scan/not-detected.nix")
      ];
  
    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ "amdgpu" "tcp_bbr" ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
  
    fileSystems."/" =
      { device = "/dev/mapper/enc";
        fsType = "btrfs";
        options = [ "subvol=root" "compress=zstd" "noatime" ];
      };
  
    boot.initrd.luks.devices."enc".device = "/dev/disk/by-uuid/fb9f7d3a-9bf3-40b3-bd53-4319c38f07cd";
  
    fileSystems."/home" =
      { device = "/dev/mapper/enc";
        fsType = "btrfs";
        options = [ "subvol=home"  "compress=zstd" "noatime" ];
      };
  
    fileSystems."/nix" =
      { device = "/dev/mapper/enc";
        fsType = "btrfs";
        options = [ "subvol=nix" "compress=zstd" "noatime" ];
      };
  
    fileSystems."/persist" =
      { device = "/dev/mapper/enc";
        fsType = "btrfs";
        options = [ "subvol=persist" "compress=zstd" "noatime" ];
        neededForBoot = true;
      };
  
    fileSystems."/var/log" =
      { device = "/dev/mapper/enc";
        fsType = "btrfs";
        options = [ "subvol=log" "compress=zstd" "noatime" ];
        neededForBoot = true;
      };
  
    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/6DD7-3A05";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
  
    swapDevices =
      [ { device = "/dev/disk/by-partuuid/929839c9-9732-4c14-ac56-ddee0fb845e9";
          randomEncryption = true; }
      ];
  
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  }; 

}
