/*
 * Hello World - C for Atari 8-bit (cc65, atarixl target)
 *
 * cc65's <conio.h> provides Atari console I/O:
 *   clrscr()   - clear screen
 *   cputs()    - print string; use \r\n for newlines
 *   cgetc()    - wait for a keypress
 *
 * <atari.h> exposes Atari hardware registers and OS structures.
 * GTIA.COLBK ($D01A) is the background color register.
 *
 * Build: make DIR=examples/hello-c
 * Run:   make run DIR=examples/hello-c
 */
#include <conio.h>
#include <atari.h>

int main(void)
{
    clrscr();
    cputs("HELLO, ATARI!\r\n");
    cputs("\r\nPRESS ANY KEY...\r\n");
    cgetc();
    return 0;
}
