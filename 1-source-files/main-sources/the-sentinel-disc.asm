\ ******************************************************************************
\
\ THE SENTINEL DISC IMAGE SCRIPT
\
\ The Sentinel was written by Geoff Crammond and is copyright Firebird 1986
\
\ The code on this site has been reconstructed from a disassembly of the
\ original game binaries
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://sentinel.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://sentinel.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces an SSD disc image for The Sentinel on the BBC Micro.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following SSD disc image:
\
\   * sentinel-sam6.dsd
\
\ This can be loaded into an emulator or a real BBC Micro.
\
\ ******************************************************************************

\ Boot file

 PUTFILE "1-source-files/boot-files/$.!BOOT.bin", "!BOOT", &FFFFFF, &FFFFFF

\ Menu

 PUTBASIC "1-source-files/basic-programs/$.MENU.bas", "MENU"
 PUTFILE "1-source-files/images/$.SENLSCR.bin", "SENLSCR", &005800, &005800

\ Game files

 PUTFILE "3-assembled-output/TheSentinel.bin", "SENTNEL", &001900, &006D00
