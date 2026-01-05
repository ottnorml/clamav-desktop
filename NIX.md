# Nix Setup for ClamAV Desktop

This directory contains Nix configuration files for easy development environment setup and building.

## Files

- `flake.nix` - Nix flake configuration (recommended, requires Nix with flakes enabled)
- `shell.nix` - Traditional Nix shell configuration (for non-flake users)
- `.envrc` - direnv configuration for automatic environment loading

## Quick Start

### Using Nix Flakes (Recommended)

1. Install Nix with flakes enabled:
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   # Enable flakes
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

2. Enter the development environment:
   ```bash
   nix develop
   ```

3. Install dependencies and start development:
   ```bash
   yarn
   yarn dev
   ```

### Using Nix Shell (Traditional)

1. Install Nix:
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enter the development environment:
   ```bash
   nix-shell
   ```

3. Install dependencies and start development:
   ```bash
   yarn
   yarn dev
   ```

### Using direnv (Automatic)

1. Install direnv and Nix
2. Enable direnv in your shell (add to `~/.bashrc` or `~/.zshrc`):
   ```bash
   eval "$(direnv hook bash)"  # or zsh, fish, etc.
   ```

3. Allow direnv in the project directory:
   ```bash
   cd clamav-desktop
   direnv allow
   ```

The environment will automatically load when you enter the directory!

## What's Included

The Nix environment provides:

### Development Tools
- Node.js v22
- Yarn package manager
- Rust toolchain (latest stable, matching project requirements)
- cargo-watch, cargo-edit, cargo-deb
- rust-analyzer

### Build Dependencies
- Tauri v2 prerequisites (WebKit, GTK, etc.)
- ClamAV build dependencies
- CMake, Ninja, pkg-config
- Python 3 with pytest

### System Libraries
- WebKitGTK 4.1
- GTK3
- OpenSSL
- libayatana-appindicator
- And all other required system libraries

## Building

### Development Build

Inside the Nix environment:
```bash
yarn dev
```

### Production Build

Inside the Nix environment:
```bash
# Build the application
yarn build

# Or use Nix to build
nix build
```

The Nix build output will be in `./result/bin/clamav-desktop`.

## Troubleshooting

### "experimental-features" error
If you get an error about experimental features, enable flakes:
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Missing system libraries
The Nix environment should provide all necessary libraries. If you encounter issues, ensure you're running commands inside the Nix shell (`nix develop` or `nix-shell`).

### WebKit errors
The environment sets `WEBKIT_DISABLE_COMPOSITING_MODE=1` to help with WebKit compatibility.

## Platform Support

Currently tested and supported on:
- **Linux (x86_64)** - Full support with GTK/WebKitGTK
- **macOS (Intel & Apple Silicon)** - Full support with native frameworks
- **NixOS** - Native support

### Platform-Specific Notes

**Linux:**
- Uses WebKitGTK 4.1, GTK3, and related Linux libraries
- Sets `WEBKIT_DISABLE_COMPOSITING_MODE=1` for compatibility
- Uses `LD_LIBRARY_PATH` for runtime library loading

**macOS:**
- Uses native macOS frameworks (AppKit, WebKit, CoreServices, Security)
- Uses `DYLD_LIBRARY_PATH` for runtime library loading
- Compatible with both Intel and Apple Silicon Macs

## Contributing

When adding new dependencies, please update both `flake.nix` and `shell.nix` to keep them in sync.
