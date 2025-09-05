\ ******************************************************************************
\
\ THE SENTINEL SOURCE
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
\ This source file contains the main game code for The Sentinel on the BBC
\ Micro.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * TheSentinel.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/the-sentinel-build-options.asm"

 _PIAS                  = (_VARIANT = 1)

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &0400          \ The address of the main game code

 LOAD% = &1900          \ The load address of the main code binary

 IRQ1V = &0204          \ The IRQ1V vector that we intercept to implement the
                        \ screen mode

 BRKIV = &0287          \ The Break Intercept vector (which is a JMP instruction
                        \ to the Break Intercept handler)

 BRKI = &0380           \ The CFS workspace, which we can use for the Break
                        \ Intercept handler

 SHEILA = &FE00         \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSRDCH = &FFE0         \ The address for the OSRDCH routine

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSWORD = &FFF1         \ The address for the OSWORD routine

\ ******************************************************************************
\
\       Name: Zero page
\       Type: Workspace
\    Address: ??? to ???
\   Category: Workspaces
\    Summary: Mainly temporary variables that are used a lot
\
\ ******************************************************************************

\ORG &0000              \ Set the assembly address to &0000

L0000                = &0000
L0001                = &0001
L0002                = &0002
L0003                = &0003
L0004                = &0004
L0005                = &0005
L0006                = &0006
L0007                = &0007
L0008                = &0008
L0009                = &0009
L000A                = &000A
L000B                = &000B
L000C                = &000C
L000D                = &000D
L000E                = &000E
L000F                = &000F
L0010                = &0010
L0011                = &0011
L0012                = &0012
L0013                = &0013
L0014                = &0014
L0015                = &0015
L0016                = &0016
L0017                = &0017
L0018                = &0018
L0019                = &0019
L001A                = &001A
L001B                = &001B
L001C                = &001C
L001D                = &001D
L001E                = &001E
L001F                = &001F
L0020                = &0020
L0021                = &0021
L0022                = &0022
L0023                = &0023
L0024                = &0024
L0025                = &0025
L0026                = &0026
L0027                = &0027
L0028                = &0028
L0029                = &0029
L002A                = &002A
L002B                = &002B
L002C                = &002C
L002D                = &002D
L002E                = &002E
L002F                = &002F
L0030                = &0030
L0031                = &0031
L0032                = &0032
L0033                = &0033
L0034                = &0034
L0035                = &0035
L0036                = &0036
L0037                = &0037
L0038                = &0038
L0039                = &0039
L003A                = &003A
L003B                = &003B
L003C                = &003C
L003D                = &003D
L003E                = &003E
L003F                = &003F
L0040                = &0040
L0041                = &0041
L0042                = &0042
L0043                = &0043
L0045                = &0045
L004A                = &004A
L004B                = &004B
L004C                = &004C
L004E                = &004E
L004F                = &004F
L0050                = &0050
L0051                = &0051
L0052                = &0052
L0053                = &0053
L0054                = &0054
L0055                = &0055
L0056                = &0056
L0057                = &0057
L0058                = &0058
L0059                = &0059
L005A                = &005A
L005C                = &005C
L005D                = &005D
L005E                = &005E
L005F                = &005F
L0060                = &0060
L0061                = &0061
L0062                = &0062
L0063                = &0063
L0064                = &0064
L0065                = &0065
L0066                = &0066
L0067                = &0067
L0068                = &0068
L0069                = &0069
L006A                = &006A
L006B                = &006B
L006C                = &006C
L006D                = &006D
L006E                = &006E
L006F                = &006F
P                    = &0070
Q                    = &0071
R                    = &0072
S                    = &0073
L0074                = &0074
L0075                = &0075
L0076                = &0076
L0077                = &0077
L0078                = &0078
L0079                = &0079
L007A                = &007A
L007B                = &007B
L007C                = &007C
L007D                = &007D
L007E                = &007E
L007F                = &007F
L0080                = &0080
L0081                = &0081
L0082                = &0082
L0083                = &0083
L0084                = &0084
L0085                = &0085
L0086                = &0086
L0088                = &0088
L008A                = &008A
L008B                = &008B
L008D                = &008D
L008E                = &008E
L008F                = &008F
L00FC                = &00FC

\ ******************************************************************************
\
\       Name: Stack variables
\       Type: Workspace
\    Address: &0100 to ???
\   Category: Workspaces
\    Summary: Variables that share page 1 with the stack
\
\ ******************************************************************************

 ORG &0100              \ Set the assembly address to &0100

L0100                = &0100
L0140                = &0140
L0142                = &0142
L0150                = &0150
L0180                = &0180
L0181                = &0181
L01A0                = &01A0
L01A1                = &01A1

\ ******************************************************************************
\
\ THE SENTINEL MAIN GAME CODE
\
\ Produces the binary file Sentinel.bin that contains the main game code.
\
\ ******************************************************************************

 ORG CODE%              \ Set the assembly address to &0400

.L0400

 EQUB &00, &00, &00, &00, &00, &00, &00, &27
 EQUB &29, &20, &27, &29, &29, &27, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &20, &20, &20
 EQUB &20, &20, &20, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &29, &29, &29
 EQUB &29, &29, &29, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &29, &29, &29
 EQUB &29, &29, &29, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &20, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &29, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &29, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &29, &29, &29
 EQUB &29, &29, &29, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &27, &29, &28, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &20, &20, &20
 EQUB &29, &20, &20, &20, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &29, &20, &20
 EQUB &29, &20, &20, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &27, &29, &28, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &29, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &28
 EQUB &29, &29, &28, &20, &29, &28, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &28, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &20, &20, &20
 EQUB &20, &20, &20, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &29, &29, &29
 EQUB &29, &29, &29, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &29, &20, &20
 EQUB &28, &20, &20, &29, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &20, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &29, &29, &29, &29, &29, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &28, &20, &20, &29, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &29
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &20, &20, &20
 EQUB &20, &20, &20, &20, &20, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &20
 EQUB &20, &20, &20, &20, &20, &20, &20, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &00, &00, &00, &00, &00, &00, &00
 EQUB &C0, &C0, &C0, &C0, &04, &04, &04, &04
 EQUB &00, &00, &00, &64, &00, &00, &00, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &05, &00, &00, &00, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &00, &00, &00, &00, &F0, &00, &0E
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &64, &06, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &90
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0900

L0901 = L0900+1
L0902 = L0900+2
L0910 = L0900+16
L093F = L0900+63
L0940 = L0900+64
L0941 = L0900+65
L0942 = L0900+66
L0950 = L0900+80
L097F = L0900+127
L0980 = L0900+128
L0981 = L0900+129
L0982 = L0900+130
L0990 = L0900+144
L09BF = L0900+191
L09C0 = L0900+192
L09C1 = L0900+193
L09C2 = L0900+194
L09D0 = L0900+208
L09FF = L0900+255

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &18
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &4B, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &02
 EQUB &00, &07, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &BF, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &07
 EQUB &00, &CE, &F8, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &12, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &80

.L0A00

L0A01 = L0A00+1
L0A02 = L0A00+2
L0A3F = L0A00+63
L0A40 = L0A00+64
L0A41 = L0A00+65
L0A7F = L0A00+127
L0A80 = L0A00+128
L0A81 = L0A00+129
L0AE0 = L0A00+224
L0AE1 = L0A00+225

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &E0
 EQUB &00, &06, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &09
 EQUB &6F, &70, &71, &73, &74, &75, &76, &78
 EQUB &79, &7B, &7C, &7E, &7F, &81, &82, &84
 EQUB &86, &87, &89, &8B, &8D, &8E, &90, &92
 EQUB &95, &96, &98, &9A, &9C, &9E, &A0, &A2
 EQUB &73, &75, &76, &77, &78, &79, &7A, &7C
 EQUB &7D, &7E, &80, &82, &83, &84, &86, &88
 EQUB &89, &8B, &8D, &8F, &90, &92, &94, &96
 EQUB &98, &99, &9B, &9D, &9F, &A1, &A3, &A5
 EQUB &96, &96, &9A, &9C, &A0, &9E, &A1, &A4
 EQUB &58, &59, &5A, &5A, &A1, &A3, &B1, &B0
 EQUB &AC, &AD, &B3, &B3, &A9, &AA, &B9, &B9
 EQUB &BC, &BC, &C6, &C6, &C4, &C4, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0B00

L0B01 = L0B00+1
L0B40 = L0B00+64
L0B56 = L0B00+86
L0BA0 = L0B00+160
L0BAB = L0B00+171

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &3B, &C1, &48, &D6, &5A, &DD, &69, &EB
 EQUB &6B, &F3, &71, &EE, &73, &ED, &67, &E7
 EQUB &5E, &D3, &50, &C3, &35, &AE, &1D, &8A
 EQUB &FF, &6A, &D5, &44, &AC, &12, &77, &E2
 EQUB &1D, &A4, &2B, &B0, &35, &B8, &3B, &BC
 EQUB &46, &C6, &44, &C2, &3E, &B9, &32, &AB
 EQUB &2B, &A1, &16, &8A, &FC, &6E, &DE, &4C
 EQUB &C1, &2D, &98, &02, &6A, &D1, &37, &9B
 EQUB &71, &02, &30, &95, &D2, &6D, &30, &95
 EQUB &4E, &2D, &58, &84, &E0, &1D, &65, &49
 EQUB &9B, &B7, &EC, &2A, &F8, &8D, &CD, &49
 EQUB &47, &53, &33, &A5, &E2, &65, &10, &10

.L0C00

 EQUB &00

.L0C01

 EQUB &00

.L0C02

 EQUB &00, &00

.L0C04

 EQUB &00

.L0C05

 EQUB &28

.L0C06

 EQUB &00

.L0C07

 EQUB &00

.L0C08

 EQUB &00

.L0C09

 EQUB &00

.L0C0A

 EQUB &00, &00

.L0C0C

 EQUB &00

.L0C0D

 EQUB &00

.L0C0E

 EQUB &00

.L0C0F

 EQUB &00

.L0C10

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00

.L0C19

 EQUB &00

.L0C1A

 EQUB &00

.L0C1B

 EQUB &00

.L0C1C

 EQUB &05

.L0C1D

 EQUB &00

.L0C1E

 EQUB &00

.L0C1F

 EQUB &00

.L0C20

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0C28

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0C30

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0C40

 EQUB &00

.L0C41

 EQUB &00

.L0C42

 EQUB &00

.L0C43

 EQUB &00

.L0C44

 EQUB &00, &00, &00

.L0C47

 EQUB &00

.L0C48

 EQUB &02

.L0C49

 EQUB &20

.L0C4A

 EQUB &07

.L0C4B

 EQUB &80

.L0C4C

 EQUB &01

.L0C4D

 EQUB &00

.L0C4E

 EQUB &00

.L0C4F

 EQUB &00

.L0C50

 EQUB &00

.L0C51

 EQUB &00

.L0C52

 EQUB &00

.L0C53

 EQUB &00

.L0C54

 EQUB &00, &00

.L0C56

 EQUB &00

.L0C57

 EQUB &0D

.L0C58

 EQUB &00

.L0C59

 EQUB &16, &00

.L0C5B

 EQUB &E0

.L0C5C

 EQUB &B7

.L0C5D

 EQUB &E4

.L0C5E

 EQUB &52

.L0C5F

 EQUB &00

.L0C60

 EQUB &00

.L0C61

 EQUB &00

.L0C62

 EQUB &00

.L0C63

 EQUB &00

.L0C64

 EQUB &00

.L0C65

 EQUB &00, &00

.L0C67

 EQUB &00

.L0C68

 EQUB &00

.L0C69

 EQUB &00

.L0C6A

 EQUB &00

.L0C6B

 EQUB &00

.L0C6C

 EQUB &00

.L0C6D

 EQUB &00

.L0C6E

 EQUB &00

.L0C6F

 EQUB &00

.L0C70

 EQUB &00

.L0C71

 EQUB &00

.L0C72

 EQUB &00

.L0C73

 EQUB &00

.L0C74

 EQUB &00

.L0C75

 EQUB &00

.L0C76

 EQUB &00, &00

.L0C78

 EQUB &EF, &00

.L0C7A

 EQUB &AA

.L0C7B

 EQUB &00

.L0C7C

 EQUB &00

.L0C7D

 EQUB &01

.L0C7E

 EQUB &00

.L0C7F

 EQUB &00

.L0C80

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0C88

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0C90

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0C98

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0CA0

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0CA8

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0CB0

 EQUB &00, &00, &00, &00, &00, &00, &00, &00

.L0CB8

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00

.L0CC1

 EQUB &00

.L0CC2

 EQUB &C0

.L0CC3

 EQUB &60

.L0CC4

 EQUB &00

.L0CC5

 EQUB &00

.L0CC6

 EQUB &00

.L0CC7

 EQUB &00

.L0CC8

 EQUB &00

.L0CC9

 EQUB &00

.L0CCA

 EQUB &80

.L0CCB

 EQUB &7F

.L0CCC

 EQUB &00

.L0CCD

 EQUB &00

.L0CCE

 EQUB &00

.L0CCF

 EQUB &00

.L0CD0

 EQUB &00

.L0CD1

 EQUB &00

.L0CD2

 EQUB &00

.L0CD3

 EQUB &00

.L0CD4

 EQUB &00, &00, &00

.L0CD7

 EQUB &00, &00, &00, &00, &00

.L0CDC

 EQUB &00

.L0CDD

 EQUB &00

.L0CDE

 EQUB &00

.L0CDF

 EQUB &00, &00, &00, &00, &00

.L0CE4

 EQUB &80

.L0CE5

 EQUB &80

.L0CE6

 EQUB &80

.L0CE7

 EQUB &80

.L0CE8

 EQUB &80

.L0CE9

 EQUB &80

.L0CEA

 EQUB &80

.L0CEB

 EQUB &80, &80, &80, &80, &80

.L0CF0

 EQUB &00

.L0CF1

 EQUB &00, &00, &00, &00, &00, &00

.L0CF7

 EQUB &00, &00, &00, &00, &00

.L0CFC

 EQUB &C0

.L0CFD

 EQUB &00

.L0CFE

 EQUB &00, &00

.NMI

 RTI

.L0D01

 EQUB &93

.L0D02

 EQUB &DC

.sub_C0D03

 STA L0074

.sub_C0D05

 LDA #&00
 LSR L0074
 BCC C0D0E
 CLC
 ADC L0075

.C0D0E

 ROR A
 ROR L0074
 BCC C0D16
 CLC
 ADC L0075

.C0D16

 ROR A
 ROR L0074
 BCC C0D1E
 CLC
 ADC L0075

.C0D1E

 ROR A
 ROR L0074
 BCC C0D26
 CLC
 ADC L0075

.C0D26

 ROR A
 ROR L0074
 BCC C0D2E
 CLC
 ADC L0075

.C0D2E

 ROR A
 ROR L0074
 BCC C0D36
 CLC
 ADC L0075

.C0D36

 ROR A
 ROR L0074
 BCC C0D3E
 CLC
 ADC L0075

.C0D3E

 ROR A
 ROR L0074
 BCC C0D46
 CLC
 ADC L0075

.C0D46

 ROR A
 ROR L0074
 RTS

.sub_C0D4A

 ASL L0074
 ROL A
 BCS C0D5B
 CMP L0076
 BCC C0D68
 BNE C0D5B
 LDY L0074
 CPY L0077
 BCC C0D68

.C0D5B

 STA L0075
 LDA L0074
 SBC L0077
 STA L0074
 LDA L0075
 SBC L0076
 SEC

.C0D68

 ROL L0074
 ROL A
 BCS C0D79
 CMP L0076
 BCC C0D86
 BNE C0D79
 LDY L0074
 CPY L0077
 BCC C0D86

.C0D79

 STA L0075
 LDA L0074
 SBC L0077
 STA L0074
 LDA L0075
 SBC L0076
 SEC

.C0D86

 ROL L0074
 ROL A
 BCS C0D97
 CMP L0076
 BCC C0DA4
 BNE C0D97
 LDY L0074
 CPY L0077
 BCC C0DA4

.C0D97

 STA L0075
 LDA L0074
 SBC L0077
 STA L0074
 LDA L0075
 SBC L0076
 SEC

.C0DA4

 PHP
 CMP L0076
 BEQ C0E10
 ASL L0074
 ROL A
 BCS C0DB2
 CMP L0076
 BCC C0DB5

.C0DB2

 SBC L0076
 SEC

.C0DB5

 ROL L0074
 ROL A
 BCS C0DBE
 CMP L0076
 BCC C0DC1

.C0DBE

 SBC L0076
 SEC

.C0DC1

 ROL L0074
 ROL A
 BCS C0DCA
 CMP L0076
 BCC C0DCD

.C0DCA

 SBC L0076
 SEC

.C0DCD

 ROL L0074
 ROL A
 BCS C0DD6
 CMP L0076
 BCC C0DD9

.C0DD6

 SBC L0076
 SEC

.C0DD9

 ROL L0074
 ROL A
 BCS C0DE2
 CMP L0076
 BCC C0DE5

.C0DE2

 SBC L0076
 SEC

.C0DE5

 ROL L0074
 ROL A
 BCS C0DEE
 CMP L0076
 BCC C0DF1

.C0DEE

 SBC L0076
 SEC

.C0DF1

 ROR L0078
 ROL A
 BCS C0DF8
 CMP L0076

.C0DF8

 ROR L0078
 LDA L0074

.C0DFC

 PLP
 BCC C0E01
 ADC #&1F

.C0E01

 BCC C0E1F
 LDA #&FF
 STA L007E
 LDA #&00
 STA L008A
 LDA #&20
 STA L008B
 RTS

.C0E10

 LDA #&00
 STA L0078
 ROR L0074
 ROR A
 ROR L0074
 ROR A
 ORA #&20
 JMP C0DFC

.C0E1F

 TAY
 STA L007E
 LDA L3B00,Y
 STA L008A
 LDA L3C01,Y
 STA L008B
 BIT L0078
 BMI C0E35
 BVS C0E50
 JMP return_1

.C0E35

 LDA L008A
 SEC
 SBC L3B01,Y
 STA L0074
 LDA L008B
 SBC L3C02,Y
 BIT L0078
 BVC C0E49
 JSR sub_C1009

.C0E49

 STA L0075
 ROL A
 ROR L0075
 ROR L0074

.C0E50

 LDA L008A
 CLC
 ADC L3B01,Y
 STA L008A
 LDA L008B
 ADC L3C02,Y
 STA L008B
 BIT L0078
 BPL C0E70
 LDA L008A
 CLC
 ADC L0074
 STA L008A
 LDA L008B
 ADC L0075
 STA L008B

.C0E70

 LSR L008B
 ROR L008A

.return_1

 RTS

.sub_C0E75

 STA L0C0C
 STX L0F3B
 JSR sub_C0F3E
 STA L0C53
 LDA L0075
 STA L0C54
 LDX #&01
 STX L0060
 LDX #&00
 BIT L0C0C
 BVC C0E94
 INX
 DEC L0060

.C0E94

 CMP #&7A
 BCC C0EA1
 BCS C0ECB

 LDA L0C53
 CMP #&F0
 BCS C0ECB

.C0EA1

 LDA #&AB
 JSR sub_C0D03
 JSR sub_C0D03
 STA L0076
 JSR sub_C0F4A
 LDA L0C53
 SEC
 SBC L0074
 STA L0074
 LDA L0C54
 SBC L0075
 ASL L0074
 ROL A
 STA L0C02,X
 LDA L0074
 AND #&FE
 STA L0C00,X
 JMP C0EFD

.C0ECB

 LDA #&00
 SEC
 SBC L0C53
 STA L0074
 LDA #&C9
 SBC L0C54
 STA L0075
 STA L0076
 JSR sub_C0F4A
 ASL L0074
 ROL L0075
 LDA #&00
 SEC
 SBC L0074
 AND #&FE
 STA L0C00,X
 LDA #&00
 SBC L0075
 BCC C0EFA
 LDA #&FE
 STA L0C00,X
 LDA #&FF

.C0EFA

 STA L0C02,X

.C0EFD

 CPX L0060
 BEQ C0F19
 LDX L0060
 LDA #&00
 SEC
 SBC L0C53
 STA L0C53
 LDA #&C9
 SBC L0C54
 STA L0C54
 STA L0075
 JMP C0E94

.C0F19

 LDA L0C0C

.sub_C0F1C

L0F1D = sub_C0F1C+1

 BPL C0F26
 LDA #&01
 ORA L0C00
 STA L0C00

.C0F26

 LDA L0C0C
 ASL A
 EOR L0C0C
 BPL C0F37
 LDA #&01
 ORA L0C01

.sub_C0F34

L0F36 = sub_C0F34+2

 STA L0C01

.C0F37

 LDX L0F3B
 RTS

.L0F3B

 EQUB &00, &A9, &00

.sub_C0F3E

 ASL L0074
 ROL A
 ASL L0074
 ROL A
 STA L0076
 LDA #&C9
 STA L0075

.sub_C0F4A

 JSR sub_C0D05
 STA L0077
 LDA L0076
 JSR sub_C0D03
 STA L0075
 LDA L0077
 CLC
 ADC L0074
 STA L0074
 BCC return_2
 INC L0075

.return_2

 RTS

.sub_C0F62

 TYA
 PHA
 LDA #129               \ osbyte_inkey
 LDY #&FF
 JSR OSBYTE
 PLA
 TAY
 CPX #&FF
 RTS

.sub_C0F70

 BPL C0F74
 EOR #&40

.C0F74

 STA L0067
 ASL L0074
 ROL A
 AND #&7F
 TAX
 EOR #&7F
 CLC
 ADC #&01
 BPL C0F85
 LDA #&7F

.C0F85

 TAY
 LDA L5980,X
 LDX L5980,Y
 BIT L0067
 BMI C0F97
 BVS C0F99

.loop_C0F92

 STA L008E
 STX L008F
 RTS

.C0F97

 BVS loop_C0F92

.C0F99

 STA L008F
 STX L008E
 RTS

.sub_C0F9E

 LDA L006B
 BPL C0FB5
 LDA #&00
 SEC
 SBC L006A
 STA L006A
 LDA #&00
 SBC L006B
 STA L006B
 LDA L0067
 EOR #&80
 STA L0067

.C0FB5

 LDA L0068
 AND #&01
 BEQ C0FC1
 LDA L0067
 EOR #&80
 STA L0067

.C0FC1

 LDA L006B
 STA L0075
 LDA L0068
 JSR sub_C0D03
 STA L0077
 LDA L0074
 CLC
 ADC #&80
 STA L0076
 BCC C0FD7
 INC L0077

.C0FD7

 LDA L0069
 JSR sub_C0D03
 STA L0078
 LDA L0074
 CLC
 ADC L0077
 STA L0077
 BCC C0FE9
 INC L0078

.C0FE9

 LDA L006A
 STA L0075
 LDA L0069
 JSR sub_C0D03
 STA L0075
 LDA L0074
 CLC
 ADC L0076
 LDA L0075
 ADC L0077
 STA L0074
 BCC C1003
 INC L0078

.C1003

 LDA L0078
 BIT L0067

.sub_C1007

 BPL return_3

.sub_C1009

 STA L0075
 LDA #&00
 SEC
 SBC L0074
 STA L0074
 LDA #&00
 SBC L0075

.return_3

 RTS

.C1017

 LDX #&FF
 TXS
 LDA #&04
 JSR sub_C5E2C
 JSR sub_C1149
 LDA #&00
 JSR sub_C324C
 LDX #&00
 JSR sub_C36AD
 LDA #&87
 JSR sub_C5E2C
 JSR sub_C5E07

.C1034

 JSR sub_C1149
 LDX #&01
 JSR sub_C36AD
 LDA #&04
 JSR sub_C329F
 JSR sub_C3321
 LDY L0CF1
 LDX L0CF0
 JSR sub_C33B7
 LDA L0C52
 BNE C105F
 LDX #&03

.loop_C1054

 LDA L108C,X
 STA L0CF0,X
 DEX
 BPL loop_C1054
 BMI C106C

.C105F

 LDX #&02
 JSR sub_C36AD
 LDA #&08
 JSR sub_C329F
 JSR sub_C3321

.C106C

 LDA #&04
 JSR sub_C5E2C
 JSR sub_C2A9C

.C1074

 JSR sub_C1149
 LDA #&00
 JSR sub_C324C
 LDA #&87
 JSR sub_C5E2C
 LDX #&03
 JSR sub_C36AD
 JSR sub_C5E07
 JMP C1034

.L108C

 EQUB &87, &53, &04, &06

.sub_C1090

 JSR sub_C130C
 JSR sub_C3699
 LDA #&00
 JSR sub_C2963
 LDA #&00
 LDY #&18
 LDX #&28
 JSR sub_C2202
 LDA L0C4C
 CMP #&03
 BNE return_4
 LDA #&03
 STA L0015

.loop_C10AF

 JSR sub_C56D5
 DEC L0015
 BNE loop_C10AF

.return_4

 RTS

.sub_C10B7

 LDY L0008
 LDX L006E
 CPY #&02
 BCS C10FD
 LDA L09C0,X
 CLC
 ADC L38F4,Y
 STA L09C0,X
 LDA #&19
 LDY #&18
 LDX #&10
 STX L0C69
 JSR sub_C2202
 JSR sub_C391E
 JSR sub_C2624
 LDX L006E
 LDY L0008
 BCS C10F2
 BNE C10EC
 LDA L09C0,X
 SEC
 SBC #&0C
 STA L09C0,X

.C10EC

 LDA #&10
 JSR sub_C38F8
 RTS

.C10F2

 LDA L09C0,X
 SEC
 SBC L38F4,Y
 STA L09C0,X
 RTS

.C10FD

 LDA L0140,X
 CMP L1145,Y
 BEQ return_5
 CLC
 ADC L38F4,Y
 STA L0140,X
 LDA #&19
 LDY #&08
 LDX #&28
 STX L0C69
 JSR sub_C2202
 JSR sub_C3908
 JSR sub_C2624
 LDX L000B
 LDY L0008
 BCS C113A
 CPY #&03
 BNE C1131
 LDA L0140,X
 CLC
 ADC #&08
 STA L0140,X

.C1131

 LDA #&08
 JSR sub_C38F8

.loop_C1136

 JSR sub_C3923

.return_5

 RTS

.C113A

 LDA L0140,X
 SEC
 SBC L38F4,Y
 STA L0140,X

.sub_C1144

L1145 = sub_C1144+1

 JMP loop_C1136

.L1147

 EQUB &35

.L1148

 EQUB &CD

.sub_C1149

 SEC
 ROR L0CFC
 LDX #&00

.C114F

 LDA #&00
 STA L0900,X
 STA L0A00,X
 CPX #&90
 BCS C115D
 STA L0000,X

.C115D

 CPX #&C0
 BCS C1164
 STA L0100,X

.C1164

 CPX #&E4
 BCC C116A
 LDA #&80

.C116A

 STA L0C00,X
 INX
 CPX #&F0
 BCC C114F

.sub_C1172

 LDX #&3F

.loop_C1174

 LDA #&FF
 STA L3E80,X
 STA L3EC0,X
 LDA #&80
 STA L0100,X
 DEX
 BPL loop_C1174
 INC L0C7D
 JSR sub_C3923
 RTS

.sub_C118B

 LDA #&80
 STA L0009
 LDX #&8E
 JSR sub_C0F62
 BNE C119A
 SEC
 ROR L0C64

.C119A

 LDX #&9D
 JSR sub_C0F62
 BNE C11C0
 LDA L1222
 BNE C11C5
 LDA L0C5F
 EOR #&80
 STA L0C5F
 BPL C11B9
 JSR sub_C1331
 JSR C39D9
 JMP C11BC

.C11B9

 JSR sub_C3AA7

.C11BC

 LDA #&80
 BNE C11C2

.C11C0

 LDA #&00

.C11C2

 STA L1222

.C11C5

 LDY #&0E
 JSR sub_C1353
 BPL C11DD
 LDA #&6B
 STA L0CC8
 LDA L0CE9
 BPL C1200
 LDA #&40
 STA L0C51
 BNE C1208

.C11DD

 LDX L0C5F
 BPL C11ED
 ASL L0CC8
 BCS C1208
 JSR sub_C3927
 JMP C11F9

.C11ED

 LDA L0CE8
 BPL C11F7
 LDA L0CEA
 BMI C1208

.C11F7

 STA L0009

.C11F9

 LDA L0009
 BMI C1208
 STA L0C1D

.C1200

 LDA #&80
 STA L0CE4
 STA L0C1E

.C1208

 LDA L0CE4
 STA L0CDC
 RTS

.sub_C120F

 SEI
 LDY #&03
 JSR sub_C1353
 LDA L0C1D
 CMP L0CE8
 BEQ C1220
 CMP L0CEA

.C1220

 CLI
 RTS

.L1222

 EQUB &00, &00

.sub_C1224

 STA L0006
 LDA #&00
 STA L0015

.C122A

 DEC L0015
 BNE C1236
 INC L0006
 LDA L0006
 CMP #&0C
 BCS C1258

.C1236

 JSR C125A
 STA L0024
 JSR C125A
 STA L0026
 JSR sub_C2B78
 BCS C122A
 AND #&0F
 BNE C122A
 LDA (L005E),Y
 LSR A
 LSR A
 LSR A
 LSR A
 CMP L0006
 BCS C122A
 JSR sub_C1EFF
 CLC
 RTS

.C1258

 SEC
 RTS

.C125A

 JSR C3194
 AND #&1F
 CMP #&1F
 BCS C125A
 RTS

.sub_C1264

 LDA #&00
 STA L0CE4
 STA L0C51

.C126C

 LDA L0CE4
 BMI C12AD
 LSR L0C1F
 LDA L0CDC
 BPL C1282
 JSR sub_C120F
 BNE C1282
 SEC
 ROR L0C1F

.C1282

 JSR sub_C16A8
 LDA L0C4E
 BEQ C1294
 LDA #&1E
 JSR sub_C5F24

.C128F

 JSR C1200
 SEC
 RTS

.C1294

 ASL L0C63
 BCS C128F
 BIT L0C64
 BMI C128F
 JSR sub_C191A
 JSR sub_C34E1
 JSR sub_C355A
 JSR C3480
 JMP C126C

.C12AD

 LDA L0009
 BMI C12B3
 CLC
 RTS

.C12B3

 LDA L0CE9
 BMI C12EB
 CMP #&22
 BCS C12C1
 BIT L0C5F
 BPL C12EB

.C12C1

 STA L0C61
 LSR L0CE5
 JSR sub_C1B0B
 BCS C12E5
 JSR sub_C3553
 LDA #&02
 JSR C3440
 LDA #&C0
 STA L0C6D
 LSR L0C1E
 JSR sub_C1F84
 JSR sub_C3553
 JSR sub_C36C7

.C12E5

 ASL L0C63
 BCC C12EB
 RTS

.C12EB

 JMP sub_C1264

.sub_C12EE

 LDA L0C50
 BNE C1308
 LDX #&17

.loop_C12F5

 LDA L0C20,X
 CMP #&02
 BCC C12FF
 DEC L0C20,X

.C12FF

 DEX
 BPL loop_C12F5
 LDA #&02
 STA L0C50
 RTS

.C1308

 DEC L0C50
 RTS

.sub_C130C

 SEI
 LDA #&C0
 STA L0CC2
 LDA #&60
 STA L0CC3
 JSR sub_C3AD3
 LDA #&0F
 PHA
 LDA #&F0
 LDX #13                \ crtc_screen_start_low
 STX SHEILA+&00         \ crtc_address_register
 STA SHEILA+&01         \ crtc_register_data
 DEX
 STX SHEILA+&00         \ crtc_address_register
 PLA
 STA SHEILA+&01         \ crtc_register_data
 CLI
 RTS

.sub_C1331

 LDA L0CC2
 CLC
 ADC #&A0
 STA L0CC4
 LDA L0CC3
 ADC #&0F
 CMP #&80
 BCC C1345
 SBC #&20

.C1345

 STA L0CC5
 LDA #&50
 STA L0CC6
 LDA #&5F
 STA L0CC7
 RTS

.sub_C1353

 LDX #&03
 LDA #&80

.loop_C1357

 STA L0CE8,X
 DEX
 BPL loop_C1357

.loop_C135D

 LDX L137D,Y
 JSR sub_C0F62
 BNE C1373
 LDA L138C,Y
 AND #&03
 TAX
 LDA L138C,Y
 LSR A
 LSR A
 STA L0CE8,X

.C1373

 DEY
 BPL loop_C135D
 LDA L0CE8
 AND L0CEA
 RTS

.L137D

 EQUB &AE, &CD, &A9, &99, &BE, &EF, &CC, &DC
 EQUB &9B, &AB, &DB, &EA, &96, &A6, &CA

.L138C

 EQUB &04, &00, &0A, &0E, &81, &85, &01, &09
 EQUB &0D, &89, &03, &07, &0B, &0F, &8D

.sub_C139B

 STA L0C1C
 STX L0C4C
 TXA
 LDX #&02
 EOR #&03
 STA L5797
 BEQ C13AC
 INX

.C13AC

 STX L57A2
 STY L140F
 LDA L1403,Y
 STA L0950
 LDA L1405,Y
 STA L0150
 LDA L1407,Y
 STA L0910
 LDA L140B,Y
 STA L0990
 LDA L140D,Y
 STA L09D0
 LDA L1409,Y
 PHA
 JSR sub_C1090
 LDA L0C1C
 BMI C13DF
 JSR sub_C5FE5

.C13DF

 PLA
 STA L0C78
 LDX #&10
 STX L006E
 JSR sub_C2624
 LDA L140F
 BNE C13FA
 LDX #&7F
 STX L140F

.loop_C13F4

 STA L3E80,X
 DEX
 BPL loop_C13F4

.C13FA

 LDA #&00
 STA L0C78
 STA L0C4C
 RTS

.L1403

 EQUB &21, &4B

.L1405

 EQUB &EA, &D9

.L1407

 EQUB &0F, &00

.L1409

 EQUB &00, &EF

.L140B

 EQUB &C2, &BF

.L140D

 EQUB &00, &12

.L140F

 EQUB &01

.sub_C1410

 LDA L0C52
 BNE C1419
 LDA #&01
 BNE C1424

.C1419

 JSR sub_C33F0
 CMP L0C07
 BCC C1424
 LDA L0C07

.C1424

 STA L0C6F
 JSR sub_C14EB
 LDA L0C6F
 SEC
 SBC #&01
 AND #&07
 TAX
 LDA L14C4,X
 STA L5E5A
 LDA L14E3,X
 STA L5E59
 RTS

.sub_C1440

 LDA #&00
 JSR sub_C210E
 STX L000B
 LDA #&0A
 STA L0C0A
 LDA L0C52
 BNE C145F
 LDA #&08
 STA L0024
 LDA #&11
 STA L0026
 JSR sub_C1EFF
 JMP C146D

.C145F

 LDA L0C06
 CMP #&06
 BCC C1468
 LDA #&06

.C1468

 JSR sub_C1224
 BCS C145F

.C146D

 LDA #&30
 SEC
 SBC L0C6F
 SBC L0C6F
 SBC L0C6F
 STA L0075
 JSR sub_C341B
 CLC
 ADC #&0A
 CMP L0075
 BCC C1487
 LDA L0075

.C1487

 STA L001E

.loop_C1489

 LDA #&02
 JSR sub_C210E
 LDA L0C06
 JSR sub_C1224
 BCS C149A
 DEC L001E
 BNE loop_C1489

.C149A

 LDX #&AA
 LDY L0BAB,X
 BIT L0C71
 BPL C14A6
 LDX #&A5

.C14A6

 JSR sub_C3364
 SEC
 SBC L0C6F,X
 BEQ C14B0
 CLC

.C14B0

 ROL L0C65
 CLC
 ADC L0100
 STA sub_C3F00,Y
 INY
 DEX
 BMI C14A6
 ASL L0C71
 BCC C14CC

.return_6

 RTS

.L14C4

 EQUB &02, &01, &03, &06, &01, &06, &01, &03

.C14CC

 LDA L0C65
 AND #&1E
 CMP #&1E
 BNE return_6
 PLA
 PLA
 CLC
 LDA L0100
 ADC #&B6
 PHA
 CLC
 ADC #&6E
 PHA
 RTS

.L14E3

 EQUB &07, &03, &06, &01, &07, &03, &06, &01

.sub_C14EB

 JSR sub_C15BC
 LDX #&00

.C14F0

 STX L006E
 LDA #&01
 STA L0A40,X

.loop_C14F7

 JSR sub_C158D
 BCC C150B
 LDA L0006
 SEC
 SBC #&10
 STA L0006
 BNE loop_C14F7
 STX L0C6F
 JMP C1582

.C150B

 JSR C3194
 AND L0027
 CMP L0074
 BCS C150B
 TAY
 LDX L5A40,Y
 LDA #&00
 STA L5B07,X
 STA L5B08,X
 STA L5B09,X
 STA L5B0F,X
 STA L5B10,X
 STA L5B11,X
 STA L5B17,X
 STA L5B18,X
 STA L5B19,X
 LDA L5B60,X
 STA L0024
 LDA L5BA0,X
 STA L0026
 LDX L006E
 BNE C155F
 STA L0C1A
 LDA L0024
 STA L0C19
 LDA #&05
 STA L0A40
 LDA #&06
 JSR sub_C210E
 JSR sub_C1EFF
 LDA #&00
 STA L09C0,X
 LDX L006E

.C155F

 JSR sub_C1EFF
 JSR sub_C196A
 JSR C3194
 LSR A
 AND #&3F
 ORA #&05
 STA L0C30,X
 LDA #&14
 BCC C1576
 LDA #&EC

.C1576

 STA L4A37,X
 INX
 CPX L0C6F
 BCS C1582
 JMP C14F0

.C1582

 LDA L0006
 LSR A
 LSR A
 LSR A
 LSR A
 STA L0C06
 CLC
 RTS

.sub_C158D

 LDX #&3F
 LDY #&00

.loop_C1591

 LDA L5B10,X
 CMP L0006
 BNE C159D
 TXA
 STA L5A40,Y
 INY

.C159D

 DEX
 BPL loop_C1591
 TYA
 BEQ C15B2
 STA L0074
 LDY #&FF

.loop_C15A7

 ASL A
 INY
 BCC loop_C15A7
 LDA L15B4,Y
 STA L0027
 CLC
 RTS

.C15B2

 SEC
 RTS

.L15B4

 EQUB &FF, &7F, &3F, &1F, &0F, &07, &03, &01

.sub_C15BC

 LDX #&00
 STX L0006

.C15C0

 TXA
 AND #&07
 ASL A
 ASL A
 STA L0018
 TXA
 AND #&38
 LSR A
 STA L001A
 LDA #&00
 STA L5B10,X
 LDA #&04
 STA L000C
 LDA L001A
 STA L0026
 CMP #&1C
 BCC C15E0
 DEC L000C

.C15E0

 LDA #&04
 STA L000D
 LDA L0018
 STA L0024
 CMP #&1C
 BCC C15EE
 DEC L000D

.C15EE

 JSR sub_C2B78
 AND #&0F
 BNE C1611
 LDA (L005E),Y
 AND #&F0
 CMP L5B10,X
 BCC C1611
 STA L5B10,X
 CMP L0006
 BCC C1607
 STA L0006

.C1607

 LDA L0024
 STA L5B60,X
 LDA L0026
 STA L5BA0,X

.C1611

 INC L0024
 DEC L000D
 BNE C15EE
 INC L0026
 DEC L000C
 BNE C15E0
 INX
 CPX #&40
 BCC C15C0
 RTS

.sub_C1623

 LDA L0C04
 BNE C162D
 CMP L0C09
 BEQ return_7

.C162D

 STA L0C09
 STA L169B
 LDA L0CC2
 SEC
 SBC #&4F
 STA L0022
 LDA L0CC3
 SBC #&00
 CMP #&60
 BCS C1646
 ADC #&20

.C1646

 STA L0023
 LDA #&08
 STA L169A

.C164D

 LDY #&03
 JSR sub_C568E
 JMP C165A

.loop_C1655

 LDA L1699
 LSR A
 LSR A

.C165A

 STA L1699
 AND #&03
 ORA L169B
 TAX
 LDA L169C,X
 STA (L0022),Y
 DEY
 BPL loop_C1655
 LDA L0022
 CLC
 ADC #&08
 STA L0022
 LDA L0023
 ADC #&00
 CMP #&80
 BCC C167C
 SBC #&20

.C167C

 STA L0023
 DEC L169A
 BEQ return_7
 LDA L169A
 CMP #&04
 BNE C164D
 LDA L0C4F
 CMP #&40
 BNE C164D
 LDA #&00
 STA L169B
 BEQ C164D

.return_7

 RTS

.L1699

 EQUB &00

.L169A

 EQUB &00

.L169B

 EQUB &00

.L169C

 EQUB &0F, &0F, &0F, &0F, &8F, &4F, &2F, &1F
 EQUB &FF, &FF, &FF, &FF

.sub_C16A8

 TSX
 STX L0C0D
 LDX L0000
 LDA L0A40,X
 CMP #&01
 BEQ C16B9
 CMP #&05
 BNE C16C9

.C16B9

 STA L0C1C
 LDA L0100,X
 BPL C16D9
 JSR sub_C1A54
 BCS C16C9
 JMP C1871

.C16C9

 JSR C3194
 DEC L0000
 BPL C16D4
 LDA #&07
 STA L0000

.C16D4

 LDA L000B
 STA L006E
 RTS

.C16D9

 LDA L0C30,X
 CMP #&02
 BCS C16C9
 LDA #&04
 STA L0C30,X
 LDA #&14
 STA L0C68
 LDA L0CA0,X
 BPL C16F2
 JMP C176A

.C16F2

 STA L006E
 LDY L0CA8,X
 LDA L0100,Y
 BMI C174F
 LDA #&00
 JSR sub_C1882
 LDA L0C57
 CMP #&14
 BCS C171B
 CPY L000B
 BNE C174F
 LDA L0014
 BEQ C1754
 JSR sub_C2147
 LDA #&04
 STA L0C1C
 JMP C16C9

.C171B

 LDA #&08
 BIT L0C57
 BPL C1724
 LDA #&F8

.C1724

 STA L0C0E
 LDY L0000
 LDX L0CA0,Y
 TXA
 JSR sub_C1AE7
 LDA L09C0,X
 CLC
 ADC L0C0E
 STA L09C0,X
 LDA #&0A
 STA L0C30,Y
 TXA
 PHA
 LDX #&03
 LDY #&46
 LDA #&01
 JSR sub_C343A
 PLA
 TAX
 JMP C1876

.C174F

 LDA #&00
 STA L0C20,X

.C1754

 LDY L0000
 LDX L0CA0,Y
 TXA
 JSR sub_C1AE7
 LDA #&80
 STA L0CA0,Y
 LDA #&02
 STA L0A40,X
 JMP C1871

.C176A

 STX L006E
 JSR sub_C1A54
 BCS C1774
 JMP C1871

.C1774

 LDX L0000
 LDA L0CB8,X
 BPL C178C
 JSR sub_C1AA7
 LDX L0000
 BCS C1789
 LDA #&40
 STA L0C80,X
 BNE C17E1

.C1789

 LSR L0CB8,X

.C178C

 LDA L0C20,X
 BEQ C17A3
 LDY L0CA8,X
 LDA #&00
 JSR sub_C1882
 LDA L0014
 BEQ C17A0
 JMP C1820

.C17A0

 STA L0C20,X

.C17A3

 LDA #&80
 STA L000F
 LDY #&3F

.loop_C17A9

 LDA #&00
 JSR sub_C1882
 LDA L0C76
 AND #&40
 BNE C17C1
 LDA L0014
 BEQ C17C1
 BMI C1820
 CPY L000B
 BNE C17C1
 STY L000F

.C17C1

 DEY
 BPL loop_C17A9
 LDY L000F
 BMI C17D7
 TYA
 CMP L0C90,X
 BEQ C17D7
 JSR sub_C196A
 LDA #&40
 STA L0014
 BNE C1820

.C17D7

 LDA #&00
 STA L0C20,X
 JSR sub_C1AA7
 BCS C17F0

.C17E1

 JSR sub_C19FF
 BCS C17F9
 LDY L0000
 LDA #&1E
 STA L0C30,Y
 JMP C1871

.C17F0

 LDX L0000
 LDA L0C28,X
 CMP #&02
 BCC C17FC

.C17F9

 JMP C16C9

.C17FC

 TXA
 JSR sub_C1AE7
 LDA L09C0,X
 CLC
 ADC L4A37,X
 STA L09C0,X
 LDA #&C8
 STA L0C28,X
 JSR sub_C196A
 LDX #&07
 LDY #&78
 LDA #&00
 JSR sub_C343A
 LDX L0000
 JMP C1876

.C1820

 TYA
 STA L0CA8,X
 LDA L0014
 STA L0CB0,X
 LDA L0C20,X
 CMP #&01
 BCS C1838
 LDA #&78
 STA L0C20,X

.loop_C1835

 JMP C16C9

.C1838

 BNE loop_C1835
 LDA L0014
 BPL C184D
 JSR sub_C19FF
 LDY L0000
 LDA #&1E
 STA L0C30,Y
 BCS C187F
 JMP C1871

.C184D

 JSR sub_C197D
 LDY L0000
 BCC C1869
 LDA L0C98,Y
 CMP #&02
 BCS C1862
 LDA #&80
 STA L0CB8,Y
 BNE C187F

.C1862

 LDA #&00
 STA L0C20,Y
 BEQ C187F

.C1869

 LDA #&32
 STA L0C30,Y
 LDX L0CA0,Y

.C1871

 LDA #&40
 STA L0C6D

.C1876

 STX L0001
 LDA L000B
 STA L006E
 JSR sub_C1F84

.C187F

 JMP C16C9

.sub_C1882

 STA L0074
 STX L1919
 STY L0C58
 LDA #&00
 STA L0014
 LDA L0100,Y
 BMI C1911
 LDA L0A40,Y
 CMP L0074
 BNE C1911
 JSR sub_C5C01
 LDX #&07
 LDA L0F36,X
 STA L0074
 AND #&0F
 CMP #&09
 BEQ C18AC
 LDX #&01

.C18AC

 TXA
 CLC
 ADC L0074
 STA L0C75
 LDA L0C68
 LSR A
 STA L0074
 LDA L0C57
 SEC
 SBC #&0A
 CLC
 ADC L0074
 CMP L0C68
 BCS C1912
 LDA L008A
 STA L003D
 LDA L008B
 STA L003E
 LDA #&02
 STA L001E
 LDA L004C
 BNE C18FF
 SEC
 ROR L0C6E
 LDA L0081
 STA L0080
 LDA L0084

.C18E1

 JSR sub_C561D
 LDA L008A
 STA L003F
 STA L0074
 LDA L008B
 STA L0040
 JSR sub_C1C43
 JSR sub_C1CCC
 ROL L0C56
 ROR L0014
 ROL L0CDD
 ROR L0C76

.C18FF

 LSR L0C6E
 LDA L0081
 SEC
 SBC #&E0
 STA L0080
 LDA L0084
 SBC #&00
 DEC L001E
 BNE C18E1

.C1911

 CLC

.C1912

 LDX L1919
 LDY L0C58
 RTS

.L1919

 EQUB &00

.sub_C191A

 LDY #&00
 STY L0074
 LDX #&07

.C1920

 LDA L0100,X
 BMI C1945
 LDA L0A40,X
 CMP #&01
 BEQ C1930
 CMP #&05
 BNE C1945

.C1930

 LDA L0CA8,X
 CMP L000B
 BNE C1945
 LDA L0C20,X
 BEQ C1945
 LDY #&04
 LDA L0CB0,X
 STA L0074
 BMI C1948

.C1945

 DEX
 BPL C1920

.C1948

 STY L0C04
 LDA L0074
 STA L0C4F
 LDA L0C73
 CPY L0C73
 STY L0C73
 BEQ return_8
 LDY #&12
 STY L5910
 CMP #&03
 BEQ return_8
 LDX #&06
 JSR C3555

.return_8

 RTS

.sub_C196A

 LDA #&80
 STA L0CA0,X
 STA L0C90,X
 LDA #&00
 STA L0C98,X
 LDA #&40
 STA L0C80,X
 RTS

.sub_C197D

 LDA #&28
 STA L0C68
 LDX L0000
 STX L006E

.C1986

 LDX L0000
 LDY L0C80,X
 BNE C1998
 INC L0C98,X
 LDA L0CA8,X
 STA L0C90,X
 SEC
 RTS

.C1998

 DEC L0C80,X
 DEY
 LDA L0100,Y
 BMI C1986
 LDA L0A40,Y
 CMP #&02
 BNE C1986
 LDA L0CA8,X
 TAX
 LDA L0900,X
 SEC
 SBC L0900,Y
 BPL C19BA
 EOR #&FF
 CLC
 ADC #&01

.C19BA

 CMP #&0A
 BCS C1986
 LDA L0980,X
 SEC
 SBC L0980,Y
 BPL C19CC
 EOR #&FF
 CLC
 ADC #&01

.C19CC

 CMP #&0A
 BCS C1986
 LDA #&02
 JSR sub_C1882
 LDA L0014
 BPL C1986
 LDX L0000
 TYA
 JSR sub_C1AF3
 BCC C19F1
 TYA
 STA L0CA0,X
 LDA #&04
 STA L0A40,Y
 LDA #&68
 STA L0CD4
 CLC
 RTS

.C19F1

 INC L0C80,X
 JMP C1AEC

.loop_C19F7

 LDA #&80
 STA L0C4E
 JMP C1AEC

.sub_C19FF

 LDX L0C58
 CPX L000B
 BNE C1A1D
 LDA L0C0A
 BEQ loop_C19F7
 SEC
 SBC #&01
 STA L0C0A
 JSR sub_C36C7
 LDA #&05
 JSR C3440
 SEC
 JMP C1A46

.C1A1D

 TXA
 JSR sub_C1AE7
 LDA L0A40,X
 BNE C1A31
 LDY L0000
 LDA #&00
 STA L0C20,Y
 LDA #&03
 BNE C1A42

.C1A31

 CMP #&02
 BNE C1A3B
 JSR sub_C1ED8
 JMP C1A45

.C1A3B

 LDA #&74
 STA L0CD4
 LDA #&02

.C1A42

 STA L0A40,X

.C1A45

 CLC

.C1A46

 PHP
 LDY L0000
 LDA L0C88,Y
 CLC
 ADC #&01
 STA L0C88,Y
 PLP
 RTS

.sub_C1A54

 LDX L0000
 SEC
 LDA L0C88,X
 BEQ return_9
 LDA #&02
 JSR sub_C210E
 LDA L0C06
 JSR sub_C1224
 BCS return_9
 TXA
 JSR sub_C1AF3
 BCC C1A78
 LDX L0000
 DEC L0C88,X
 LDX L0001
 CLC

.return_9

 RTS

.C1A78

 JSR sub_C1ED8
 JMP C1AEC

.sub_C1A7E

 SED
 JSR sub_C342C
 CLC
 ADC L0CFD
 TAX
 LDA L0CFE
 ADC #&00
 TAY
 CLD
 JSR sub_C33B7
 JSR sub_C2A9C
 JSR sub_C1410
 JSR sub_C1440
 LDA #&80
 JSR sub_C324C
 LDX #&05
 JSR sub_C36AD
 JMP C33AB

.sub_C1AA7

 LDX #&3F

.C1AA9

 LDA L0100,X
 BMI C1AE2
 CMP #&40
 BCS C1AB9
 LDA L0A40,X
 CMP #&03
 BNE C1AE2

.C1AB9

 LDA L0900,X
 STA L0024
 LDA L0980,X
 STA L0026
 JSR sub_C2B78
 BCC C1AE2
 AND #&3F
 TAY
 LDA L0A40,Y
 CMP #&02
 BEQ C1AD6
 CMP #&03
 BNE C1AE2

.C1AD6

 JSR sub_C1882
 LDA L0014
 BPL C1AE2
 STY L0C58
 CLC
 RTS

.C1AE2

 DEX
 BPL C1AA9
 SEC
 RTS

.sub_C1AE7

 JSR sub_C1AF3
 BCS return_10

.C1AEC

 LDX L0C0D
 TXS
 JMP C16C9

.sub_C1AF3

 SEC
 BIT L0C1F
 BPL return_10
 STA L0001
 LDA L000B
 STA L006E
 TXA
 PHA
 TYA
 PHA
 JSR sub_C2096
 PLA
 TAY
 PLA
 TAX

.return_10

 RTS

.sub_C1B0B

 LDA L0C61
 CMP #&22
 BNE C1B1C
 JSR sub_C2147
 LDA #&00
 STA L0C1C

.loop_C1B1A

 SEC
 RTS

.C1B1C

 LDX L006E
 CMP #&23
 BNE C1B33
 ASL L0C51
 BPL loop_C1B1A
 LDA L09C0,X
 EOR #&80
 STA L09C0,X
 LDA #&28
 BNE C1B73

.C1B33

 LSR L0C6E
 JSR sub_C1BFF
 JSR sub_C1CCC
 BCS C1B98
 LDA L0C61
 AND #&20
 BEQ C1BA9
 JSR sub_C2B78
 BCC C1B98
 AND #&3F
 TAX
 LDA L0C61
 LSR A
 BCC C1B7D
 LDY L0A40,X
 BNE C1B98
 JSR C1200
 STX L000B

.loop_C1B5D

 LDA L0100,X
 CMP #&40
 BCC C1B71
 AND #&3F
 TAX
 EOR #&3F
 BNE loop_C1B5D
 LDA L0A40,X
 STA L0CE6

.C1B71

 LDA #&19

.C1B73

 JSR sub_C5FF6
 LDA #&80
 STA L0C63
 SEC
 RTS

.C1B7D

 LDA L0100
 BMI C1B98
 LDA L0A40,X
 CMP #&04
 BEQ C1BDB
 CMP #&06
 BEQ C1B98

.C1B8D

 JSR sub_C1ED8
 STX L0001
 CLC
 JSR sub_C2127
 CLC
 RTS

.C1B98

 LDA #&AA
 STA L591C
 LDA #&05
 JSR C3440
 LDA #&90
 STA L591C
 SEC
 RTS

.C1BA9

 JSR sub_C2111
 BCS C1B98
 SEC
 JSR sub_C2127
 BCS C1B98
 LDX L0001
 LDA L003A
 STA L0024
 LDA L003C
 STA L0026
 JSR sub_C1EFF
 BCC C1BCA
 CLC
 JSR sub_C2127
 JMP C1B98

.C1BCA

 LDA L0A40,X
 BNE C1BD9
 LDY L000B
 LDA L09C0,Y
 EOR #&80
 STA L09C0,X

.C1BD9

 CLC
 RTS

.C1BDB

 LDY #&07

.loop_C1BDD

 LDA L0100,Y
 BMI C1BFA
 LDA L0A40,Y
 CMP #&01
 BEQ C1BED
 CMP #&05
 BNE C1BFA

.C1BED

 TXA
 CMP L0CA0,Y
 BNE C1BFA
 LDA #&80
 STA L0CA0,Y
 BNE C1B8D

.C1BFA

 DEY
 BPL loop_C1BDD
 BMI C1B8D

.sub_C1BFF

 LDA L0CC6
 STA L0075
 LDA #&00
 LSR L0075
 ROR A
 LSR L0075
 ROR A
 LSR L0075
 ROR A
 CLC
 STA L003D
 LDA L0075
 ADC L09C0,X
 SEC
 SBC #&0A
 STA L003E
 LDA L0CC7
 SEC
 SBC #&05
 STA L0075
 LDA #&00
 LSR L0075
 ROR A
 LSR L0075
 ROR A
 LSR L0075
 ROR A
 LSR L0075
 ROR A
 CLC
 ADC #&20
 STA L003F
 STA L0074
 LDA L0075
 ADC L0140,X
 CLC
 ADC #&03
 STA L0040

.sub_C1C43

 JSR sub_C0E75
 LDY #&01
 JSR sub_C1C8C
 STA L0033
 STX L0032
 LDY #&00
 JSR sub_C1C8C
 STA L0030
 STX L002D
 LDA L003D
 STA L0074
 LDA L003E
 JSR sub_C0E75
 LDY #&01
 LDX #&02
 JSR sub_C1C6C
 LDY #&00
 LDX #&00

.sub_C1C6C

 LDA #&00
 STA L0067
 LDA L0032
 STA L006A
 LDA L0033
 STA L006B
 LDA L0C00,Y
 STA L0068
 LDA L0C02,Y
 STA L0069
 JSR sub_C0F9E
 STA L002F,X
 LDA L0074
 STA L002C,X
 RTS

.sub_C1C8C

 LDA L0C00,Y
 STA L0074
 LDA L0C02,Y
 LSR A
 ROR L0074
 PHP
 LSR A
 ROR L0074
 LSR A
 ROR L0074
 LSR A
 ROR L0074
 PLP
 BCC C1CA7
 JSR sub_C1009

.C1CA7

 LDX L0074
 RTS

.sub_C1CAA

 LDX #&02

.loop_C1CAC

 LDA #&00
 STA L0074
 LDA L0034,X
 CLC
 ADC L002C,X
 STA L0034,X
 LDA L002F,X
 BPL C1CBD
 DEC L0074

.C1CBD

 ADC L0037,X
 STA L0037,X
 LDA L003A,X
 ADC L0074
 STA L003A,X
 DEX
 BPL loop_C1CAC
 RTS

 EQUB &00

.sub_C1CCC

 LDX L006E
 LSR L0C56
 LSR L0CDD
 JSR sub_C1EB5

.C1CD7

 JSR sub_C1CAA
 LDA L003A
 STA L0024
 CMP #&1F
 BCS C1D33
 LDA L003C
 STA L0026
 CMP #&1F
 BCS C1D33
 LDA #&80
 STA L0060
 STA L000C
 LDA #&00
 STA L0079
 STA L0C67
 JSR sub_C1DE6
 BCS C1D35
 TAX
 LDA L0079
 SEC
 SBC L0038
 STA L0079
 TXA
 SBC L003B
 BMI C1CD7
 BNE C1D33
 LDA L0079
 CMP L000C
 BCS C1D33
 BIT L0060
 BVS C1D33
 LDA L0C6E
 ORA L0C67
 BMI C1D21
 LDA L0030
 BPL C1D33

.C1D21

 LDX L006E
 LDA L0024
 CMP L0900,X
 BNE C1D31
 LDA L0026
 CMP L0980,X
 BEQ C1CD7

.C1D31

 CLC
 RTS

.C1D33

 SEC
 RTS

.C1D35

 STA S
 STA L0077
 LSR L0060
 INC L0024
 JSR sub_C1DE6
 STA L0076
 INC L0026
 JSR sub_C1DE6
 STA L0075
 DEC L0024
 JSR sub_C1DE6
 STA L0074
 DEC L0026
 JSR sub_C2B78
 AND #&0F
 CMP #&04
 BEQ C1D5F
 CMP #&0C
 BNE C1D77

.C1D5F

 LDA L003B
 CMP S
 BCS C1D74
 CMP L0074
 BCS C1D74
 CMP L0075
 BCS C1D74
 CMP L0076
 BCS C1D74
 JMP C1D33

.C1D74

 JMP C1CD7

.C1D77

 LSR A
 BCC C1D89
 LSR A
 BCS C1D82
 AND #&01
 JMP C1D9C

.C1D82

 ADC #&01
 AND #&03
 JMP C1D8A

.C1D89

 LSR A

.C1D8A

 STA L0078
 LSR A
 LDA L0037
 BCC C1D93
 EOR #&FF

.C1D93

 CMP L0039
 LDA L0078
 ROL A
 TAY
 LDA L1DDE,Y

.C1D9C

 TAX
 LSR A
 LDY L0037
 BCS C1DA4
 LDY L0039

.C1DA4

 LSR A
 TYA
 BCC C1DAA
 EOR #&FF

.C1DAA

 STA L0002
 LDA S,X
 STA L0078
 LDA L0074,X
 SEC
 SBC S,X
 PHP
 BPL C1DBD
 EOR #&FF
 CLC
 ADC #&01

.C1DBD

 STA L0075
 LDA L0002
 JSR sub_C0D03
 PLP
 JSR sub_C1007
 CLC
 ADC L0078
 STA L0075
 LDA L0038
 SEC
 SBC L0074
 LDA L003B
 SBC L0075
 BPL C1DDB
 JMP C1D33

.C1DDB

 JMP C1CD7

.L1DDE

 EQUB &00, &03, &01, &00, &01, &02, &02, &03

.sub_C1DE6

 JSR sub_C2B78
 BCS C1E28
 PHA
 AND #&0F
 TAY
 PLA
 LSR A
 LSR A
 LSR A
 LSR A
 CPY #&01
 RTS

.C1DF7

 CPY L0C58
 BNE C1DFF
 ROR L0C56

.C1DFF

 LDA L0A40,Y
 CMP #&03
 BEQ C1E31
 CMP #&02
 BEQ C1E31
 CMP #&06
 BNE C1E8D
 JSR sub_C1E98
 CMP #&64
 BCS C1E82
 LDA #&10
 STA L000C
 LDA L0A00,Y
 CLC
 ADC #&20
 STA L0079
 LDA L0940,Y
 ADC #&00
 CLC
 RTS

.C1E28

 AND #&3F
 TAY
 BIT L0060
 BPL C1E8D
 BMI C1DF7

.C1E31

 JSR sub_C1E98
 CMP #&40
 BCS C1E82
 LDA L0A40,Y
 CMP #&02
 BEQ C1E52
 SEC
 ROR L0C67
 LDA L0A00,Y
 SEC
 SBC #&60
 STA L0079
 LDA L0940,Y
 SBC #&00
 CLC
 RTS

.C1E52

 LDA L0A00,Y
 SEC
 SBC L0038
 STA L0075
 LDA L0940,Y
 SBC L003B
 PHA
 LDA L0075
 CLC
 ADC #&E0
 STA L0075
 PLA
 ADC #&00
 BMI C1E82
 LSR A
 ROR L0075
 LSR A
 BNE C1E82
 LDA L0075
 ROR A
 CMP L0074
 BCC C1E82
 BIT L0C56
 BMI C1E82
 SEC
 ROR L0CDD

.C1E82

 LDA L0A40,Y
 CMP #&02
 BEQ C1E8D
 LDA #&C0
 STA L0060

.C1E8D

 LDA L0100,Y
 CMP #&40
 BCS C1E28
 LDA L0940,Y
 RTS

.sub_C1E98

 LDA L0037
 SEC
 SBC #&80
 BPL C1EA1
 EOR #&FF

.C1EA1

 STA L0074
 LDA L0039
 SEC
 SBC #&80
 BPL C1EAC
 EOR #&FF

.C1EAC

 CMP L0074
 BCS C1EB2
 LDA L0074

.C1EB2

 STA L0074
 RTS

.sub_C1EB5

 LDA #&00
 STA L0034
 STA L0035
 STA L0036
 LDA #&80
 STA L0037
 STA L0039
 LDA L0A00,X
 STA L0038
 LDA L0900,X
 STA L003A
 LDA L0940,X
 STA L003B
 LDA L0980,X
 STA L003C
 RTS

.sub_C1ED8

 LDA L0900,X
 STA L0024
 LDA L0980,X
 STA L0026
 JSR sub_C2B78
 LDA L0100,X
 CMP #&40
 BCC C1EF0
 ORA #&C0
 BNE C1EF7

.C1EF0

 LDA L0940,X
 ASL A
 ASL A
 ASL A
 ASL A

.C1EF7

 STA (L005E),Y
 LDA #&80
 STA L0100,X
 RTS

.sub_C1EFF

 LDA L0024
 STA L0900,X
 LDA L0026
 STA L0980,X
 JSR sub_C2B78
 BCC C1F4B
 STY L1F77
 AND #&3F
 TAY
 LDA L0A40,Y
 CMP #&03
 BEQ C1F1F
 CMP #&06
 BNE C1F75

.C1F1F

 TYA
 ORA #&40
 STA L0100,X
 LDA L0A40,Y
 CMP #&06
 BNE C1F37
 LDA L0A00,Y
 STA L0A00,X
 CLC
 LDA #&01
 BNE C1F42

.C1F37

 LDA L0A00,Y
 CLC
 ADC #&80
 STA L0A00,X
 LDA #&00

.C1F42

 ADC L0940,Y
 LDY L1F77
 JMP C1F5B

.C1F4B

 PHA
 LDA #&00
 STA L0100,X
 LDA #&E0
 STA L0A00,X
 PLA
 LSR A
 LSR A
 LSR A
 LSR A

.C1F5B

 STA L0940,X
 TXA
 ORA #&C0
 STA (L005E),Y
 LDA #&F5
 STA L0140,X
 JSR C3194
 AND #&F8
 CLC
 ADC #&60
 STA L09C0,X
 CLC
 RTS

.C1F75

 SEC
 RTS

.L1F77

 EQUB &00

.C1F78

 LDA #&00
 STA L0C6D
 STA L0C4D
 STA L0C1E
 RTS

.sub_C1F84

 JSR sub_C2096
 BCS C1F78
 LDA #&19
 STA L2094
 LDA L0C6D
 BPL C1F98
 SEI
 JSR sub_C3AA7
 CLI

.C1F98

 LDX L006E
 LDA L0C62
 STA L2095
 LDA #&00
 LSR L2095
 ROR A
 STA L001F
 LDA L2095
 ADC L09C0,X
 STA L09C0,X
 LDY #&00
 STY L0008
 LDA L0C69
 JSR sub_C2997
 LDA #&19
 LDY #&18
 LDX L0C69
 JSR sub_C2202
 BIT L0C4D
 BPL C1FD2
 LDY L0001
 JSR sub_C5D33
 JMP C1FD5

.C1FD2

 JSR sub_C2624

.C1FD5

 LDY #&00
 JSR sub_C38FB
 LDX L006E
 LDA #&00
 STA L001F
 SEC
 LDA L09C0,X
 SBC L2095
 STA L09C0,X
 LDA #&00
 STA L0075
 LDA L0C62
 ASL A
 ASL A
 ASL A
 ROL L0075
 CLC
 ADC L0CC2
 STA L2092
 LDA L0CC3
 ADC L0075
 CMP #&80
 BCC C2008
 SBC #&20

.C2008

 STA L2093
 BIT L0C6D
 BVC C2022
 BIT L0C4E
 BPL C201A
 LDA #&28
 STA L2094

.C201A

 JSR sub_C5E5F
 LDA L0C4E
 BMI C2061

.C2022

 SEI
 JSR sub_C3AA7
 SEC
 ROR L0CD7
 CLI
 LDA L2092
 STA L0064
 LDA L2093
 STA L0065
 LDA L0C69
 STA L0015
 JMP C2058

.C203D

 LDA L2092
 CLC
 ADC #&08
 STA L2092
 STA L0064
 LDA L2093
 ADC #&00
 CMP #&80
 BCC C2053
 SBC #&20

.C2053

 STA L2093
 STA L0065

.C2058

 LDY L0008
 JSR sub_C3832
 DEC L0015
 BNE C203D

.C2061

 LDA L0C62
 CLC
 ADC L0C69
 STA L0C62
 LDA L0C6A
 SEC
 SBC L0C69
 BEQ C2080
 STA L0C6A
 STA L0C69
 STA L2094
 JMP C1F98

.C2080

 LSR L0CD7
 LDA L0C5F
 BPL C208D
 SEI
 JSR C39D9
 CLI

.C208D

 JMP C1F78

.L2090

 EQUB &00

.L2091

 EQUB &00

.L2092

 EQUB &00

.L2093

 EQUB &00

.L2094

 EQUB &00

.L2095

 EQUB &00

.sub_C2096

 LDY L0001
 CPY L000B
 BEQ C2105
 JSR sub_C5C01
 LDY L0001
 LDX L0A40,Y
 LDA L2107,X
 CMP L0CD4
 BCS C20AF
 LDA L0CD4

.C20AF

 STA L0080
 LDA #&00
 STA L0CD4
 JSR sub_C561D
 LDA L0C59
 SEC
 SBC L008A
 STA L0074
 LDA L0C57
 SBC L008B
 BPL C20CC
 LDA #&00
 BEQ C20D3

.C20CC

 ASL L0074
 ROL A
 CMP #&28
 BCS C2105

.C20D3

 STA L0C62
 LDA L0C59
 CLC
 ADC L008A
 STA L0074
 LDA L0C57
 ADC L008B
 BMI C2105
 ASL L0074
 ROL A
 CMP #&28
 BCC C20EE
 LDA #&27

.C20EE

 CLC
 ADC #&01
 SEC
 SBC L0C62
 STA L0C6A
 BEQ C2105
 CMP #&15
 BCC C2100
 LDA #&14

.C2100

 STA L0C69
 CLC
 RTS

.C2105

 SEC
 RTS

.L2107

 EQUB &3E, &46, &72, &7A, &4A, &4E, &C1

.sub_C210E

 STA L0C61

.sub_C2111

 LDX #&3F

.loop_C2113

 LDA L0100,X
 BMI C211D
 DEX
 BPL loop_C2113
 SEC
 RTS

.C211D

 STX L0001
 LDA L0C61
 STA L0A40,X
 CLC
 RTS

.sub_C2127

 LDY L0A40,X
 LDA L0C0A
 BCC C2136
 SBC L2140,Y
 BCS C2139
 SEC
 RTS

.C2136

 ADC L2140,Y

.C2139

 AND #&3F
 STA L0C0A
 CLC
 RTS

.L2140

 EQUB &03, &03, &01, &02, &01, &04, &00

.sub_C2147

 LDA #&00
 JSR sub_C210E
 LDX L000B
 LDA L0940,X
 CLC
 ADC #&01
 LDX L0001
 JSR sub_C1224
 BCS return_11
 SEC
 JSR sub_C2127
 BCC C2170
 JSR sub_C1ED8
 LDA #&03
 STA L0C4C
 LDA #&80
 STA L0CDE
 BNE C2198

.C2170

 LDA #&00
 JSR sub_C5FF6
 LDX L000B
 LDA L0900,X
 CMP L0C19
 BNE C2191
 LDA L0980,X
 CMP L0C1A
 BNE C2191
 LDA #&C0
 STA L0CDE
 LDA #&80
 STA L0C71

.C2191

 JSR C1200
 LDX L0001
 STX L000B

.C2198

 LDA #&80
 STA L0C63
 CLC

.return_11

 RTS

.C219F

 AND #&3F
 STA L0C6C
 LDX #&00

.loop_C21A6

 INX
 AND #&3F
 TAY
 LDA L0100,Y
 CMP #&40
 BCS loop_C21A6
 DEX
 STX L0C6B
 BEQ C21F3

.C21B7

 LDX L000B
 LDA L0A00,X
 SEC
 SBC L0A00,Y
 STA L0074
 LDA L0940,X
 SBC L0940,Y
 BMI C21F0
 ORA L0074
 BNE C21D5
 LDA L0A40,Y
 CMP #&06
 BEQ C21F0

.C21D5

 JSR sub_C5D33
 LDY L0C6C
 DEC L0C6B
 BMI return_12
 LDX L0C6B
 BPL C21EC

.loop_C21E5

 LDA L0100,Y
 AND #&3F
 TAY
 DEX

.C21EC

 BNE loop_C21E5
 BEQ C21B7

.C21F0

 LDY L0C6C

.C21F3

 JSR sub_C5D33
 LDA L0100,Y
 AND #&3F
 TAY
 DEC L0C6B
 BPL C21F3

.return_12

 RTS

.sub_C2202

 STA L0026
 STY L0057
 TXA
 CMP #&20
 BCC C2211
 SBC #&20
 LDX #&20
 BNE C2213

.C2211

 LDA #&80

.C2213

 STA L001E
 STX L0025
 LDX L0C4C
 LDA L2277,X
 STA L0074
 LDA L227B,X
 STA L0075

.C2224

 LDX L0026
 LDA L3D83,X
 STA P
 LDA L3DB5,X
 STA Q
 LDX L0025
 LDA #&01
 STA L0015

.C2236

 LDY #&FF

.C2238

 INY
 LDA L0074
 STA (P),Y
 INY
 LDA L0075
 STA (P),Y
 INY
 LDA L0074
 STA (P),Y
 INY
 LDA L0075
 STA (P),Y
 INY
 LDA L0074
 STA (P),Y
 INY
 LDA L0075
 STA (P),Y
 INY
 LDA L0074
 STA (P),Y
 INY
 LDA L0075
 STA (P),Y
 DEX
 BNE C2238
 DEC L0015
 BMI C2270
 LDX L001E
 BMI C2270
 INC Q
 JMP C2236

.C2270

 INC L0026
 DEC L0057
 BNE C2224
 RTS

.L2277

 EQUB &00, &00, &AA, &0F

.L227B

 EQUB &0F, &00, &55, &0F

.L227F

 EQUB &88, &44, &22, &11

.L2283

 EQUB &00, &0F, &F0, &FF

.L2287

 EQUB &00, &88, &CC, &EE

.L228B

 EQUB &77, &33, &11, &00

.L228F

 EQUB &88, &CC, &EE, &FF

.L2293

 EQUB &00, &60, &00

.L2296

 EQUB &00, &00, &00

.sub_C2299

 LDA #&01
 STA L002C
 STA L002D
 LDA L0006
 CLC
 ADC L0004
 ROR A
 TAX
 LDA Noise3,X
 CMP Noise2,X
 BCC return_13
 LDA #&F0
 CLC
 SBC L0006
 STA L0074
 LSR A
 LSR A
 LSR A
 CLC
 ADC L0055
 TAX
 LDA L0074
 AND #&07
 CLC
 ADC L3D83,X
 STA R
 LDA L3DB5,X
 STA S
 LDY L0010
 LDA R
 CLC
 ADC L2293,Y
 STA R
 LDA S
 ADC L2296,Y
 STA S
 LDA L0019
 BIT L0C7A
 BPL C22EF
 AND #&CF
 STA L0074
 LDA L0019
 ASL A
 ASL A
 AND #&30
 ORA L0074

.C22EF

 STA L23C7
 STA L2367
 ORA #&40
 STA L23A2
 LSR A
 LSR A
 AND #&03
 TAY
 LDA L2283,Y
 STA L0058
 LDY L0006
 STY L001A
 CPY L0004
 BCS C237F

.return_13

 RTS

.C230D

 LDY L001A
 CPY L0004
 BEQ return_13
 TYA
 AND #&07
 BNE C237A
 LDA R
 CLC
 ADC #&39
 STA R
 LDA S
 ADC #&01
 CMP #&53
 BNE C232F
 LDA L3DAC
 STA R
 LDA L3DDE

.C232F

 STA S
 BNE C237C

.C2333

 LDA #&00
 STA L002D
 BEQ C230D

.C2339

 LDA #&00
 STA L002C
 BEQ C230D

.C233F

 LDA L0061
 ASL A
 STA L0056
 STA L002C
 BNE C23A6

.C2348

 LDA R
 SEC
 SBC #&08
 STA P
 LDA S
 SBC #&00
 STA Q
 LDA #&00
 STA L002D
 LDA #&F8
 BNE C23D8

.C235D

 TXA
 AND #&03
 TAX
 LDA L0054
 AND L2287,X

.sub_C2366

L2367 = sub_C2366+1

 ORA L3E3C,X
 AND L228F,X
 STA L0074
 LDA (R),Y
 AND L228B,X
 ORA L0074
 STA (R),Y
 JMP C230D

.C237A

 INC R

.C237C

 DEY
 STY L001A

.C237F

 LDA Noise3,Y
 CMP Noise2,Y
 BCC return_13
 TAX
 SBC L0035
 BCC C2333
 CMP L0061
 BCS C233F
 ASL A
 AND #&F8
 TAY
 TXA
 AND #&03
 TAX
 STY L0056
 LDA (R),Y
 STA L0054
 AND L228B,X

.sub_C23A1

L23A2 = sub_C23A1+1

 ORA L3E7C,X
 STA (R),Y

.C23A6

 LDY L001A
 LDA Noise2,Y
 TAX
 CMP L0036
 BCS C2339
 SEC
 SBC L0035
 BCC C2348
 ASL A
 AND #&F8
 TAY
 CPY L0056
 BCS C235D
 TXA
 AND #&03
 TAX
 LDA (R),Y
 AND L2287,X

.sub_C23C6

L23C7 = sub_C23C6+1

 ORA L3E3C,X
 STA (R),Y
 TYA
 CLC
 ADC R
 STA P
 LDA S
 ADC #&00
 STA Q
 TYA

.C23D8

 SEC
 SBC L0056
 LSR A
 STA L23E3
 LDA L0058
 CLC

.sub_C23E2

L23E3 = sub_C23E2+1

 BCC C2460

 LDY #&F8
 STA (P),Y
 LDY #&F0
 STA (P),Y
 LDY #&E8
 STA (P),Y
 LDY #&E0
 STA (P),Y
 LDY #&D8
 STA (P),Y
 LDY #&D0
 STA (P),Y
 LDY #&C8
 STA (P),Y
 LDY #&C0
 STA (P),Y
 LDY #&B8
 STA (P),Y
 LDY #&B0
 STA (P),Y
 LDY #&A8
 STA (P),Y
 LDY #&A0
 STA (P),Y
 LDY #&98
 STA (P),Y
 LDY #&90
 STA (P),Y
 LDY #&88
 STA (P),Y
 LDY #&80
 STA (P),Y
 LDY #&78
 STA (P),Y
 LDY #&70
 STA (P),Y
 LDY #&68
 STA (P),Y
 LDY #&60
 STA (P),Y
 LDY #&58
 STA (P),Y
 LDY #&50
 STA (P),Y
 LDY #&48
 STA (P),Y
 LDY #&40
 STA (P),Y
 LDY #&38
 STA (P),Y
 LDY #&30
 STA (P),Y
 LDY #&28
 STA (P),Y
 LDY #&20
 STA (P),Y
 LDY #&18
 STA (P),Y
 LDY #&10
 STA (P),Y
 LDY #&08
 STA (P),Y

.C2460

 JMP C230D

.sub_C2463

 LDA L0CDE
 BMI return_14
 LDA #&00
 STA L0005
 LDX #&7F

.loop_C246E

 STA L3E80,X
 DEX
 BPL loop_C246E
 JSR sub_C25C3
 LDA #&1F
 STA L001A
 JSR sub_C24EA
 DEC L001A

.C2480

 LDA L0005
 EOR #&20
 STA L0005
 JSR sub_C24EA
 LDX L000B
 LDA L0940,X
 STA L0076
 LDX #&1E

.C2492

 TXA
 TAY
 LDA (P),Y
 LDY #&FF
 LSR A
 BCS C24A2
 CMP L0076
 BCC C24A2
 BEQ C24A2
 INY

.C24A2

 STY L0077
 TXA
 ASL A
 ASL A
 ASL A
 AND #&E0
 ORA L001A
 LSR A
 STA L0074
 TXA
 AND #&03
 ROL A
 TAY
 LDA L24E2,Y
 EOR #&FF
 STA L0027
 LDA L0180,X
 ORA L0181,X
 ORA L01A0,X
 ORA L01A1,X
 AND L0077
 AND L24E2,Y
 STA L0075
 LDY L0074
 LDA L3E80,Y
 AND L0027
 ORA L0075
 STA L3E80,Y
 DEX
 BPL C2492
 DEC L001A
 BPL C2480

.return_14

 RTS

.L24E2

 EQUB &80, &40, &20, &10, &08, &04, &02, &01

.sub_C24EA

 LDA L001A
 CLC
 ADC #&60
 STA Q
 LDA #&1F
 STA L0018

.C24F5

 JSR sub_C355A
 LDY #&00
 STY L0074
 DEY
 STY L0017
 LDY L0018
 LDA (P),Y
 LSR A
 STA L0019
 LDX L000B
 JSR sub_C1EB5
 LDX #&02

.C250D

 LDA #&00
 STA L0086,X
 SEC
 SBC L0037,X
 STA L002C,X
 LDA L0018,X
 SBC L003A,X
 STA L002F,X
 BPL C2529
 DEC L0086,X
 LDA #&00
 SEC
 SBC L002C,X
 LDA #&00
 SBC L002F,X

.C2529

 CMP L0074
 BCC C252F
 STA L0074

.C252F

 DEX
 BPL C250D
 LDA L0074
 ASL A
 ASL A
 CMP #&06
 BCC C25AF

.loop_C253A

 ASL L002C
 ROL L002F
 ASL L002D
 ROL L0030
 ASL L002E
 ROL L0031
 LSR L0017
 ASL A
 BCC loop_C253A
 LDA L003C
 CLC
 ADC #&60
 STA L003C
 LDA L0CCE
 BMI C257E
 LDA L0B56,X
 CLC
 ADC #&29
 STA L000C
 LDX #&03
 TXA
 CLC
 ADC #&3C
 STA L000D
 LDY #&00

.loop_C2569

 LDA (L000C),Y
 CMP #&7F
 BNE C25D7
 DEC L000C
 DEX
 BPL loop_C2569
 LDA (L000C),Y
 CMP #&7F
 BEQ C25D7
 SEC
 ROR L0CCE

.C257E

 LDX #&02
 CLC
 BCC C2589

.loop_C2583

 LDA L0034,X
 ADC L002C,X
 STA L0034,X

.C2589

 LDA L0037,X
 ADC L002F,X
 STA L0037,X
 LDA L003A,X
 ADC L0086,X
 STA L003A,X
 CLC
 DEX
 BEQ C2589
 BPL loop_C2583
 LDA L003C
 STA S
 LDY L003A
 LDA L003B
 CMP (R),Y
 BCC C25AE
 DEC L0017
 BNE C257E
 CLC
 BCC C25AF

.C25AE

 SEC

.C25AF

 LDA L0018
 ORA L0005
 TAY
 LDA #&00
 SBC #&00
 STA L0180,Y
 DEC L0018
 BMI return_15
 JMP C24F5

.return_15

 RTS

.sub_C25C3

 LDA #&00
 STA P
 STA L0060
 LDA #&7F
 STA Q
 LDA #&1F
 STA L0026

.loop_C25D1

 LDA #&1F
 STA L0024
 BNE C25DA

.C25D7

 JMP C3663

.C25DA

 JSR sub_C1DE6
 LDY L0024
 ROL A
 STA (P),Y
 DEC L0024
 BPL C25DA
 DEC Q
 DEC L0026
 BPL loop_C25D1
 LDA #&20
 STA R
 LDX #&1E

.C25F2

 TXA
 CLC
 ADC #&60
 STA Q
 STA S
 LDY #&1E

.C25FC

 LDA (P),Y
 LSR A
 BCC C261B
 ROL A
 INY
 CMP (P),Y
 BCC C2609
 LDA (P),Y

.C2609

 INC Q
 CMP (P),Y
 BCC C2611
 LDA (P),Y

.C2611

 DEY
 CMP (P),Y
 BCC C2618
 LDA (P),Y

.C2618

 DEC Q
 LSR A

.C261B

 STA (R),Y
 DEY
 BPL C25FC
 DEX
 BPL C25F2
 RTS

.sub_C2624

 LDX L006E
 LDA #&40
 STA L003C
 LDA #&0C
 STA L003D
 LDA L09C0,X
 CLC
 ADC #&20
 STA L001C
 AND #&3F
 SEC
 SBC #&20
 STA L0074
 LDA L001C
 ASL A
 ROL A
 ROL A
 AND #&03
 TAY
 LDA L27AB,Y
 STA L001B
 TYA
 ASL A
 ASL A
 STA L0066
 TYA
 SEC
 SBC #&02
 STA L004B
 LDA L0074
 SEC
 SBC #&0A
 STA L0020
 BIT L001C
 BMI C267F
 BVS C266F
 LDA L0900,X
 STA L0003
 LDA L0980,X
 STA L001D
 JMP C26A1

.C266F

 CLC
 LDA #&1F
 SBC L0980,X
 STA L0003
 LDA L0900,X
 STA L001D
 JMP C26A1

.C267F

 BVS C2694
 CLC
 LDA #&1F
 SBC L0900,X
 STA L0003
 CLC
 LDA #&1F
 SBC L0980,X
 STA L001D
 JMP C26A1

.C2694

 LDA L0980,X
 STA L0003
 CLC
 LDA #&1F
 SBC L0900,X
 STA L001D

.C26A1

 LDA #&1F
 STA L0026
 LDA L0C48
 STA L0032
 LDA #&00
 STA L0005
 JSR sub_C27AF
 LDA L0032
 STA L0C48

.C26B6

 LDA L0005
 EOR #&20
 STA L0005
 LDA L0032
 STA L0037
 LDA L0033
 STA L0038
 JSR sub_C355A
 DEC L0026
 BMI C26D4
 LDY L0026
 CPY L001D
 BNE C26D6
 JMP C2747

.C26D4

 CLC
 RTS

.C26D6

 JSR sub_C27AF
 LDY L0032
 CPY L0037
 BEQ C2707
 BCC C26EB

.loop_C26E1

 DEY
 JSR C2815
 CPY L0037
 BNE loop_C26E1
 BEQ C2707

.C26EB

 LDA L0005
 EOR #&20
 STA L0005
 INC L0026
 LDY L0037

.loop_C26F5

 DEY
 JSR C2815
 CPY L0032
 BNE loop_C26F5
 STY L0037
 DEC L0026
 LDA L0005
 EOR #&20
 STA L0005

.C2707

 LDY L0033
 CPY L0038
 BEQ C2735
 BCS C2719

.loop_C270F

 INY
 JSR C2815
 CPY L0038
 BNE loop_C270F
 BEQ C2735

.C2719

 LDA L0005
 EOR #&20
 STA L0005
 INC L0026
 LDY L0038

.loop_C2723

 INY
 JSR C2815
 CPY L0033
 BNE loop_C2723
 STY L0038
 DEC L0026
 LDA L0005
 EOR #&20
 STA L0005

.C2735

 JSR sub_C292D
 BIT L0C1B
 BPL C2742
 JSR sub_C120F
 BNE C2745

.C2742

 JMP C26B6

.C2745

 SEC
 RTS

.C2747

 LDY L0037
 INY
 CPY L0003
 BNE C2753
 STY L0038
 JMP C275E

.C2753

 LDY L0038
 DEY
 DEY
 CPY L0003
 BNE C276B
 INY
 STY L0037

.C275E

 LDY L0037
 JSR C2815
 LDY L0038
 JSR C2815
 JSR sub_C292D

.C276B

 LDA #&00
 STA L0005
 INC L0026
 LDY L0003
 JSR C2815
 LDA L0AE0,Y
 CMP #&02
 BCS C27A9
 STA L0AE1,Y
 LDA L0A80,Y
 STA L0A81,Y
 LDA #&20
 STA L0005
 DEC L0026
 LDA #&FF
 STA L0B00,Y
 STA L0B01,Y
 STA L5520,Y
 STA L5500,Y
 LDA #&14
 STA L5521,Y
 STA L5501,Y
 LDA L0003
 STA L0025
 JSR C2A1B

.C27A9

 CLC
 RTS

.L27AB

 EQUB &00, &01, &21, &20

.sub_C27AF

 LDY L0032
 JSR C2815
 BEQ C27E9
 CMP #&80
 BEQ C27D7

.loop_C27BA

 LDA L0024
 STA L0032
 JSR sub_C280E
 BCS C27D2
 CMP #&81
 BEQ loop_C27BA
 CMP #&80
 BEQ C27D2

.loop_C27CB

 JSR sub_C280E
 BCS C27D2
 BEQ loop_C27CB

.C27D2

 LDA L0024
 STA L0033
 RTS

.C27D7

 LDA L0024
 STA L0033
 JSR sub_C2806
 BCS C27FF
 CMP #&80
 BEQ C27D7
 CMP #&00
 JMP C27FD

.C27E9

 JSR sub_C280E
 BCS C27F0
 BEQ C27E9

.C27F0

 LDA L0024
 STA L0033
 LDA L0032
 STA L0024

.loop_C27F8

 JSR sub_C2806
 BCS C27FF

.C27FD

 BEQ loop_C27F8

.C27FF

 LDA L0024
 STA L0032
 RTS

.C2804

 SEC
 RTS

.sub_C2806

 LDY L0024
 BEQ C2804
 DEY
 JMP C2815

.sub_C280E

 LDY L0024
 INY
 CPY #&20
 BEQ C2804

.C2815

 STY L0024
 STY L000F
 TYA
 ORA L0005
 STA L0021
 LDA #&00
 STA L007F
 LDX L006E
 LDA #&80
 STA L0080
 CLC
 LDA L0024
 SBC L0003
 SEC
 SBC L0C78
 STA L0086
 BPL C2840
 LDA #&00
 SEC
 SBC L0080
 STA L0080
 LDA #&00
 SBC L0086

.C2840

 STA L0083
 LDA #&80
 STA L0082
 CLC
 LDA L0026
 SBC L001D
 STA L0088
 BPL C285A
 LDA #&00
 SEC
 SBC L0082
 STA L0082
 LDA #&00
 SBC L0088

.C285A

 STA L0085
 JSR sub_C5567
 LDY L0021
 LDA L008A
 SEC
 SBC L001F
 STA L0BA0,Y
 LDA L008B
 SBC L0020
 STA L5500,Y
 JSR sub_C565F
 BIT L001C
 BMI C288B
 BVS C2880
 LDX L0024
 LDY L0026
 JMP C28A4

.C2880

 LDX L0026
 LDA #&1F
 SEC
 SBC L0024
 TAY
 JMP C28A4

.C288B

 BVS C289C
 LDA #&1F
 SEC
 SBC L0024
 TAX
 LDA #&1F
 SEC
 SBC L0026
 TAY
 JMP C28A4

.C289C

 LDA #&1F
 SEC
 SBC L0026
 TAX
 LDY L0024

.C28A4

 STY L0074
 TXA
 ASL A
 ASL A
 ASL A
 AND #&E0
 ORA L0074
 TAY
 TXA
 AND #&03
 STA L0074
 CLC
 ADC #&04
 STA L005F
 LDA (L005E),Y
 LDX L0021
 STA L0180,X
 CMP #&C0
 BCC C28D6

.loop_C28C4

 AND #&3F
 TAY
 LDA L0100,Y
 CMP #&40
 BCS loop_C28C4
 LDA L0940,Y
 STA L0075
 JMP C28EE

.C28D6

 LSR A
 LSR A
 LSR A
 LSR A
 STA L0075
 TYA
 LSR A
 TAY
 ROL L0074
 LDA L3E80,Y
 LDY L0074
 AND L24E2,Y
 BNE C28EE
 STA L0180,X

.C28EE

 LDX L006E
 LDA #&00
 SEC
 SBC L0A00,X
 STA L0080
 LDA L0075
 SBC L0940,X
 JSR sub_C561D
 LDY L0021
 LDA L008D
 STA L0AE0,Y
 LDA L0050
 STA L0A80,Y
 LDA L5500,Y
 CMP L0007
 BCC C2927
 BNE C291F
 LDA L0BA0,Y
 CMP L0028
 BCC C2927
 LDA L5500,Y

.C291F

 ROR L007F
 CMP L0012
 BCC C2927
 INC L007F

.C2927

 LDY L000F
 LDA L007F
 CLC
 RTS

.sub_C292D

 LDA L0037
 STA L0025

.loop_C2931

 CMP L0038
 BCS return_16
 CMP L0003
 BCS C2943
 JSR sub_C29E2
 INC L0025
 LDA L0025
 JMP loop_C2931

.C2943

 LDA L0038

.loop_C2945

 SEC
 SBC #&01
 BMI return_16
 STA L0025
 CMP L0037
 BCC return_16
 CMP L0003
 BCC return_16
 JSR sub_C29E2
 LDA L0025
 JMP loop_C2945

.return_16

 RTS

.sub_C295D

 LDA L0010
 AND #&01
 EOR #&01

.sub_C2963

 STA L0010
 TAY
 LDA L2994,Y
 STA L0007
 LSR A
 EOR #&80
 STA L0012
 LDA L298B,Y
 STA L0011
 LDA L2991,Y
 STA L0061
 LDA L298E,Y
 STA L0035
 CLC
 ADC L0061
 STA L0036
 LDA #&00
 STA L0028
 STA L0029
 RTS

.L298B

 EQUB &0A, &02, &0C

.L298E

 EQUB &50, &40, &60

.L2991

 EQUB &70, &70, &40

.L2994

 EQUB &14, &14, &08

.sub_C2997

 STA L0074
 LSR A
 STA L0007
 LDA #&00
 ROR A
 STA L0028
 LDA L0007
 LSR A
 EOR #&80
 STA L0012
 LDA L0074
 ASL A
 ASL A
 STA L0061
 LSR A
 AND #&FC
 ORA #&80
 STA L0036
 SEC
 SBC L0061
 STA L0035
 LSR A
 LSR A
 LSR A
 STA L0011
 LDA #&00
 ROR A
 STA L0029
 LDA #&02
 STA L0010

.return_17

 RTS

.C29C9

 LDA L0180,X
 AND #&0F
 STA L0A7F
 BEQ return_17
 LDA L0025
 STA L093F
 LDA L0026
 STA L09BF
 LDY #&3F
 JMP sub_C5D33

.sub_C29E2

 JSR sub_C355A
 LDA L0025
 ORA L0005
 CLC
 ADC L001B
 AND #&3F
 TAX
 BIT L0C4B
 BMI C29C9
 LDA L0180,X
 BEQ return_17
 CMP #&C0
 BCC C2A05
 PHA
 JSR C2A1B
 PLA
 JMP C219F

.C2A05

 AND #&0F
 BEQ C2A1B
 CMP #&0C
 BEQ C2A11
 CMP #&04
 BNE C2A39

.C2A11

 PHA
 LDA L004B
 AND #&01
 STA L0045
 PLA
 BNE C2A5A

.C2A1B

 LDX #&00
 LDA L0025
 EOR L0026
 AND #&01
 BEQ C2A2D
 LDX #&08
 LDA L0C75,X
 STA L0C4D,X

.C2A2D

 LDA L2CE3,X
 STA L0019
 LDA #&00
 STA L003B
 JMP C2A79

.C2A39

 TAX
 SEC
 SBC L0066
 AND #&0F
 TAY
 AND #&03
 CMP #&01
 BEQ C2A2D
 LDA L2D03,Y
 STA L0045
 TXA
 AND #&04
 LSR A
 LSR A
 CLC
 ADC L004B
 CMP #&02
 TXA
 BCS C2A5A
 ORA #&10

.C2A5A

 STA L0034
 TAX
 LDA #&80
 STA L003B
 LDA L2CE3,X
 STA L0019
 JSR C2A79
 LDA L0034
 EOR #&10
 TAX
 LDA L2CE3,X
 STA L0019
 LDA L003B
 ORA #&40
 STA L003B

.C2A79

 LDY L0010
 CPY #&02
 BCS C2A93
 JSR sub_C2D36
 BCS C2A90
 JSR sub_C2299
 LDY L0010
 LDA L002C,Y
 CMP #&01
 BEQ return_18

.C2A90

 JSR sub_C295D

.C2A93

 JSR sub_C2D36
 BCS return_18
 JSR sub_C2299

.return_18

 RTS

.sub_C2A9C

 LDX #&50

.loop_C2A9E

 JSR C3194
 STA Noise2,X
 DEX
 BPL loop_C2A9E
 LDA L0C52
 BNE C2AB0
 LDA #&18
 BNE C2AB6

.C2AB0

 JSR sub_C341B
 CLC
 ADC #&0E

.C2AB6

 STA L0C08
 LDA #&80
 JSR sub_C2AF2
 LDA #&00
 JSR sub_C2B53
 LDA #&01
 JSR sub_C2AF2
 LDA #&40
 JSR sub_C2B53
 LDA #&1E
 STA L0026

.loop_C2AD1

 LDA #&1E
 STA L0024

.loop_C2AD5

 JSR sub_C2C4E
 JSR sub_C2B78
 TXA
 ASL A
 ASL A
 ASL A
 ASL A
 ORA (L005E),Y
 STA (L005E),Y
 DEC L0024
 BPL loop_C2AD5
 DEC L0026
 BPL loop_C2AD1
 LDA #&02
 JSR sub_C2AF2
 RTS

.sub_C2AF2

 STA L001C
 LDA #&1F
 STA L0026

.C2AF8

 LDA #&1F
 STA L0024

.C2AFC

 JSR sub_C2B78
 LDA L001C
 BEQ C2B48
 BMI C2B45
 LSR A
 LDA (L005E),Y
 BCS C2B1B
 LSR A
 LSR A
 LSR A
 LSR A
 STA L0074
 LDA (L005E),Y
 ASL A
 ASL A
 ASL A
 ASL A
 ORA L0074
 JMP C2B48

.C2B1B

 SEC
 SBC #&80
 PHP
 BPL C2B26
 EOR #&FF
 CLC
 ADC #&01

.C2B26

 STA L0075
 LDA L0C08
 JSR sub_C0D03
 PLP
 JSR sub_C1007
 CLC
 ADC #&06
 BPL C2B39
 LDA #&00

.C2B39

 CLC
 ADC #&01
 CMP #&0C
 BCC C2B42
 LDA #&0B

.C2B42

 JMP C2B48

.C2B45

 JSR C3194

.C2B48

 STA (L005E),Y
 DEC L0024
 BPL C2AFC
 DEC L0026
 BPL C2AF8
 RTS

.sub_C2B53

 STA L0066
 LDA #&02
 STA L0015

.loop_C2B59

 LDA #&1F
 STA L0026

.loop_C2B5D

 LDA #&00
 JSR sub_C2B90
 DEC L0026
 BPL loop_C2B5D
 LDA #&1F
 STA L0024

.loop_C2B6A

 LDA #&80
 JSR sub_C2B90
 DEC L0024
 BPL loop_C2B6A
 DEC L0015
 BNE loop_C2B59
 RTS

.sub_C2B78

 LDA L0024
 ASL A
 ASL A
 ASL A
 AND #&E0
 ORA L0026
 TAY
 LDA L0024
 AND #&03
 CLC
 ADC #&04
 STA L005F
 LDA (L005E),Y
 CMP #&C0
 RTS

.sub_C2B90

 ORA L0066
 STA L001C
 LDX #&22

.loop_C2B96

 TXA
 AND #&1F
 BIT L001C
 BPL C2BA2
 STA L0026
 JMP C2BA4

.C2BA2

 STA L0024

.C2BA4

 JSR sub_C2B78
 STA Noise2,X
 DEX
 BPL loop_C2B96
 BIT L001C
 BVC C2BFE
 LDX #&1F

.C2BB3

 LDA L5A01,X
 CMP L5A02,X
 BEQ C2BE8
 BCS C2BCD
 CMP Noise2,X
 BEQ C2BE8
 BCS C2BE8
 LDA L5A02,X
 CMP Noise2,X
 JMP C2BDA

.C2BCD

 CMP Noise2,X
 BEQ C2BE8
 BCC C2BE8
 LDA Noise2,X
 CMP L5A02,X

.C2BDA

 BCC C2BE2
 LDA Noise2,X
 JMP C2BE5

.C2BE2

 LDA L5A02,X

.C2BE5

 STA L5A01,X

.C2BE8

 DEX
 BPL C2BB3
 BIT L0C71
 BMI C2BFB
 LDA #&5F
 STA L0100,X
 DEX
 LDA #&7D
 STA L0100,X

.C2BFB

 JMP C2C34

.C2BFE

 LDX #&00

.C2C00

 LDA #&00
 STA L0075
 LDA Noise2,X
 CLC
 ADC L5A01,X
 BCC C2C10
 CLC
 INC L0075

.C2C10

 ADC L5A02,X
 BCC C2C18
 CLC
 INC L0075

.C2C18

 ADC L5A03,X
 BCC C2C20
 CLC
 INC L0075

.C2C20

 LSR L0075
 ROR A
 LSR L0075
 ROR A
 STA Noise2,X
 INX
 CPX #&20
 BCC C2C00
 LDA L5A2E,X
 STA L0F1D,X

.C2C34

 LDX #&1F

.loop_C2C36

 TXA
 BIT L001C
 BPL C2C40
 STA L0026
 JMP C2C42

.C2C40

 STA L0024

.C2C42

 JSR sub_C2B78
 LDA Noise2,X
 STA (L005E),Y
 DEX
 BPL loop_C2C36
 RTS

.sub_C2C4E

 JSR sub_C2B78
 AND #&0F
 STA S
 INC L0024
 JSR sub_C2B78
 AND #&0F
 STA L0076
 INC L0026
 JSR sub_C2B78
 AND #&0F
 STA L0075
 DEC L0024
 JSR sub_C2B78
 AND #&0F
 STA L0074
 DEC L0026
 LDA S
 CMP L0076
 BEQ C2CB1
 CMP L0074
 BEQ C2C92
 LDA L0075
 CMP L0076
 BEQ C2C85

.C2C82

 LDX #&0C
 RTS

.C2C85

 CMP L0074
 BNE C2C9C
 LDX #&02
 CMP S
 BCS return_19
 LDX #&0B

.return_19

 RTS

.C2C92

 LDA L0075
 CMP L0076
 BEQ C2CA8
 CMP L0074
 BEQ C2C9F

.C2C9C

 LDX #&04
 RTS

.C2C9F

 LDX #&0E
 CMP L0076
 BCC return_20
 LDX #&07

.return_20

 RTS

.C2CA8

 LDX #&05
 CMP L0074
 BCC return_21
 LDX #&0D

.return_21

 RTS

.C2CB1

 CMP L0074
 BEQ C2CD1
 LDA L0075
 CMP L0074
 BEQ C2CC8
 CMP L0076
 BNE C2C82
 LDX #&06
 CMP L0074
 BCC return_22
 LDX #&0F

.return_22

 RTS

.C2CC8

 LDX #&01
 CMP L0076
 BCC return_23
 LDX #&09

.return_23

 RTS

.C2CD1

 CMP L0075
 BEQ C2CDC
 LDX #&0A
 BCC return_24
 LDX #&03

.return_24

 RTS

.C2CDC

 LDX #&00
 RTS

.L2CDF

 EQUB &01, &21, &FF, &1F

.L2CE3

 EQUB &3C, &04, &04, &08, &08, &08, &04, &08
 EQUB &00, &04, &08, &04, &04, &08, &08, &04
 EQUB &00, &00, &08, &04, &08, &00, &08, &04
 EQUB &00, &00, &04, &08, &04, &00, &04, &08

.L2D03

 EQUB &00, &00, &00, &00, &00, &00, &01, &01
 EQUB &00, &00, &00, &00, &00, &00, &01, &01

.C2D13

 LDY L0045
 BVC C2D1E
 CLC
 ADC #&21
 AND #&3F
 INY
 INY

.C2D1E

 STA L0C40
 STA L0C43
 EOR #&20
 STA L0C41
 CLC
 ADC L2CDF,Y
 AND #&3F
 STA L0C42
 LDX #&03
 BNE C2D58

.sub_C2D36

 LDA L0025
 ORA L0005
 BIT L003B
 BMI C2D13
 BVS C2D93
 STA L0C40
 STA L0C44
 EOR #&20
 STA L0C41
 CLC
 ADC #&01
 STA L0C42
 EOR #&20
 STA L0C43
 LDX #&04

.C2D58

 STX L0017
 JMP C2D93

.C2D5D

 LDA #&C0
 STA L006C
 LDY L0017

.C2D63

 LDA (L003C),Y
 TAX
 LDA L0BA0,X
 CLC
 ADC L0029
 STA L0074
 LDA L5500,X
 ADC L0011
 ASL L0074
 ROL A
 ROL L0074
 ROL A
 ROL L0074
 ROL A
 STA L54A0,X
 LDA L0074
 ROL A
 AND #&07
 CMP #&04
 BCC C2D8A
 ORA #&F8

.C2D8A

 STA L0B40,X
 DEY
 BPL C2D63
 JMP C2DBC

.C2D93

 LDA #&00
 STA L006C
 LDY L0017

.C2D99

 LDA (L003C),Y
 TAX
 LDA L0BA0,X
 CLC
 ADC L0029
 STA L0074
 LDA L5500,X
 ADC L0011
 CMP #&20
 BCS C2D5D
 ASL L0074
 ROL A
 ASL L0074
 ROL A
 ASL L0074
 ROL A
 STA L54A0,X
 DEY
 BPL C2D99

.C2DBC

 LDA #&00
 STA L0006
 STA L0031
 STA L001E
 LDA #&FF
 STA L0004
 STA L0030
 STA L007F
 LDY #&00

.C2DCE

 STY L004A
 LDA (L003C),Y
 TAX
 INY
 LDA (L003C),Y
 TAY
 LDA #&5A
 STA L0002
 LDA L0A80,Y
 SEC
 SBC L0A80,X
 STA L000C
 LDA L0AE0,Y
 SBC L0AE0,X
 BPL C2E03
 STA L0076
 INC L0002
 STX L0074
 STY L0075
 LDX L0075
 LDY L0074
 LDA #&00
 SEC
 SBC L000C
 STA L000C
 LDA #&00
 SBC L0076

.C2E03

 STA L0076
 BIT L006C
 BVC C2E1C
 LDA L0B40,Y
 ORA L0B40,X
 BEQ C2E1C
 LDA L0076
 BNE C2E19
 LDA L000C
 BEQ C2E56

.C2E19

 JMP C2FCC

.C2E1C

 LDA L0076
 BEQ C2E2B
 LDA #&00
 STA L0B40,Y
 STA L0B40,X
 JMP C2FCC

.C2E2B

 LDA L000C
 BEQ C2E96
 LDA L0AE0,Y
 STA L003E
 LDA L0A80,Y
 STA L001A
 LDA L0AE0,X
 STA L003F
 LDA L0A80,X
 STA L0016
 LDA L54A0,Y
 STA L0018
 LDA L54A0,X
 STA L0039
 LDA #&00
 STA L0041
 STA L0042
 JSR sub_C2EAE

.C2E56

 LDY L004A
 INY
 CPY L0017
 BEQ C2E60
 JMP C2DCE

.C2E60

 LDA L001E
 CMP L0017
 BNE C2E88
 LDA L0AE0,X
 BNE C2E88
 LDY L0A80,X
 CPY L0052
 BCC C2E88
 CPY L0051
 BCS C2E88
 STY L0004
 STY L0006
 LDA L0030
 STA Noise2,Y
 LDA L0031
 STA Noise3,Y
 LDA #&00
 STA L007F

.C2E88

 LDA L007F
 BNE C2E94
 LDA L0006
 CMP L0004
 BCC C2E94
 CLC
 RTS

.C2E94

 SEC
 RTS

.C2E96

 LDA L54A0,X
 CMP L0031
 BCC C2E9F
 STA L0031

.C2E9F

 CMP L0030
 BCS C2EA5
 STA L0030

.C2EA5

 INC L001E
 JMP C2E56

.C2EAA

 JMP C3087

.return_25

 RTS

.sub_C2EAE

 LDA L003F
 BMI C2EC2
 BNE return_25
 LDA L0016
 CMP L0051
 BCS return_25
 CMP L0004
 BCS C2EC6
 CMP L0052
 BCS C2EC4

.C2EC2

 LDA L0052

.C2EC4

 STA L0004

.C2EC6

 LDA L003E
 BMI return_25
 BNE C2EDA
 LDA L001A
 CMP L0052
 BCC return_25
 CMP L0006
 BCC C2EE1
 CMP L0051
 BCC C2EDF

.C2EDA

 LDA L0051
 SEC
 SBC #&01

.C2EDF

 STA L0006

.C2EE1

 LDA L0041
 ORA L0042
 BNE C2EAA
 LDA L0018
 SEC
 SBC L0039
 BCS C2EF9
 EOR #&FF
 CLC
 ADC #&01
 STA L000D
 LDX #&E8
 BNE C2EFD

.C2EF9

 STA L000D
 LDX #&CA

.C2EFD

 LDY L000D
 CPY L000C
 LDY L001A
 LDA L0002
 BCS C2F3B
 STA L2F2B
 STY L2F2A
 STX C2F28
 LDY L000C
 INY
 LDA L000C
 LSR A
 EOR #&FF
 CLC
 LDX L003E
 BNE C2F80
 LDX L0018
 JMP C2F29

.loop_C2F22

 ADC L000D
 BCC C2F29
 SBC L000C

.C2F28

 INX

.C2F29

L2F2A = C2F29+1
L2F2B = C2F29+2

 STX L5B9F
 DEC L2F2A
 BEQ C2F37

.C2F31

 DEY
 BNE loop_C2F22

.C2F34

 STY L007F

.return_26

 RTS

.C2F37

 LDY #&00
 BEQ C2F34

.C2F3B

 STA L2F79
 STY L2F78
 STX C2F6B
 LDY #&07
 CMP #&5A
 BEQ C2F50
 CPX #&CA
 BEQ C2F54
 BNE C2F56

.C2F50

 CPX #&CA
 BEQ C2F56

.C2F54

 LDY #&0A

.C2F56

 STY L2F6F
 LDY L000D
 INY
 LDA L000D
 LSR A
 EOR #&FF
 CLC
 LDX L003E
 BNE C2FA6
 LDX L0018
 JMP C2F77

.C2F6B

 DEX
 ADC L000C

.sub_C2F6E

L2F6F = sub_C2F6E+1

 BCC C2F7A
 SBC L000D
 DEC L2F78
 BEQ C2F37

.C2F77

L2F78 = C2F77+1
L2F79 = C2F77+2

 STX L5B9E

.C2F7A

 DEY
 BNE C2F6B
 JMP C2F34

.C2F80

 INC L2F2A
 LDX C2F28
 STX C2F94
 LDX L0018
 JMP C2F95

.loop_C2F8E

 ADC L000D
 BCC C2F95
 SBC L000C

.C2F94

 INX

.C2F95

 DEC L2F2A
 BEQ C2FA0
 DEY
 BNE loop_C2F8E
 JMP return_26

.C2FA0

 DEC L2F2A
 JMP C2F31

.C2FA6

 INC L2F78
 LDX C2F6B
 STX C2FB4
 LDX L0018
 JMP C2FC0

.C2FB4

 INX
 ADC L000C
 BCC C2FC0
 SBC L000D
 DEC L2F78
 BEQ C2FC6

.C2FC0

 DEY
 BNE C2FB4
 JMP return_26

.C2FC6

 DEC L2F78
 JMP C2F7A

.C2FCC

 STX L000E
 LDA #&00
 STA L0040
 LDA L54A0,Y
 SEC
 SBC L54A0,X
 STA L0074
 LDA L0B40,Y
 SBC L0B40,X
 STA L000A
 JSR sub_C1007
 STA L0075
 ORA L0076
 BEQ C2FFA

.C2FEC

 LSR L0076
 ROR L000C
 LSR L0075
 ROR L0074
 SEC
 ROL L0040
 LSR A
 BNE C2FEC

.C2FFA

 LDX L000C
 CPX #&FF
 BEQ C2FEC
 LDX L0074
 CPX #&FF
 BEQ C2FEC
 LDA L0075
 BIT L000A
 JSR sub_C1007
 STA L0043
 LDA L0074
 STA L003A
 LDA L54A0,Y
 STA L0039
 LDA L0B40,Y
 STA L0042
 LDA L0AE0,Y
 STA L003F
 LDA L0A80,Y
 STA L0016
 LDA L0040
 BEQ C3054

.C302B

 LDA L0016
 STA L001A
 SEC
 SBC L000C
 STA L0016
 LDA L003F
 STA L003E
 SBC #&00
 STA L003F
 LDA L0039
 STA L0018
 SEC
 SBC L003A
 STA L0039
 LDA L0042
 STA L0041
 SBC L0043
 STA L0042
 JSR sub_C2EAE
 DEC L0040
 BNE C302B

.C3054

 LDA L0016
 STA L001A
 LDA L003F
 STA L003E
 LDA L0039
 STA L0018
 LDA L0042
 STA L0041
 LDX L000E
 LDA L0A80,X
 STA L0016
 LDA L0AE0,X
 STA L003F
 LDA L54A0,X
 STA L0039
 LDA L0B40,X
 STA L0042
 LDA L001A
 SEC
 SBC L0016
 STA L000C
 JSR sub_C2EAE
 JMP C2E56

.C3087

 LDA L0018
 SEC
 SBC L0039
 STA L000D
 LDA L0041
 SBC L0042
 BPL C30A4
 LDA #&00
 SEC
 SBC L000D
 STA L000D
 LDX #&E8
 LDA #&00
 LDY #&E6
 JMP C30AA

.C30A4

 LDX #&CA
 LDA #&FF
 LDY #&C6

.C30AA

 STY L0074
 STA L0076
 LDY L000D
 CPY L000C
 LDY L001A
 LDA L0002
 BCS C3112
 STA L30EB
 STX C30E3
 LDA L003E
 BEQ C30C3
 INY

.C30C3

 STY L30EA
 LDA L0074
 STA C310A
 LDY L000C
 TYA
 LSR A
 EOR #&FF
 CLC
 INY
 STY L0075
 LDX L0018
 JSR sub_C316E
 JMP C30E9

.loop_C30DD

 ADC L000D
 BCC C30E9
 SBC L000C

.C30E3

 INX
 CPX L0076
 CLC
 BEQ C310A

.C30E9

L30EA = C30E9+1
L30EB = C30E9+2

 STX Noise2
 DEC L30EA
 BEQ C30F8

.C30F1

 DEC L0075
 BNE loop_C30DD
 JMP return_26

.C30F8

 DEC L003E
 BPL C30FF
 JMP return_26

.C30FF

 BNE C30F1
 DEC L30EA
 JSR sub_C316E
 JMP C30F1

.C310A

 INC L0041
 JSR sub_C316E
 JMP C30E9

.C3112

 STA L314A
 STX C3137
 LDA L003E
 BEQ C311D
 INY

.C311D

 STY L3149
 LDA L0074
 STA C3164
 LDY L000D
 TYA
 LSR A
 EOR #&FF
 CLC
 INY
 STY L0075
 LDX L0018
 JSR sub_C316E
 JMP C3148

.C3137

 INX
 CPX L0076
 CLC
 BEQ C3164

.C313D

 ADC L000C
 BCC C3148
 SBC L000D
 DEC L3149
 BEQ C3152

.C3148

L3149 = C3148+1
L314A = C3148+2

 STX Noise2
 DEC L0075
 BNE C3137
 JMP return_26

.C3152

 DEC L003E
 BPL C3159
 JMP return_26

.C3159

 BNE C3148
 DEC L3149
 JSR sub_C316E
 JMP C3148

.C3164

 INC L0041
 JSR sub_C316E
 JMP C313D

.sub_C316C

 BCC C3194

.sub_C316E

 PHA
 LDA L003E
 BEQ C3177
 LDA #&2C
 BNE C318C

.C3177

 STA L007F
 LDA L0041
 BNE C3181
 LDA #&8E
 BNE C318C

.C3181

 BPL C3188
 LDY #&00
 JMP C318A

.C3188

 LDY #&FF

.C318A

 LDA #&8C

.C318C

 STA C30E9
 STA C3148
 PLA
 RTS

.C3194

 STY L31BC
 LDY #&08

.loop_C3199

 LDA L0C7D
 LSR A
 LSR A
 LSR A
 EOR L0C7F
 ROR A
 ROL L0C7B
 ROL L0C7C
 ROL L0C7D
 ROL L0C7E
 ROL L0C7F
 DEY
 BNE loop_C3199
 LDY L31BC
 LDA L0C7F
 RTS

.L31BC

 EQUB &00

.C31BD

 CLC
 ADC #&30

.sub_C31C0

 CMP #&30
 BNE C31C6
 LDA #&4F

.C31C6

 BIT L0C60
 BMI C31CE
 JMP C5744

.C31CE

 PHA
 STA L0C10
 AND #&C0
 BPL C31E5
 ASL A
 ASL A
 PLA
 AND #&1F
 BCS C31E1
 STA L0C49
 RTS

.C31E1

 STA L0C4A
 RTS

.C31E5

 TXA
 PHA
 TYA
 PHA
 LDY #>(L0C10)
 LDX #<(L0C10)
 LDA #10                \ osword_read_char
 JSR OSWORD
 LDA L0C4A
 STA L0026
 LDX #&07
 LDA L0C6E,X
 CMP L0F36,X
 BCS C3204
 JSR sub_C316C

.C3204

 ASL L0C10,X
 LDA L0C49
 STA L0024
 LDA #&04
 STA L0015

.loop_C3210

 ASL L0C10,X
 ROL A
 ASL L0C10,X
 ROL A
 AND #&03
 TAY
 LDA L3248,Y
 PHA
 JSR sub_C2B78
 PLA
 STA (L005E),Y
 INC L0024
 DEC L0015
 BNE loop_C3210
 INC L0026
 DEX
 BMI C3239
 BNE C3204
 LDA #&00
 STA L0C10
 BEQ C3204

.C3239

 LDA L0C49
 CLC
 ADC #&04
 STA L0C49
 PLA
 TAY
 PLA
 TAX
 PLA
 RTS

.L3248

 EQUS " '()"

.sub_C324C

 STA L328F
 LDA #&80
 STA L09FF
 LDA #&E0
 STA L0A3F
 LDA #&02
 STA L097F
 SEC
 ROR L0C4B
 LDA #&00
 JSR sub_C2AF2
 BIT L328F
 BPL C3275
 JSR sub_C3381
 LDX #&03
 LDA #&00
 BEQ C3286

.C3275

 LDX #&00

.loop_C3277

 LDA L3290,X
 JSR C31CE
 INX
 CPX #&0F
 BCC loop_C3277
 LDX #&01
 LDA #&05

.C3286

 LDY #&01
 JSR sub_C139B
 LSR L0C4B
 RTS

.L328F

 EQUB &00

.L3290

 EQUB &84, &D5
 EQUS "THE"
 EQUB &80, &C7
 EQUS "SENTINEL"

.sub_C329F

 STA L0074
 JSR sub_C5E20
 LDY #&07
 LDA #&20

.loop_C32A8

 STA L0CF0,Y
 DEY
 BPL loop_C32A8
 JSR sub_C3303

.loop_C32B1

 LDY #&00

.C32B3

 JSR C5E0A
 CMP #&0D
 BEQ return_27
 CMP #&30
 BCC C32B3
 CMP #&7F
 BCC C32DB
 BNE C32B3
 DEY
 BMI loop_C32B1
 LDX #&00

.loop_C32C9

 LDA L0CF1,X
 STA L0CF0,X
 INX
 CPX #&07
 BNE loop_C32C9
 LDA #&20
 STA L0CF7
 BNE C32FC

.C32DB

 CMP #&3A
 BCS C32B3
 CPY L0074
 BNE C32EB
 LDA #&07
 JSR OSWRCH
 JMP C32B3

.C32EB

 INY
 PHA
 LDX #&06

.loop_C32EF

 LDA L0CF0,X
 STA L0CF1,X
 DEX
 BPL loop_C32EF
 PLA
 STA L0CF0

.C32FC

 JSR sub_C3303
 JMP C32B3

.return_27

 RTS

.sub_C3303

 SEC
 ROR L0C0F
 LDX L0074
 DEX

.loop_C330A

 LDA L0CF0,X
 JSR sub_C31C0
 DEX
 BPL loop_C330A
 LDX L0074
 LDA #&08

.loop_C3317

 JSR sub_C31C0
 DEX
 BNE loop_C3317
 LSR L0C0F
 RTS

.sub_C3321

 LDY #&00
 LDX #&00

.loop_C3325

 JSR sub_C333E
 STA L0074
 INY
 JSR sub_C333E
 ASL A
 ASL A
 ASL A
 ASL A
 ORA L0074
 STA L0CF0,X
 INX
 INY
 CPY #&08
 BNE loop_C3325
 RTS

.sub_C333E

 LDA L0CF0,Y
 CPY #&04
 BCC C334C
 PHA
 LDA #&FF
 STA L0CF0,Y
 PLA

.C334C

 CMP #&20
 BNE C3352
 LDA #&30

.C3352

 SEC
 SBC #&30
 RTS

.C3356

 PHA
 LSR A
 LSR A
 LSR A
 LSR A
 JSR C31BD
 PLA
 AND #&0F
 JMP C31BD

.sub_C3364

 JSR C3194
 PHA
 AND #&0F
 CMP #&0A
 BCC C3370
 SBC #&06

.C3370

 STA L3380
 PLA
 AND #&F0
 CMP #&A0
 BCC C337C
 SBC #&60

.C337C

 ORA L3380
 RTS

.L3380

 EQUB &00

.sub_C3381

 LDA #&80
 STA L0C60
 JSR C31CE
 LDA #&C7
 JSR C31CE
 LSR L0CE6
 LDX L0CE6

.loop_C3394

 JSR sub_C3364
 CPX #&04
 BCS C339E
 JSR C3356

.C339E

 DEX
 BPL loop_C3394
 STX L0CE6
 JSR C3194
 LSR L0C60
 RTS

.C33AB

 LDA L0CFE
 JSR C3356
 LDA L0CFD
 JMP C3356

.sub_C33B7

 STY L0C7C
 STX L0C7B
 STY L0CFE
 STX L0CFD
 STY L0C52
 TYA
 BNE C33D8
 TXA
 STA L0C52
 LSR A
 LSR A
 LSR A
 LSR A
 CLC
 ADC #&01
 CMP #&09
 BCC C33DA

.C33D8

 LDA #&08

.C33DA

 STA L0C07
 RTS

.sub_C33DE

 CMP #&C8
 BCS C33E5
 JMP C576A

.C33E5

 SBC #&C8
 TAX
 TYA
 PHA
 JSR sub_C36AD
 PLA
 TAY
 RTS

.sub_C33F0

 LDA L0CFE
 LSR A
 LSR A
 LSR A
 LSR A
 CLC
 ADC #&02
 STA L0074

.loop_C33FC

 JSR C3194
 LDY #&07
 ASL A
 PHP
 BEQ C340B
 LDY #&FF

.loop_C3407

 INY
 ASL A
 BCC loop_C3407

.C340B

 TYA
 PLP
 BCC C3411
 EOR #&FF

.C3411

 CLC
 ADC L0074
 CMP #&08
 BCS loop_C33FC
 ADC #&01
 RTS

.sub_C341B

 JSR C3194
 PHA
 AND #&07
 STA L0074
 PLA
 LSR A
 LSR A
 AND #&1E
 LSR A
 ADC L0074
 RTS

.sub_C342C

 LDA #&00
 LDX L0C0A
 BEQ return_28

.loop_C3433

 CLC
 ADC #&01
 DEX
 BNE loop_C3433

.return_28

 RTS

.sub_C343A

 STX L5904
 STY L590C

.C3440

 PHA
 SEC
 SBC #&01
 BCS C3448
 ADC #&01

.C3448

 JSR sub_C3463
 PLA
 TAX
 LDA L3479,X
 CMP #&01
 BNE C3459
 JSR C3459
 LDA #&00

.C3459

 ASL A
 ASL A
 ASL A
 ADC #&00
 TAX
 LDA #&07
 BNE C3473

.sub_C3463

 STA L3478
 ASL A
 ASL A
 ASL A
 SEC
 SBC L3478
 ASL A
 ADC #&28
 TAX
 LDA #&08

.C3473

 LDY #&59
 JMP OSWORD

.L3478

 EQUB &00

.L3479

 EQUB &01, &01, &04, &02, &02, &03, &01

.C3480

 LDA L0CE4
 BMI return_29
 LDA L34D4
 LDX L0CEB
 BEQ C3498
 DEX
 BNE return_29
 CMP #&78
 BCS C349E
 ADC #&08
 BNE C349E

.C3498

 CMP #&00
 BEQ C349E
 SBC #&08

.C349E

 LDX L0CDF
 CPX #&02
 BCS C3480
 STA L34D4
 TAY
 BEQ C34AD
 LDY #&08

.C34AD

 STY L595F
 STY L5951
 LDY #&0B

.loop_C34B5

 LDX L34D5,Y
 CPX #&4F
 BNE C34C0
 EOR #&FF
 ADC #&00

.C34C0

 STA L5928,X
 DEY
 BPL loop_C34B5
 LDA #&0C
 STA L0CDF
 LDA #&05
 JSR C3440
 JMP C3480

.return_29

 RTS

.L34D4

 EQUB &58

.L34D5

 EQUB &4F, &0C, &0D, &1A, &1B, &24, &28, &36
 EQUB &40, &44, &4E, &52

.sub_C34E1

 LDA L0CEB
 BMI return_30
 CMP #&02
 BNE return_30
 ROR L0C72
 LDA #&08
 JSR C162D
 JSR sub_C3548

.loop_C34F5

 LDA L0CEB
 CMP #&03
 BNE loop_C34F5
 LDA #&00
 JSR C162D
 LSR L0C72

.return_30

 RTS

.C3505

 LDX L0CE7
 BMI return_31
 INC L0CE7
 LDA L5850,X
 CMP #&FF
 BEQ C3544
 CMP #&C8
 BCC C3522
 SBC #&C8
 ASL A
 ASL A
 STA L0C70
 JMP C3505

.C3522

 STA L5914
 LDA L0C70
 STA L0CDF
 LDA L5910
 CLC
 ADC #&01
 CMP #&14
 BCC C3537
 LDA #&11

.C3537

 STA L5910
 LDA #&04
 STA L5912
 LDA #&03
 JMP C3440

.C3544

 STA L0CE7

.return_31

 RTS

.sub_C3548

 LDX #&07

.loop_C354A

 JSR C3555
 DEX
 CPX #&04
 BCS loop_C354A
 RTS

.sub_C3553

 LDX #&04

.C3555

 LDA #21                \ osbyte_flush_buffer
 JMP OSBYTE

.sub_C355A

 LDA L0CDF
 BNE return_32
 LDA L0C73
 CMP #&04
 BEQ C358E
 CMP #&03
 BEQ C358B
 CMP #&06
 BNE return_32
 LDX #&07
 LDY L0C74
 CPY #&50
 BCC return_32
 LDA #&06
 JSR sub_C343A
 JSR C3194
 AND #&03
 CLC
 ADC #&01
 STA L0CDF
 DEC L0C74

.return_32

 RTS

.C358B

 JMP C3505

.C358E

 LDA #&32
 STA L0CDF
 LDA #&22
 STA L5914
 LDA #&03
 STA L5912
 LDA #&04
 JSR C3440
 RTS

 EQUB &B9

.sub_C35A4

 LDA #&83
 JSR sub_C5E2C
 JSR sub_C5E07
 LSR L0CFC

.C35AF

 JSR sub_C3548
 LDA L0C64
 BPL C35BA
 JMP C1017

.C35BA

 LDA L0C4E
 BMI C361D
 LDA #&04
 JSR sub_C5E2C
 LDA #&00
 STA L0055
 STA L0008
 STA L0CC9
 STA L0C5F
 JSR sub_C5734
 LDA L000B
 STA L006E
 BIT L0CDE
 BPL C35E4
 BVS C362C
 JSR sub_C1090
 JMP C35F5

.C35E4

 LDA L0C51
 BMI C35EC
 JSR sub_C2463

.C35EC

 JSR sub_C1090
 JSR sub_C2624
 JSR sub_C36C7

.C35F5

 LDA #&19
 STA L0055
 LDA #&02
 JSR sub_C2963

.loop_C35FE

 JSR sub_C355A
 LDA L0CE7
 BPL loop_C35FE
 LDA #&83
 JSR sub_C5E2C
 LDA L0CDE
 BPL C3666
 STA L0C4E
 LDA #&06
 STA L0C73
 LDA #&05
 JSR sub_C5F24

.C361D

 JSR sub_C1149
 LDY L0CFE
 LDX L0CFD
 JSR sub_C33B7
 JMP C106C

.C362C

 LDA #&04
 JSR sub_C5E2C
 LDX #&03
 LDA #&00
 STA L0C73

.loop_C3638

 STA L0C7C,X
 DEX
 BPL loop_C3638
 JSR sub_C1172
 JSR sub_C1A7E
 LDA #&87
 JSR sub_C5E2C
 LDA #&0A
 STA L0CDF
 LDA #&42
 JSR sub_C5FF6

.loop_C3653

 JSR sub_C355A
 LDA L0CE7
 BPL loop_C3653
 LDX #&06
 JSR sub_C36AD
 JSR sub_C5E07

.C3663

 JMP C1017

.C3666

 JSR sub_C1264
 BCC C366E
 JMP C35AF

.C366E

 LDA L0009
 STA L0008
 LDA #&00
 STA L0CD1
 STA L0C1E
 BIT L0C5F
 BMI C3683
 SEC
 ROR L0C1B

.C3683

 JSR sub_C10B7
 LSR L0C1B
 JSR sub_C36C7
 LDA L0CD1
 STA L0CC1

.loop_C3692

 LDA L0CC1
 BNE loop_C3692
 BEQ C3666

.sub_C3699

 LDA #&00
 STA L0C05

.loop_C369E

 LDA #&00
 JSR sub_C373A
 LDA L0C05
 CMP #&28
 BCC loop_C369E
 JMP C3AEB

.sub_C36AD

 LDY L5784,X

.loop_C36B0

 LDA L5796,Y
 CMP #&FF
 BEQ return_33
 JSR sub_C33DE
 INY
 JMP loop_C36B0

.return_33

 RTS

.L36BF

 EQUB &77, &BB, &DD, &EE, &88, &44, &22, &11

.sub_C36C7

 LDA #&00
 STA L0C05
 JSR sub_C373A
 LDA L0C0A
 STA L0015

.loop_C36D4

 LDA L0015
 CMP #&0F
 BCC C36EB
 SBC #&0F
 STA L0015
 LDA #&06
 JSR sub_C373A
 LDA #&00
 JSR sub_C373A
 JMP loop_C36D4

.C36EB

 LDA L0015
 CMP #&03
 BCC C3702
 SBC #&03
 STA L0015
 LDA #&01
 JSR sub_C373A
 LDA #&00
 JSR sub_C373A
 JMP C36EB

.C3702

 CMP #&01
 BCC C3710
 ASL A
 JSR sub_C373A
 CLC
 ADC #&01
 JSR sub_C373A

.C3710

 LDA #&00
 JSR sub_C373A
 LDA L0C05
 CMP #&1D
 BCC C3710
 LDA #&07
 JSR sub_C373A

.loop_C3721

 LDA #&08
 JSR sub_C373A
 LDA L0C05
 CMP #&26
 BCC loop_C3721
 LDA #&09
 JSR sub_C373A
 LDA #&00
 JSR sub_C373A
 JMP C3AEB

.sub_C373A

 PHA
 ASL A
 ASL A
 ASL A
 ORA #&07
 TAX
 LDA L0C05
 ASL A
 ASL A
 ADC #&00
 STA P
 LDA #&2D
 ADC #&00
 ASL P
 ROL A
 STA Q
 LDY #&07

.loop_C3755

 LDA L58B0,X
 STA (P),Y
 DEX
 DEY
 BPL loop_C3755
 INC L0C05
 PLA
 RTS

.C3763

 JMP (L0D01)

.sub_C3766

 SEI
 LDA SHEILA+&6D         \ user_via_ifr
 AND #&40
 BEQ C3763
 STA SHEILA+&6D         \ user_via_ifr
 LDA L00FC
 PHA
 TXA
 PHA
 TYA
 PHA
 CLD
 DEC L0CDF
 BPL C3781
 INC L0CDF

.C3781

 LDA L0CFC
 BMI C37CB
 LDA L0C4E
 BMI C37C3
 LDA L0C72
 BMI C37B1
 LDA L0CC1
 BEQ C379B
 JSR sub_C37D1
 JSR C3AEB

.C379B

 LDA L0CE5
 BMI C37A6
 JSR sub_C12EE
 JSR sub_C1623

.C37A6

 LDA L0CE4
 BMI C37CB
 JSR sub_C118B
 JMP C37CB

.C37B1

 LDY #&0D
 JSR sub_C1353
 LDX #&02
 LDA #&80

.loop_C37BA

 STA L0CE8,X
 DEX
 BPL loop_C37BA
 JMP C37CB

.C37C3

 LDA L0C4D
 BPL C37CB
 JSR sub_C56D9

.C37CB

 PLA
 TAY
 PLA
 TAX
 PLA
 RTI

.sub_C37D1

 LDY L0008
 LDA L0CC2
 CLC
 ADC L38E4,Y
 STA L0CC2
 LDA L0CC3
 ADC L38E8,Y
 CMP #&80
 BCC C37EC
 SBC #&20
 JMP C37F2

.C37EC

 CMP #&60
 BCS C37F2
 ADC #&20

.C37F2

 STA L0CC3
 JSR sub_C3AD3
 STA L006D
 LDA L0CCA
 LSR L006D
 ROR A
 LSR L006D
 ROR A
 LSR L006D
 ROR A
 LDX #13                \ crtc_screen_start_low
 STX SHEILA+&00         \ crtc_address_register
 STA SHEILA+&01         \ crtc_register_data
 LDX #12                \ crtc_screen_start_high
 STX SHEILA+&00         \ crtc_address_register
 LDA L006D
 STA SHEILA+&01         \ crtc_register_data
 DEC L0CC1
 LDA L0CC2
 CLC
 ADC L38DC,Y
 STA L0064
 LDA L0CC3
 ADC L38E0,Y
 CMP #&80
 BCC C3830
 SBC #&20

.C3830

 STA L0065

.sub_C3832

 LDA L2090
 CLC
 ADC L38E4,Y
 STA L2090
 STA L0062
 LDA L2091
 ADC L38E8,Y
 STA L2091
 STA L0063
 CPY #&02
 BCS C3889
 LDX #&18

.C384F

 JSR sub_C38B2
 LDA L0062
 CLC
 ADC #&40
 STA L0062
 LDA L0063
 ADC #&01
 CMP #&53
 BNE C386E
 LDA L2090
 CLC
 ADC #&A0
 STA L0062
 LDA L2091
 ADC #&00

.C386E

 STA L0063
 LDA L0064
 CLC
 ADC #&40
 STA L0064
 LDA L0065
 ADC #&01
 CMP #&80
 BCC C3881
 SBC #&20

.C3881

 STA L0065
 DEX
 BNE C384F
 JMP return_34

.C3889

 LDX #&28

.C388B

 JSR sub_C38B2
 LDA L0062
 CLC
 ADC #&08
 STA L0062
 LDA L0063
 ADC #&00
 STA L0063
 LDA L0064
 CLC
 ADC #&08
 STA L0064
 LDA L0065
 ADC #&00
 CMP #&80
 BCC C38AC
 SBC #&20

.C38AC

 STA L0065
 DEX
 BNE C388B

.return_34

 RTS

.sub_C38B2

 LDY #&00
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 INY
 LDA (L0062),Y
 STA (L0064),Y
 RTS

.L38DC

 EQUB &38, &00, &00, &C0

.L38E0

 EQUB &01, &00, &00, &1C

.L38E4

 EQUB &08, &F8, &C0, &40

.L38E8

 EQUB &00, &FF, &FE, &01

.L38EC

 EQUB &3E, &3F, &49, &3D

.L38F0

 EQUB &F8, &80, &00, &C0

.L38F4

 EQUB &14, &F8, &04, &F4

.sub_C38F8

 STA L0CD1

.sub_C38FB

 LDA L38F0,Y
 STA L2090
 LDA L38EC,Y
 STA L2091
 RTS

.sub_C3908

 LDA #&00
 JSR sub_C2963
 LDY #&00

.loop_C390F

 LDA L391A,Y
 STA L0051
 LDA L391C,Y
 STA L0052
 RTS

.L391A

 EQUB &F0, &F0

.L391C

 EQUB &B0, &30

.sub_C391E

 LDA #&02
 JSR sub_C2963

.sub_C3923

 LDY #&01
 BNE loop_C390F

.sub_C3927

 JSR sub_C3934
 LDA L0009
 BPL C3931
 JSR sub_C396B

.C3931

 JMP C39D9

.sub_C3934

 LDX L0CE8
 BMI return_35
 BNE C3953
 LDA L0CC6
 CLC
 ADC #&01
 CMP #&90
 BCC C3949
 SBC #&40
 STX L0009

.C3949

 STA L0CC6
 AND #&03
 BEQ C39B6
 JMP return_35

.C3953

 LDA L0CC6
 SEC
 SBC #&01
 CMP #&10
 BCS C3961
 ADC #&40
 STX L0009

.C3961

 STA L0CC6
 AND #&03
 CMP #&03
 BEQ C39B6

.return_35

 RTS

.sub_C396B

 LDX L000B
 LDY L0140,X
 LDX L0CEA
 BMI return_36
 CPX #&02
 BNE C3997
 LDA L0CC7
 CLC
 ADC #&01
 CMP #&A0
 BCC C398D
 CPY L1147
 BEQ return_36
 SEC
 SBC #&40
 STX L0009

.C398D

 STA L0CC7
 AND #&07
 BNE C39B6
 JMP C39B4

.C3997

 LDA L0CC7
 SEC
 SBC #&01
 CMP #&20
 BCS C39AB
 CPY L1148
 BEQ return_36
 CLC
 ADC #&40
 STX L0009

.C39AB

 STA L0CC7
 AND #&07
 CMP #&07
 BNE C39B6

.C39B4

 INX
 INX

.C39B6

 LDA L0CC4
 CLC
 ADC L3AC7,X
 STA L0CC4
 LDA L0CC5
 ADC L3ACD,X
 CMP #&80
 BCC C39CF
 SBC #&20
 JMP C39D5

.C39CF

 CMP #&60
 BCS C39D5
 ADC #&20

.C39D5

 STA L0CC5

.return_36

 RTS

.C39D9

 LDA L0CD7
 BMI C3A05
 JSR sub_C3AA7
 LDA L0CC6
 AND #&03
 STA L0CCC
 LDA L0CC4
 AND #&07
 TAY
 LDA L0CC4
 AND #&F8
 STA L002A
 LDA L0CC5
 STA L002B

.C39FB

 LDX L0CC9
 TYA
 CLC
 ADC L3A9A,X
 BPL C3A08

.C3A05

 JMP return_37

.C3A08

 CMP #&08
 TAY
 BCC C3A23
 SBC #&08
 TAY
 LDA L002A
 CLC
 ADC #&40
 STA L002A
 LDA L002B
 ADC #&01
 CMP #&80
 BCC C3A21
 SBC #&20

.C3A21

 STA L002B

.C3A23

 LDA L3A8E,X
 BEQ C3A58
 CLC
 ADC L0CCC
 STA L0CCC
 AND #&FC
 ASL A
 BPL C3A36
 DEC L002B

.C3A36

 CLC
 ADC L002A
 STA L002A
 LDA L002B
 ADC #&00
 CMP #&60
 BCS C3A48
 ADC #&20
 JMP C3A4E

.C3A48

 CMP #&80
 BCC C3A4E
 SBC #&20

.C3A4E

 STA L002B
 LDA L0CCC
 AND #&03
 STA L0CCC

.C3A58

 TYA
 ORA L002A
 STA L49C1,X
 LDA L002B
 STA L3DF3,X
 LDA (L002A),Y
 STA L3DE7,X
 LDX L0CCC
 AND L227F,X
 CMP #&10
 PHP
 LDA (L002A),Y
 AND L36BF,X
 PLP
 BCS C3A7E
 ORA L3A8A,X
 BCC C3A81

.C3A7E

 ORA L5730,X

.C3A81

 STA (L002A),Y
 INC L0CC9
 JMP C39FB

.return_37

 RTS

.L3A8A

 EQUB &80, &40, &20, &10

.L3A8E

 EQUB &00, &00, &00, &FB, &02, &02, &02, &02
 EQUB &02, &FB, &00, &00

.L3A9A

 EQUB &00, &02, &02, &01, &00, &00, &00, &00
 EQUB &00, &01, &02, &02, &80

.sub_C3AA7

 LDX L0CC9
 BEQ return_38
 DEX
 LDY #&00

.loop_C3AAF

 LDA L49C1,X
 STA L002A
 LDA L3DF3,X
 STA L002B
 LDA L3DE7,X
 STA (L002A),Y
 DEX
 BPL loop_C3AAF
 LDX #&00
 STX L0CC9

.return_38

 RTS

.L3AC7

 EQUB &08, &F8, &FF, &01, &C7, &39

.L3ACD

 EQUB &00, &FF, &FF, &00, &FE, &01

.sub_C3AD3

 LDA L0CC2
 SEC
 SBC #&40
 STA L0CCA
 LDA L0CC3
 SBC #&01
 CMP #&60
 BCS C3AE7
 ADC #&20

.C3AE7

 STA L0CCB
 RTS

.C3AEB

 LDA #&5A
 STA L0063
 LDA #&00
 STA L0062
 LDA L0CCB
 STA L0065
 LDA L0CCA
 STA L0064
 JMP C3889

.L3B00

L3B01 = L3B00+1

 EQUB &00, &29, &51, &7A, &A3, &CC, &F4, &1D
 EQUB &46, &6F, &97, &C0, &E9, &11, &3A, &62
 EQUB &8B, &B4, &DC, &05, &2D, &56, &7E, &A7
 EQUB &CF, &F7, &20, &48, &70, &99, &C1, &E9
 EQUB &11, &39, &61, &89, &B1, &D9, &01, &29
 EQUB &51, &78, &A0, &C8, &EF, &17, &3E, &66
 EQUB &8D, &B5, &DC, &03, &2A, &51, &78, &9F
 EQUB &C6, &ED, &14, &3B, &61, &88, &AE, &D5
 EQUB &FB, &22, &48, &6E, &94, &BA, &E0, &06
 EQUB &2C, &51, &77, &9D, &C2, &E7, &0D, &32
 EQUB &57, &7C, &A1, &C6, &EB, &10, &34, &59
 EQUB &7D, &A2, &C6, &EA, &0F, &33, &56, &7A
 EQUB &9E, &C2, &E5, &09, &2C, &50, &73, &96
 EQUB &B9, &DC, &FF, &21, &44, &67, &89, &AB
 EQUB &CE, &F0, &12, &34, &56, &77, &99, &BB
 EQUB &DC, &FD, &1F, &40, &61, &82, &A3, &C3
 EQUB &E4, &05, &25, &45, &66, &86, &A6, &C6
 EQUB &E6, &05, &25, &44, &64, &83, &A2, &C1
 EQUB &E0, &FF, &1E, &3D, &5B, &7A, &98, &B7
 EQUB &D5, &F3, &11, &2F, &4C, &6A, &88, &A5
 EQUB &C2, &E0, &FD, &1A, &37, &54, &70, &8D
 EQUB &AA, &C6, &E2, &FE, &1B, &37, &53, &6E
 EQUB &8A, &A6, &C1, &DD, &F8, &13, &2E, &49
 EQUB &64, &7F, &9A, &B4, &CF, &E9, &04, &1E
 EQUB &38, &52, &6C, &86, &9F, &B9, &D3, &EC
 EQUB &05, &1F, &38, &51, &6A, &83, &9C, &B4
 EQUB &CD, &E5, &FE, &16, &2E, &46, &5E, &76
 EQUB &8E, &A6, &BE, &D5, &ED, &04, &1B, &33
 EQUB &4A, &61, &78, &8E, &A5, &BC, &D3, &E9
 EQUB &FF, &16, &2C, &42, &58, &6E, &84, &9A
 EQUB &B0, &C5, &DB, &F0, &06, &1B, &30, &45
 EQUB &5A, &6F, &84, &99, &AE, &C3, &D7, &EC

.L3C00

L3C01 = L3C00+1
L3C02 = L3C00+2

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &01, &01, &01, &01, &01, &01, &02, &02
 EQUB &02, &02, &02, &02, &03, &03, &03, &03
 EQUB &03, &03, &03, &04, &04, &04, &04, &04
 EQUB &04, &05, &05, &05, &05, &05, &05, &06
 EQUB &06, &06, &06, &06, &06, &06, &07, &07
 EQUB &07, &07, &07, &07, &08, &08, &08, &08
 EQUB &08, &08, &08, &09, &09, &09, &09, &09
 EQUB &09, &09, &0A, &0A, &0A, &0A, &0A, &0A
 EQUB &0B, &0B, &0B, &0B, &0B, &0B, &0B, &0C
 EQUB &0C, &0C, &0C, &0C, &0C, &0C, &0D, &0D
 EQUB &0D, &0D, &0D, &0D, &0D, &0E, &0E, &0E
 EQUB &0E, &0E, &0E, &0E, &0F, &0F, &0F, &0F
 EQUB &0F, &0F, &0F, &0F, &10, &10, &10, &10
 EQUB &10, &10, &10, &11, &11, &11, &11, &11
 EQUB &11, &11, &11, &12, &12, &12, &12, &12
 EQUB &12, &12, &13, &13, &13, &13, &13, &13
 EQUB &13, &13, &14, &14, &14, &14, &14, &14
 EQUB &14, &14, &14, &15, &15, &15, &15, &15
 EQUB &15, &15, &15, &16, &16, &16, &16, &16
 EQUB &16, &16, &16, &16, &17, &17, &17, &17
 EQUB &17, &17, &17, &17, &17, &18, &18, &18
 EQUB &18, &18, &18, &18, &18, &18, &19, &19
 EQUB &19, &19, &19, &19, &19, &19, &19, &1A
 EQUB &1A, &1A, &1A, &1A, &1A, &1A, &1A, &1A
 EQUB &1A, &1B, &1B, &1B, &1B, &1B, &1B, &1B
 EQUB &1B, &1B, &1B, &1B, &1C, &1C, &1C, &1C
 EQUB &1C, &1C, &1C, &1C, &1C, &1C, &1D, &1D
 EQUB &1D, &1D, &1D, &1D, &1D, &1D, &1D, &1D
 EQUB &1D, &1D, &1E, &1E, &1E, &1E, &1E, &1E
 EQUB &1E, &1E, &1E, &1E, &1E, &1F, &1F, &1F
 EQUB &1F, &1F, &1F, &1F, &1F, &1F, &1F, &1F

.L3D00

L3D02 = L3D00+2
L3D83 = L3D00+131
L3DAC = L3D00+172
L3DB5 = L3D00+181
L3DDE = L3D00+222
L3DE7 = L3D00+231
L3DF3 = L3D00+243

 EQUB &1F, &20, &00, &02, &04, &06, &08, &0A
 EQUB &0C, &0E, &10, &12, &14, &16, &18, &1A
 EQUB &1C, &1E, &20, &22, &24, &26, &28, &2A
 EQUB &2C, &2E, &30, &32, &33, &35, &37, &39
 EQUB &3B, &3D, &3F, &41, &43, &45, &47, &49
 EQUB &4A, &4C, &4E, &50, &52, &54, &56, &57
 EQUB &59, &5B, &5D, &5F, &60, &62, &64, &66
 EQUB &68, &69, &6B, &6D, &6F, &70, &72, &74
 EQUB &75, &77, &79, &7B, &7C, &7E, &80, &81
 EQUB &83, &84, &86, &88, &89, &8B, &8D, &8E
 EQUB &90, &91, &93, &94, &96, &97, &99, &9B
 EQUB &9C, &9E, &9F, &A1, &A2, &A3, &A5, &A6
 EQUB &A8, &A9, &AB, &AC, &AD, &AF, &B0, &B2
 EQUB &B3, &B4, &B6, &B7, &B8, &BA, &BB, &BC
 EQUB &BE, &BF, &C0, &C2, &C3, &C4, &C5, &C7
 EQUB &C8, &C9, &CA, &CC, &CD, &CE, &CF, &D1
 EQUB &D2, &D3, &D4, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &A0, &E0, &20, &60
 EQUB &A0, &E0, &20, &60, &A0, &60, &62, &63
 EQUB &64, &65, &67, &68, &69, &6A, &6C, &6D
 EQUB &6E, &6F, &71, &72, &73, &74, &76, &77
 EQUB &78, &79, &7B, &7C, &7D, &7E, &3F, &40
 EQUB &41, &42, &44, &45, &46, &47, &49, &4A
 EQUB &4B, &4C, &4E, &4F, &50, &51, &3F, &40
 EQUB &42, &43, &44, &45, &47, &48, &49, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &08

.L3E00

L3E3C = L3E00+60
L3E7C = L3E00+124
L3E80 = L3E00+128
L3EC0 = L3E00+192

 EQUB &00, &00, &00, &00, &07, &03, &01, &00
 EQUB &70, &30, &10, &00, &77, &33, &11, &00
 EQUB &08, &04, &02, &01, &0F, &07, &03, &01
 EQUB &78, &34, &12, &01, &7F, &37, &13, &01
 EQUB &80, &40, &20, &10, &87, &43, &21, &10
 EQUB &F0, &70, &30, &10, &F7, &73, &31, &10
 EQUB &88, &44, &22, &11, &8F, &47, &23, &11
 EQUB &F8, &74, &32, &11, &FF, &77, &33, &11
 EQUB &00, &00, &00, &00, &00, &08, &0C, &0E
 EQUB &00, &80, &C0, &E0, &00, &88, &CC, &EE
 EQUB &08, &04, &02, &01, &08, &0C, &0E, &0F
 EQUB &08, &84, &C2, &E1, &08, &8C, &CE, &EF
 EQUB &80, &40, &20, &10, &80, &48, &2C, &1E
 EQUB &80, &C0, &E0, &F0, &80, &C8, &EC, &FE
 EQUB &88, &44, &22, &11, &88, &4C, &2E, &1F
 EQUB &88, &C4, &E2, &F1, &88, &CC, &EE, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.sub_C3F00

 SEC
 ROR L0CFC

.Begin

 LDA #4                 \ osbyte_set_cursor_editing
 LDY #&00
 LDX #&01
 JSR OSBYTE
 LDA #144               \ osbyte_tv
 LDX #&00
 LDY #&00
 JSR OSBYTE
 LDA #&16
 JSR OSWRCH
 LDA #&05
 JSR OSWRCH
 SEI
 LDA #6                 \ crtc_vert_displayed
 STA SHEILA+&00         \ crtc_address_register
 LDA #&19
 STA SHEILA+&01         \ crtc_register_data
 LDA #7                 \ crtc_vert_sync_pos
 STA SHEILA+&00         \ crtc_address_register

.C3F30

 LDA #&20
 STA SHEILA+&01         \ crtc_register_data
 LDA #10                \ crtc_cursor_start
 STA SHEILA+&00         \ crtc_address_register
 LDA #&20
 STA SHEILA+&01         \ crtc_register_data
 CLI
 LDA #151               \ osbyte_write_sheila
 LDX #&42
 LDY #&FF
 JSR OSBYTE
 LDA #151               \ osbyte_write_sheila
 LDX #&40
 LDY #&05
 JSR OSBYTE
 LDA #151               \ osbyte_write_sheila
 LDX #&40
 LDY #&0C
 JSR OSBYTE
 LDA #0                 \ osbyte_read_os_version
 LDX #&FF

 JSR OSBYTE
 CPX #&00
 BEQ C3F72
 LDA #200               \ osbyte_read_write_escape_break_effect
 LDX #&02
 LDY #&00
 JSR OSBYTE
 JMP C3F8C

.C3F72

 LDX #&1C

.loop_C3F74

 LDA sub_C3FED,X
 STA BRKI,X
 DEX
 BPL loop_C3F74
 LDA #&4C
 STA BRKIV
 LDA #LO(BRKI)
 STA BRKIV+1
 LDA #HI(BRKI)
 STA BRKIV+2

.C3F8C

 LDA #&00
 STA P
 STA R
 LDA #&41
 STA Q
 LDA #&58
 STA S

.loop_C3F9A

 LDY #&00

.loop_C3F9C

 LDA (P),Y
 STA (R),Y
 DEY
 BNE loop_C3F9C
 INC Q
 INC S
 LDA Q
 CMP #&4A
 BCC loop_C3F9A
 SEI
 LDA IRQ1V
 STA L0D01
 LDA IRQ1V+1
 STA L0D02
 LDA #&02

.loop_C3FBC

 BIT SHEILA+&4D         \ system_via_ifr
 BEQ loop_C3FBC
 LDA #&40
 STA SHEILA+&6B         \ user_via_acr
 LDA #&C0
 STA SHEILA+&6E         \ user_via_ier
 LDA #&00
 STA SHEILA+&64         \ user_via_t1c_l
 LDA #&39
 STA SHEILA+&65         \ user_via_t1c_h
 LDA #&1E
 STA SHEILA+&66         \ user_via_t1l_l
 LDA #&4E
 STA SHEILA+&67         \ user_via_t1l_h
 LDA #&37
 STA IRQ1V+1
 LDA #&66
 STA IRQ1V
 CLI
 JMP C1017

.sub_C3FED

 LDA #&04
 STA Q
 LDA #&00
 STA P

.loop_C3FF5

 LDY #&FF

.loop_C3FF7

 STA (P),Y
 DEY
 BNE loop_C3FF7
 INC Q
 LDX Q
 CPX #&7C
 BCC loop_C3FF5
 LDA #&00
 STA BRKIV
 RTS

.Noise1

 EQUB &20, &65, &74, &73, &36, &0D, &12, &CA
 EQUB &19, &20, &20, &20, &20, &20, &20, &4C
 EQUB &44, &58, &23, &36, &3A, &4A, &53, &52
 EQUB &20, &43, &46, &4C, &53, &48, &0D, &12
 EQUB &D4, &05, &20, &0D, &12, &DE, &0D, &2E
 EQUB &65, &74, &73, &36, &20, &72, &74, &73
 EQUB &0D, &12, &E8, &05, &20, &0D, &12, &F2
 EQUB &05, &20, &0D, &12, &FC, &05, &20, &0D
 EQUB &13, &06, &05, &20, &0D, &13, &10, &05
 EQUB &20, &0D, &13, &1A, &05, &20, &0D, &13
 EQUB &24, &05, &20, &0D, &13, &2E, &2A, &2E
 EQUB &4D, &49, &4E, &49, &20, &4C, &44, &41
 EQUB &23, &31, &32, &38, &3A, &53, &54, &41
 EQUB &20, &4D, &45, &41, &4E, &59, &2C, &58
 EQUB &3A, &53, &54, &41, &20, &4D, &45, &4D
 EQUB &4F, &52, &59, &2C, &58, &0D, &13, &38
 EQUB &1F, &20, &20, &20, &20, &20, &20, &4C
 EQUB &44, &41, &23, &30, &3A, &53, &54, &41
 EQUB &20, &4D, &45, &41, &4E, &59, &53, &43
 EQUB &41, &4E, &2C, &58, &0D, &13, &42, &22
 EQUB &20, &20, &20, &20, &20, &20, &4C, &44
 EQUB &41, &23, &36, &34, &3A, &53, &54, &41
 EQUB &20, &4D, &54, &52, &59, &43, &4E, &54
 EQUB &2C, &58, &3A, &72, &74, &73, &0D, &13
 EQUB &4C, &05, &20, &0D, &13, &56, &1A, &2E
 EQUB &4D, &45, &41, &4E, &20, &4C, &44, &41
 EQUB &23, &34, &30, &3A, &53, &54, &41, &20
 EQUB &43, &4F, &56, &45, &52, &0D, &13, &60
 EQUB &1B, &20, &20, &20, &20, &20, &20, &4C
 EQUB &44, &58, &20, &45, &54, &45, &4D, &3A
 EQUB &53, &54, &58, &20, &58, &54

L49A0                = &49A0
L49A1                = &49A1
L49AB                = &49AB
L49AC                = &49AC
L49B6                = &49B6
L49C1                = &49C1


 ORG &4A00

.L4A00

L4A37 = L4A00+55

 EQUB &4B, &4A, &46, &4B, &47, &4D, &4C, &47
 EQUB &4B, &4E, &4A, &4B, &4C, &4D, &4F, &4C
 EQUB &4C, &4F, &4E, &4B, &4C, &46, &4A, &49
 EQUB &46, &47, &48, &4D, &47, &4A, &50, &49
 EQUB &4A, &48, &51, &4D, &48, &4A, &4E, &50
 EQUB &4A, &4D, &51, &4F, &4D, &49, &50, &51
 EQUB &48, &49, &4F, &51, &50, &4E, &4F, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &10
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L4AE0

 EQUB &CF, &31, &5F, &A1, &D9, &27, &57, &A9
 EQUB &CB, &00, &35, &55, &AB, &C5, &3B, &52
 EQUB &AE, &00, &EC, &14, &63, &9D, &C0, &40
 EQUB &69, &97, &21, &DF, &00, &DA, &26, &5A
 EQUB &A6, &F5, &0B, &40, &5A, &A6, &C0, &DA
 EQUB &26, &5A, &A6, &F5, &0B, &F8, &08, &E2
 EQUB &1E, &5C, &A4, &E0, &20, &60, &A0, &E0
 EQUB &20, &60, &A0, &00, &20, &40, &60, &80
 EQUB &A0, &C0, &E0, &00, &00, &20, &40, &60
 EQUB &80, &A0, &C0, &E0, &00, &59, &A7, &80
 EQUB &72, &8E, &E1, &1F, &59, &A7, &D5, &F6
 EQUB &0A, &2B, &FB, &05, &E9, &17, &DA, &26
 EQUB &5A, &A6, &DA, &26, &5A, &A6, &F5, &0B
 EQUB &40, &5A, &A6, &C0, &DA, &26, &5A, &A6
 EQUB &F5, &0B, &53, &AD, &F8, &08, &E2, &1E
 EQUB &DC, &24, &66, &9A, &E0, &20, &60, &A0
 EQUB &D4, &EC, &14, &2C, &54, &6C, &94, &AC
 EQUB &E0, &FD, &83, &A0, &E0, &FD, &83, &A0
 EQUB &03, &20, &60, &7D, &03, &20, &60, &7D
 EQUB &E0, &20, &60, &A0, &E0, &20, &60, &A0
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &10
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L4C20

 EQUB &F0, &F0, &F0, &F0, &B8, &B8, &B8, &B8
 EQUB &B8, &B8, &B8, &B8, &B8, &92, &92, &92
 EQUB &92, &8A, &8B, &8B, &8B, &8B, &08, &08
 EQUB &08, &08, &83, &83, &95, &F0, &F0, &F0
 EQUB &F0, &98, &98, &9B, &9B, &9B, &9B, &88
 EQUB &88, &88, &88, &88, &88, &01, &01, &08
 EQUB &08, &05, &05, &F0, &F0, &F0, &F0, &C8
 EQUB &C8, &C8, &C8, &C8, &C8, &C8, &C8, &C8
 EQUB &C8, &C8, &C8, &78, &B0, &F0, &B0, &F0
 EQUB &B0, &F0, &B0, &F0, &F0, &F0, &F0, &BC
 EQUB &BC, &BC, &8A, &8A, &01, &01, &88, &8E
 EQUB &8E, &88, &85, &85, &06, &06, &F0, &F0
 EQUB &F0, &F0, &E0, &E0, &E0, &E0, &88, &88
 EQUB &8B, &8B, &8B, &8B, &08, &08, &05, &05
 EQUB &08, &08, &02, &02, &11, &11, &18, &18
 EQUB &27, &27, &27, &27, &F0, &F0, &F0, &F0
 EQUB &10, &10, &10, &10, &10, &10, &10, &10
 EQUB &F0, &F0, &F0, &F0, &70, &70, &70, &70
 EQUB &F0, &F0, &F0, &F0, &70, &70, &70, &70
 EQUB &F0, &F0, &F0, &F0, &70, &70, &70, &70
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &18
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L4D60

 EQUB &14, &14, &1B, &1B, &1F, &1F, &23, &23
 EQUB &2A, &20, &2A, &30, &30, &34, &34, &38
 EQUB &38, &00, &13, &13, &1D, &1D, &0C, &0C
 EQUB &13, &13, &1C, &1C, &20, &2A, &2A, &2A
 EQUB &2A, &32, &32, &36, &2A, &2A, &36, &22
 EQUB &22, &22, &22, &40, &40, &3F, &3F, &22
 EQUB &22, &1F, &1F, &18, &18, &18, &18, &18
 EQUB &18, &18, &18, &68, &68, &68, &68, &68
 EQUB &68, &68, &68, &00, &70, &70, &70, &70
 EQUB &70, &70, &70, &70, &34, &44, &44, &1A
 EQUB &29, &29, &0C, &0C, &17, &17, &2E, &36
 EQUB &36, &2E, &3A, &3A, &22, &22, &38, &38
 EQUB &38, &38, &2A, &2A, &2A, &2A, &32, &32
 EQUB &36, &2A, &2A, &36, &22, &22, &22, &22
 EQUB &40, &40, &46, &46, &3F, &3F, &22, &22
 EQUB &13, &13, &18, &18, &B5, &B5, &B5, &B5
 EQUB &91, &91, &91, &91, &91, &91, &91, &91
 EQUB &C0, &88, &88, &C0, &C0, &88, &88, &C0
 EQUB &88, &C0, &C0, &88, &88, &C0, &C0, &88
 EQUB &C0, &C0, &C0, &C0, &C0, &C0, &C0, &C0
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L4EA0

 EQUB &15, &14, &15, &99, &99, &A5, &A5, &91
 EQUB &91, &99, &90, &90, &94, &94, &90, &90
 EQUB &9C, &9C, &90, &15, &3C, &3C, &19, &19
 EQUB &15, &15, &3D, &95, &94, &94, &95, &A8
 EQUB &A8, &A8, &A8, &A8, &A9, &A8, &A8, &95
 EQUB &A8, &94, &94, &15, &15, &29, &29, &15
 EQUB &1D, &1D, &1D, &1D, &15, &15, &15, &15
 EQUB &19, &19, &15, &18, &1C, &18, &1C, &18
 EQUB &1C, &18, &1C, &14, &14, &14, &14, &18
 EQUB &18, &18, &18, &15, &15, &15, &28, &28
 EQUB &1C, &1C, &35, &BC, &BC, &B9, &14, &14
 EQUB &18, &18, &18, &14, &14, &3D, &18, &18
 EQUB &14, &14, &3C, &3C, &35, &35, &15, &14
 EQUB &14, &95, &A9, &95, &95, &95, &95, &94
 EQUB &94, &95, &A8, &A8, &A8, &A8, &A8, &A8
 EQUB &A9, &94, &94, &BC, &BC, &95, &15, &15
 EQUB &14, &14, &1D, &1D, &1D, &1D, &15, &29
 EQUB &29, &15, &29, &15, &29, &3C, &3C, &3C
 EQUB &3C, &3D, &3D, &3D, &15, &15, &29, &3D
 EQUB &15, &15, &29, &3D, &15, &15, &29, &3D

.L4F40

 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &12
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L4FE0

 EQUB &B4, &B9, &BD, &C2, &C7, &CC, &D1, &D6
 EQUB &DB, &E0, &E5, &E9, &ED, &F1, &F5, &F9
 EQUB &FD, &01, &05, &09, &0E, &12, &16, &1B
 EQUB &20, &25, &2A, &2F, &34, &38, &3C, &41
 EQUB &45, &49, &4D, &51, &55, &5A, &5E, &62
 EQUB &67, &6B, &6F, &73, &78, &7D, &82, &87
 EQUB &8C, &91, &96, &9B, &00, &05, &0A, &0F
 EQUB &14, &19, &1E, &23, &27, &2B, &2F, &33
 EQUB &37, &3B, &3F, &43, &47, &4B, &4F, &53
 EQUB &57, &5B, &5F, &63, &68, &CD, &D2, &D6
 EQUB &DA, &DE, &E2, &E7, &EB, &EF, &F4, &F8
 EQUB &FC, &00, &04, &08, &0C, &10, &15, &19
 EQUB &1D, &21, &25, &29, &2D, &32, &60, &65
 EQUB &69, &6D, &72, &77, &7C, &81, &86, &8B
 EQUB &8F, &93, &98, &9C, &A0, &A4, &A8, &AC
 EQUB &B0, &B5, &B9, &BD, &C1, &C5, &CA, &CF
 EQUB &D4, &D8, &DC, &E1, &E6, &EB, &F0, &F5
 EQUB &FA, &6D, &72, &77, &7C, &81, &85, &89
 EQUB &8D, &91, &96, &9B, &A0, &A5, &AA, &AF
 EQUB &A0, &A5, &AA, &AF, &A0, &A5, &AA, &AF

.L5080

 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L5120

 EQUB &53, &53, &53, &53, &53, &53, &53, &53
 EQUB &53, &53, &53, &53, &53, &53, &53, &53
 EQUB &53, &54, &54, &54, &54, &54, &54, &54
 EQUB &54, &54, &54, &54, &54, &54, &54, &54
 EQUB &54, &54, &54, &54, &54, &54, &54, &54
 EQUB &54, &54, &54, &54, &54, &54, &54, &54
 EQUB &54, &54, &54, &54, &53, &53, &53, &53
 EQUB &53, &53, &53, &53, &53, &53, &53, &53
 EQUB &53, &53, &53, &53, &53, &53, &53, &53
 EQUB &53, &53, &53, &53, &53, &49, &49, &49
 EQUB &49, &49, &49, &49, &49, &49, &49, &49
 EQUB &49, &4A, &4A, &4A, &4A, &4A, &4A, &4A
 EQUB &4A, &4A, &4A, &4A, &4A, &4A, &52, &52
 EQUB &52, &52, &52, &52, &52, &52, &52, &52
 EQUB &52, &52, &52, &52, &52, &52, &52, &52
 EQUB &52, &52, &52, &52, &52, &52, &52, &52
 EQUB &52, &52, &52, &52, &52, &52, &52, &52
 EQUB &52, &53, &53, &53, &53, &53, &53, &53
 EQUB &53, &53, &53, &53, &53, &53, &53, &53
 EQUB &53, &53, &53, &53, &53, &53, &53, &53

.L51C0

 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L5260

 EQUB &54, &50, &51, &55, &54, &51, &4E, &55
 EQUB &51, &54, &4F, &50, &54, &4F, &53, &52
 EQUB &4E, &4F, &43, &47, &46, &42, &43, &40
 EQUB &44, &47, &43, &40, &42, &46, &45, &41
 EQUB &42, &41, &45, &44, &40, &41, &47, &4C
 EQUB &4B, &46, &47, &44, &4D, &47, &44, &46
 EQUB &4A, &45, &46, &45, &49, &48, &44, &45
 EQUB &47, &4D, &4C, &47, &46, &4B, &4A, &46
 EQUB &44, &48, &4D, &44, &45, &4A, &49, &45
 EQUB &4D, &51, &4C, &4D, &4B, &50, &4A, &4B
 EQUB &4C, &51, &50, &4B, &4C, &4D, &4E, &51
 EQUB &4D, &4A, &50, &4F, &4A, &48, &4E, &4D
 EQUB &48, &49, &4A, &4F, &49, &49, &4F, &4E
 EQUB &48, &49, &59, &5B, &5A, &58, &59, &55
 EQUB &5D, &5C, &54, &55, &4E, &58, &55, &4E
 EQUB &54, &59, &4F, &54, &52, &56, &58, &4E
 EQUB &52, &4F, &59, &57, &53, &4F, &57, &59
 EQUB &58, &56, &57, &53, &57, &56, &52, &53
 EQUB &5B, &5C, &5D, &5A, &5B, &58, &5A, &5D
 EQUB &55, &58, &54, &5C, &5B, &59, &54, &10
 EQUB &48, &4F, &4E, &49, &48, &49, &4E, &4D
 EQUB &4A, &49, &4A, &4D, &4C, &4B, &4A, &41
 EQUB &45, &44, &40, &41, &42, &46, &45, &41
 EQUB &42, &40, &44, &47, &43, &40, &43, &47
 EQUB &46, &42, &43, &48, &50, &4F, &48, &49
 EQUB &50, &48, &49, &4A, &50, &49, &4A, &4B
 EQUB &50, &4A, &4B, &4C, &50, &4B, &4C, &4D
 EQUB &50, &4C, &4D, &4E, &50, &4D, &4E, &4F
 EQUB &50, &4E, &4F, &41, &40, &47, &41, &43
 EQUB &42, &41, &43, &45, &44, &43, &45, &47
 EQUB &46, &45, &47, &41, &42, &40, &41, &43
 EQUB &44, &42, &43, &45, &46, &44, &45, &47
 EQUB &40, &46, &47, &41, &47, &45, &43, &41
 EQUB &40, &42, &44, &46, &40, &41, &46, &45
 EQUB &40, &41, &42, &48, &47, &41, &42, &43
 EQUB &4A, &49, &42, &43, &40, &44, &4B, &43
 EQUB &40, &40, &45, &44, &40, &41, &47, &46
 EQUB &41, &42, &49, &48, &42, &43, &4B, &4A
 EQUB &43, &46, &47, &48, &49, &46, &46, &49
 EQUB &4A, &45, &46, &45, &4A, &4B, &44, &45
 EQUB &40, &44, &47, &43, &40, &42, &46, &45
 EQUB &41, &42, &41, &45, &44, &40, &41, &45
 EQUB &46, &47, &44, &45, &4B, &4A, &48, &4C
 EQUB &4B, &4A, &49, &48, &4A, &54, &53, &52
 EQUB &55, &54, &40, &44, &47, &43, &40, &42
 EQUB &46, &45, &41, &42, &43, &47, &46, &42
 EQUB &43, &41, &45, &44, &40, &41, &48, &4D
 EQUB &50, &4C, &48, &4B, &4F, &4E, &4A, &4B
 EQUB &4C, &50, &4F, &4B, &4C, &4A, &5C, &49
 EQUB &4A, &49, &5C, &48, &49, &4A, &4E, &5C
 EQUB &4A, &48, &5C, &4D, &48, &4E, &51, &5C
 EQUB &4E, &5C, &51, &4D, &5C, &4F, &51, &4E
 EQUB &4F, &4D, &51, &50, &4D, &50, &51, &4F
 EQUB &50, &53, &5A, &5B, &52, &53, &52, &5B
 EQUB &55, &52, &54, &5A, &53, &54, &5B, &56
 EQUB &59, &55, &5B, &54, &58, &57, &5A, &54
 EQUB &55, &59, &58, &54, &55, &57, &58, &59
 EQUB &56, &57, &5A, &57, &56, &5B, &5A, &43
 EQUB &48, &47, &42, &43, &40, &49, &43, &40
 EQUB &42, &46, &41, &42, &41, &45, &44, &40
 EQUB &41, &43, &49, &48, &43, &42, &47, &46
 EQUB &42, &41, &46, &45, &41, &40, &44, &49
 EQUB &40, &49, &4D, &48, &49, &48, &4D, &4C
 EQUB &47, &48, &47, &4C, &46, &47, &46, &4B
 EQUB &45, &46, &45, &4B, &4A, &44, &45, &44
 EQUB &4A, &49, &44, &49, &4A, &4D, &49, &46
 EQUB &4C, &4B, &46, &4B, &4F, &4E, &4A, &4B
 EQUB &4D, &55, &54, &4C, &4D, &4A, &52, &55
 EQUB &4D, &4A, &4C, &54, &53, &4B, &4C, &53
 EQUB &54, &55, &52, &53, &51, &53, &52, &50
 EQUB &51, &4E, &50, &52, &4A, &4E, &4B, &53
 EQUB &51, &4F, &4B, &4F, &51, &50, &4E, &4F

.L54A0

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &7E, &7B, &79, &7C, &7E, &7B, &79, &7C
 EQUB &B2, &B9, &B2, &A4, &A7, &A8, &A3, &9A
 EQUB &9C, &A5, &9F, &99, &97, &AC, &9E, &9A
 EQUB &A2, &9A, &A1, &9D, &9F, &A3, &00, &00

.L5500

L5501 = L5500+1

 EQUB &01, &01, &02, &02, &03, &03, &04, &04
 EQUB &05, &05, &06, &06, &07, &07, &08, &08
 EQUB &09, &09, &0A, &0A, &0B, &0B, &0C, &0C
 EQUB &0C, &0D, &0D, &0E, &0E, &0F, &0F, &0F

.L5520

L5521 = L5520+1

 EQUB &01, &01, &02, &02, &03, &03, &04, &04
 EQUB &05, &05, &06, &06, &07, &07, &08, &08
 EQUB &09, &09, &0A, &0A, &0A, &0B, &0B, &0C
 EQUB &0C, &0D, &0D, &0E, &0E, &0E, &0F, &0F
 EQUB &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D
 EQUB &14, &15, &14, &12, &12, &13, &12, &11
 EQUB &11, &12, &11, &11, &10, &13, &11, &11
 EQUB &12, &11, &12, &11, &11, &12, &FF, &FF

.C5560

 STA L007E
 STA L008A
 STA L008B
 RTS

.sub_C5567

 LDA L0085
 CMP L0083
 BCC C5575
 BNE C5588
 LDA L0082
 CMP L0080
 BCS C5588

.C5575

 LDA L0085
 STA L005D
 LDA L0082
 STA L005C
 LDA L0080
 STA L007A
 LDA L0083
 STA L007B
 JMP C55A5

.C5588

 LDA L0083
 STA L005D
 LDA L0080
 STA L005C
 LDA L0082
 STA L007A
 LDA L0085
 STA L007B
 ORA L0082
 BEQ C5560
 LDA L0085
 JMP C55E3

.loop_C55A1

 ASL L0082
 ROL L0085

.C55A5

 ASL L0080
 ROL A
 BCC loop_C55A1
 ROR A
 ROR L0080
 STA L0076
 LDA L0082
 STA L0074
 LDA L0080
 AND #&FC
 STA L0077
 LDA L0085
 JSR sub_C0D4A
 LDA L0086
 EOR L0088
 BMI C55D1
 LDA #&00
 SEC
 SBC L008A
 STA L008A
 LDA #&00
 SBC L008B
 STA L008B

.C55D1

 LDA #&40
 BIT L0086
 BPL C55D9
 LDA #&C0

.C55D9

 CLC
 ADC L008B
 STA L008B
 RTS

.loop_C55DF

 ASL L0080
 ROL L0083

.C55E3

 ASL L0082
 ROL A
 BCC loop_C55DF
 ROR A
 ROR L0082
 STA L0076
 LDA L0080
 STA L0074
 LDA L0082
 AND #&FC
 STA L0077
 LDA L0083
 JSR sub_C0D4A
 LDA L0086
 EOR L0088
 BPL C560F
 LDA #&00
 SEC
 SBC L008A
 STA L008A
 LDA #&00
 SBC L008B
 STA L008B

.C560F

 LDA #&00
 BIT L0088
 BPL C5617
 LDA #&80

.C5617

 CLC
 ADC L008B
 STA L008B
 RTS

.sub_C561D

 STA L0086
 TAY
 BPL C562D
 LDA #&00
 SEC
 SBC L0080
 STA L0080
 LDA #&00
 SBC L0086

.C562D

 STA L0083
 LDA L007C
 STA L0082
 LDA L007D
 STA L0085
 LDA #&00
 STA L0088
 JSR sub_C5567
 LDA L008A
 SEC
 SBC #&20
 STA L0050
 LDA L008B
 SBC L0140,X
 PHP
 LSR A
 ROR L0050
 LSR A
 ROR L0050
 LSR A
 ROR L0050
 LSR A
 ROR L0050
 PLP
 BPL C565C
 ORA #&F0

.C565C

 STA L008D
 RTS

.sub_C565F

 STY L568D
 LDA L007E
 LSR A
 ADC #&00
 TAY
 LDA L3D02,Y
 STA L0075
 LDA L005C
 STA L0074
 LDA L005D
 STA L0076
 JSR sub_C0F4A
 LSR L0075
 ROR L0074
 LDA L0074
 CLC
 ADC L007A
 STA L007C
 LDA L0075
 ADC L007B
 STA L007D
 LDY L568D
 RTS

.L568D

 EQUB &41

.sub_C568E

 LDA L56CF
 STA L56D2
 LDA L56D0
 STA L56D3
 LDA L56D1
 STA L56D4
 ASL L56D2
 ROL L56D3
 ROL L56D4
 ASL L56D2
 ROL L56D3
 ROL L56D4
 LDA L56CF
 CLC
 ADC L56D2
 STA L56CF
 LDA L56D0
 ADC L56D3
 STA L56D0
 LDA L56D1
 ADC L56D4
 STA L56D1
 RTS

.L56CF

 EQUB &01

.L56D0

 EQUB &00

.L56D1

 EQUB &00

.L56D2

 EQUB &01

.L56D3

 EQUB &00

.L56D4

 EQUB &00

.sub_C56D5

 LDA #&80
 BNE C56DB

.sub_C56D9

 LDA #&00

.C56DB

 STA L572F
 LDA #&50
 STA L572E

.C56E3

 JSR sub_C568E
 STA L0022
 LDA L56D0
 STA L002A
 AND #&1F
 CMP #&1E
 BCS C56E3
 STA L0023
 LDA L0CC2
 CLC
 ADC L0022
 STA L0022
 LDA L0CC3
 ADC L0023
 CMP #&80
 BCC C5708
 SBC #&20

.C5708

 STA L0023
 LDA L002A
 ROL A
 ROL A
 ROL A
 AND #&03
 TAX
 LDY #&00
 LDA L227F,X
 EOR #&FF
 AND (L0022),Y
 ORA L5730,X
 BIT L572F
 BPL C5726
 EOR L227F,X

.C5726

 STA (L0022),Y
 DEC L572E
 BNE C56E3
 RTS

.L572E

 EQUB &00

.L572F

 EQUB &00

.L5730

 EQUB &08, &04, &02, &01

.sub_C5734

 STA L0C04
 LDX #&28

.C5739

 DEY
 BNE C5739
 DEX
 BNE C5739
 RTS

 EQUB &FF, &FF, &FF, &FF

.C5744

 BIT L0C0F
 BMI C5767
 CMP #&20
 BCC C5767
 CMP #&7F
 BCS C5767
 STA L5796
 STA L57A1
 TXA
 PHA
 LDX #&16

.loop_C575B

 LDA L5796,X
 JSR OSWRCH
 DEX
 BPL loop_C575B
 PLA
 TAX
 RTS

.C5767

 JMP OSWRCH

.C576A

 CMP #&19
 BEQ C5775
 JMP C5744

.loop_C5771

 INY
 LDA L5796,Y

.C5775

 JSR OSWRCH
 DEC L5783
 BNE loop_C5771
 LDA #&06
 STA L5783
 RTS

.L5783

L5784 = L5783+1
L5796 = L5783+19
L5797 = L5783+20
L57A1 = L5783+30
L57A2 = L5783+31

 EQUB &06, &17, &1D, &30, &39, &4E, &57, &5D
 EQUB &60, &67, &6E, &75, &7A, &7F, &86, &90
 EQUB &A2, &A8, &AC, &43, &02, &00, &12, &00
 EQUB &04, &00, &00, &00, &19, &08, &43, &03
 EQUB &00, &12, &FF, &FC, &00, &00, &00, &19
 EQUB &7F, &20, &D2, &D4, &D9, &11, &81, &FF
 EQUB &D4, &D7, &D7, &D8, &CF, &D5, &20, &4E
 EQUB &55, &4D, &42, &45, &52, &3F, &04, &1F
 EQUB &05, &1B, &FF, &D2, &CF, &D6, &3F, &04
 EQUB &1F, &03, &1B, &FF, &D2, &CF, &57, &52
 EQUB &4F, &4E, &47, &20, &53, &45, &43, &52
 EQUB &45, &54, &20, &43, &4F, &44, &45, &C8
 EQUB &FF, &D3, &D1, &D9, &CF, &09, &09, &D5
 EQUB &09, &FF, &CF, &D6, &D0, &D5, &09, &FF
 EQUB &D4, &D9, &FF, &19, &04, &40, &00, &00
 EQUB &03, &FF, &19, &04, &C0

.L5800

 EQUB &00, &C0, &02, &FF, &19, &04, &C0, &00
 EQUB &40, &00, &FF, &05, &12, &00, &80, &FF
 EQUB &05, &12, &00, &81, &FF, &19, &04, &40
 EQUB &00, &A0, &00, &FF
 EQUS "LANDSCAPE"
 EQUB &FF
 EQUS "SECRET ENTRY CODE"
 EQUB &FF
 EQUS "     "
 EQUB &FF
 EQUS "   "
 EQUB &FF
 EQUS "PRESS ANY KEY"
 EQUB &FF

.L5850

 EQUB &C8, &08, &24, &CE, &24, &C8, &14, &30
 EQUB &CE, &30, &C8, &1C, &38, &CE, &38, &C8
 EQUB &00, &1C, &CE, &1C, &C8, &08, &24, &24
 EQUB &FF, &C8, &08, &24, &CE, &24, &C8, &14
 EQUB &30, &CE, &30, &C8, &10, &2C, &CE, &2C
 EQUB &C8, &00, &1C, &CE, &1C, &C8, &08, &24
 EQUB &24, &FF, &CC, &08, &24, &40, &44, &D7
 EQUB &54, &C9, &68, &54, &44, &40, &24, &D4
 EQUB &08, &FF, &C9, &08, &24, &D4, &24, &C9
 EQUB &00, &1C, &CD, &1C, &C9, &1C, &38, &CE
 EQUB &38, &C9, &14, &30, &CF, &30, &C9, &10
 EQUB &1C, &D1, &1C, &C9, &08, &24, &24, &FF

.L58B0

 EQUB &0F, &0F, &0F, &0F, &0F, &0F, &0F, &0F
 EQUB &6F, &0F, &00, &06, &09, &09, &0F, &0F
 EQUB &2F, &2F, &7A, &7A, &FA, &2D, &0F, &0F
 EQUB &0F, &0F, &0F, &0F, &8F, &0F, &0F, &0F
 EQUB &0F, &0F, &78, &D2, &87, &87, &0F, &0F
 EQUB &0F, &0F, &0F, &87, &87, &87, &0F, &0F
 EQUB &6F, &0F, &FF, &9F, &6F, &6F, &0F, &0F
 EQUB &1E, &1E, &1E, &1E, &1E, &1E, &0F, &0F
 EQUB &F0, &0F, &0F, &0F, &0F, &F0, &0F, &0F
 EQUB &87, &87, &87, &87, &87, &87, &0F, &0F

.L5900

L5904 = L5900+4
L590C = L5900+12
L5910 = L5900+16
L5912 = L5900+18
L5914 = L5900+20
L591C = L5900+28
L5928 = L5900+40
L5951 = L5900+81
L595F = L5900+95

 EQUB &10, &00, &01, &00, &07, &00, &05, &00
 EQUB &11, &00, &00, &00, &78, &00, &0A, &00
 EQUB &12, &00, &03, &00, &22, &00, &14, &00
 EQUB &13, &00, &04, &00, &90, &00, &14, &00
 EQUB &10, &00, &02, &00, &04, &00, &28, &00
 EQUB &01, &02, &00, &00, &00, &00, &00, &00
 EQUB &14, &00, &EC, &EC, &78, &78, &02, &04
 EQUB &00, &00, &00, &00, &00, &00, &02, &FF
 EQUB &00, &00, &78, &78, &04, &02, &01, &FF
 EQUB &00, &01, &01, &08, &78, &FF, &00, &FF
 EQUB &78, &08, &03, &01, &06, &FA, &00, &01
 EQUB &01, &00, &01, &FF, &00, &00, &78, &08
 EQUB &04, &82, &01, &FF, &00, &02, &01, &07
 EQUB &78, &FA, &FE, &FE, &78, &00, &01, &01
 EQUB &00, &00, &00, &00, &00, &00, &78, &88
 EQUB &FF, &FF, &78, &00, &00, &00, &00, &00

.L5980

 EQUB &00, &03, &06, &09, &0D, &10, &13, &16
 EQUB &19, &1C, &1F, &22, &26, &29, &2C, &2F
 EQUB &32, &35, &38, &3B, &3E, &41, &44, &47
 EQUB &4A, &4D, &50, &53, &56, &59, &5C, &5F
 EQUB &62, &65, &68, &6B, &6D, &70, &73, &76
 EQUB &79, &7B, &7E, &81, &84, &86, &89, &8C
 EQUB &8E, &91, &93, &96, &98, &9B, &9D, &A0
 EQUB &A2, &A5, &A7, &AA, &AC, &AE, &B1, &B3
 EQUB &B5, &B7, &B9, &BC, &BE, &C0, &C2, &C4
 EQUB &C6, &C8, &CA, &CC, &CE, &CF, &D1, &D3
 EQUB &D5, &D7, &D8, &DA, &DC, &DD, &DF, &E0
 EQUB &E2, &E3, &E5, &E6, &E7, &E9, &EA, &EB
 EQUB &ED, &EE, &EF, &F0, &F1, &F2, &F3, &F4
 EQUB &F5, &F6, &F7, &F8, &F8, &F9, &FA, &FA
 EQUB &FB, &FC, &FC, &FD, &FD, &FE, &FE, &FE
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.Noise2

L5A01 = Noise2+1
L5A02 = Noise2+2
L5A03 = Noise2+3
L5A2E = Noise2+46
L5A40 = Noise2+64

 EQUB &44, &58, &20, &45, &54, &45, &4D, &0D
 EQUB &14, &3C, &05, &20, &0D, &14, &46, &23
 EQUB &20, &20, &20, &20, &20, &20, &54, &59
 EQUB &41, &3A, &4A, &53, &52, &20, &45, &4D
 EQUB &49, &52, &54, &45, &53, &54, &3A, &42
 EQUB &43, &43, &20, &6D, &65, &61, &32, &0D
 EQUB &14, &50, &05, &20, &0D, &14, &5A, &1A
 EQUB &20, &20, &20, &20, &20, &20, &54, &59
 EQUB &41, &3A, &53, &54, &41, &20, &4D, &45
 EQUB &41, &4E, &59, &2C, &58, &20, &0D, &14
 EQUB &64, &05, &20, &0D, &14, &6E, &1C, &20
 EQUB &20, &20, &20, &20, &20, &4C, &44, &41
 EQUB &23, &34, &3A, &53, &54, &41, &20, &4F
 EQUB &42, &54, &59, &50, &45, &2C, &59, &0D
 EQUB &14, &78, &23, &20, &20, &20, &20, &20
 EQUB &20, &4C, &44, &41, &23, &31, &30, &34
 EQUB &3A, &53, &54, &41, &20, &4F, &42, &48
 EQUB &41, &4C, &46, &53, &49, &5A, &45, &4D
 EQUB &49, &4E, &0D, &14, &82, &11, &20, &20
 EQUB &20, &20, &20, &20, &43, &4C, &43, &3A
 EQUB &72, &74, &73, &0D, &14, &83, &05, &20
 EQUB &0D, &14, &84, &21, &2E, &6D, &65, &61
 EQUB &32, &20, &49, &4E, &43, &20, &4D, &54
 EQUB &52, &59, &43, &4E, &54, &2C, &58, &3A
 EQUB &4A, &4D, &50, &20, &45, &45, &58, &49
 EQUB &54, &0D, &14, &85, &05, &20, &0D, &14
 EQUB &8C, &05, &20, &0D, &14, &96, &26, &2E
 EQUB &74, &61, &6B, &35, &20, &4C, &44, &41
 EQUB &23, &31, &32, &38, &3A, &53, &54, &41
 EQUB &20, &54, &48, &45, &45, &4E, &44, &3A
 EQUB &4A, &4D, &50, &20, &45, &45, &58, &49
 EQUB &54, &0D, &14, &A0, &05, &20, &0D, &14

.Noise3

L5B07 = Noise3+7
L5B08 = Noise3+8
L5B09 = Noise3+9
L5B0F = Noise3+15
L5B10 = Noise3+16
L5B11 = Noise3+17
L5B17 = Noise3+23
L5B18 = Noise3+24
L5B19 = Noise3+25
L5B60 = Noise3+96
L5B9E = Noise3+158
L5B9F = Noise3+159
L5BA0 = Noise3+160

 EQUB &AA, &14, &2E, &54, &41, &4B, &45, &20
 EQUB &4C, &44, &58, &20, &50, &45, &52, &53
 EQUB &4F, &4E, &0D, &14, &B4, &22, &20, &20
 EQUB &20, &20, &20, &20, &43, &50, &58, &20
 EQUB &50, &4C, &41, &59, &45, &52, &49, &4E
 EQUB &44, &45, &58, &3A, &42, &4E, &45, &20
 EQUB &74, &61, &6B, &31, &0D, &14, &BE, &1D
 EQUB &20, &20, &20, &20, &20, &20, &4C, &44
 EQUB &41, &20, &45, &4E, &45, &52, &47, &59
 EQUB &3A, &42, &45, &51, &20, &74, &61, &6B
 EQUB &35, &0D, &14, &C8, &1E, &20, &20, &20
 EQUB &20, &20, &20, &53, &45, &43, &3A, &53
 EQUB &42, &43, &23, &31, &3A, &53, &54, &41
 EQUB &20, &45, &4E, &45, &52, &47, &59, &0D
 EQUB &14, &D2, &12, &20, &20, &20, &20, &20
 EQUB &20, &4A, &53, &52, &20, &45, &44, &49
 EQUB &53, &0D, &14, &DC, &18, &20, &20, &20
 EQUB &20, &20, &20, &4C, &44, &41, &23, &35
 EQUB &3A, &4A, &53, &52, &20, &56, &49, &50
 EQUB &4F, &0D, &14, &E6, &16, &20, &20, &20
 EQUB &20, &20, &20, &53, &45, &43, &3A, &4A
 EQUB &4D, &50, &20, &74, &61, &6B, &33, &0D
 EQUB &14, &F0, &05, &20, &0D, &14, &FA, &05
 EQUB &20, &0D, &15, &04, &18, &2E, &74, &61
 EQUB &6B, &31, &20, &54, &58, &41, &3A, &4A
 EQUB &53, &52, &20, &45, &4D, &49, &52, &50
 EQUB &54, &0D, &15, &0E, &05, &20, &0D, &15
 EQUB &18, &1F, &20, &20, &20, &20, &20, &20
 EQUB &4C, &44, &41, &20, &4F, &42, &54, &59
 EQUB &50, &45, &2C, &58, &3A, &42, &4E, &45
 EQUB &20, &74, &61, &6B, &34, &0D, &15, &22
 EQUB &05, &20, &0D, &15, &2C, &1E, &20, &5C

.sub_C5C00

 RTS

.sub_C5C01

 STY L006F
 LDA L0A40,Y
 STA L004C
 LDX L006E
 JSR sub_C5DC4
 JSR sub_C5DF5
 JSR sub_C5567
 LDX L006E
 LDA L008A
 SEC
 SBC L001F
 STA L0C59
 LDA L008B
 SBC L09C0,X
 CLC
 ADC #&0A
 STA L0C57
 LDY L006F
 LDA #&00
 SEC
 SBC L008A
 STA L0059
 LDA L09C0,Y
 SBC L008B
 STA L005A
 JSR sub_C565F
 LDA L140F
 BNE C5C60
 LDA #&80
 STA L005A
 LDA #&00
 STA L0059
 CPY #&3F
 BEQ C5C60
 LSR L007D
 ROR L007C
 SEC
 ROR L0084
 ROR L0081
 LDA L0081
 CLC
 ADC #&70
 STA L0081
 BCC C5C60
 INC L0084

.C5C60

 LDA L007C
 STA L0C5D
 LDA L007D
 STA L0C5E
 LDA L0081
 STA L0C5B
 LDA L0084
 STA L0C5C
 RTS

.sub_C5C75

 LDX L004C
 LDA #&40
 STA L0021
 LDA L49A1,X
 STA L004F
 LDY L49A0,X
 STY L004E

.C5C85

 LDA L0059
 STA L0074
 LDA L005A
 CLC
 ADC L4AE0,Y
 JSR sub_C0F70
 LDY L004E
 LDA L4D60,Y
 STA L0075
 LDA L008F
 JSR sub_C0D03
 STA L0074
 LDA #&00
 BIT L0067
 BVC C5CA9
 JSR sub_C1009

.C5CA9

 STA L0075
 LDA L0C5D
 CLC
 ADC L0074
 STA L0082
 LDA L0C5E
 ADC L0075
 STA L0088
 BPL C5CC7
 LDA #&00
 SEC
 SBC L0082
 STA L0082
 LDA #&00
 SBC L0088

.C5CC7

 STA L0085
 LDA L4D60,Y
 STA L0075
 LDA L008E
 JSR sub_C0D03
 STA L0080
 LDA #&00
 STA L0083
 LDA L0067
 STA L0086
 JSR sub_C5567
 LDY L0021
 LDA L008A
 CLC
 ADC L0C59
 STA L0BA0,Y
 LDA L008B
 ADC L0C57
 STA L5500,Y
 JSR sub_C565F
 LDY L004E
 LDA L4C20,Y
 ASL A
 STA L0074
 LDA #&00
 BCC C5D05
 JSR sub_C1009

.C5D05

 STA L0075
 LDA L0074
 CLC
 ADC L0C5B
 STA L0080
 LDA L0075
 ADC L0C5C
 LDX L006E
 JSR sub_C561D
 LDY L0021
 LDA L008D
 STA L0AE0,Y
 LDA L0050
 STA L0A80,Y
 INC L004E
 INC L0021
 LDY L004E
 CPY L004F
 BEQ return_39
 JMP C5C85

.return_39

 RTS

.sub_C5D33

 JSR sub_C5C01
 LDA L007D
 CMP #&0F
 ROR L0C7A
 JSR sub_C5C75
 LDA #&40
 STA L003B
 LDA #&00
 STA L0053
 STA L0C47
 LDX L004C
 LDA L49B6,X
 BEQ C5D6F
 LSR A
 BCS C5D5C
 LDA L005A
 ADC #&C0
 JMP C5D69

.C5D5C

 LDA L0C5C
 BNE C5D67
 LDA L0C5B
 BEQ C5D6F
 LSR A

.C5D67

 EOR #&80

.C5D69

 BPL C5D6F
 LDA #&02
 STA L0053

.C5D6F

 LDX L004C
 LDA L49AC,X
 STA L004F
 LDY L49AB,X

.C5D79

 STY L004E
 LDA L4EA0,Y
 LDX L0053
 BEQ C5D87
 EOR L0C47
 BMI C5DA4

.C5D87

 AND #&3C
 STA L0019
 LDA L4EA0,Y
 AND #&03
 CLC
 ADC #&03
 STA L0017
 LDA L4FE0,Y
 STA L003C
 LDA L5120,Y
 STA L003D
 JSR C2A79
 LDY L004E

.C5DA4

 INY
 CPY L004F
 BCC C5D79
 DEC L0053
 BMI C5DB6
 BEQ C5DB6
 LDA #&80
 STA L0C47
 BMI C5D6F

.C5DB6

 LDA #&40
 STA L003C
 LDA #&0C
 STA L003D
 LSR L0C7A
 LDY L006F
 RTS

.sub_C5DC4

 LDA #&00
 STA L0080
 SEC
 LDA L0900,Y
 SBC L0900,X
 SEC
 SBC L0C78
 STA L0086
 BPL C5DDC
 SEC
 LDA #&00
 SBC L0086

.C5DDC

 STA L0083
 LDA #&00
 STA L0082
 SEC
 LDA L0980,Y
 SBC L0980,X
 STA L0088
 BPL C5DF2
 SEC
 LDA #&00
 SBC L0088

.C5DF2

 STA L0085
 RTS

.sub_C5DF5

 LDA L0A00,Y
 SEC
 SBC L0A00,X
 STA L0081
 LDA L0940,Y
 SBC L0940,X
 STA L0084
 RTS

.sub_C5E07

 JSR sub_C5E20

.C5E0A

 JSR OSRDCH
 BCC return_40
 CMP #&1B
 BNE return_40
 TYA
 PHA
 LDA #126               \ osbyte_acknowledge_escape
 JSR OSBYTE
 PLA
 TAY
 JMP C5E0A

.return_40

 RTS

.sub_C5E20

 LDA #2                 \ osbyte_select_input_stream
 LDX #&00
 JSR OSBYTE
 LDX #&00
 JMP C3555

.sub_C5E2C

 STA L0074
 AND #&7F
 TAY
 LDA #&03
 STA L0075

.loop_C5E35

 LDX L0074
 BPL C5E3C
 LDX L5E57,Y

.C5E3C

 LDA #&13
 JSR OSWRCH
 LDA L0075
 JSR OSWRCH
 TXA
 LDX #&04

.loop_C5E49

 JSR OSWRCH
 LDA #&00
 DEX
 BNE loop_C5E49
 DEY
 DEC L0075
 BPL loop_C5E35
 RTS

.L5E57

L5E59 = L5E57+2
L5E5A = L5E57+3

 EQUB &04, &00, &06, &03, &04, &00, &01, &03

.sub_C5E5F

 LDA #&FF
 STA L0CD2
 LDA L0C69
 ASL A
 ASL A
 ASL A
 STA L0CD3
 SEC
 SBC #&01
 BEQ C5E7B
 LDY #&FF

.loop_C5E74

 ASL A
 INY
 BCC loop_C5E74
 LDA L15B4,Y

.C5E7B

 STA L0CCF

.C5E7E

 SEI
 JSR sub_C568E
 LDY L56D0
 STY L0CD0
 CLI
 CLC
 ADC L0CCD
 AND L0CCF
 CMP L0CD3
 BCC C5E98
 SBC L0CD3

.C5E98

 STA L0CCD
 LDA L0CD0
 AND #&1F
 STA L0013
 LSR A
 CLC
 ADC L0013
 AND #&FE
 STA L0013
 ASL A
 ASL A
 ADC L0013
 STA L0013
 LDA #&00
 LSR L0013
 ROR A
 LSR L0013
 ROR A
 LSR L0013
 ROR A
 ADC L0CCD
 STA L0062
 LDA L0013
 ADC #&00
 STA L0063
 LDA L2092
 CLC
 ADC L0062
 STA L0064
 LDA L2093
 ADC L0063
 CMP #&80
 BCC C5ED9
 SBC #&20

.C5ED9

 STA L0065
 LDA L0063
 CLC
 ADC #&3F
 STA L0063
 CMP #&53
 BCC C5EF3
 LDA L0062
 SEC
 SBC #&60
 STA L0062
 LDA L0063
 SBC #&13
 STA L0063

.C5EF3

 LDA L0CD0
 ASL A
 ROL A
 ROL A
 AND #&03
 TAX
 LDY #&00
 LDA (L0062),Y
 AND L227F,X
 STA L0013
 LDA (L0064),Y
 AND L36BF,X
 ORA L0013
 STA (L0064),Y
 BIT L0C1E
 BMI return_41
 DEC L0CD2
 BNE C5F20
 JSR sub_C355A
 DEC L2094
 BEQ return_41

.C5F20

 JMP C5E7E

.return_41

 RTS

.sub_C5F24

 PHA
 JSR sub_C3548
 JSR sub_C3699
 LDA #&06
 STA L0C73
 LDA #&FA
 STA L0C74
 PLA
 JSR sub_C5F68
 LDY #&00
 STY L0CC9
 STY L0C5F
 LDA L0C1C
 JSR sub_C5F80
 LDA #&03
 STA L0C4C
 LDA #&01
 STA L0001
 LDA #&C0
 STA L0C4D
 STA L0C6D
 LSR L0C1E
 LDA #&32
 JSR sub_C5FF6
 JSR sub_C1F84
 LDA #&1E
 JMP sub_C5F68

.sub_C5F68

 STA L001E

.loop_C5F6A

 LDA #&1E
 STA L0015

.loop_C5F6E

 JSR sub_C56D9
 JSR sub_C355A
 DEC L0015
 BNE loop_C5F6E
 DEC L001E
 BNE loop_C5F6A
 RTS

.sub_C5F7D

 JMP C3F30

.sub_C5F80

 STA L0A41
 LDA L5FBC,Y
 CLC
 ADC L0982
 STA L0981
 LDA L0942
 CLC
 ADC L5FDC,Y
 STA L0941
 LDA L0902
 STA L0901
 LDA L5FD9,Y
 STA L0142
 LDA L5FE2,Y
 STA L09C2
 LDA #&00
 STA L0A02
 STA L0A01
 LDA L5FDF,Y
 STA L09C1
 LDX #&02
 STX L006E
 RTS

.L5FBC

 EQUB &05, &07, &07

.sub_C5FBF

 JSR sub_C1410
 LDX #&03
 LDY #&00
 LDA #&80
 JSR sub_C139B
 LDX #&04
 JSR sub_C36AD
 JSR C33AB
 JSR sub_C1440
 JMP C1074

.L5FD9

L5FDC = L5FD9+3
L5FDF = L5FD9+6
L5FE2 = L5FD9+9

 EQUB &F4, &FB, &FB, &00, &01, &00, &80, &8E
 EQUB &CE, &00, &F8, &F8

.sub_C5FE5

 LDY #&01
 JSR sub_C5FEE
 LDY #&02
 LDA #&06

.sub_C5FEE

 JSR sub_C5F80
 LDY #&01
 JMP sub_C5D33

.sub_C5FF6

 STA L0CE7
 LDA #&03
 STA L0C73
 RTS

 EQUB &23, &FE, &FE, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &FF, &FF, &FF, &FF, &FF, &7F, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &10, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &00, &1D, &33, &44, &4C, &5E, &7C
 EQUB &88, &90, &98, &A0, &00, &1B, &34, &43
 EQUB &4D, &66, &89, &94, &98, &9C, &A0, &03
 EQUB &03, &00, &00, &02, &03, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &47, &4C
 EQUB &4B, &46, &47, &40, &45, &42, &40, &41
 EQUB &44, &40, &41, &40, &44, &43, &40, &40
 EQUB &43, &45, &40, &42, &45, &44, &41, &42
 EQUB &45, &46, &49, &45, &44, &48, &47, &44
 EQUB &45, &49, &48, &44, &45, &43, &46, &45
 EQUB &43, &44, &47, &43, &44, &43, &47, &46
 EQUB &43

 ORG &6D00

.Entry

 LDA #&00
 STA P
 STA R
 LDA #&19
 STA Q
 LDA #&04
 STA S

.loop_C6D0E

 LDY #&00

.loop_C6D10

 LDA (P),Y
 STA (R),Y
 INY
 BNE loop_C6D10
 INC Q
 INC S
 LDA Q
 CMP #&6D
 BNE loop_C6D0E
 JMP Begin

\ ******************************************************************************
\
\ Save Sentinel.bin
\
\ ******************************************************************************

\SAVE "3-assembled-output/TheSentinel.bin", CODE%, P%

                              \ Game addr to file addr
COPYBLOCK &5800, &6100, &4100 \ 5800-60FF to 4100-49FF
COPYBLOCK &0400, &5800, &1900 \ 0400-57FF to 1900-6CFF

SAVE "3-assembled-output/TheSentinel.bin", &1900, &6D24
