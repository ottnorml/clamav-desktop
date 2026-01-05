# This file provides backward compatibility for users not using Nix flakes.
# For flake users, run: nix develop
# For non-flake users, run: nix-shell

{ pkgs ? import <nixpkgs> {
    overlays = [
      (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
    ];
  }
}:

let
  # Rust toolchain matching the project requirements (1.87+)
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" ];
  };

  # Node.js version matching package.json (v22)
  nodejs = pkgs.nodejs_22;

  # Common build inputs
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
    
    # Additional dev tools
    cargo-watch
    cargo-edit
    cargo-deb
    rust-analyzer
    
    # Additional tools
    git
  ];

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

in pkgs.mkShell {
  buildInputs = buildInputs ++ nativeBuildInputs;

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
}
