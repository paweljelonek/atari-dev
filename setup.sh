#!/usr/bin/env bash
# =============================================================================
# Atari 8-bit Development Environment Setup
# Supports: Atari 400/800, 800XL, 65XE, 130XE
# For: Linux Mint / Ubuntu / Debian
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR ]${NC} $*"; exit 1; }

INSTALL_DIR="$HOME/.atari-dev"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

# =============================================================================
# 1. SYSTEM DEPENDENCIES
# =============================================================================
info "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    make \
    cmake \
    python3 \
    python3-pip \
    libsdl2-dev \
    libsdl2-image-dev \
    libpng-dev \
    zlib1g-dev \
    freeglut3-dev \
    libxi-dev \
    libxmu-dev
ok "Dependencies installed."

# =============================================================================
# 2. ATARI800 EMULATOR
# =============================================================================
info "Installing Atari800 emulator..."
if ! command -v atari800 &>/dev/null; then
    sudo apt-get install -y atari800 2>/dev/null || {
        info "Building Atari800 from source..."
        cd "$INSTALL_DIR"
        git clone --depth 1 https://github.com/atari800/atari800.git atari800-src
        cd atari800-src
        ./autogen.sh
        ./configure --with-sdl
        make -j"$(nproc)"
        sudo make install
        ok "Atari800 built and installed."
        cd "$INSTALL_DIR"
    }
    ok "Atari800 installed."
else
    ok "Atari800 already installed: $(atari800 --version 2>&1 | head -1)"
fi
warn "Note: Atari OS ROMs must be provided manually due to licensing."
warn "  Copy ROM files to: $HOME/.config/atari800/"
warn "  Required: ATARIOSA.ROM (400/800), ATARIXL.ROM (XL/XE), ATARIBAS.ROM"
warn "  On first run, atari800 will guide you through ROM setup."

# =============================================================================
# 3. MADS - MACRO ASSEMBLER DS (primary Atari 8-bit assembler)
# =============================================================================
info "Installing MADS assembler..."
MADS_BIN="$BIN_DIR/mads"
if [ ! -f "$MADS_BIN" ]; then
    cd "$INSTALL_DIR"
    git clone --depth 1 https://github.com/tebe6502/Mad-Assembler.git mads-src
    cd mads-src
    # Try prebuilt binary first (Linux x86_64)
    MADS_RELEASE=$(find . -name "mads" -type f 2>/dev/null | head -1)
    if [ -n "$MADS_RELEASE" ]; then
        cp "$MADS_RELEASE" "$BIN_DIR/mads"
        chmod +x "$BIN_DIR/mads"
        ok "MADS binary found and installed."
    else
        # Build from Pascal source (requires Free Pascal Compiler)
        if ! command -v fpc &>/dev/null; then
            sudo apt-get install -y fpc
        fi
        fpc mads.pas -o"$BIN_DIR/mads" 2>&1 | tail -5
        ok "MADS built from source."
    fi
    cd "$INSTALL_DIR"
else
    ok "MADS already installed."
fi

# =============================================================================
# 4. XASM - FAST ATARI 8-BIT ASSEMBLER
# =============================================================================
info "Installing xasm assembler..."
XASM_BIN="$BIN_DIR/xasm"
if [ ! -f "$XASM_BIN" ]; then
    cd "$INSTALL_DIR"
    [ -d "xasm-src" ] || git clone --depth 1 https://github.com/pfusik/xasm.git xasm-src
    cd xasm-src
    if [ -f "Makefile" ] && (command -v dmd &>/dev/null || command -v ldc2 &>/dev/null); then
        make -j"$(nproc)"
        cp xasm "$BIN_DIR/"
        ok "xasm installed."
    elif command -v fpc &>/dev/null && [ -f "xasm.pas" ]; then
        fpc xasm.pas -o"$BIN_DIR/xasm" 2>&1 | tail -5
        ok "xasm installed (via fpc)."
    else
        warn "xasm: skipping - requires 'dmd' or 'ldc2' (D compiler) to build."
        warn "  Install with: sudo apt-get install ldc  OR  https://dlang.org/download.html"
    fi
    cd "$INSTALL_DIR"
else
    ok "xasm already installed."
fi

# =============================================================================
# 5. CC65 - C COMPILER FOR 6502 (with Atari target)
# =============================================================================
info "Checking cc65..."
if command -v cl65 &>/dev/null; then
    ok "cc65 already installed: $(cc65 --version 2>&1)"
else
    info "Building cc65 from source..."
    cd "$INSTALL_DIR"
    git clone --depth 1 https://github.com/cc65/cc65.git cc65-src
    cd cc65-src
    make -j"$(nproc)"
    make install PREFIX="$HOME/.local"
    ok "cc65 installed."
    cd "$INSTALL_DIR"
fi

# =============================================================================
# 6. DIR2ATR - CREATE ATR DISK IMAGES FROM FILES
# =============================================================================
info "Installing dir2atr..."
DIR2ATR_BIN="$BIN_DIR/dir2atr"
if [ ! -f "$DIR2ATR_BIN" ]; then
    cd "$INSTALL_DIR"
    git clone --depth 1 https://github.com/HolgerJanz/dir2atr.git dir2atr-src 2>/dev/null || {
        # Alternative: build from Hias's version
        wget -q https://www.horus.com/~hias/atari/dir2atr.zip -O dir2atr.zip 2>/dev/null && {
            unzip -q dir2atr.zip -d dir2atr-src
        } || {
            warn "dir2atr: could not download - skipping."
            cd "$INSTALL_DIR"
        }
    }
    if [ -d "dir2atr-src" ]; then
        cd dir2atr-src
        make -j"$(nproc)" 2>/dev/null && cp dir2atr "$BIN_DIR/" && ok "dir2atr installed." || \
            warn "dir2atr: build failed - install manually."
        cd "$INSTALL_DIR"
    fi
else
    ok "dir2atr already installed."
fi

# =============================================================================
# 7. ATR TOOLS - DISK IMAGE UTILITIES
# =============================================================================
info "Installing atr disk tools..."
if ! command -v adir &>/dev/null; then
    sudo apt-get install -y atari-tools 2>/dev/null && ok "atari-tools (adir, etc.) installed." || \
        warn "atari-tools not in apt - skipping. Install from: https://www.horus.com/~hias/atari/"
else
    ok "atari-tools already installed."
fi

# =============================================================================
# 8. EXOMIZER - DATA COMPRESSOR (works for Atari too)
# =============================================================================
info "Installing Exomizer..."
if ! command -v exomizer &>/dev/null; then
    cd "$INSTALL_DIR"
    git clone --depth 1 https://bitbucket.org/magli143/exomizer.git exomizer-src 2>/dev/null || \
        git clone --depth 1 https://github.com/exomizer/exomizer.git exomizer-src
    cd exomizer-src/src
    make -j"$(nproc)"
    cp exomizer "$BIN_DIR/"
    ok "Exomizer installed."
    cd "$INSTALL_DIR"
else
    ok "Exomizer already installed."
fi

# =============================================================================
# 9. ZX0 - MODERN EFFICIENT COMPRESSOR
# =============================================================================
info "Installing zx0 compressor..."
ZX0_BIN="$BIN_DIR/zx0"
if [ ! -f "$ZX0_BIN" ]; then
    cd "$INSTALL_DIR"
    git clone --depth 1 https://github.com/einar-saukas/ZX0.git zx0-src
    cd zx0-src
    make -j"$(nproc)" 2>/dev/null || gcc -O2 -o zx0 src/zx0.c src/compress.c 2>/dev/null || \
        warn "zx0: build failed - skipping."
    [ -f "zx0" ] && cp zx0 "$BIN_DIR/" && ok "zx0 installed." || true
    cd "$INSTALL_DIR"
else
    ok "zx0 already installed."
fi

# =============================================================================
# 10. ADD ~/.local/bin TO PATH
# =============================================================================
SHELL_RC="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q 'atari-dev\|\.local/bin' "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# Atari 8-bit Development tools' >> "$SHELL_RC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    info "Added ~/.local/bin to PATH in $SHELL_RC"
fi

# cc65_HOME for cc65
if ! grep -q 'CC65_HOME' "$SHELL_RC" 2>/dev/null; then
    echo 'export CC65_HOME="$HOME/.local/share/cc65"' >> "$SHELL_RC"
    info "Added CC65_HOME to $SHELL_RC"
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Atari 8-bit Dev environment ready!${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "  Installed tools:"
echo ""
echo "  ASSEMBLERS:"
echo "    mads     - $(command -v mads    && mads 2>&1 | head -1 || echo 'not available')"
echo "    xasm     - $(command -v xasm    && xasm --version 2>&1 | head -1 || echo 'not available')"
echo "    cl65     - $(command -v cl65    && cl65 --version 2>&1 || echo 'not available')"
echo ""
echo "  EMULATOR:"
echo "    atari800 - $(command -v atari800 && atari800 --version 2>&1 | head -1 || echo 'not available')"
echo ""
echo "  DISK TOOLS:"
echo "    dir2atr  - $(command -v dir2atr && echo 'available' || echo 'not available')"
echo "    adir     - $(command -v adir    && echo 'available' || echo 'not available')"
echo ""
echo "  COMPRESSORS:"
echo "    exomizer - $(command -v exomizer && echo 'available' || echo 'not available')"
echo "    zx0      - $(command -v zx0      && echo 'available' || echo 'not available')"
echo ""
echo -e "${YELLOW}  IMPORTANT: Atari OS ROMs needed!${NC}"
echo "    Copy ROM files to: $HOME/.config/atari800/"
echo "    Required: ATARIOSA.ROM, ATARIXL.ROM, ATARIBAS.ROM"
echo ""
echo -e "${YELLOW}  Restart your terminal or run: source $SHELL_RC${NC}"
echo ""
echo "  Useful links:"
echo "    https://mads.atari8.info/                  - MADS assembler docs"
echo "    https://atari800.github.io/                - Atari800 emulator"
echo "    https://atariwiki.org/wiki/Wiki.jsp?page=Programming"
echo "    https://www.atariarchives.org/mapping/      - Mapping the Atari"
echo "    https://cc65.github.io/doc/atari.html       - cc65 Atari target"
echo ""
