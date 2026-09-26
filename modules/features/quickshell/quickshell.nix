{ self, inputs, ... }: {

  perSystem = { pkgs, ... }: {

    packages.myQuickshell = inputs.wrapper-modules.wrappers.quickshell.wrap {
      inherit pkgs;
      configDir = pkgs.runCommand "quickshell-config" { } ''
        mkdir -p $out
        cp -r ${./qml}/* $out/
        cat > $out/Theme.qml <<'EOF'
        import QtQuick

        QtObject {
            readonly property color bg: "${self.theme.base00}"
            readonly property color dim: "${self.theme.base03}"
            readonly property color mid: "${self.theme.base05}"
            readonly property color fg: "${self.theme.base06}"
            readonly property color bright: "${self.theme.base07}"
            readonly property color red: "${self.theme.red}"
            readonly property color green: "${self.theme.green}"
            readonly property color yellow: "${self.theme.yellow}"
        }
        EOF
        cat > $out/WallpaperPath.qml <<'EOF'
        import QtQuick

        QtObject {
            readonly property string path: "file://${self.wallpaper}"
        }
        EOF
      '';
    };
  };
}
