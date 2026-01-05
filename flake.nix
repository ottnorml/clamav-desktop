{
  description = "ClamAV Desktop - A cross-platform desktop GUI for ClamAV antivirus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain matching the project requirements (1.87+)
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        # Node.js version matching package.json (v22)
        nodejs = pkgs.nodejs_22;

        # Common build inputs for the application
        buildInputs = with pkgs; [
          # Tauri prerequisites
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl
          librsvg
          libayatana-appindicator
          xdotool

          # ClamAV dependencies
          bzip2
          curl
          json_c
          libmilter
          ncurses
          pcre2
          libxml2
          zlib
        ];

        nativeBuildInputs = with pkgs; [
          # Build tools
          pkg-config
          cmake
          ninja
          python3
          python3Packages.pytest
          
          # Rust toolchain
          rustToolchain
          cargo
          
          # Node.js and package manager
          nodejs
          yarn
          
          # Additional tools
          git
          makeWrapper
        ];

        # Libraries needed at runtime
        runtimeDependencies = with pkgs; [
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl
          librsvg
          libayatana-appindicator
        ];

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = buildInputs ++ nativeBuildInputs ++ [
            # Additional dev tools
            pkgs.cargo-watch
            pkgs.cargo-edit
            pkgs.cargo-deb
            pkgs.rust-analyzer
          ];

          shellHook = ''
            echo "ClamAV Desktop Development Environment"
            echo "======================================"
            echo "Node version: $(node --version)"
            echo "Yarn version: $(yarn --version)"
            echo "Rust version: $(rustc --version)"
            echo "Cargo version: $(cargo --version)"
            echo ""
            echo "Available commands:"
            echo "  yarn dev              - Start development server"
            echo "  yarn build            - Build the application"
            echo "  yarn test             - Run tests"
            echo "  make test             - Run Rust tests"
            echo ""
            echo "Setup hints:"
            echo "  1. Run 'yarn' to install dependencies"
            echo "  2. Copy src-tauri/.cargo/config.toml.example to src-tauri/.cargo/config.toml"
            echo "  3. Run 'yarn dev' to start development"
            echo ""
            
            # Set up environment variables for building
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.webkitgtk_4_1}/lib/pkgconfig:$PKG_CONFIG_PATH"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeDependencies}:$LD_LIBRARY_PATH"
            export WEBKIT_DISABLE_COMPOSITING_MODE=1
          '';

          # Environment variables for Rust compilation
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          OPENSSL_DIR = "${pkgs.openssl.dev}";
          OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
          OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
        };

        # Package definition for building the application
        packages.default = pkgs.stdenv.mkDerivation rec {
          pname = "clamav-desktop";
          version = "0.3.24";

          src = ./.;

          nativeBuildInputs = nativeBuildInputs;
          buildInputs = buildInputs;

          configurePhase = ''
            export HOME=$TMPDIR
            export CARGO_HOME=$TMPDIR/cargo
            export NODE_ENV=production
            
            # Install Node dependencies
            yarn install --frozen-lockfile
          '';

          buildPhase = ''
            # Build webview
            yarn build:webview
            
            # Prepare core build
            node ./scripts/build/prepare_core_build.js
            
            # Build core (Rust)
            cd src-tauri
            cargo build --release
            cd ..
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp src-tauri/target/release/clamav-desktop $out/bin/
            
            # Wrap the binary with necessary library paths
            wrapProgram $out/bin/clamav-desktop \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeDependencies}"
          '';

          meta = with pkgs.lib; {
            description = "A cross-platform desktop GUI for ClamAV antivirus";
            homepage = "https://github.com/ivangabriele/clamav-desktop";
            license = licenses.agpl3Only;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };

        # Alias for the package
        packages.clamav-desktop = self.packages.${system}.default;
      }
    );
}
