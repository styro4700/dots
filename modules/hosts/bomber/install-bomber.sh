#!/usr/bin/env bash
# modules/hosts/bomber/install.sh
#
# Installs NixOS for the `bomber` host from the minimal NixOS ISO:
# partitions + encrypts the disk (disko), sets the login passwords, and runs
# nixos-install. Everything it does is announced as it happens.
#
# Usage, from the booted minimal ISO (UEFI mode), with network up:
#   curl -O https://raw.githubusercontent.com/styro4700/dots/main/modules/hosts/bomber/install.sh
#   bash install.sh
#
# Overridable: REPO_URL, BRANCH.
set -euo pipefail

HOST="bomber"
USERS=(alice root)                 # accounts that get a password file
MAIN_USER="alice"                  # gets a copy of the repo in ~/dots
MAIN_USER_UID=1000
MAIN_USER_GID=100                  # "users" group
REPO_URL="${REPO_URL:-https://github.com/styro4700/dots}"
BRANCH="${BRANCH:-main}"
WORKDIR="/tmp/dots"
PERSIST="/mnt/persist"
LUKS_NAME="cryptroot"              # must match disko.nix

export NIX_CONFIG="experimental-features = nix-command flakes"

# ---------------------------------------------------------------- output ----
if [[ -t 1 ]]; then B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'; else B=""; G=""; Y=""; R=""; N=""; fi
TOTAL=8; N_STEP=0
step() { N_STEP=$((N_STEP + 1)); printf '\n%s==> [%d/%d] %s%s\n' "$B$G" "$N_STEP" "$TOTAL" "$1" "$N"; }
info() { printf '    %s\n' "$1"; }
warn() { printf '%s    ! %s%s\n' "$Y" "$1" "$N"; }
die()  { printf '%s\nERROR: %s%s\n' "$R" "$1" "$N" >&2; exit 1; }
trap 'printf "%s\nFailed at line %s: %s\nNothing after this point ran. Fix the problem and re-run the script (it is safe to re-run).%s\n" "$R" "$LINENO" "$BASH_COMMAND" "$N" >&2' ERR

# --------------------------------------------------------------- preflight --
if [[ $EUID -ne 0 ]]; then
  info "Not root; re-running this script with sudo."
  exec sudo -E bash "$0" "$@"
fi

printf '%sInstalling NixOS host "%s"%s\n' "$B" "$HOST" "$N"
info "Repo:   $REPO_URL (branch $BRANCH)"
info "Users:  ${USERS[*]}"

# ------------------------------------------------------------------ step 1 --
step "Checking that the ISO was booted in UEFI mode"
[[ -d /sys/firmware/efi ]] || die "Not booted in UEFI mode. Reboot and pick the UEFI entry for the USB stick in the boot menu (F12)."
info "UEFI firmware detected."

# ------------------------------------------------------------------ step 2 --
step "Checking the network"
info "Any working connection is fine (ethernet or wifi); testing by reaching github.com."
online=false
for attempt in 1 2 3 4 5 6; do   # ethernet can take a few seconds to get an address after boot
  if curl -fsS --max-time 5 -o /dev/null https://github.com 2>/dev/null; then online=true; break; fi
  info "Not reachable yet (attempt $attempt/6), waiting 5s..."
  sleep 5
done
$online || die "No working internet connection. Plug in ethernet, or join wifi ('nmcli device wifi connect <SSID> --ask'), then re-run."
IFACE="$(ip -o route get 1.1.1.1 2>/dev/null | sed -n 's/.* dev \([^ ]*\).*/\1/p' | head -n1)"
info "Online${IFACE:+ via $IFACE}."

# ------------------------------------------------------------------ step 3 --
step "Fetching the configuration"
info "Cloning $REPO_URL into $WORKDIR (any previous copy is replaced)."
rm -rf "$WORKDIR"
git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"
info "Checked out commit $(git rev-parse --short HEAD): $(git log -1 --format=%s)"
FLAKE="$WORKDIR#$HOST"

# ------------------------------------------------------------------ step 4 --
step "Reading the target disk from the configuration"
info "Evaluating the flake (this downloads the inputs and can take a minute)."
DISK="$(nix eval --raw "$WORKDIR#nixosConfigurations.$HOST.config.disko.devices.disk.main.device")"
[[ -b "$(readlink -f "$DISK")" ]] || die "Disk $DISK from disko.nix does not exist on this machine. Check 'ls -l /dev/disk/by-id' and fix disko.nix."
info "disko.nix says the target disk is: $DISK"
echo
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS "$(readlink -f "$DISK")"
echo
warn "EVERYTHING on this disk will be permanently erased, including any Windows install."
read -rp "    Type WIPE to erase it and continue, anything else aborts: " answer
[[ "$answer" == "WIPE" ]] || die "Aborted, nothing was changed."

# ------------------------------------------------------------------ step 5 --
step "Partitioning, encrypting and mounting the disk (disko)"
info "Layout: 1 GB ESP (/boot) + LUKS2 volume with btrfs subvolumes root, nix, persist."
info "You will be asked to choose the LUKS passphrase (needed at every boot). Do not forget it."
umount -R /mnt 2>/dev/null || true
cryptsetup close "$LUKS_NAME" 2>/dev/null || true
info "You already confirmed the wipe above, so disko's own prompt is skipped (--yes-wipe-all-disks)."
nix run github:nix-community/disko/latest -- --mode destroy,format,mount --yes-wipe-all-disks --flake "$FLAKE"
mountpoint -q /mnt/persist || die "/mnt/persist is not mounted after disko; the layout in disko.nix does not match what this script expects."
info "Disk ready and mounted under /mnt."

# ------------------------------------------------------------------ step 6 --
step "Creating the login password files in /persist/passwords"
info "Passwords are stored as yescrypt hashes; the config reads them at boot (hashedPasswordFile)."
mkdir -p "$PERSIST/passwords"
chmod 700 "$PERSIST/passwords"
for user in "${USERS[@]}"; do
  while true; do
    read -rsp "    Password for $user: " pw1; echo
    read -rsp "    Repeat password for $user: " pw2; echo
    if [[ -n "$pw1" && "$pw1" == "$pw2" ]]; then break; fi
    warn "Empty or not matching, try again."
  done
  (umask 077; printf '%s' "$pw1" | nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt -s > "$PERSIST/passwords/$user")
  chmod 600 "$PERSIST/passwords/$user"
  info "Wrote $PERSIST/passwords/$user"
done
unset pw1 pw2

# ------------------------------------------------------------------ step 7 --
step "Seeding persistent state"
info "Creating a machine-id in /persist/etc, so the first boot has a real one to bind-mount."
mkdir -p "$PERSIST/etc"
[[ -s "$PERSIST/etc/machine-id" ]] || systemd-machine-id-setup --root="$PERSIST"
HOME_DIR="$PERSIST/home/$MAIN_USER"
info "Copying the config repo to /persist/home/$MAIN_USER/dots so it is in ~/dots on first boot."
mkdir -p "$HOME_DIR"
cp -a "$WORKDIR" "$HOME_DIR/dots"
chown -R "$MAIN_USER_UID:$MAIN_USER_GID" "$HOME_DIR"

# ------------------------------------------------------------------ step 8 --
step "Installing NixOS (nixos-install)"
info "Builds the system from the flake and installs it, plus GRUB, onto /mnt. This is the long step."
info "Root has no separate prompt: its password comes from /persist/passwords/root."
nixos-install --root /mnt --flake "$FLAKE" --no-root-passwd
sync

trap - ERR
printf '\n%sInstall finished.%s\n' "$B$G" "$N"
info "Next: run 'reboot', remove the USB stick, and enter the LUKS passphrase at boot."
info "If the firmware shows no NixOS entry, pick it from the boot menu (F12)."
info "After logging in: 'touch /imperm-test', reboot once, and check the file is gone."
