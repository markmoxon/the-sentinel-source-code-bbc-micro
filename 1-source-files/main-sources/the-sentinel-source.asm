\ ******************************************************************************
\
\ THE SENTINEL REVS
\
\ The Sentinel was written by Geoffrey J Crammond and is copyright Firebird 1985
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
\   * sentinel-pias.dsd
\
\ This can be loaded into an emulator or a real BBC Micro.
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/the-sentinel-build-options.asm"

 _PIAS6                 = (_VARIANT = 1)

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &1900          \ The address of the main game code

 LOAD% = &1900          \ The load address of the main code binary

\ ******************************************************************************
\
\       Name: Zero page
\       Type: Workspace
\    Address: ??? to ???
\   Category: Workspaces
\    Summary: Mainly temporary variables that are used a lot
\
\ ******************************************************************************

 ORG &0000              \ Set the assembly address to &0000



\ ******************************************************************************
\
\ THE SENTINEL MAIN GAME CODE
\
\ Produces the binary file Sentinel.bin that contains the main game code.
\
\ ******************************************************************************

 ORG CODE%

 INCBIN "4-reference-binaries/pias/TheSentinel.bin"

\ ******************************************************************************
\
\ Save Sentinel.bin
\
\ ******************************************************************************

 SAVE "3-assembled-output/TheSentinel.bin", CODE%, P%
