; ============================================================
; GTIA Color Bars - 6502 Assembly for Atari 8-bit (MADS)
;
; Classic raster effect: change GTIA background color
; (COLBK, $D01A) on each scanline using ANTIC's WSYNC
; strobe ($D40A) to synchronize with the electron beam.
;
; WSYNC ($D40A) - write any value to halt the CPU until
;   the next horizontal retrace. This gives exact per-line
;   color changes without IRQ setup.
; VCOUNT ($D40B) - vertical line counter (increments every
;   2 scanlines), range 0-$7C (NTSC) / $82 (PAL).
; COLBK ($D01A)  - background color: bits 7-4 = hue (0-15),
;                  bits 3-1 = luminance (0-7), bit 0 = 0.
;
; Build: make DIR=examples/colors-asm
; Run:   make run DIR=examples/colors-asm
; ============================================================

COLBK   = $D01A         ; GTIA: background color register
WSYNC   = $D40A         ; ANTIC: horizontal sync strobe (write)
VCOUNT  = $D40B         ; ANTIC: vertical line counter (/2)

VCOUNT_VISIBLE = 104    ; end of visible area (~208 scanlines / 2)

    org  $2000

start
    sei                 ; disable IRQs - we poll ANTIC directly

frame
    ; wait for top of frame (VCOUNT wraps back to 0)
vblank
    lda  VCOUNT
    bne  vblank

bars
    sta  WSYNC          ; wait for scanline boundary
    lda  VCOUNT
    asl                 ; VCOUNT steps by 2 scanlines; shift left for more hue spread
    asl
    ora  #$0E           ; force high luminance so colors are visible (bits 3-1 = 7)
    sta  COLBK          ; apply color to background

    lda  VCOUNT
    cmp  #VCOUNT_VISIBLE
    bcc  bars           ; loop until bottom of visible area

    jmp  frame

    run  start
