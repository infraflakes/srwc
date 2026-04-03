{
  description = "srwm — a trackpad-first infinite canvas Wayland compositor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      nativeBuildInputs = with pkgs; [
        pkg-config
      ];

      buildInputs = with pkgs; [
        wayland
        wayland-protocols
        seatd # libseat
        libdisplay-info
        libinput
        libgbm
        libxkbcommon
        libdrm
        systemd # libudev
        libglvnd
        libx11
        libxcursor
        libxrandr
        libxi
        libxcb
        pixman
      ];

      runtimeLibs = with pkgs; [
        wayland
        seatd
        libdisplay-info
        libinput
        libgbm
        libxkbcommon
        libdrm
        systemd
        libglvnd
        libx11
        libxcursor
        libxrandr
        libxi
        libxcb
        pixman
      ];
    in
    {
      packages.${system}.default = pkgs.rustPlatform.buildRustPackage rec {
        pname = "srwm";
        version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            let baseName = builtins.baseNameOf path;
            in baseName != "target" && baseName != ".git" && baseName != ".direnv";
        };

        cargoLock = {
          lockFile = ./Cargo.lock;
          outputHashes = {
            "smithay-drm-extras-0.1.0" = "sha256-k3x4jRv20c2/TCgURomWgR/5oGpNOnUqnvyO+zovfvQ=";
          };
        };

        inherit nativeBuildInputs buildInputs;

        # Make sure the binary can find shared libraries at runtime
        postFixup = ''
          patchelf --add-rpath "${pkgs.lib.makeLibraryPath runtimeLibs}" $out/bin/srwm
        '';

        postInstall = ''
          install -Dm755 resources/srwm-session $out/bin/srwm-session
          install -Dm644 resources/srwm.desktop $out/share/wayland-sessions/srwm.desktop
          install -Dm644 resources/srwm-portals.conf $out/share/xdg-desktop-portal/srwm-portals.conf
          install -Dm644 config.example.toml $out/etc/srwm/config.toml
          for f in extras/wallpapers/*.glsl; do
            install -Dm644 "$f" "$out/share/srwm/wallpapers/$(basename "$f")"
          done
        '';

        passthru.providedSessions = [ "srwm" ];

        meta = with pkgs.lib; {
          description = "A trackpad-first infinite canvas Wayland compositor";
          license = licenses.gpl3Plus;
          platforms = [ "x86_64-linux" ];
          mainProgram = "srwm";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit nativeBuildInputs buildInputs;

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
      };
    };
}
