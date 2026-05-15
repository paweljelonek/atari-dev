# atari-dev

> ⚠️ **Early version** - work in progress, expect breaking changes.

Development environment for Atari 8-bit computers (400/800, 800XL, 65XE, 130XE) - 6502 assembler, cc65 C compiler, Atari800 emulator and helper tools.

## About this project

This is my personal setup - built for fun, built for learning, built because I got nerd-sniped by a YouTube course at 11pm and suddenly needed a working Atari dev environment. No grand plans, no roadmap, no enterprise architecture. Just a guy, a 40-year-old 8-bit computer, and way too much coffee.

If you find it useful - great, glad it helped. If something is wrong, missing, or could be done better - you're probably right, feel free to fix it. Fork it, reshape it, strip it down, build on top of it, or just steal the parts you need. No need to ask. No strings attached.

Have fun with it. That's the whole point.

> 🕹️ **One more thing** - this setup was born alongside a fantastic 6502 assembly course by **Larkadiusz** from his YouTube channel [https://www.youtube.com/@larek](https://www.youtube.com/@larek). The full playlist is [right here](https://www.youtube.com/playlist?list=PLjJ96DbvVFy9XNXhlAZW5TGAeetdt7_uk). If you want to actually learn to write code for Atari - go watch it. Seriously. Note: the course is in Polish.

---

## Structure

```
atari-dev/
├── .env               - local configuration (git-ignored, copy from .env.dist)
├── .env.dist          - configuration template
├── .gitignore
├── LICENSE
├── setup-atari-dev.sh - install all tools (Linux Mint / Ubuntu / Debian)
├── Makefile           - build and run projects
└── examples/
    ├── hello-asm/     - Hello World in 6502 assembly (MADS)
    ├── hello-c/       - Hello World in C (cc65)
    └── colors-asm/    - GTIA color bars raster effect in assembly
```

Projects live separately in `~/Projects/atari-projects/` - each as its own git repository.

## Quick start

### 1. Install tools

```bash
./setup-atari-dev.sh
```

> 🐧 **Linux only - Ubuntu / Linux Mint / Debian and derivatives.**
> 
> The script uses `apt` and assumes a Debian-based system. It will **not** work on Arch, Fedora, openSUSE or other distributions. Support for other distros may appear someday - or it may not, depending on available free time.

Installs: MADS, xasm, cc65, Atari800 emulator, dir2atr, exomizer, zx0.

Tools are installed in three locations:

| Location          | What                                               |
|-------------------|----------------------------------------------------|
| system (apt)      | `atari800`, `atari-tools`, `cc65`                  |
| `~/.atari-dev/`   | source builds and archives                         |
| `~/.local/bin/`   | compiled binaries and wrappers                     |

### 2. Atari OS ROMs

Atari OS ROMs are required to run the emulator but cannot be distributed freely.
Copy your ROM files to `~/.config/atari800/`:

| File            | Description                     |
|-----------------|---------------------------------|
| `ATARIXL.ROM`   | Atari XL/XE OS (recommended)    |
| `ATARIOSA.ROM`  | Atari 400/800 OS A              |
| `ATARIBAS.ROM`  | Atari BASIC                     |

On first run, `atari800` will guide you through the ROM configuration.

### 3. Configure

Copy `.env.dist` to `.env` and adjust the path:

```bash
cp .env.dist .env
```

```env
ATARI_PROJECTS=/home/you/Projects/atari-projects
```

### 4. New project

```bash
mkdir ~/Projects/atari-projects/my-project
cd ~/Projects/atari-projects/my-project
git init
echo -e "*.xex\n*.lst\n*.sym" > .gitignore
# create main.asm and start coding
```

### 5. Build and run

The Makefile supports two ways to specify what to build:

**`PROJECT=name`** - builds a project from `ATARI_PROJECTS` directory (set in `.env`):

```bash
make PROJECT=my-project           # build (auto-detects main.asm or main.c)
make run PROJECT=my-project       # build and launch in Atari800
make debug PROJECT=my-project     # launch with Atari800 built-in monitor
make clean PROJECT=my-project     # remove build artifacts
make list                         # list projects and examples
```

**`DIR=path`** - builds a project in any directory, e.g. the bundled examples:

```bash
make DIR=examples/hello-asm       # build assembly example
make run DIR=examples/hello-c     # build and run C example
make clean DIR=examples/colors-asm
```

Source type is detected automatically: `main.c` → cc65 (`atarixl`), `main.asm` → MADS.

## Tools

| Tool       | Description                              | Website                                    |
|------------|------------------------------------------|--------------------------------------------|
| mads       | MADS Macro Assembler (primary)           | https://mads.atari8.info/                  |
| xasm       | Fast Atari 8-bit assembler               | https://github.com/pfusik/xasm             |
| cl65       | cc65 C compiler (atarixl target)         | https://cc65.github.io/                    |
| atari800   | Atari 8-bit emulator                     | https://atari800.github.io/                |
| dir2atr    | Create ATR disk images from files        | https://github.com/HolgerJanz/dir2atr      |
| adir       | List/extract ATR disk images             | https://www.horus.com/~hias/atari/         |
| exomizer   | Data compressor                          | https://bitbucket.org/magli143/exomizer    |
| zx0        | Modern efficient compressor              | https://github.com/einar-saukas/ZX0        |

## MADS Assembler syntax

MADS uses standard 6502 mnemonics with a few Atari-specific conveniences:

```asm
    org  $2000          ; set origin address

    lda  #$FF           ; load immediate
    sta  $D01A          ; store to GTIA COLBK

    dta  $41,$42        ; define bytes (like !byte in ACME, db in NASM)
    dta  c'TEXT'        ; define ATASCII string bytes
    dta  $9B            ; Atari EOL (newline)

    run  start          ; set XEX run address (creates binary load header)
```

## Atari 8-bit hardware overview

| Chip    | Function                                          | Address range       |
|---------|---------------------------------------------------|---------------------|
| GTIA    | Graphics/sprites (Player-Missile), color regs     | $D000 - $D0FF       |
| POKEY   | Sound (4 channels), keyboard, timers, serial      | $D200 - $D2FF       |
| PIA     | Joystick ports, BASIC switch                      | $D300 - $D3FF       |
| ANTIC   | Display list processor, DMA controller            | $D400 - $D4FF       |
| OS ROM  | Kernel routines, CIO, SIO, IRQ handlers           | $C000-$CFFF + $D800-$FFFF |

Key addresses:

| Address | Name    | Description                                  |
|---------|---------|----------------------------------------------|
| $E456   | CIOV    | CIO dispatch - universal I/O (E:, K:, P:...) |
| $D01A   | COLBK   | GTIA background color                        |
| $D40A   | WSYNC   | ANTIC horizontal sync strobe                 |
| $D40B   | VCOUNT  | ANTIC vertical line counter (÷2)             |
| $D200   | AUDF1   | POKEY channel 1 frequency                   |
| $D201   | AUDC1   | POKEY channel 1 control                     |

## Links

- [Mapping the Atari](https://www.atariarchives.org/mapping/) - complete hardware reference
- [MADS Assembler documentation](https://mads.atari8.info/)
- [cc65 Atari target](https://cc65.github.io/doc/atari.html)
- [Atariwiki - Programming](https://atariwiki.org/wiki/Wiki.jsp?page=Programming)
- [Atari POKEY](https://www.atariarchives.org/mapping/memorymap.php)
- [6502.org - instruction set](http://www.6502.org/tutorials/6502opcodes.html)

## License

MIT - see [LICENSE](LICENSE)
