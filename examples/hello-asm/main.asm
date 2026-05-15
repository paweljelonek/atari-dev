; ============================================================
; Hello World - 6502 Assembly for Atari 8-bit (MADS)
;
; Writes "HELLO, ATARI!" to the screen using CIO (Central I/O):
;   IOCB 0  - E: device (screen editor, always open)
;   CIOV    - $E456  CIO dispatch vector
;   ICCOM   - $0342  command byte for IOCB 0
;   ICBAL/H - $0344/$0345  buffer address
;   ICBLL/H - $0348/$0349  buffer length
;
; $9B is the Atari EOL character (equivalent to newline).
;
; Build: make DIR=examples/hello-asm
; Run:   make run DIR=examples/hello-asm
; ============================================================

CIOV    = $E456         ; CIO dispatch vector
ICCOM   = $0342         ; IOCB 0: command
ICBAL   = $0344         ; IOCB 0: buffer address low
ICBAH   = $0345         ; IOCB 0: buffer address high
ICBLL   = $0348         ; IOCB 0: buffer length low
ICBLH   = $0349         ; IOCB 0: buffer length high
PUTBLK  = $09           ; CIO command: write block

    org  $2000

start
    lda  #PUTBLK
    sta  ICCOM
    lda  #<msg
    sta  ICBAL
    lda  #>msg
    sta  ICBAH
    lda  #<(msg_end-msg)
    sta  ICBLL
    lda  #0
    sta  ICBLH
    ldx  #0             ; IOCB 0 (E: screen device, X = iocb_num * 16)
    jsr  CIOV
    rts

msg
    dta  c'HELLO, ATARI!',$9B
msg_end

    run  start
