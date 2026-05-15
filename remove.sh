#!/usr/bin/env bash
# =============================================================================
# Atari 8-bit Development Environment - Uninstaller
# Removes everything installed by setup-atari-dev.sh
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

INSTALL_DIR="$HOME/.atari-dev"
BIN_DIR="$HOME/.local/bin"

echo ""
echo -e "${RED}============================================================${NC}"
echo -e "${RED}  Atari 8-bit Dev Environment - UNINSTALLER${NC}"
echo -e "${RED}============================================================${NC}"
echo ""
echo "  This will remove:"
echo ""
echo "  Binaries from $BIN_DIR/:"
echo "    mads, xasm, dir2atr, exomizer, zx0"
echo "    cc65 binaries (cc65, cl65, ld65, ar65, ca65, ...)"
echo ""
echo "  Source/build directory:"
echo "    $INSTALL_DIR/"
echo ""
echo "  cc65 platform files:"
echo "    $HOME/.local/share/cc65/"
echo ""
echo "  PATH entries from ~/.bashrc and ~/.zshrc:"
echo "    ~/.local/bin, CC65_HOME"
echo ""
echo -e "${YELLOW}  NOT removed (installed system-wide via apt):${NC}"
echo "    atari800, atari-tools (adir)"
echo "    Use: sudo apt-get remove atari800 atari-tools  (if you want)"
echo ""
echo -e "${RED}------------------------------------------------------------${NC}"
read -r -p "  Are you sure you want to continue? [y/N] " confirm
echo ""

if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "  Aborted."
    exit 0
fi

# =============================================================================
# MADS
# =============================================================================
if [ -f "$BIN_DIR/mads" ]; then
    rm -f "$BIN_DIR/mads"
    ok "Removed mads binary."
fi

# =============================================================================
# XASM
# =============================================================================
if [ -f "$BIN_DIR/xasm" ]; then
    rm -f "$BIN_DIR/xasm"
    ok "Removed xasm binary."
fi

# =============================================================================
# CC65
# =============================================================================
CC65_BINS="cc65 cl65 ld65 ar65 ca65 co65 grc65 da65 od65 sim65 sp65"
removed_cc65=0
for bin in $CC65_BINS; do
    if [ -f "$BIN_DIR/$bin" ]; then
        rm -f "$BIN_DIR/$bin"
        removed_cc65=1
    fi
done
[ "$removed_cc65" -eq 1 ] && ok "Removed cc65 binaries."

if [ -d "$HOME/.local/share/cc65" ]; then
    rm -rf "$HOME/.local/share/cc65"
    ok "Removed cc65 platform files (~/.local/share/cc65)."
fi

# =============================================================================
# DIR2ATR
# =============================================================================
if [ -f "$BIN_DIR/dir2atr" ]; then
    rm -f "$BIN_DIR/dir2atr"
    ok "Removed dir2atr binary."
fi

# =============================================================================
# EXOMIZER
# =============================================================================
if [ -f "$BIN_DIR/exomizer" ]; then
    rm -f "$BIN_DIR/exomizer"
    ok "Removed exomizer binary."
fi

# =============================================================================
# ZX0
# =============================================================================
if [ -f "$BIN_DIR/zx0" ]; then
    rm -f "$BIN_DIR/zx0"
    ok "Removed zx0 binary."
fi

# =============================================================================
# SOURCE / BUILD DIRECTORY
# =============================================================================
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed $INSTALL_DIR."
fi

# =============================================================================
# PATH ENTRIES FROM SHELL RC FILES
# =============================================================================
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    if grep -q 'atari-dev\|\.local/bin\|CC65_HOME' "$rc" 2>/dev/null; then
        sed -i '/# Atari 8-bit Development tools/d' "$rc"
        sed -i '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$rc"
        sed -i '/export CC65_HOME/d' "$rc"
        ok "Cleaned up $rc."
    fi
done

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Done. Atari dev tools removed.${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
warn "atari800 and atari-tools (adir) were NOT removed."
warn "To remove them: sudo apt-get remove atari800 atari-tools"
echo ""
info "Restart your terminal to apply PATH changes."
echo ""
