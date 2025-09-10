\ ******************************************************************************
\
\ THE SENTINEL SOURCE
\
\ The Sentinel was written by Geof Crammond and is copyright Firebird 1985
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

 BRKIV = &0287          \ The Break Intercept code (which is a JMP instruction
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

 ORG &0000              \ Set the assembly address to &0000

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
secondAxis           = &0060
L0061                = &0061
L0062                = &0062
L0063                = &0063
L0064                = &0064
L0065                = &0065
L0066                = &0066
H                    = &0067
RR                   = &0068
SS                   = &0069
PP                   = &006A
QQ                   = &006B
L006C                = &006C
L006D                = &006D
L006E                = &006E
L006F                = &006F
P                    = &0070
Q                    = &0071
R                    = &0072
S                    = &0073
T                    = &0074
U                    = &0075
V                    = &0076
W                    = &0077
G                    = &0078
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

\ ******************************************************************************
\
\       Name: L0400
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L0900
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L0A00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L0B00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L0C00
\       Type: Workspace
\    Address: ??? to ???
\   Category: Workspaces
\    Summary: ???
\
\ ******************************************************************************

.sinYawAngleLo

 EQUB &00

.cosYawAngleLo

 EQUB &00

.sinYawAngleHi

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

.J

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

.G2

 EQUB &00

.H2

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

\ ******************************************************************************
\
\       Name: NMI
\       Type: Subroutine
\   Category: Setup
\    Summary: The NMI handler at the start of the NMI workspace
\
\ ******************************************************************************

.NMI

 RTI                    \ This is the address of the current NMI handler, at
                        \ the start of the NMI workspace at address &0D00
                        \
                        \ We put an RTI instruction here to make sure we return
                        \ successfully from any NMIs that call this workspace

\ ******************************************************************************
\
\       Name: irq1Address
\       Type: Variable
\   Category: ???
\    Summary: Stores the previous value of IRQ1V before we install our custom
\             IRQ handler
\
\ ******************************************************************************

.irq1Address

 EQUW &DC93             \ This value is workspace noise and has no meaning

\ ******************************************************************************
\
\       Name: Multiply8x8
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A T) = T * U
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers:
\
\   (A T) = A * U
\
\ This routine is from Revs, Geoff Crammond's previous game.
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X is unchanged
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   Multiply8x8+2       Calculate (A T) = T * U
\
\ ******************************************************************************

.Multiply8x8

 STA T                  \ Set T = A

                        \ We now calculate (A T) = T * U
                        \                        = A * U

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LSR T                  \ Set T = T >> 1
                        \ and C flag = bit 0 of T

                        \ We are now going to work our way through the bits of
                        \ T, and do a shift-add for any bits that are set,
                        \ keeping the running total in A, and instead of using a
                        \ loop, we unroll the calculation, starting with bit 0

 BCC P%+5               \ If C (i.e. the next bit from T) is set, do the
 CLC                    \ addition for this bit of T:
 ADC U                  \
                        \   A = A + U

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of T while
                        \ also extracting the next bit of T

 ROR T                  \ Add the overspill from shifting A to the right onto
                        \ the start of T, and shift T right to fetch the next
                        \ bit for the calculation into the C flag

 BCC P%+5               \ Repeat the shift-and-add loop for bit 1
 CLC
 ADC U
 ROR A
 ROR T

 BCC P%+5               \ Repeat the shift-and-add loop for bit 2
 CLC
 ADC U
 ROR A
 ROR T

 BCC P%+5               \ Repeat the shift-and-add loop for bit 3
 CLC
 ADC U
 ROR A
 ROR T

 BCC P%+5               \ Repeat the shift-and-add loop for bit 4
 CLC
 ADC U
 ROR A
 ROR T

 BCC P%+5               \ Repeat the shift-and-add loop for bit 5
 CLC
 ADC U
 ROR A
 ROR T

 BCC P%+5               \ Repeat the shift-and-add loop for bit 6
 CLC
 ADC U
 ROR A
 ROR T

 BCC P%+5               \ Repeat the shift-and-add loop for bit 7
 CLC
 ADC U
 ROR A
 ROR T

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: sub_C0D4A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ The first part of this routine is based on the Divide16x16 routine in Revs,
\ Geoff Crammond's previous game, except it supports a divisor (V W) instead of
\ (V 0), though only the top three bits of W are included in the calculation.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               Unsigned integer
\
\   (V W)               Unsigned integer
\
\ ******************************************************************************

.sub_C0D4A

                        \ We start by calculating the following using a similar
                        \ shift-and-subtract algorithm as Revs:
                        \
                        \   T = 256 * (A T) / (V W)
                        \
                        \ In Revs, W is assumed to be zero, so there is some
                        \ extra code below to cater for non-zero values of W

 ASL T                  \ Shift T left, which clears bit 0 of T, ready for us to
                        \ start building the result in T at the same time as we
                        \ shift the low byte of (A T) out to the left

                        \ We now repeat the following seven-instruction block
                        \ eight times, one for each bit in T

 ROL A                  \ Shift the high byte of (A T) to the left to extract
                        \ the next bit from the number being divided

 BCS divd1              \ If we just shifted a 1 out of A, skip the next few
                        \ instructions and jump straight to the subtraction

 CMP V                  \ If A < V then jump to divd2 with the C flag clear, so
 BCC divd2              \ we shift a 0 into the result in T

                        \ This part of the routine has been added to the Revs
                        \ algorithm to cater for W potentially being non-zero

 BNE divd1              \ If A > V then jump to divd2 with the C flag set, so
                        \ we shift a 1 into the result in T

                        \ If we get here then A = V

 LDY T                  \ If T < W then jump to divd2 with the C flag clear, so
 CPY W                  \ we shift a 0 into the result in T
 BCC divd2

.divd1

                        \ If we get here then T >= W

 STA U
 LDA T
 SBC W
 STA T
 LDA U

 SBC V                  \ A >= V, so set A = A - V and set the C flag so we
 SEC                    \ shift a 1 into the result in T

.divd2

 ROL T                  \ Shift the result in T to the left, pulling the C flag
                        \ into bit 0

 ROL A                  \ Repeat the shift-and-subtract loop for bit 1
 BCS divd3
 CMP V
 BCC divd4
 BNE divd3
 LDY T
 CPY W
 BCC divd4

.divd3

 STA U
 LDA T
 SBC W
 STA T
 LDA U
 SBC V
 SEC

.divd4

 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 2
 BCS divd5
 CMP V
 BCC divd6
 BNE divd5
 LDY T
 CPY W
 BCC divd6

.divd5

 STA U
 LDA T
 SBC W
 STA T
 LDA U
 SBC V
 SEC

.divd6

 PHP
 CMP V
 BEQ C0E10
 ASL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 3
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 4
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 5
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 6
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 7
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for bit 8
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC

 ROR G
 ROL A
 BCS C0DF8
 CMP V

.C0DF8

 ROR G

 LDA T

.C0DFC

 PLP
 BCC C0E01
 ADC #&1F

.C0E01

 BCC C0E1F
 LDA #&FF
 STA L007E
 LDA #0
 STA L008A
 LDA #&20
 STA L008B
 RTS

.C0E10

 LDA #0
 STA G
 ROR T
 ROR A
 ROR T
 ROR A
 ORA #&20
 JMP C0DFC

.C0E1F

 TAY
 STA L007E
 LDA arctanLo,Y
 STA L008A
 LDA arctanHi,Y
 STA L008B
 BIT G
 BMI C0E35
 BVS C0E50
 JMP CRE01

.C0E35

 LDA L008A
 SEC
 SBC arctanLo+1,Y
 STA T
 LDA L008B
 SBC arctanHi+1,Y
 BIT G
 BVC C0E49
 JSR Negate16Bit

.C0E49

 STA U
 ROL A
 ROR U
 ROR T

.C0E50

 LDA L008A
 CLC
 ADC arctanLo+1,Y
 STA L008A
 LDA L008B
 ADC arctanHi+1,Y
 STA L008B
 BIT G
 BPL C0E70
 LDA L008A
 CLC
 ADC T
 STA L008A
 LDA L008B
 ADC U
 STA L008B

.C0E70

 LSR L008B
 ROR L008A

.CRE01

 RTS

\ ******************************************************************************
\
\       Name: GetRotationMatrix (Part 1 of 5)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the rotation matrix for rotating the player's yaw angle
\             into the global 3D coordinate system
\
\ ------------------------------------------------------------------------------
\
\ This routine calculates the following:
\
\   sinYawAngle = sin(playerYawAngle)
\   cosYawAngle = cos(playerYawAngle)
\
\ We can use these to create a rotation matrix that rotates the yaw angle from
\ the player's frame of reference into the global 3D coordinate system.
\
\ This routine is from Revs, Geoff Crammond's previous game. There are only
\ minor differences: the argument is (A T) instead of (A X), and the value of X
\ is preserved. Note that to avoid clashing names, the variables G and H have
\ been renamed to G2 and H2, but the routine is otherwise the same.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               Player yaw angle in (playerYawAngleHi playerYawAngleLo)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X is preserved
\
\ ******************************************************************************

.GetRotationMatrix

 STA J                  \ Set (J T) = (A T)
                        \           = playerYawAngle

 STX xStoreMatrix       \ Store X in xStoreMatrix so it can be preserved across
                        \ calls to the routine

 JSR GetAngleInRadians  \ Set (U A) to the playerYawAngle, reduced to a quarter
                        \ circle, converted to radians, and halved
                        \
                        \ Let's call this yawRadians / 2, where yawRadians is
                        \ the reduced player yaw angle in radians

 STA G2                 \ Set (U G) = (U A) = yawRadians / 2

 LDA U                  \ Set (A G) = (U G) = yawRadians / 2

 STA H2                 \ Set (H G) = (A G) = yawRadians / 2

                        \ So we now have:
                        \
                        \   (H G) = (A G) = (U G) = yawRadians / 2
                        \
                        \ This is the angle vector that we now project onto the
                        \ x- and z-axes of the world 3D coordinate system

 LDX #1                 \ Set X = 0 and secondAxis = 1, so we project sin(H G)
 STX secondAxis         \ into sinYawAngle and cos(H G) into cosYawAngle
 LDX #0

 BIT J                  \ If bit 6 of J is clear, then playerYawAngle is in one
 BVC rotm1              \ of these ranges:
                        \
                        \   * 0 to 63 (%00000000 to %00111111)
                        \
                        \   * -128 to -65 (%10000000 to %10111111)
                        \
                        \ The degree system in Revs looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of car
                        \         \  |  /
                        \          \ | /             0 = looking straight ahead
                        \           \|/              +64 = looking sharp right
                        \   -64 -----+----- +64      -64 = looking sharp left
                        \           /|\
                        \          / | \
                        \         /  |  \
                        \      -96   |   +96
                        \           128
                        \
                        \ So playerYawAngle is in the top-right or bottom-left
                        \ quarter in the above diagram
                        \
                        \ In both cases we jump to rotm1 to set sinYawAngle and
                        \ cosYawAngle

                        \ If we get here then bit 6 of J is set, so
                        \ playerYawAngle is in one of these ranges:
                        \
                        \   * 64 to 127 (%01000000 to %01111111)
                        \
                        \   * -64 to -1 (%11000000 to %11111111)
                        \
                        \ So playerYawAngle is in the bottom-right or top-left
                        \ quarter in the above diagram
                        \
                        \ In both cases we set the variables the other way
                        \ round, as the triangle we draw to calculate the angle
                        \ is the opposite way round (i.e. it's reflected in the
                        \ x-axis or y-axis)

 INX                    \ Set X = 1 and secondAxis = 0, so we project sin(H G)
 DEC secondAxis         \ into cosYawAngle and cos(H G) into sinYawAngle

                        \ We now enter a loop that sets sinYawAngle + X to
                        \ sin(H G) on the first iteration, and sets
                        \ sinYawAngle + secondAxis to cos(H G) on the second
                        \ iteration
                        \
                        \ The commentary is for the sin(H G) iteration, see the
                        \ end of the loop for details of how the second
                        \ iteration calculates cos(H G) instead

.rotm1

                        \ If we get here, then we are set up to calculate the
                        \ following:
                        \
                        \   * If playerYawAngle is top-right or bottom-left:
                        \
                        \     sinYawAngle = sin(playerYawAngle)
                        \     cosYawAngle = cos(playerYawAngle)
                        \
                        \   * If playerYawAngle is bottom-right or top-left:
                        \
                        \     sinYawAngle = cos(playerYawAngle)
                        \     cosYawAngle = sin(playerYawAngle)
                        \
                        \ In each case, the calculation gives us the correct
                        \ coordinate, as the second set of results uses angles
                        \ that are "reflected" in the x-axis or y-axis by the
                        \ capping process in the GetAngleInRadians routine

 CMP #122               \ If A < 122, i.e. U < 122 and H < 122, jump to rotm2
 BCC rotm2              \ to calculate sin(H G) for smaller angles

 BCS rotm3              \ Jump to rotm3 to calculate sin(H G) for larger angles
                        \ (this BCS is effectively a JMP as we just passed
                        \ through a BCS)

 LDA G2                 \ It doesn't look like this code is ever reached, so
 CMP #240               \ presumably it's left over from development
 BCS rotm3

\ ******************************************************************************
\
\       Name: GetRotationMatrix (Part 2 of 5)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate sin(H G) for smaller angles
\
\ ******************************************************************************

.rotm2

                        \ If we get here then (U G) = yawRadians / 2 and U < 122

 LDA #171               \ Set A = 171

 JSR Multiply8x8        \ Set (A T) = (A * U) * U
 JSR Multiply8x8        \           = A * U^2
                        \           = 171 * (yawRadians / 2)^2

 STA V                  \ Set (V T) = (A T)
                        \           = 171 * (yawRadians / 2)^2

 JSR Multiply8x16       \ Set (U T) = U * (V T) / 256
                        \           = (171 / 256) * (yawRadians / 2)^3
                        \           = 2/3 * (yawRadians / 2)^3

 LDA G2                 \ Set (A T) = (H G) - (U T)
 SEC                    \           = yawRadians / 2 - 2/3 * (yawRadians / 2)^3
 SBC T                  \
 STA T                  \ starting with the low bytes

 LDA H2                 \ And then the high bytes
 SBC U

 ASL T                  \ Set (A T) = (A T) * 2
 ROL A

                        \ So we now have the following in (A T):
                        \
                        \     (yawRadians / 2 - 2/3 * (yawRadians / 2)^3) * 2
                        \
                        \   = yawRadians - 4/3 * (yawRadians / 2)^3
                        \
                        \   = yawRadians - 4/3 * yawRadians^3 / 2^3
                        \
                        \   = yawRadians - 8/6 * yawRadians^3 * 1/8
                        \
                        \   = yawRadians - 1/6 * yawRadians^3
                        \
                        \   = yawRadians - yawRadians^3 / 3!
                        \
                        \ The Taylor series expansion of sin(x) starts like
                        \ this:
                        \
                        \   sin(x) = x - (x^3 / 3!) + (x^5 / 5!) - ...
                        \
                        \ If we take the first two parts of the series and
                        \ apply them to yawRadians, we get:
                        \
                        \   sin(yawRadians) = yawRadians - (yawRadians^3 / 3!)
                        \
                        \ which is the same as our value in (A T)
                        \
                        \ So the value in (A T) is equal to the first two parts
                        \ of the Taylor series, and we have effectively just
                        \ calculated an approximation of this:
                        \
                        \   (A T) = sin(yawRadians)

 STA sinYawAngleHi,X    \ Set (sinYawAngleHi sinYawAngleLo) = (A T)
 LDA T                  \
 AND #%11111110         \ with the sign bit cleared in bit 0 of sinYawAngleLo to
 STA sinYawAngleLo,X    \ denote a positive result

 JMP rotm5              \ Jump to rotm5 to move on to the next axis

\ ******************************************************************************
\
\       Name: GetRotationMatrix (Part 3 of 5)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate sin(H G) for bigger angles
\
\ ******************************************************************************

.rotm3

                        \ If we get here then (H G) = yawRadians / 2 and
                        \ H >= 122

                        \ PI is represented by 804, as 804 / 256 = 3.14, so 201
                        \ represents PI/4, which we use in the following
                        \ subtraction

 LDA #0                 \ Set (U T) = (201 0) - (H G)
 SEC                    \           = PI/4 - yawRadians / 2
 SBC G2                 \
 STA T                  \ starting with the low bytes

 LDA #201               \ And then the high bytes
 SBC H2
 STA U

 STA V                  \ Set (V T) = (U T)
                        \           = PI/4 - yawRadians / 2

 JSR Multiply8x16       \ Set (U T) = U * (V T) / 256
                        \           = U * (PI/4 - yawRadians / 2)
                        \
                        \ U is the high byte of (U T), which also contains
                        \ PI/4 - yawRadians / 2, so this approximation holds
                        \ true:
                        \
                        \   (U T) = U * (PI/4 - yawRadians / 2)
                        \         =~ (PI/4 - yawRadians / 2) ^ 2

 ASL T                  \ Set (U T) = (U T) * 2
 ROL U                  \           = (PI/4 - yawRadians / 2) ^ 2 * 2

                        \ By this point we have the following:
                        \
                        \   (U T) = (PI/4 - yawRadians / 2) ^ 2 * 2
                        \         = ((PI/2 - yawRadians) / 2) ^ 2 * 2
                        \
                        \ If we define x = PI/2 - yawRadians, then we have:
                        \
                        \   (U T) = (x / 2) ^ 2 * 2
                        \         = ((x ^ 2) / (2 ^ 2)) * 2
                        \         = (x ^ 2) / 2
                        \
                        \ The small angle approximation states that for small
                        \ values of x, the following approximation holds true:
                        \
                        \   cos(x) =~ 1 - (x ^ 2) / 2!
                        \
                        \ As yawRadians is large, this means x is small, so we
                        \ can use this approximation
                        \
                        \ We are storing the cosine, which is in the range 0 to
                        \ 1, in the 16-bit variable (U T), so in terms of 16-bit
                        \ arithmetic, the 1 in the above equation is (1 0 0)
                        \
                        \ So this is the same as:
                        \
                        \   cos(x) =~ (1 0 0) - (x ^ 2) / 2!
                        \          =  (1 0 0) - (U T)
                        \
                        \ It's a trigonometric identity that:
                        \
                        \   cos(PI/2 - x) = sin(x)
                        \
                        \ so we have:
                        \
                        \   cos(x) = cos(PI/2 - yawRadians)
                        \          = sin(yawRadians)
                        \
                        \ and we already calculated that:
                        \
                        \   cos(x) =~ (1 0 0) - (U T)
                        \
                        \ so that means that:
                        \
                        \   sin(yawRadians) = cos(x)
                        \                   =~ (1 0 0) - (U T)
                        \
                        \ So we just need to calculate (1 0 0) - (U T) to get
                        \ our result

 LDA #0                 \ Set A = (1 0 0) - (U T)
 SEC                    \
 SBC T                  \ starting with the low bytes

 AND #%11111110         \ Which we store in sinYawAngleLo, with bit 0 cleared to
 STA sinYawAngleLo,X    \ denote a positive result (as it's a sign-magnitude
                        \ number we want to store)

 LDA #0                 \ And then the high bytes
 SBC U

 BCC rotm4              \ We now need to subtract the top bytes, i.e. the 1 in
                        \ (1 0 0) and the 0 in (0 U T), while including the
                        \ carry from the high byte subtraction
                        \
                        \ So the top byte should be:
                        \
                        \   A = 1 - 0 - (1 - C)
                        \     = 1 - (1 - C)
                        \     = C
                        \
                        \ If the C flag is clear, then that means the top byte
                        \ is zero, so we already have a valid result from the
                        \ high and low bytes, so we jump to rotm4 to store the
                        \ high byte of the result in sinYawAngleHi
                        \
                        \ If the C flag is set, then the result is (1 A T), but
                        \ the highest possible value for sin or cos is 1, so
                        \ that's what we return
                        \
                        \ Because sinYawAngle is a sign-magnitude number with
                        \ the sign bit in bit 0, we return the following value
                        \ to represent the closest value to 1 that we can fit
                        \ into 16 bits:
                        \
                        \   (11111111 11111110)

 LDA #%11111110         \ Set sinYawAngleLo to the highest possible positive
 STA sinYawAngleLo,X    \ value (i.e. all ones except for the sign in bit 0)

 LDA #%11111111         \ Set A to the highest possible value of sinYawAngleHi,
                        \ so we can store it in the next instruction

.rotm4

 STA sinYawAngleHi,X    \ Store A in the high byte in sinYawAngleHi

\ ******************************************************************************
\
\       Name: GetRotationMatrix (Part 4 of 5)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Loop back to calculate cos instead of sin
\
\ ******************************************************************************

.rotm5

 CPX secondAxis         \ If we just processed the second axis, then we have
 BEQ rotm6              \ now set both sinYawAngle and cosYawAngle, so jump to
                        \ rotm6 to set their signs

 LDX secondAxis         \ Otherwise set X = secondAxis so the next time we reach
                        \ the end of the loop, we take the BEQ branch we just
                        \ passed through

 LDA #0                 \ Set (H G) = (201 0) - (H G)
 SEC                    \
 SBC G2                 \ starting with the low bytes
 STA G2

 LDA #201               \ And then the high bytes
 SBC H2
 STA H2

 STA U                  \ Set (U G) = (H G)
                        \
                        \ (U G) and (H G) were set to yawRadians / 2 for the
                        \ first pass through the loop above, so we now have the
                        \ following:
                        \
                        \   201 - yawRadians / 2
                        \
                        \ PI is represented by 804, as 804 / 256 = 3.14, so 201
                        \ represents PI/4, so this the same as:
                        \
                        \   PI/4 - yawRadians / 2
                        \
                        \ Given that we expect (U G) to contain half the angle
                        \ we are projecting, this means we are going to find the
                        \ sine of this angle when we jump back to rotm1:
                        \
                        \   PI/2 - yawRadians
                        \
                        \ It's a trigonometric identity that:
                        \
                        \   sin(PI/2 - x) = cos(x)
                        \
                        \ so jumping back will, in fact, find the cosine of the
                        \ angle

 JMP rotm1              \ Loop back to set the other variable of sinYawAngle and
                        \ cosYawAngle to the cosine of the angle

\ ******************************************************************************
\
\       Name: GetRotationMatrix (Part 5 of 5)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Apply the correct signs to the result
\  Deep dive: The core driving model
\
\ ******************************************************************************

.rotm6

                        \ By this point, we have the yaw angle vector's
                        \ x-coordinate in sinYawAngle and the y-coordinate in
                        \ cosYawAngle
                        \
                        \ The above calculations were done on an angle that was
                        \ reduced to a quarter-circle, so now we need to add the
                        \ correct signs according to which quarter-circle the
                        \ original playerYawAngle in (J T) was in

 LDA J                  \ If J is positive then playerYawAngle is positive (as
 BPL rotm7              \ J contains playerYawAngleHi), so jump to rotm7 to skip
                        \ the following

                        \ If we get here then playerYawAngle is negative
                        \
                        \ The degree system in Revs looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of car
                        \         \  |  /
                        \          \ | /             0 = looking straight ahead
                        \           \|/              +64 = looking sharp right
                        \   -64 -----+----- +64      -64 = looking sharp left
                        \           /|\
                        \          / | \
                        \         /  |  \
                        \      -96   |   +96
                        \           128
                        \
                        \ So playerYawAngle is in the left half of the above
                        \ diagram, where the x-coordinates are negative, so we
                        \ need to negate the x-coordinate

 LDA #1                 \ Negate sinYawAngle by setting bit 0 of the low byte,
 ORA sinYawAngleLo      \ as sinYawAngle is a sign-magnitude number
 STA sinYawAngleLo

.rotm7

 LDA J                  \ If bits 6 and 7 of J are the same (i.e. their EOR is
 ASL A                  \ zero), jump to rotm8 to return from the subroutine as
 EOR J                  \ the sign of cosYawAngle is correct
 BPL rotm8

                        \ Bits 6 and 7 of J, i.e. of playerYawAngleHi, are
                        \ different, so the angle is in one of these ranges:
                        \
                        \   * 64 to 127 (%01000000 to %01111111)
                        \
                        \   * -128 to -65 (%10000000 to %10111111)
                        \
                        \ The degree system in Revs looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of car
                        \         \  |  /
                        \          \ | /             0 = looking straight ahead
                        \           \|/              +64 = looking sharp right
                        \   -64 -----+----- +64      -64 = looking sharp left
                        \           /|\
                        \          / | \
                        \         /  |  \
                        \      -96   |   +96
                        \           128
                        \
                        \ So playerYawAngle is in the bottom half of the above
                        \ diagram, where the y-coordinates are negative, so we
                        \ need to negate the y-coordinate


 LDA #1                 \ Negate cosYawAngle by setting bit 0 of the low byte,
 ORA cosYawAngleLo      \ as cosYawAngle is a sign-magnitude number
 STA cosYawAngleLo

.rotm8

 LDX xStoreMatrix       \ Restore the value of X that we stored in xStoreMatrix
                        \ at the start of the routine, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: xStoreMatrix
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Temporary storage for X so it can be preserved through calls to
\             GetRotationMatrix
\
\ ******************************************************************************

.xStoreMatrix

 EQUB 0

\ ******************************************************************************
\
\       Name: GetAngleInRadians
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Convert a 16-bit angle into radians, restricted to a quarter
\             circle
\  Deep dive: Trigonometry
\
\ ------------------------------------------------------------------------------
\
\ This routine is from Revs, Geoff Crammond's previous game.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               A yaw angle in Revs format (-128 to +127)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   (U A)               The angle, reduced to a quarter circle, converted to
\                       radians, and halved
\
\ ******************************************************************************

 LDA #0                 \ This instuction appears to be unused

.GetAngleInRadians

 ASL T                  \ Set (V T) = (A T) << 2
 ROL A                  \
 ASL T                  \ This shift multiplies (A T) by four, removing bits 6
 ROL A                  \ and 7 in the process
 STA V                  \
                        \ The degree system in Revs looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of car
                        \         \  |  /
                        \          \ | /             0 = looking straight ahead
                        \           \|/              +64 = looking sharp right
                        \   -64 -----+----- +64      -64 = looking sharp left
                        \           /|\
                        \          / | \
                        \         /  |  \
                        \      -96   |   +96
                        \           128
                        \
                        \ The top byte of (A T) is in this range, so shifting to
                        \ the left by two places drops bits 6 and 7 and scales
                        \ the angle into the range 0 to 252, as follows:
                        \
                        \   * 0 to 63 (%00000000 to %00111111)
                        \     -> 0 to 252 (%00000000 to %11111100)
                        \
                        \   * 64 to 127 (%01000000 to %01111111)
                        \     -> 0 to 252 (%00000000 to %11111100)
                        \
                        \   * -1 to -64 (%11111111 to %11000000)
                        \     -> 252 to 0 (%11111100 to %00000000)
                        \
                        \   * -65 to -128 (%10111111 to %10000000)
                        \     -> 252 to 0 (%11111100 to %00000000)

                        \ We now convert this number from a Revs angle into
                        \ radians
                        \
                        \ The value of (V T) represents a quarter-circle, which
                        \ is PI/2 radians, but we actually multiply by PI/4 to
                        \ return the angle in radians divided by 2, to prevent
                        \ overflow in the GetRotationMatrix routine

 LDA #201               \ Set U = 201
 STA U

                        \ Fall through into Multiply8x16 to calculate:
                        \
                        \   (U A) = U * (V T) / 256
                        \         = 201 * (V T) / 256
                        \         = (201 / 256) * (V T)
                        \         = (3.14 / 4) * (V T)
                        \
                        \ So we return (U A) = PI/4 * (V T)
                        \
                        \ which is the original angle, reduced to a quarter
                        \ circle, converted to radians, and halved

\ ******************************************************************************
\
\       Name: Multiply8x16
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Multiply an 8-bit and a 16-bit number
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned numbers:
\
\   (U T) = U * (V T) / 256
\
\ The result is also available in (U A).
\
\ This routine is from Revs, Geoff Crammond's previous game.
\
\ ******************************************************************************

.Multiply8x16

 JSR Multiply8x8+2      \ Set (A T) = T * U

 STA W                  \ Set (W T) = (A T)
                        \           = T * U
                        \
                        \ So W = T * U / 256

 LDA V                  \ Set A = V

 JSR Multiply8x8        \ Set (A T) = A * U
                        \           = V * U

 STA U                  \ Set (U T) = (A T)
                        \           = V * U

 LDA W                  \ Set (U T) = (U T) + W
 CLC                    \
 ADC T                  \ starting with the low bytes
 STA T

 BCC mult1              \ And then the high bytes, so we get the following:
 INC U                  \
                        \   (U T) = (U T) + W
                        \         = V * U + (T * U / 256)
                        \         = U * (V + T / 256)
                        \         = U * (256 * V + T) / 256
                        \         = U * (V T) / 256
                        \
                        \ which is what we want

.mult1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ScanKeyboard
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard for a specific key press
\
\ ------------------------------------------------------------------------------
\
\ This routine is from Revs, Geoff Crammond's previous game. There is only one
\ minor difference: the value of Y is preserved.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The negative inkey value of the key to scan for (in the
\                       range &80 to &FF)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   Z flag              The result:
\
\                         * Set if the key in X is being pressed, in which case
\                           BEQ will branch
\
\                         * Clear if the key in X is not being pressed, in which
\                           case BNE will branch
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.ScanKeyboard

 TYA                    \ Store Y on the stack so we can preserve it
 PHA

 LDA #129               \ Call OSBYTE with A = 129, Y = &FF and the inkey value
 LDY #&FF               \ in X, to scan the keyboard for key X
 JSR OSBYTE

 PLA                    \ Retrieve Y from the stack so it is unchanged
 TAY

 CPX #&FF               \ If the key in X is being pressed, the above call sets
                        \ both X and Y to &FF, so this sets the Z flag depending
                        \ on whether the key is being pressed (so a BEQ after
                        \ the call will branch if the key in X is being pressed)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: sub_C0F70
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C0F70

 BPL C0F74
 EOR #&40

.C0F74

 STA H
 ASL T
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
 LDA sin,X
 LDX sin,Y
 BIT H
 BMI C0F97
 BVS C0F99

.P0F92

 STA L008E
 STX L008F
 RTS

.C0F97

 BVS P0F92

.C0F99

 STA L008F
 STX L008E
 RTS

\ ******************************************************************************
\
\       Name: Multiply16x16
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Multiply a sign-magnitude 16-bit number and a signed 16-bit number
\
\ ------------------------------------------------------------------------------
\
\ This routine calculates:
\
\   (A T) = (QQ PP) * (SS RR) / 256^2
\
\ It uses the following algorithm:
\
\  (QQ PP) * (SS RR) = (QQ << 8 + PP) * (SS << 8 + RR)
\                    = (QQ << 8 * SS << 8) + (QQ << 8 * RR)
\                                          + (PP * SS << 8)
\                                          + (PP * RR)
\                    = (QQ * SS) << 16 + (QQ * RR) << 8
\                                      + (PP * SS) << 8
\                                      + (PP * RR)
\
\ Finally, it replaces the low byte multiplication in (PP * RR) with 128, as an
\ estimate, as it's a pain to multiply the low bytes of a signed integer with a
\ sign-magnitude number. So the final result that is returned in (A T) is as
\ follows:
\
\   (A T) = (QQ PP) * (SS RR) / 256^2
\         = ((QQ * SS) << 16 + (QQ * RR) << 8 + (PP * SS) << 8 + 128) / 256^2
\
\ which is the algorithm that is implemented in this routine.
\
\ This routine is from Revs, Geoff Crammond's previous game.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (QQ PP)             16-bit signed integer
\
\   (SS RR)             16-bit sign-magnitude integer with the sign bit in bit 0
\                       of RR
\
\   H                   The sign to apply to the result (in bit 7)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   (A T)               (QQ PP) * (SS RR) * abs(H)
\
\ ******************************************************************************

.Multiply16x16

 LDA QQ                 \ If (QQ PP) is positive, jump to muls1 to skip the
 BPL muls1              \ following

 LDA #0                 \ (QQ PP) is negative, so we now negate (QQ PP) so it's
 SEC                    \ positive, starting with the low bytes
 SBC PP
 STA PP

 LDA #0                 \ And then the high bytes
 SBC QQ                 \
 STA QQ                 \ So we now have (QQ PP) = |QQ PP|

 LDA H                  \ Flip bit 7 of H, so when we set the result to the sign
 EOR #%10000000         \ of H below, this ensures the result is the correct
 STA H                  \ sign

.muls1

 LDA RR                 \ If bit 0 of RR is clear, then (SS RR) is positive, so
 AND #1                 \ jump to muls2
 BEQ muls2

 LDA H                  \ Flip bit 7 of H, so when we set the result to the sign
 EOR #%10000000         \ of H below, this ensures the result is the correct
 STA H                  \ sign

.muls2

 LDA QQ                 \ Set U = QQ
 STA U

 LDA RR                 \ Set A = RR

 JSR Multiply8x8        \ Set (A T) = A * U
                        \           = RR * QQ

 STA W                  \ Set (W T) = (A T)
                        \           = RR * QQ

 LDA T                  \ Set (W V) = (A T) + 128
 CLC                    \           = RR * QQ + 128
 ADC #128               \
 STA V                  \ starting with the low bytes

 BCC muls3              \ And then the high byte
 INC W

                        \ So we now have (W V) = RR * QQ + 128

.muls3

 LDA SS                 \ Set A = SS

 JSR Multiply8x8        \ Set (A T) = A * U
                        \           = SS * QQ

 STA G                  \ Set (G T) = (A T)
                        \           = SS * QQ

 LDA T                  \ Set (G W V) = (G T 0) + (W V)
 CLC                    \
 ADC W                  \ starting with the middle bytes (as the low bytes are
 STA W                  \ simply V = 0 + V with no carry)

 BCC muls4              \ And then the high byte
 INC G

                        \ So now we have:
                        \
                        \   (G W V) = (G T 0) + (W V)
                        \           = (SS * QQ << 8) + RR * QQ + 128

.muls4

 LDA PP                 \ Set U = PP
 STA U

 LDA SS                 \ Set A = SS

 JSR Multiply8x8        \ Set (A T) = A * U
                        \           = SS * PP

 STA U                  \ Set (U T) = (A T)
                        \           = SS * PP

 LDA T                  \ Set (G T ?) = (G W V) + (U T)
 CLC                    \
 ADC V                  \ starting with the low bytes (which we throw away)

 LDA U                  \ And then the high bytes
 ADC W
 STA T

 BCC muls5              \ And then the high byte
 INC G

                        \ So now we have:
                        \
                        \   (G T ?) = (G W V) + (U T)
                        \           = (SS * QQ << 8) + RR * QQ + 128 + SS * PP
                        \           = (QQ * SS) << 8 + (QQ * RR) + (PP * SS)
                        \              + 128
                        \           = (QQ PP) * (SS RR) / 256
                        \
                        \ So:
                        \
                        \   (G T) = (G T ?) / 256
                        \         = (QQ PP) * (SS RR) / 256^2
                        \
                        \ which is the result that we want

.muls5

 LDA G                  \ Set (A T) = (G T)

 BIT H                  \ We are about to fall through into Absolute16Bit, so
                        \ this ensures we set the sign of (A T) to the sign in
                        \ H, so we get:
                        \
                        \   (A T) = (A T) * abs(H)

\ ******************************************************************************
\
\       Name: Absolute16Bit
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate the absolute value (modulus) of a 16-bit number
\
\ ------------------------------------------------------------------------------
\
\ This routine sets (A T) = |A T|.
\
\ It can also return (A T) * abs(n), where A is given the sign of n.
\
\ This routine is from Revs, Geoff Crammond's previous game.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               The number to make positive
\
\   N flag              Controls the sign to be applied:
\
\                         * If we want to calculate |A T|, do an LDA or
\                           equivalent before calling the routine
\
\                         * If we want to calculate (A T) * abs(n), do a BIT n
\                           before calling the routine
\
\                         * If we want to set the sign of (A T), then call with:
\
\                           * N flag clear to calculate (A T) * 1
\
\                           * N flag set to calculate (A T) * -1
\
\ ******************************************************************************

.Absolute16Bit

 BPL MainLoop-1         \ If the high byte in A is already positive, return from
                        \ the subroutine (as MainLoop-1 contains an RTS)

                        \ Otherwise fall through into Negate16Bit to negate the
                        \ number in (A T), which will make it positive, so this
                        \ sets (A T) = |A T|

\ ******************************************************************************
\
\       Name: Negate16Bit
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Negate a 16-bit number
\
\ ------------------------------------------------------------------------------
\
\ This routine negates the 16-bit number (A T).
\
\ This routine is from Revs, Geoff Crammond's previous game.
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   Negate16Bit+2       Set (A T) = -(U T)
\
\ ******************************************************************************

.Negate16Bit

 STA U                  \ Set (U T) = (A T)

 LDA #0                 \ Set (A T) = 0 - (U T)
 SEC                    \           = -(A T)
 SBC T                  \
 STA T                  \ starting with the low bytes

 LDA #0                 \ And then the high bytes
 SBC U

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MainLoop
\       Type: Subroutine
\   Category: Main loop
\    Summary: The main game loop, where we display the title screen, fetch the
\             landscape number, play the game and repeat
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   MainLoop-1          Contains an RTS
\
\   main4               ???
\
\   main5               ???
\
\ ******************************************************************************

.MainLoop

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 JSR ResetVariables     \ Reset all the game's main variables

 LDA #0                 \ Call DrawTitleScreen with A = 0 to draw the title
 JSR DrawTitleScreen    \ screen

 LDX #0
 JSR sub_C36AD

 LDA #&87               \ Set the palette to the second set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, red, yellow)

 JSR sub_C5E07

.main1

 JSR ResetVariables     \ Reset all the game's main variables

 LDX #1
 JSR sub_C36AD

 LDA #4
 JSR sub_C329F

 JSR sub_C3321

 LDY L0CF1
 LDX L0CF0
 JSR sub_C33B7

 LDA L0C52
 BNE main3

 LDX #3

.main2

 LDA L108C,X
 STA L0CF0,X

 DEX

 BPL main2

 BMI main4

.main3

 LDX #2
 JSR sub_C36AD

 LDA #8
 JSR sub_C329F

 JSR sub_C3321

.main4

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 JSR sub_C2A9C

.main5

 JSR ResetVariables     \ Reset all the game's main variables

 LDA #0                 \ Call DrawTitleScreen with A = 0 to draw the title
 JSR DrawTitleScreen    \ screen

 LDA #&87               \ Set the palette to the second set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, red, yellow)

 LDX #3
 JSR sub_C36AD

 JSR sub_C5E07

 JMP main1

\ ******************************************************************************
\
\       Name: L108C
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L108C

 EQUB &87, &53, &04, &06

\ ******************************************************************************
\
\       Name: sub_C1090
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1090

 JSR sub_C130C
 JSR sub_C3699
 LDA #0
 JSR sub_C2963
 LDA #0
 LDY #&18
 LDX #&28
 JSR sub_C2202
 LDA L0C4C
 CMP #&03
 BNE CRE04
 LDA #&03
 STA L0015

.P10AF

 JSR sub_C56D5
 DEC L0015
 BNE P10AF

.CRE04

 RTS

\ ******************************************************************************
\
\       Name: sub_C10B7
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 BEQ CRE05
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

.P1136

 JSR sub_C3923

.CRE05

 RTS

.C113A

 LDA L0140,X
 SEC
 SBC L38F4,Y
 STA L0140,X

.C1144

L1145 = C1144+1

 JMP P1136

\ ******************************************************************************
\
\       Name: L1147
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1147

 EQUB &35

\ ******************************************************************************
\
\       Name: L1148
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1148

 EQUB &CD

\ ******************************************************************************
\
\       Name: ResetVariables
\       Type: Subroutine
\   Category: Main Loop
\    Summary: Reset all the game's main variables
\
\ ******************************************************************************

.ResetVariables

 SEC                    \ Set bit 7 of L0CFC (so we skip a part of the interrupt
 ROR L0CFC              \ handler) ???

                        \ We now zero the following variable blocks:
                        \
                        \   * &0000 to &008F
                        \
                        \   * &0100 to &01BF
                        \
                        \   * &0900 to &09EF
                        \
                        \   * &0A00 to &0AEF
                        \
                        \   * &0C00 to &0CE3
                        \
                        \ and set the following variable block to &80:
                        \
                        \   * &0CE4 to &0CEF

 LDX #0                 \ Set X to use as a byte counter to run from 0 to &EF

.rese1

 LDA #0                 \ Set A = 0 so we can zero the following variable blocks

 STA L0900,X            \ Zero the X-th byte of L0900

 STA L0A00,X            \ Zero the X-th byte of L0A00

 CPX #&90               \ If X >= &90 then skip the following instruction
 BCS rese2

 STA L0000,X            \ Zero the X-th byte of L0000

.rese2

 CPX #&C0               \ If X >= &C0 then skip the following instruction
 BCS rese3

 STA L0100,X            \ Zero the X-th byte of L0100

.rese3

 CPX #&E4               \ If X < &E4 then skip the following instruction,
 BCC rese4              \ leaving A = 0, so we zero &0C00 to &0CE3

 LDA #&80               \ If we get here then X >= &E4, so set A = &80 so we
                        \ set &0CE4 to &0CEF to &80

.rese4

 STA sinYawAngleLo,X            \ Set the X-th byte of sinYawAngleLo to A

 INX                    \ Increment the byte counter

 CPX #&F0               \ Loop back until we have processed X from 0 to &EF
 BCC rese1

                        \ Fall through into ResetVariables2 to ???

\ ******************************************************************************
\
\       Name: ResetVariables2
\       Type: Subroutine
\   Category: Main Loop
\    Summary: Reset the L3E80, L3EC0 and L0100 variable blocks ???
\
\ ******************************************************************************

.ResetVariables2

                        \ We now set the following variable blocks to &FF:
                        \
                        \   * &3E80 to &3EBF
                        \
                        \   * &3EC0 to &3EFF
                        \
                        \ and set the following variable block to &80:
                        \
                        \   * &0100 to &01EF

 LDX #&3F               \ Set X to use as a byte counter to run from &3F to 0

.resv1

 LDA #&FF               \ Set the X-th byte of L3E80 to &FF
 STA L3E80,X

 STA L3EC0,X            \ Set the X-th byte of L3EC0 to &FF

 LDA #&80               \ Set the X-th byte of L0100 to &80
 STA L0100,X

 DEX                    \ Decrement the byte counter

 BPL resv1              \ Loop back until we have processed X from &3F to 0

 INC L0C7D              \ ???

 JSR sub_C3923          \ ???

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: sub_C118B
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C118B

 LDA #&80
 STA L0009
 LDX #&8E
 JSR ScanKeyboard
 BNE C119A
 SEC
 ROR L0C64

.C119A

 LDX #&9D
 JSR ScanKeyboard
 BNE C11C0
 LDA L1222
 BNE C11C5
 LDA L0C5F
 EOR #&80
 STA L0C5F
 BPL C11B9
 JSR sub_C1331
 JSR sub_C39D9
 JMP C11BC

.C11B9

 JSR sub_C3AA7

.C11BC

 LDA #&80
 BNE C11C2

.C11C0

 LDA #0

.C11C2

 STA L1222

.C11C5

 LDY #&0E
 JSR sub_C1353
 BPL C11DD
 LDA #&6B
 STA L0CC8
 LDA L0CE9
 BPL sub_C1200
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

\ ******************************************************************************
\
\       Name: sub_C1200
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1200

 LDA #&80
 STA L0CE4
 STA L0C1E

.C1208

 LDA L0CE4
 STA L0CDC
 RTS

\ ******************************************************************************
\
\       Name: sub_C120F
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L1222
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1222

 EQUB &00, &00

\ ******************************************************************************
\
\       Name: sub_C1224
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1224

 STA L0006
 LDA #0
 STA L0015

.C122A

 DEC L0015
 BNE C1236
 INC L0006
 LDA L0006
 CMP #&0C
 BCS C1258

.C1236

 JSR sub_C125A
 STA L0024
 JSR sub_C125A
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

\ ******************************************************************************
\
\       Name: sub_C125A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C125A

 JSR sub_C3194
 AND #&1F
 CMP #&1F
 BCS sub_C125A
 RTS

\ ******************************************************************************
\
\       Name: sub_C1264
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1264

 LDA #0
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

 JSR sub_C1200
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
 JSR sub_C3480
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
 JSR sub_C3440
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

\ ******************************************************************************
\
\       Name: sub_C12EE
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C12EE

 LDA L0C50
 BNE C1308
 LDX #&17

.P12F5

 LDA L0C20,X
 CMP #&02
 BCC C12FF
 DEC L0C20,X

.C12FF

 DEX
 BPL P12F5
 LDA #&02
 STA L0C50
 RTS

.C1308

 DEC L0C50
 RTS

\ ******************************************************************************
\
\       Name: sub_C130C
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C1331
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C1353
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1353

 LDX #&03
 LDA #&80

.P1357

 STA L0CE8,X
 DEX
 BPL P1357

.P135D

 LDX L137D,Y
 JSR ScanKeyboard
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
 BPL P135D
 LDA L0CE8
 AND L0CEA
 RTS

\ ******************************************************************************
\
\       Name: L137D
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L137D

 EQUB &AE, &CD, &A9, &99, &BE, &EF, &CC, &DC
 EQUB &9B, &AB, &DB, &EA, &96, &A6, &CA

\ ******************************************************************************
\
\       Name: L138C
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L138C

 EQUB &04, &00, &0A, &0E, &81, &85, &01, &09
 EQUB &0D, &89, &03, &07, &0B, &0F, &8D

\ ******************************************************************************
\
\       Name: DrawObject
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.DrawObject

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

.P13F4

 STA L3E80,X
 DEX
 BPL P13F4

.C13FA

 LDA #0
 STA L0C78
 STA L0C4C
 RTS

\ ******************************************************************************
\
\       Name: L1403
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1403

 EQUB &21, &4B

\ ******************************************************************************
\
\       Name: L1405
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1405

 EQUB &EA, &D9

\ ******************************************************************************
\
\       Name: L1407
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1407

 EQUB &0F, &00

\ ******************************************************************************
\
\       Name: L1409
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1409

 EQUB &00, &EF

\ ******************************************************************************
\
\       Name: L140B
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L140B

 EQUB &C2, &BF

\ ******************************************************************************
\
\       Name: L140D
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L140D

 EQUB &00, &12

\ ******************************************************************************
\
\       Name: L140F
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L140F

 EQUB &01

\ ******************************************************************************
\
\       Name: sub_C1410
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA colourPalettes+3
 LDA L14E3,X
 STA colourPalettes+2
 RTS

\ ******************************************************************************
\
\       Name: sub_C1440
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1440

 LDA #0
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
 STA U
 JSR sub_C341B
 CLC
 ADC #&0A
 CMP U
 BCC C1487
 LDA U

.C1487

 STA L001E

.P1489

 LDA #&02
 JSR sub_C210E
 LDA L0C06
 JSR sub_C1224
 BCS C149A
 DEC L001E
 BNE P1489

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

.CRE06

 RTS

\ ******************************************************************************
\
\       Name: L14C4
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L14C4

 EQUB &02, &01, &03, &06, &01, &06, &01, &03

.C14CC

 LDA L0C65
 AND #&1E
 CMP #&1E
 BNE CRE06
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

\ ******************************************************************************
\
\       Name: L14E3
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L14E3

 EQUB &07, &03, &06, &01, &07, &03, &06, &01

\ ******************************************************************************
\
\       Name: sub_C14EB
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C14EB

 JSR sub_C15BC
 LDX #0

.C14F0

 STX L006E
 LDA #&01
 STA L0A40,X

.P14F7

 JSR sub_C158D
 BCC C150B
 LDA L0006
 SEC
 SBC #&10
 STA L0006
 BNE P14F7
 STX L0C6F
 JMP C1582

.C150B

 JSR sub_C3194
 AND L0027
 CMP T
 BCS C150B
 TAY
 LDX L5A40,Y
 LDA #0
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
 LDA #0
 STA L09C0,X
 LDX L006E

.C155F

 JSR sub_C1EFF
 JSR sub_C196A
 JSR sub_C3194
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

\ ******************************************************************************
\
\       Name: sub_C158D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C158D

 LDX #&3F
 LDY #0

.P1591

 LDA L5B10,X
 CMP L0006
 BNE C159D
 TXA
 STA L5A40,Y
 INY

.C159D

 DEX
 BPL P1591
 TYA
 BEQ C15B2
 STA T
 LDY #&FF

.P15A7

 ASL A
 INY
 BCC P15A7
 LDA L15B4,Y
 STA L0027
 CLC
 RTS

.C15B2

 SEC
 RTS

\ ******************************************************************************
\
\       Name: L15B4
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L15B4

 EQUB &FF, &7F, &3F, &1F, &0F, &07, &03, &01

\ ******************************************************************************
\
\       Name: sub_C15BC
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C15BC

 LDX #0
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
 LDA #0
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

\ ******************************************************************************
\
\       Name: sub_C1623
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1623

 LDA L0C04
 BNE sub_C162D
 CMP L0C09
 BEQ CRE07

\ ******************************************************************************
\
\       Name: sub_C162D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C162D

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

.P1655

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
 BPL P1655
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
 BEQ CRE07
 LDA L169A
 CMP #&04
 BNE C164D
 LDA L0C4F
 CMP #&40
 BNE C164D
 LDA #0
 STA L169B
 BEQ C164D

.CRE07

 RTS

\ ******************************************************************************
\
\       Name: L1699
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1699

 EQUB &00

\ ******************************************************************************
\
\       Name: L169A
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L169A

 EQUB &00

\ ******************************************************************************
\
\       Name: L169B
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L169B

 EQUB &00

\ ******************************************************************************
\
\       Name: L169C
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L169C

 EQUB &0F, &0F, &0F, &0F, &8F, &4F, &2F, &1F
 EQUB &FF, &FF, &FF, &FF

\ ******************************************************************************
\
\       Name: sub_C16A8
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

 JSR sub_C3194
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
 LDA #0
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

 LDA #0
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
 LDA #0
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

.P17A9

 LDA #0
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
 BPL P17A9
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

 LDA #0
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
 LDA #0
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

.P1835

 JMP C16C9

.C1838

 BNE P1835
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

 LDA #0
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

\ ******************************************************************************
\
\       Name: sub_C1882
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1882

 STA T
 STX L1919
 STY L0C58
 LDA #0
 STA L0014
 LDA L0100,Y
 BMI C1911
 LDA L0A40,Y
 CMP T
 BNE C1911
 JSR sub_C5C01
 LDX #&07
 LDA rotm8-1,X
 STA T
 AND #&0F
 CMP #&09
 BEQ C18AC
 LDX #&01

.C18AC

 TXA
 CLC
 ADC T
 STA L0C75
 LDA L0C68
 LSR A
 STA T
 LDA L0C57
 SEC
 SBC #&0A
 CLC
 ADC T
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
 STA T
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

\ ******************************************************************************
\
\       Name: L1919
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1919

 EQUB &00

\ ******************************************************************************
\
\       Name: sub_C191A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C191A

 LDY #0
 STY T
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
 STA T
 BMI C1948

.C1945

 DEX
 BPL C1920

.C1948

 STY L0C04
 LDA T
 STA L0C4F
 LDA L0C73
 CPY L0C73
 STY L0C73
 BEQ CRE08
 LDY #&12
 STY L5910
 CMP #&03
 BEQ CRE08
 LDX #&06
 JSR sub_C3555

.CRE08

 RTS

\ ******************************************************************************
\
\       Name: sub_C196A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C196A

 LDA #&80
 STA L0CA0,X
 STA L0C90,X
 LDA #0
 STA L0C98,X
 LDA #&40
 STA L0C80,X
 RTS

\ ******************************************************************************
\
\       Name: sub_C197D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 JMP sub_C1AEC

.P19F7

 LDA #&80
 STA L0C4E
 JMP sub_C1AEC

\ ******************************************************************************
\
\       Name: sub_C19FF
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C19FF

 LDX L0C58
 CPX L000B
 BNE C1A1D
 LDA L0C0A
 BEQ P19F7
 SEC
 SBC #&01
 STA L0C0A
 JSR sub_C36C7
 LDA #&05
 JSR sub_C3440
 SEC
 JMP C1A46

.C1A1D

 TXA
 JSR sub_C1AE7
 LDA L0A40,X
 BNE C1A31
 LDY L0000
 LDA #0
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

\ ******************************************************************************
\
\       Name: sub_C1A54
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1A54

 LDX L0000
 SEC
 LDA L0C88,X
 BEQ CRE09
 LDA #&02
 JSR sub_C210E
 LDA L0C06
 JSR sub_C1224
 BCS CRE09
 TXA
 JSR sub_C1AF3
 BCC C1A78
 LDX L0000
 DEC L0C88,X
 LDX L0001
 CLC

.CRE09

 RTS

.C1A78

 JSR sub_C1ED8
 JMP sub_C1AEC

\ ******************************************************************************
\
\       Name: sub_C1A7E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

 LDA #&80               \ Call DrawTitleScreen with A = &80 to draw the screen
 JSR DrawTitleScreen    \ showing the landscape code

 LDX #&05
 JSR sub_C36AD
 JMP sub_C33AB

\ ******************************************************************************
\
\       Name: sub_C1AA7
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C1AE7
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1AE7

 JSR sub_C1AF3
 BCS CRE10

\ ******************************************************************************
\
\       Name: sub_C1AEC
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1AEC

 LDX L0C0D
 TXS
 JMP C16C9

\ ******************************************************************************
\
\       Name: sub_C1AF3
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1AF3

 SEC
 BIT L0C1F
 BPL CRE10
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

.CRE10

 RTS

\ ******************************************************************************
\
\       Name: sub_C1B0B
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1B0B

 LDA L0C61
 CMP #&22
 BNE C1B1C
 JSR sub_C2147
 LDA #0
 STA L0C1C

.P1B1A

 SEC
 RTS

.C1B1C

 LDX L006E
 CMP #&23
 BNE C1B33
 ASL L0C51
 BPL P1B1A
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
 JSR sub_C1200
 STX L000B

.P1B5D

 LDA L0100,X
 CMP #&40
 BCC C1B71
 AND #&3F
 TAX
 EOR #&3F
 BNE P1B5D
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
 JSR sub_C3440
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

.P1BDD

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
 BPL P1BDD
 BMI C1B8D

\ ******************************************************************************
\
\       Name: sub_C1BFF
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1BFF

 LDA L0CC6
 STA U
 LDA #0
 LSR U
 ROR A
 LSR U
 ROR A
 LSR U
 ROR A
 CLC
 STA L003D
 LDA U
 ADC L09C0,X
 SEC
 SBC #&0A
 STA L003E
 LDA L0CC7
 SEC
 SBC #&05
 STA U
 LDA #0
 LSR U
 ROR A
 LSR U
 ROR A
 LSR U
 ROR A
 LSR U
 ROR A
 CLC
 ADC #&20
 STA L003F
 STA T
 LDA U
 ADC L0140,X
 CLC
 ADC #&03
 STA L0040

\ ******************************************************************************
\
\       Name: sub_C1C43
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1C43

 JSR GetRotationMatrix
 LDY #&01
 JSR sub_C1C8C
 STA L0033
 STX L0032
 LDY #0
 JSR sub_C1C8C
 STA L0030
 STX L002D
 LDA L003D
 STA T
 LDA L003E
 JSR GetRotationMatrix
 LDY #&01
 LDX #&02
 JSR sub_C1C6C
 LDY #0
 LDX #0

\ ******************************************************************************
\
\       Name: sub_C1C6C
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1C6C

 LDA #0
 STA H
 LDA L0032
 STA PP
 LDA L0033
 STA QQ
 LDA sinYawAngleLo,Y
 STA RR
 LDA sinYawAngleHi,Y
 STA SS
 JSR Multiply16x16
 STA L002F,X
 LDA T
 STA L002C,X
 RTS

\ ******************************************************************************
\
\       Name: sub_C1C8C
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1C8C

 LDA sinYawAngleLo,Y
 STA T
 LDA sinYawAngleHi,Y
 LSR A
 ROR T
 PHP
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 ROR T
 PLP
 BCC C1CA7
 JSR Negate16Bit

.C1CA7

 LDX T
 RTS

\ ******************************************************************************
\
\       Name: sub_C1CAA
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1CAA

 LDX #&02

.P1CAC

 LDA #0
 STA T
 LDA L0034,X
 CLC
 ADC L002C,X
 STA L0034,X
 LDA L002F,X
 BPL C1CBD
 DEC T

.C1CBD

 ADC L0037,X
 STA L0037,X
 LDA L003A,X
 ADC T
 STA L003A,X
 DEX
 BPL P1CAC
 RTS

 EQUB &00

\ ******************************************************************************
\
\       Name: sub_C1CCC
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA secondAxis
 STA L000C
 LDA #0
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
 BIT secondAxis
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
 STA W
 LSR secondAxis
 INC L0024
 JSR sub_C1DE6
 STA V
 INC L0026
 JSR sub_C1DE6
 STA U
 DEC L0024
 JSR sub_C1DE6
 STA T
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
 CMP T
 BCS C1D74
 CMP U
 BCS C1D74
 CMP V
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

 STA G
 LSR A
 LDA L0037
 BCC C1D93
 EOR #&FF

.C1D93

 CMP L0039
 LDA G
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
 STA G
 LDA T,X
 SEC
 SBC S,X
 PHP
 BPL C1DBD
 EOR #&FF
 CLC
 ADC #&01

.C1DBD

 STA U
 LDA L0002
 JSR Multiply8x8
 PLP
 JSR Absolute16Bit
 CLC
 ADC G
 STA U
 LDA L0038
 SEC
 SBC T
 LDA L003B
 SBC U
 BPL C1DDB
 JMP C1D33

.C1DDB

 JMP C1CD7

\ ******************************************************************************
\
\       Name: L1DDE
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1DDE

 EQUB &00, &03, &01, &00, &01, &02, &02, &03

\ ******************************************************************************
\
\       Name: sub_C1DE6
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 BIT secondAxis
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
 STA U
 LDA L0940,Y
 SBC L003B
 PHA
 LDA U
 CLC
 ADC #&E0
 STA U
 PLA
 ADC #&00
 BMI C1E82
 LSR A
 ROR U
 LSR A
 BNE C1E82
 LDA U
 ROR A
 CMP T
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
 STA secondAxis

.C1E8D

 LDA L0100,Y
 CMP #&40
 BCS C1E28
 LDA L0940,Y
 RTS

\ ******************************************************************************
\
\       Name: sub_C1E98
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1E98

 LDA L0037
 SEC
 SBC #&80
 BPL C1EA1
 EOR #&FF

.C1EA1

 STA T
 LDA L0039
 SEC
 SBC #&80
 BPL C1EAC
 EOR #&FF

.C1EAC

 CMP T
 BCS C1EB2
 LDA T

.C1EB2

 STA T
 RTS

\ ******************************************************************************
\
\       Name: sub_C1EB5
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1EB5

 LDA #0
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

\ ******************************************************************************
\
\       Name: sub_C1ED8
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C1EFF
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDA #0

.C1F42

 ADC L0940,Y
 LDY L1F77
 JMP C1F5B

.C1F4B

 PHA
 LDA #0
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
 JSR sub_C3194
 AND #&F8
 CLC
 ADC #&60
 STA L09C0,X
 CLC
 RTS

.C1F75

 SEC
 RTS

\ ******************************************************************************
\
\       Name: L1F77
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L1F77

 EQUB &00

\ ******************************************************************************
\
\       Name: sub_C1F84
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.C1F78

 LDA #0
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
 LDA #0
 LSR L2095
 ROR A
 STA L001F
 LDA L2095
 ADC L09C0,X
 STA L09C0,X
 LDY #0
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

 LDY #0
 JSR sub_C38FB
 LDX L006E
 LDA #0
 STA L001F
 SEC
 LDA L09C0,X
 SBC L2095
 STA L09C0,X
 LDA #0
 STA U
 LDA L0C62
 ASL A
 ASL A
 ASL A
 ROL U
 CLC
 ADC L0CC2
 STA L2092
 LDA L0CC3
 ADC U
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
 JSR sub_C39D9
 CLI

.C208D

 JMP C1F78

\ ******************************************************************************
\
\       Name: L2090
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2090

 EQUB &00

\ ******************************************************************************
\
\       Name: L2091
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2091

 EQUB &00

\ ******************************************************************************
\
\       Name: L2092
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2092

 EQUB &00

\ ******************************************************************************
\
\       Name: L2093
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2093

 EQUB &00

\ ******************************************************************************
\
\       Name: L2094
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2094

 EQUB &00

\ ******************************************************************************
\
\       Name: L2095
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2095

 EQUB &00

\ ******************************************************************************
\
\       Name: sub_C2096
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDA #0
 STA L0CD4
 JSR sub_C561D
 LDA L0C59
 SEC
 SBC L008A
 STA T
 LDA L0C57
 SBC L008B
 BPL C20CC
 LDA #0
 BEQ C20D3

.C20CC

 ASL T
 ROL A
 CMP #&28
 BCS C2105

.C20D3

 STA L0C62
 LDA L0C59
 CLC
 ADC L008A
 STA T
 LDA L0C57
 ADC L008B
 BMI C2105
 ASL T
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

\ ******************************************************************************
\
\       Name: L2107
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2107

 EQUB &3E, &46, &72, &7A, &4A, &4E, &C1

\ ******************************************************************************
\
\       Name: sub_C210E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C210E

 STA L0C61

\ ******************************************************************************
\
\       Name: sub_C2111
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2111

 LDX #&3F

.P2113

 LDA L0100,X
 BMI C211D
 DEX
 BPL P2113
 SEC
 RTS

.C211D

 STX L0001
 LDA L0C61
 STA L0A40,X
 CLC
 RTS

\ ******************************************************************************
\
\       Name: sub_C2127
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L2140
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2140

 EQUB &03, &03, &01, &02, &01, &04, &00

\ ******************************************************************************
\
\       Name: sub_C2147
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2147

 LDA #0
 JSR sub_C210E
 LDX L000B
 LDA L0940,X
 CLC
 ADC #&01
 LDX L0001
 JSR sub_C1224
 BCS CRE11
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

 LDA #0
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

 JSR sub_C1200
 LDX L0001
 STX L000B

.C2198

 LDA #&80
 STA L0C63
 CLC

.CRE11

 RTS

\ ******************************************************************************
\
\       Name: sub_C219F
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C219F

 AND #&3F
 STA L0C6C
 LDX #0

.P21A6

 INX
 AND #&3F
 TAY
 LDA L0100,Y
 CMP #&40
 BCS P21A6
 DEX
 STX L0C6B
 BEQ C21F3

.C21B7

 LDX L000B
 LDA L0A00,X
 SEC
 SBC L0A00,Y
 STA T
 LDA L0940,X
 SBC L0940,Y
 BMI C21F0
 ORA T
 BNE C21D5
 LDA L0A40,Y
 CMP #&06
 BEQ C21F0

.C21D5

 JSR sub_C5D33
 LDY L0C6C
 DEC L0C6B
 BMI CRE12
 LDX L0C6B
 BPL C21EC

.P21E5

 LDA L0100,Y
 AND #&3F
 TAY
 DEX

.C21EC

 BNE P21E5
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

.CRE12

 RTS

\ ******************************************************************************
\
\       Name: sub_C2202
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA T
 LDA L227B,X
 STA U

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
 LDA T
 STA (P),Y
 INY
 LDA U
 STA (P),Y
 INY
 LDA T
 STA (P),Y
 INY
 LDA U
 STA (P),Y
 INY
 LDA T
 STA (P),Y
 INY
 LDA U
 STA (P),Y
 INY
 LDA T
 STA (P),Y
 INY
 LDA U
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

\ ******************************************************************************
\
\       Name: L2277
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2277

 EQUB &00, &00, &AA, &0F

\ ******************************************************************************
\
\       Name: L227B
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L227B

 EQUB &0F, &00, &55, &0F

\ ******************************************************************************
\
\       Name: L227F
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L227F

 EQUB &88, &44, &22, &11

\ ******************************************************************************
\
\       Name: L2283
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2283

 EQUB &00, &0F, &F0, &FF

\ ******************************************************************************
\
\       Name: L2287
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2287

 EQUB &00, &88, &CC, &EE

\ ******************************************************************************
\
\       Name: L228B
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L228B

 EQUB &77, &33, &11, &00

\ ******************************************************************************
\
\       Name: L228F
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L228F

 EQUB &88, &CC, &EE, &FF

\ ******************************************************************************
\
\       Name: L2293
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2293

 EQUB &00, &60, &00

\ ******************************************************************************
\
\       Name: L2296
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2296

 EQUB &00, &00, &00

\ ******************************************************************************
\
\       Name: sub_C2299
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2299

 LDA #&01
 STA L002C
 STA L002D
 LDA L0006
 CLC
 ADC L0004
 ROR A
 TAX
 LDA L5B00,X
 CMP L5A00,X
 BCC CRE13
 LDA #&F0
 CLC
 SBC L0006
 STA T
 LSR A
 LSR A
 LSR A
 CLC
 ADC L0055
 TAX
 LDA T
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
 STA T
 LDA L0019
 ASL A
 ASL A
 AND #&30
 ORA T

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

.CRE13

 RTS

\ ******************************************************************************
\
\       Name: sub_C230D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C230D

 LDY L001A
 CPY L0004
 BEQ CRE13
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

 LDA #0
 STA L002D
 BEQ sub_C230D

.C2339

 LDA #0
 STA L002C
 BEQ sub_C230D

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
 LDA #0
 STA L002D
 LDA #&F8
 BNE C23D8

.C235D

 TXA
 AND #&03
 TAX
 LDA L0054
 AND L2287,X

.C2366

L2367 = C2366+1

 ORA L3E3C,X
 AND L228F,X
 STA T
 LDA (R),Y
 AND L228B,X
 ORA T
 STA (R),Y
 JMP sub_C230D

.C237A

 INC R

.C237C

 DEY
 STY L001A

.C237F

 LDA L5B00,Y
 CMP L5A00,Y
 BCC CRE13
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

.C23A1

L23A2 = C23A1+1

 ORA L3E7C,X
 STA (R),Y

.C23A6

 LDY L001A
 LDA L5A00,Y
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

.C23C6

L23C7 = C23C6+1

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

.C23E2

L23E3 = C23E2+1

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

 JMP sub_C230D

\ ******************************************************************************
\
\       Name: sub_C2463
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2463

 LDA L0CDE
 BMI CRE14
 LDA #0
 STA L0005
 LDX #&7F

.P246E

 STA L3E80,X
 DEX
 BPL P246E
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
 STA V
 LDX #&1E

.C2492

 TXA
 TAY
 LDA (P),Y
 LDY #&FF
 LSR A
 BCS C24A2
 CMP V
 BCC C24A2
 BEQ C24A2
 INY

.C24A2

 STY W
 TXA
 ASL A
 ASL A
 ASL A
 AND #&E0
 ORA L001A
 LSR A
 STA T
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
 AND W
 AND L24E2,Y
 STA U
 LDY T
 LDA L3E80,Y
 AND L0027
 ORA U
 STA L3E80,Y
 DEX
 BPL C2492
 DEC L001A
 BPL C2480

.CRE14

 RTS

\ ******************************************************************************
\
\       Name: L24E2
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L24E2

 EQUB &80, &40, &20, &10, &08, &04, &02, &01

\ ******************************************************************************
\
\       Name: sub_C24EA
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C24EA

 LDA L001A
 CLC
 ADC #&60
 STA Q
 LDA #&1F
 STA L0018

.C24F5

 JSR sub_C355A
 LDY #0
 STY T
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

 LDA #0
 STA L0086,X
 SEC
 SBC L0037,X
 STA L002C,X
 LDA L0018,X
 SBC L003A,X
 STA L002F,X
 BPL C2529
 DEC L0086,X
 LDA #0
 SEC
 SBC L002C,X
 LDA #0
 SBC L002F,X

.C2529

 CMP T
 BCC C252F
 STA T

.C252F

 DEX
 BPL C250D
 LDA T
 ASL A
 ASL A
 CMP #&06
 BCC C25AF

.P253A

 ASL L002C
 ROL L002F
 ASL L002D
 ROL L0030
 ASL L002E
 ROL L0031
 LSR L0017
 ASL A
 BCC P253A
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
 LDY #0

.P2569

 LDA (L000C),Y
 CMP #&7F
 BNE C25D7
 DEC L000C
 DEX
 BPL P2569
 LDA (L000C),Y
 CMP #&7F
 BEQ C25D7
 SEC
 ROR L0CCE

.C257E

 LDX #&02
 CLC
 BCC C2589

.P2583

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
 BPL P2583
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
 LDA #0
 SBC #&00
 STA L0180,Y
 DEC L0018
 BMI CRE15
 JMP C24F5

.CRE15

 RTS

\ ******************************************************************************
\
\       Name: sub_C25C3
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C25C3

 LDA #0
 STA P
 STA secondAxis
 LDA #&7F
 STA Q
 LDA #&1F
 STA L0026

.P25D1

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
 BPL P25D1
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

\ ******************************************************************************
\
\       Name: sub_C2624
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA T
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
 LDA T
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
 LDA #0
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

.P26E1

 DEY
 JSR sub_C2815
 CPY L0037
 BNE P26E1
 BEQ C2707

.C26EB

 LDA L0005
 EOR #&20
 STA L0005
 INC L0026
 LDY L0037

.P26F5

 DEY
 JSR sub_C2815
 CPY L0032
 BNE P26F5
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

.P270F

 INY
 JSR sub_C2815
 CPY L0038
 BNE P270F
 BEQ C2735

.C2719

 LDA L0005
 EOR #&20
 STA L0005
 INC L0026
 LDY L0038

.P2723

 INY
 JSR sub_C2815
 CPY L0033
 BNE P2723
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
 JSR sub_C2815
 LDY L0038
 JSR sub_C2815
 JSR sub_C292D

.C276B

 LDA #0
 STA L0005
 INC L0026
 LDY L0003
 JSR sub_C2815
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
 STA L5520+1,Y
 STA L5500+1,Y
 LDA L0003
 STA L0025
 JSR sub_C2A1B

.C27A9

 CLC
 RTS

\ ******************************************************************************
\
\       Name: L27AB
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L27AB

 EQUB &00, &01, &21, &20

\ ******************************************************************************
\
\       Name: sub_C27AF
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C27AF

 LDY L0032
 JSR sub_C2815
 BEQ C27E9
 CMP #&80
 BEQ C27D7

.P27BA

 LDA L0024
 STA L0032
 JSR sub_C280E
 BCS C27D2
 CMP #&81
 BEQ P27BA
 CMP #&80
 BEQ C27D2

.P27CB

 JSR sub_C280E
 BCS C27D2
 BEQ P27CB

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

.P27F8

 JSR sub_C2806
 BCS C27FF

.C27FD

 BEQ P27F8

.C27FF

 LDA L0024
 STA L0032
 RTS

.C2804

 SEC
 RTS

\ ******************************************************************************
\
\       Name: sub_C2806
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2806

 LDY L0024
 BEQ C2804
 DEY
 JMP sub_C2815

\ ******************************************************************************
\
\       Name: sub_C280E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C280E

 LDY L0024
 INY
 CPY #&20
 BEQ C2804

\ ******************************************************************************
\
\       Name: sub_C2815
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2815

 STY L0024
 STY L000F
 TYA
 ORA L0005
 STA L0021
 LDA #0
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
 LDA #0
 SEC
 SBC L0080
 STA L0080
 LDA #0
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
 LDA #0
 SEC
 SBC L0082
 STA L0082
 LDA #0
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

 STY T
 TXA
 ASL A
 ASL A
 ASL A
 AND #&E0
 ORA T
 TAY
 TXA
 AND #&03
 STA T
 CLC
 ADC #&04
 STA L005F
 LDA (L005E),Y
 LDX L0021
 STA L0180,X
 CMP #&C0
 BCC C28D6

.P28C4

 AND #&3F
 TAY
 LDA L0100,Y
 CMP #&40
 BCS P28C4
 LDA L0940,Y
 STA U
 JMP C28EE

.C28D6

 LSR A
 LSR A
 LSR A
 LSR A
 STA U
 TYA
 LSR A
 TAY
 ROL T
 LDA L3E80,Y
 LDY T
 AND L24E2,Y
 BNE C28EE
 STA L0180,X

.C28EE

 LDX L006E
 LDA #0
 SEC
 SBC L0A00,X
 STA L0080
 LDA U
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

\ ******************************************************************************
\
\       Name: sub_C292D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C292D

 LDA L0037
 STA L0025

.P2931

 CMP L0038
 BCS CRE16
 CMP L0003
 BCS C2943
 JSR sub_C29E2
 INC L0025
 LDA L0025
 JMP P2931

.C2943

 LDA L0038

.P2945

 SEC
 SBC #&01
 BMI CRE16
 STA L0025
 CMP L0037
 BCC CRE16
 CMP L0003
 BCC CRE16
 JSR sub_C29E2
 LDA L0025
 JMP P2945

.CRE16

 RTS

\ ******************************************************************************
\
\       Name: sub_C295D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C295D

 LDA L0010
 AND #&01
 EOR #&01

\ ******************************************************************************
\
\       Name: sub_C2963
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDA #0
 STA L0028
 STA L0029
 RTS

\ ******************************************************************************
\
\       Name: L298B
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L298B

 EQUB &0A, &02, &0C

\ ******************************************************************************
\
\       Name: L298E
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L298E

 EQUB &50, &40, &60

\ ******************************************************************************
\
\       Name: L2991
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2991

 EQUB &70, &70, &40

\ ******************************************************************************
\
\       Name: L2994
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2994

 EQUB &14, &14, &08

\ ******************************************************************************
\
\       Name: sub_C2997
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2997

 STA T
 LSR A
 STA L0007
 LDA #0
 ROR A
 STA L0028
 LDA L0007
 LSR A
 EOR #&80
 STA L0012
 LDA T
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
 LDA #0
 ROR A
 STA L0029
 LDA #&02
 STA L0010

.CRE17

 RTS

.C29C9

 LDA L0180,X
 AND #&0F
 STA L0A7F
 BEQ CRE17
 LDA L0025
 STA L093F
 LDA L0026
 STA L09BF
 LDY #&3F
 JMP sub_C5D33

\ ******************************************************************************
\
\       Name: sub_C29E2
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 BEQ CRE17
 CMP #&C0
 BCC C2A05
 PHA
 JSR sub_C2A1B
 PLA
 JMP sub_C219F

.C2A05

 AND #&0F
 BEQ sub_C2A1B
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

\ ******************************************************************************
\
\       Name: sub_C2A1B
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2A1B

 LDX #0
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
 LDA #0
 STA L003B
 JMP sub_C2A79

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
 JSR sub_C2A79
 LDA L0034
 EOR #&10
 TAX
 LDA L2CE3,X
 STA L0019
 LDA L003B
 ORA #&40
 STA L003B

\ ******************************************************************************
\
\       Name: sub_C2A79
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2A79

 LDY L0010
 CPY #&02
 BCS C2A93
 JSR sub_C2D36
 BCS C2A90
 JSR sub_C2299
 LDY L0010
 LDA L002C,Y
 CMP #&01
 BEQ CRE18

.C2A90

 JSR sub_C295D

.C2A93

 JSR sub_C2D36
 BCS CRE18
 JSR sub_C2299

.CRE18

 RTS

\ ******************************************************************************
\
\       Name: sub_C2A9C
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2A9C

 LDX #&50

.P2A9E

 JSR sub_C3194
 STA L5A00,X
 DEX
 BPL P2A9E
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
 LDA #0
 JSR sub_C2B53
 LDA #&01
 JSR sub_C2AF2
 LDA #&40
 JSR sub_C2B53
 LDA #&1E
 STA L0026

.P2AD1

 LDA #&1E
 STA L0024

.P2AD5

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
 BPL P2AD5
 DEC L0026
 BPL P2AD1
 LDA #&02
 JSR sub_C2AF2
 RTS

\ ******************************************************************************
\
\       Name: sub_C2AF2
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA T
 LDA (L005E),Y
 ASL A
 ASL A
 ASL A
 ASL A
 ORA T
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

 STA U
 LDA L0C08
 JSR Multiply8x8
 PLP
 JSR Absolute16Bit
 CLC
 ADC #&06
 BPL C2B39
 LDA #0

.C2B39

 CLC
 ADC #&01
 CMP #&0C
 BCC C2B42
 LDA #&0B

.C2B42

 JMP C2B48

.C2B45

 JSR sub_C3194

.C2B48

 STA (L005E),Y
 DEC L0024
 BPL C2AFC
 DEC L0026
 BPL C2AF8
 RTS

\ ******************************************************************************
\
\       Name: sub_C2B53
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2B53

 STA L0066
 LDA #&02
 STA L0015

.P2B59

 LDA #&1F
 STA L0026

.P2B5D

 LDA #0
 JSR sub_C2B90
 DEC L0026
 BPL P2B5D
 LDA #&1F
 STA L0024

.P2B6A

 LDA #&80
 JSR sub_C2B90
 DEC L0024
 BPL P2B6A
 DEC L0015
 BNE P2B59
 RTS

\ ******************************************************************************
\
\       Name: sub_C2B78
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C2B90
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2B90

 ORA L0066
 STA L001C
 LDX #&22

.P2B96

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
 STA L5A00,X
 DEX
 BPL P2B96
 BIT L001C
 BVC C2BFE
 LDX #&1F

.C2BB3

 LDA L5A01,X
 CMP L5A02,X
 BEQ C2BE8
 BCS C2BCD
 CMP L5A00,X
 BEQ C2BE8
 BCS C2BE8
 LDA L5A02,X
 CMP L5A00,X
 JMP C2BDA

.C2BCD

 CMP L5A00,X
 BEQ C2BE8
 BCC C2BE8
 LDA L5A00,X
 CMP L5A02,X

.C2BDA

 BCC C2BE2
 LDA L5A00,X
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

 LDX #0

.C2C00

 LDA #0
 STA U
 LDA L5A00,X
 CLC
 ADC L5A01,X
 BCC C2C10
 CLC
 INC U

.C2C10

 ADC L5A02,X
 BCC C2C18
 CLC
 INC U

.C2C18

 ADC L5A03,X
 BCC C2C20
 CLC
 INC U

.C2C20

 LSR U
 ROR A
 LSR U
 ROR A
 STA L5A00,X
 INX
 CPX #&20
 BCC C2C00
 LDA L5A2E,X
 STA rotm6+4,X

.C2C34

 LDX #&1F

.P2C36

 TXA
 BIT L001C
 BPL C2C40
 STA L0026
 JMP C2C42

.C2C40

 STA L0024

.C2C42

 JSR sub_C2B78
 LDA L5A00,X
 STA (L005E),Y
 DEX
 BPL P2C36
 RTS

\ ******************************************************************************
\
\       Name: sub_C2C4E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2C4E

 JSR sub_C2B78
 AND #&0F
 STA S
 INC L0024
 JSR sub_C2B78
 AND #&0F
 STA V
 INC L0026
 JSR sub_C2B78
 AND #&0F
 STA U
 DEC L0024
 JSR sub_C2B78
 AND #&0F
 STA T
 DEC L0026
 LDA S
 CMP V
 BEQ C2CB1
 CMP T
 BEQ C2C92
 LDA U
 CMP V
 BEQ C2C85

.C2C82

 LDX #&0C
 RTS

.C2C85

 CMP T
 BNE C2C9C
 LDX #&02
 CMP S
 BCS CRE19
 LDX #&0B

.CRE19

 RTS

.C2C92

 LDA U
 CMP V
 BEQ C2CA8
 CMP T
 BEQ C2C9F

.C2C9C

 LDX #&04
 RTS

.C2C9F

 LDX #&0E
 CMP V
 BCC CRE20
 LDX #&07

.CRE20

 RTS

.C2CA8

 LDX #&05
 CMP T
 BCC CRE21
 LDX #&0D

.CRE21

 RTS

.C2CB1

 CMP T
 BEQ C2CD1
 LDA U
 CMP T
 BEQ C2CC8
 CMP V
 BNE C2C82
 LDX #&06
 CMP T
 BCC CRE22
 LDX #&0F

.CRE22

 RTS

.C2CC8

 LDX #&01
 CMP V
 BCC CRE23
 LDX #&09

.CRE23

 RTS

.C2CD1

 CMP U
 BEQ C2CDC
 LDX #&0A
 BCC CRE24
 LDX #&03

.CRE24

 RTS

.C2CDC

 LDX #0
 RTS

\ ******************************************************************************
\
\       Name: L2CDF
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2CDF

 EQUB &01, &21, &FF, &1F

\ ******************************************************************************
\
\       Name: L2CE3
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2CE3

 EQUB &3C, &04, &04, &08, &08, &08, &04, &08
 EQUB &00, &04, &08, &04, &04, &08, &08, &04
 EQUB &00, &00, &08, &04, &08, &00, &08, &04
 EQUB &00, &00, &04, &08, &04, &00, &04, &08

\ ******************************************************************************
\
\       Name: L2D03
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L2D03

 EQUB &00, &00, &00, &00, &00, &00, &01, &01
 EQUB &00, &00, &00, &00, &00, &00, &01, &01

\ ******************************************************************************
\
\       Name: sub_C2D36
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA T
 LDA L5500,X
 ADC L0011
 ASL T
 ROL A
 ROL T
 ROL A
 ROL T
 ROL A
 STA L54A0,X
 LDA T
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

 LDA #0
 STA L006C
 LDY L0017

.C2D99

 LDA (L003C),Y
 TAX
 LDA L0BA0,X
 CLC
 ADC L0029
 STA T
 LDA L5500,X
 ADC L0011
 CMP #&20
 BCS C2D5D
 ASL T
 ROL A
 ASL T
 ROL A
 ASL T
 ROL A
 STA L54A0,X
 DEY
 BPL C2D99

.C2DBC

 LDA #0
 STA L0006
 STA L0031
 STA L001E
 LDA #&FF
 STA L0004
 STA L0030
 STA L007F
 LDY #0

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
 STA V
 INC L0002
 STX T
 STY U
 LDX U
 LDY T
 LDA #0
 SEC
 SBC L000C
 STA L000C
 LDA #0
 SBC V

.C2E03

 STA V
 BIT L006C
 BVC C2E1C
 LDA L0B40,Y
 ORA L0B40,X
 BEQ C2E1C
 LDA V
 BNE C2E19
 LDA L000C
 BEQ C2E56

.C2E19

 JMP C2FCC

.C2E1C

 LDA V
 BEQ C2E2B
 LDA #0
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
 LDA #0
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
 STA L5A00,Y
 LDA L0031
 STA L5B00,Y
 LDA #0
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

.CRE25

 RTS

\ ******************************************************************************
\
\       Name: sub_C2EAE
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C2EAE

 LDA L003F
 BMI C2EC2
 BNE CRE25
 LDA L0016
 CMP L0051
 BCS CRE25
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
 BMI CRE25
 BNE C2EDA
 LDA L001A
 CMP L0052
 BCC CRE25
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

.P2F22

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
 BNE P2F22

.C2F34

 STY L007F

.CRE26

 RTS

.C2F37

 LDY #0
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

.C2F6E

L2F6F = C2F6E+1

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

.P2F8E

 ADC L000D
 BCC C2F95
 SBC L000C

.C2F94

 INX

.C2F95

 DEC L2F2A
 BEQ C2FA0
 DEY
 BNE P2F8E
 JMP CRE26

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
 JMP CRE26

.C2FC6

 DEC L2F78
 JMP C2F7A

.C2FCC

 STX L000E
 LDA #0
 STA L0040
 LDA L54A0,Y
 SEC
 SBC L54A0,X
 STA T
 LDA L0B40,Y
 SBC L0B40,X
 STA L000A
 JSR Absolute16Bit
 STA U
 ORA V
 BEQ C2FFA

.C2FEC

 LSR V
 ROR L000C
 LSR U
 ROR T
 SEC
 ROL L0040
 LSR A
 BNE C2FEC

.C2FFA

 LDX L000C
 CPX #&FF
 BEQ C2FEC
 LDX T
 CPX #&FF
 BEQ C2FEC
 LDA U
 BIT L000A
 JSR Absolute16Bit
 STA L0043
 LDA T
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
 LDA #0
 SEC
 SBC L000D
 STA L000D
 LDX #&E8
 LDA #0
 LDY #&E6
 JMP C30AA

.C30A4

 LDX #&CA
 LDA #&FF
 LDY #&C6

.C30AA

 STY T
 STA V
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
 LDA T
 STA C310A
 LDY L000C
 TYA
 LSR A
 EOR #&FF
 CLC
 INY
 STY U
 LDX L0018
 JSR sub_C316E
 JMP C30E9

.P30DD

 ADC L000D
 BCC C30E9
 SBC L000C

.C30E3

 INX
 CPX V
 CLC
 BEQ C310A

.C30E9

L30EA = C30E9+1
L30EB = C30E9+2

 STX L5A00
 DEC L30EA
 BEQ C30F8

.C30F1

 DEC U
 BNE P30DD
 JMP CRE26

.C30F8

 DEC L003E
 BPL C30FF
 JMP CRE26

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
 LDA T
 STA C3164
 LDY L000D
 TYA
 LSR A
 EOR #&FF
 CLC
 INY
 STY U
 LDX L0018
 JSR sub_C316E
 JMP C3148

.C3137

 INX
 CPX V
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

 STX L5A00
 DEC U
 BNE C3137
 JMP CRE26

.C3152

 DEC L003E
 BPL C3159
 JMP CRE26

.C3159

 BNE C3148
 DEC L3149
 JSR sub_C316E
 JMP C3148

.C3164

 INC L0041
 JSR sub_C316E
 JMP C313D

\ ******************************************************************************
\
\       Name: sub_C316C
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C316C

 BCC sub_C3194

\ ******************************************************************************
\
\       Name: sub_C316E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDY #0
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

\ ******************************************************************************
\
\       Name: sub_C3194
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3194

 STY L31BC
 LDY #&08

.P3199

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
 BNE P3199
 LDY L31BC
 LDA L0C7F
 RTS

\ ******************************************************************************
\
\       Name: L31BC
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L31BC

 EQUB &00

\ ******************************************************************************
\
\       Name: sub_C31BD
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C31BD

 CLC
 ADC #&30

\ ******************************************************************************
\
\       Name: sub_C31C0
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C31C0

 CMP #&30
 BNE C31C6
 LDA #&4F

.C31C6

 BIT L0C60
 BMI DrawLetter3D
 JMP sub_C5744

\ ******************************************************************************
\
\       Name: DrawLetter3D
\       Type: Subroutine
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.DrawLetter3D

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
 CMP rotm8-1,X
 BCS C3204
 JSR sub_C316C

.C3204

 ASL L0C10,X
 LDA L0C49
 STA L0024
 LDA #&04
 STA L0015

.P3210

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
 BNE P3210
 INC L0026
 DEX
 BMI C3239
 BNE C3204
 LDA #0
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

\ ******************************************************************************
\
\       Name: L3248
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3248

 EQUB &20, &27, &28, &29

\ ******************************************************************************
\
\       Name: DrawTitleScreen
\       Type: Subroutine
\   Category: Title screen
\    Summary: Draw the title screen or the screen showing the landscape code
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Determines the type of screen to draw:
\
\                         * If bit 7 = 0 then draw the title screen
\
\                         * If bit 7 = 1 then draw the landscape code screen
\
\ ******************************************************************************

.DrawTitleScreen

 STA screenType         \ Store the screen type in A in screenType, so we can
                        \ refer to it below

 LDA #&80               \ Set L09FF = &80 ???
 STA L09FF

 LDA #&E0               \ Set L0A3F = &E0 ???
 STA L0A3F

 LDA #2                 \ Set L097F = 2 ???
 STA L097F

 SEC                    \ Set bit 7 of L0C4B ???
 ROR L0C4B

 LDA #0
 JSR sub_C2AF2

 BIT screenType         \ If bit 7 of the screen type is clear, jump to titl1 to
 BPL titl1              \ print "THE SENTINEL" on the title screen

                        \ If we get here then bit 7 of the argument is set, so
                        \ we now draw the landscape code

 JSR DrawLandscapeCode  \ Draw the landscape code in 3D ???

 LDX #3

 LDA #0                 \ Set A = 0 so the call to DrawObject draws a robot on
                        \ the right of the screen

 BEQ titl3              \ Jump to titl3 to ??? (this BEQ is effectively a JMP as
                        \ A is always zero)

.titl1

 LDX #0                 \ We now look through all the characters in the title
                        \ text, drawing each one in turn, so set X as a
                        \ character index

.titl2

 LDA titleText,X        \ Set A to the X-th character in the title text

 JSR DrawLetter3D       \ Draw the character in A in 3D ???

 INX                    \ Increment the character index

 CPX #15                \ Loop back until we have drawn all 15 characters in the
 BCC titl2              \ title text

 LDX #1

 LDA #5                 \ Set A = 5 so the call to DrawObject draws the Sentinel
                        \ on the right of the screen

.titl3

 LDY #1

 JSR DrawObject         \ Draw the Sentinel on the title screen or the robot on
                        \ the landscape code screen ???

 LSR L0C4B              \ Clear bit 7 of L0C4B ???

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: screenType
\       Type: Variable
\   Category: Title screen
\    Summary: A variable that determines whether we are drawing the title screen
\             or the landscape code screen in the DrawTitleScreen routine
\
\ ******************************************************************************

.screenType

 EQUB 0

\ ******************************************************************************
\
\       Name: titleText
\       Type: Variable
\   Category: Title screen
\    Summary: The text to draw on the title screen
\
\ ******************************************************************************

.titleText

 EQUB &84, &D5
 EQUS "THE"
 EQUB &80, &C7
 EQUS "SENTINEL"

\ ******************************************************************************
\
\       Name: sub_C329F
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C329F

 STA T
 JSR sub_C5E20
 LDY #&07
 LDA #&20

.P32A8

 STA L0CF0,Y
 DEY
 BPL P32A8
 JSR sub_C3303

.P32B1

 LDY #0

.C32B3

 JSR sub_C5E0A
 CMP #&0D
 BEQ CRE27
 CMP #&30
 BCC C32B3
 CMP #&7F
 BCC C32DB
 BNE C32B3
 DEY
 BMI P32B1
 LDX #0

.P32C9

 LDA L0CF1,X
 STA L0CF0,X
 INX
 CPX #&07
 BNE P32C9
 LDA #&20
 STA L0CF7
 BNE C32FC

.C32DB

 CMP #&3A
 BCS C32B3
 CPY T
 BNE C32EB
 LDA #&07
 JSR OSWRCH
 JMP C32B3

.C32EB

 INY
 PHA
 LDX #&06

.P32EF

 LDA L0CF0,X
 STA L0CF1,X
 DEX
 BPL P32EF
 PLA
 STA L0CF0

.C32FC

 JSR sub_C3303
 JMP C32B3

.CRE27

 RTS

\ ******************************************************************************
\
\       Name: sub_C3303
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3303

 SEC
 ROR L0C0F
 LDX T
 DEX

.P330A

 LDA L0CF0,X
 JSR sub_C31C0
 DEX
 BPL P330A
 LDX T
 LDA #&08

.P3317

 JSR sub_C31C0
 DEX
 BNE P3317
 LSR L0C0F
 RTS

\ ******************************************************************************
\
\       Name: sub_C3321
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3321

 LDY #0
 LDX #0

.P3325

 JSR sub_C333E
 STA T
 INY
 JSR sub_C333E
 ASL A
 ASL A
 ASL A
 ASL A
 ORA T
 STA L0CF0,X
 INX
 INY
 CPY #&08
 BNE P3325
 RTS

\ ******************************************************************************
\
\       Name: sub_C333E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C3356
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3356

 PHA
 LSR A
 LSR A
 LSR A
 LSR A
 JSR sub_C31BD
 PLA
 AND #&0F
 JMP sub_C31BD

\ ******************************************************************************
\
\       Name: sub_C3364
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3364

 JSR sub_C3194
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

\ ******************************************************************************
\
\       Name: L3380
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3380

 EQUB &00

\ ******************************************************************************
\
\       Name: DrawLandscapeCode
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.DrawLandscapeCode

 LDA #&80
 STA L0C60
 JSR DrawLetter3D
 LDA #&C7
 JSR DrawLetter3D
 LSR L0CE6
 LDX L0CE6

.P3394

 JSR sub_C3364
 CPX #&04
 BCS C339E
 JSR sub_C3356

.C339E

 DEX
 BPL P3394
 STX L0CE6
 JSR sub_C3194
 LSR L0C60
 RTS

\ ******************************************************************************
\
\       Name: sub_C33AB
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C33AB

 LDA L0CFE
 JSR sub_C3356
 LDA L0CFD
 JMP sub_C3356

\ ******************************************************************************
\
\       Name: sub_C33B7
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C33DE
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C33F0
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C33F0

 LDA L0CFE
 LSR A
 LSR A
 LSR A
 LSR A
 CLC
 ADC #&02
 STA T

.P33FC

 JSR sub_C3194
 LDY #&07
 ASL A
 PHP
 BEQ C340B
 LDY #&FF

.P3407

 INY
 ASL A
 BCC P3407

.C340B

 TYA
 PLP
 BCC C3411
 EOR #&FF

.C3411

 CLC
 ADC T
 CMP #&08
 BCS P33FC
 ADC #&01
 RTS

\ ******************************************************************************
\
\       Name: sub_C341B
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C341B

 JSR sub_C3194
 PHA
 AND #&07
 STA T
 PLA
 LSR A
 LSR A
 AND #&1E
 LSR A
 ADC T
 RTS

\ ******************************************************************************
\
\       Name: sub_C342C
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C342C

 LDA #0
 LDX L0C0A
 BEQ CRE28

.P3433

 CLC
 ADC #&01
 DEX
 BNE P3433

.CRE28

 RTS

\ ******************************************************************************
\
\       Name: sub_C343A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C343A

 STX L5904
 STY L590C

\ ******************************************************************************
\
\       Name: sub_C3440
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3440

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
 BNE sub_C3459
 JSR sub_C3459
 LDA #0

\ ******************************************************************************
\
\       Name: sub_C3459
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3459

 ASL A
 ASL A
 ASL A
 ADC #&00
 TAX
 LDA #&07
 BNE C3473

\ ******************************************************************************
\
\       Name: sub_C3463
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L3478
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3478

 EQUB &00

\ ******************************************************************************
\
\       Name: L3479
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3479

 EQUB &01, &01, &04, &02, &02, &03, &01

\ ******************************************************************************
\
\       Name: sub_C3480
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3480

 LDA L0CE4
 BMI CRE29
 LDA L34D4
 LDX L0CEB
 BEQ C3498
 DEX
 BNE CRE29
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
 BCS sub_C3480
 STA L34D4
 TAY
 BEQ C34AD
 LDY #&08

.C34AD

 STY L595F
 STY L5951
 LDY #&0B

.P34B5

 LDX L34D5,Y
 CPX #&4F
 BNE C34C0
 EOR #&FF
 ADC #&00

.C34C0

 STA L5928,X
 DEY
 BPL P34B5
 LDA #&0C
 STA L0CDF
 LDA #&05
 JSR sub_C3440
 JMP sub_C3480

.CRE29

 RTS

\ ******************************************************************************
\
\       Name: L34D4
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L34D4

 EQUB &58

\ ******************************************************************************
\
\       Name: L34D5
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L34D5

 EQUB &4F, &0C, &0D, &1A, &1B, &24, &28, &36
 EQUB &40, &44, &4E, &52

\ ******************************************************************************
\
\       Name: sub_C34E1
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C34E1

 LDA L0CEB
 BMI CRE30
 CMP #&02
 BNE CRE30
 ROR L0C72
 LDA #&08
 JSR sub_C162D
 JSR sub_C3548

.P34F5

 LDA L0CEB
 CMP #&03
 BNE P34F5
 LDA #0
 JSR sub_C162D
 LSR L0C72

.CRE30

 RTS

\ ******************************************************************************
\
\       Name: sub_C3505
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3505

 LDX L0CE7
 BMI CRE31
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
 JMP sub_C3505

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
 JMP sub_C3440

.C3544

 STA L0CE7

.CRE31

 RTS

\ ******************************************************************************
\
\       Name: sub_C3548
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3548

 LDX #&07

.P354A

 JSR sub_C3555
 DEX
 CPX #&04
 BCS P354A
 RTS

\ ******************************************************************************
\
\       Name: sub_C3553
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3553

 LDX #&04

\ ******************************************************************************
\
\       Name: sub_C3555
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3555

 LDA #21                \ osbyte_flush_buffer
 JMP OSBYTE

\ ******************************************************************************
\
\       Name: sub_C355A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C355A

 LDA L0CDF
 BNE CRE32
 LDA L0C73
 CMP #&04
 BEQ C358E
 CMP #&03
 BEQ C358B
 CMP #&06
 BNE CRE32
 LDX #&07
 LDY L0C74
 CPY #&50
 BCC CRE32
 LDA #&06
 JSR sub_C343A
 JSR sub_C3194
 AND #&03
 CLC
 ADC #&01
 STA L0CDF
 DEC L0C74

.CRE32

 RTS

.C358B

 JMP sub_C3505

.C358E

 LDA #&32
 STA L0CDF
 LDA #&22
 STA L5914
 LDA #&03
 STA L5912
 LDA #&04
 JSR sub_C3440
 RTS

 EQUB &B9

\ ******************************************************************************
\
\       Name: sub_C35A4
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C35A4

 LDA #&83               \ Set the palette to the first set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, cyan, yellow)

 JSR sub_C5E07

 LSR L0CFC              \ Clear bit 7 of L0CFC ???

.C35AF

 JSR sub_C3548
 LDA L0C64
 BPL C35BA
 JMP MainLoop

.C35BA

 LDA L0C4E
 BMI C361D

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 LDA #0
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

.P35FE

 JSR sub_C355A
 LDA L0CE7
 BPL P35FE

 LDA #&83               \ Set the palette to the first set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, cyan, yellow)

 LDA L0CDE
 BPL C3666
 STA L0C4E
 LDA #&06
 STA L0C73
 LDA #&05
 JSR sub_C5F24

.C361D

 JSR ResetVariables     \ Reset all the game's main variables

 LDY L0CFE
 LDX L0CFD
 JSR sub_C33B7
 JMP main4

.C362C

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 LDX #&03
 LDA #0
 STA L0C73

.P3638

 STA L0C7C,X
 DEX
 BPL P3638

 JSR ResetVariables2    \ ???

 JSR sub_C1A7E

 LDA #&87               \ Set the palette to the second set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, red, yellow)

 LDA #&0A
 STA L0CDF
 LDA #&42
 JSR sub_C5FF6

.P3653

 JSR sub_C355A
 LDA L0CE7
 BPL P3653
 LDX #&06
 JSR sub_C36AD
 JSR sub_C5E07

.C3663

 JMP MainLoop

.C3666

 JSR sub_C1264
 BCC C366E
 JMP C35AF

.C366E

 LDA L0009
 STA L0008
 LDA #0
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

.P3692

 LDA L0CC1
 BNE P3692
 BEQ C3666

\ ******************************************************************************
\
\       Name: sub_C3699
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3699

 LDA #0
 STA L0C05

.P369E

 LDA #0
 JSR sub_C373A
 LDA L0C05
 CMP #&28
 BCC P369E
 JMP sub_C3AEB

\ ******************************************************************************
\
\       Name: sub_C36AD
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C36AD

 LDY L5784,X

.P36B0

 LDA L5796,Y
 CMP #&FF
 BEQ CRE33
 JSR sub_C33DE
 INY
 JMP P36B0

.CRE33

 RTS

\ ******************************************************************************
\
\       Name: L36BF
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L36BF

 EQUB &77, &BB, &DD, &EE, &88, &44, &22, &11

\ ******************************************************************************
\
\       Name: sub_C36C7
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C36C7

 LDA #0
 STA L0C05
 JSR sub_C373A
 LDA L0C0A
 STA L0015

.P36D4

 LDA L0015
 CMP #&0F
 BCC C36EB
 SBC #&0F
 STA L0015
 LDA #&06
 JSR sub_C373A
 LDA #0
 JSR sub_C373A
 JMP P36D4

.C36EB

 LDA L0015
 CMP #&03
 BCC C3702
 SBC #&03
 STA L0015
 LDA #&01
 JSR sub_C373A
 LDA #0
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

 LDA #0
 JSR sub_C373A
 LDA L0C05
 CMP #&1D
 BCC C3710
 LDA #&07
 JSR sub_C373A

.P3721

 LDA #&08
 JSR sub_C373A
 LDA L0C05
 CMP #&26
 BCC P3721
 LDA #&09
 JSR sub_C373A
 LDA #0
 JSR sub_C373A
 JMP sub_C3AEB

\ ******************************************************************************
\
\       Name: sub_C373A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

.P3755

 LDA L58B0,X
 STA (P),Y
 DEX
 DEY
 BPL P3755
 INC L0C05
 PLA
 RTS

.C3763

 JMP (irq1Address)      \ Jump to the original address from IRQ1V to pass
                        \ control to the next interrupt handler

\ ******************************************************************************
\
\       Name: IRQHandler
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.IRQHandler

 SEI
 LDA SHEILA+&6D         \ user_via_ifr
 AND #&40
 BEQ C3763
 STA SHEILA+&6D         \ user_via_ifr
 LDA L00FC

 PHA                    \ Store A, X and Y on the stack so we can preserve them
 TXA                    \ across calls to the interrupt handler
 PHA
 TYA
 PHA

 CLD
 DEC L0CDF
 BPL C3781
 INC L0CDF

.C3781

 LDA L0CFC              \ If bit 7 of L0CFC is set, jump to C37CB to skip the
 BMI C37CB              \ following and return from the interrupt handler ???

 LDA L0C4E
 BMI C37C3
 LDA L0C72
 BMI C37B1
 LDA L0CC1
 BEQ C379B
 JSR sub_C37D1
 JSR sub_C3AEB

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

.P37BA

 STA L0CE8,X
 DEX
 BPL P37BA
 JMP C37CB

.C37C3

 LDA L0C4D
 BPL C37CB
 JSR sub_C56D9

.C37CB

 PLA                    \ Restore A, X and Y from the stack
 TAY
 PLA
 TAX
 PLA

 RTI                    \ Return from the interrupt handler

\ ******************************************************************************
\
\       Name: sub_C37D1
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C3832
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 JMP CRE34

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

.CRE34

 RTS

\ ******************************************************************************
\
\       Name: sub_C38B2
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C38B2

 LDY #0
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

\ ******************************************************************************
\
\       Name: L38DC
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38DC

 EQUB &38, &00, &00, &C0

\ ******************************************************************************
\
\       Name: L38E0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38E0

 EQUB &01, &00, &00, &1C

\ ******************************************************************************
\
\       Name: L38E4
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38E4

 EQUB &08, &F8, &C0, &40

\ ******************************************************************************
\
\       Name: L38E8
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38E8

 EQUB &00, &FF, &FE, &01

\ ******************************************************************************
\
\       Name: L38EC
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38EC

 EQUB &3E, &3F, &49, &3D

\ ******************************************************************************
\
\       Name: L38F0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38F0

 EQUB &F8, &80, &00, &C0

\ ******************************************************************************
\
\       Name: L38F4
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L38F4

 EQUB &14, &F8, &04, &F4

\ ******************************************************************************
\
\       Name: sub_C38F8
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C38F8

 STA L0CD1

\ ******************************************************************************
\
\       Name: sub_C38FB
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C38FB

 LDA L38F0,Y
 STA L2090
 LDA L38EC,Y
 STA L2091
 RTS

\ ******************************************************************************
\
\       Name: sub_C3908
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3908

 LDA #0
 JSR sub_C2963
 LDY #0

.P390F

 LDA L391A,Y
 STA L0051
 LDA L391C,Y
 STA L0052
 RTS

\ ******************************************************************************
\
\       Name: L391A
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L391A

 EQUB &F0, &F0

\ ******************************************************************************
\
\       Name: L391C
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L391C

 EQUB &B0, &30

\ ******************************************************************************
\
\       Name: sub_C391E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C391E

 LDA #&02
 JSR sub_C2963

\ ******************************************************************************
\
\       Name: sub_C3923
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3923

 LDY #1

 BNE P390F              \ Jump to P390F to ??? (this BNE is effectively a JMP as
                        \ Y is never zero

\ ******************************************************************************
\
\       Name: sub_C3927
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3927

 JSR sub_C3934
 LDA L0009
 BPL C3931
 JSR sub_C396B

.C3931

 JMP sub_C39D9

\ ******************************************************************************
\
\       Name: sub_C3934
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3934

 LDX L0CE8
 BMI CRE35
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
 JMP CRE35

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

.CRE35

 RTS

\ ******************************************************************************
\
\       Name: sub_C396B
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C396B

 LDX L000B
 LDY L0140,X
 LDX L0CEA
 BMI CRE36
 CPX #&02
 BNE C3997
 LDA L0CC7
 CLC
 ADC #&01
 CMP #&A0
 BCC C398D
 CPY L1147
 BEQ CRE36
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
 BEQ CRE36
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

.CRE36

 RTS

\ ******************************************************************************
\
\       Name: sub_C39D9
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C39D9

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

 JMP CRE37

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

.CRE37

 RTS

\ ******************************************************************************
\
\       Name: L3A8A
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3A8A

 EQUB &80, &40, &20, &10

\ ******************************************************************************
\
\       Name: L3A8E
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3A8E

 EQUB &00, &00, &00, &FB, &02, &02, &02, &02
 EQUB &02, &FB, &00, &00

\ ******************************************************************************
\
\       Name: L3A9A
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3A9A

 EQUB &00, &02, &02, &01, &00, &00, &00, &00
 EQUB &00, &01, &02, &02, &80

\ ******************************************************************************
\
\       Name: sub_C3AA7
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3AA7

 LDX L0CC9
 BEQ CRE38
 DEX
 LDY #0

.P3AAF

 LDA L49C1,X
 STA L002A
 LDA L3DF3,X
 STA L002B
 LDA L3DE7,X
 STA (L002A),Y
 DEX
 BPL P3AAF
 LDX #0
 STX L0CC9

.CRE38

 RTS

\ ******************************************************************************
\
\       Name: L3AC7
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3AC7

 EQUB &08, &F8, &FF, &01, &C7, &39

\ ******************************************************************************
\
\       Name: L3ACD
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3ACD

 EQUB &00, &FF, &FF, &00, &FE, &01

\ ******************************************************************************
\
\       Name: sub_C3AD3
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: sub_C3AEB
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3AEB

 LDA #&5A
 STA L0063
 LDA #0
 STA L0062
 LDA L0CCB
 STA L0065
 LDA L0CCA
 STA L0064
 JMP C3889

\ ******************************************************************************
\
\       Name: arctanLo
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Table for arctan values when calculating yaw angles (low byte)
\
\ ******************************************************************************

.arctanLo

 FOR I%, 0, 256

  EQUB LO(INT(0.5 + 32* ATN(I% / 256) * 256 / ATN(1)))

 NEXT

\ ******************************************************************************
\
\       Name: arctanHi
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Table for arctan values when calculating yaw angles (high byte)
\
\ ******************************************************************************

.arctanHi

 FOR I%, 0, 256

  EQUB HI(INT(0.5 + 32* ATN(I% / 256) * 256 / ATN(1)))

 NEXT

\ ******************************************************************************
\
\       Name: L3D02
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: ???
\
\ ******************************************************************************

.L3D02

 EQUB 0

 FOR I%, 1, 128

  EQUB INT(0.5 + 512 * (1 - COS(ATN(I% / 128))) / SIN(ATN(I% / 128)))

  \ Can also be:
  \ EQUB INT(0.5 + 512 * TAN(ATN(I% / 128) / 2))

 NEXT

\ ******************************************************************************
\
\       Name: L3D83
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3D83

 EQUB &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0, &00, &40, &80, &C0
 EQUB &00, &40, &80, &C0

.L3DAC

 EQUB &A0, &E0, &20, &60
 EQUB &A0, &E0, &20, &60, &A0

.L3DB5

 EQUB &60, &62, &63
 EQUB &64, &65, &67, &68, &69, &6A, &6C, &6D
 EQUB &6E, &6F, &71, &72, &73, &74, &76, &77
 EQUB &78, &79, &7B, &7C, &7D, &7E, &3F, &40
 EQUB &41, &42, &44, &45, &46, &47, &49, &4A
 EQUB &4B, &4C, &4E, &4F, &50, &51

.L3DDE

 EQUB &3F, &40
 EQUB &42, &43, &44, &45, &47, &48, &49

.L3DE7

 EQUB &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00

.L3DF3

 EQUB &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &08

\ ******************************************************************************
\
\       Name: L3E00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L3E00

 EQUB &00, &00, &00, &00, &07, &03, &01, &00
 EQUB &70, &30, &10, &00, &77, &33, &11, &00
 EQUB &08, &04, &02, &01, &0F, &07, &03, &01
 EQUB &78, &34, &12, &01, &7F, &37, &13, &01
 EQUB &80, &40, &20, &10, &87, &43, &21, &10
 EQUB &F0, &70, &30, &10, &F7, &73, &31, &10
 EQUB &88, &44, &22, &11, &8F, &47, &23, &11
 EQUB &F8, &74, &32, &11

.L3E3C

 EQUB &FF, &77, &33, &11
 EQUB &00, &00, &00, &00, &00, &08, &0C, &0E
 EQUB &00, &80, &C0, &E0, &00, &88, &CC, &EE
 EQUB &08, &04, &02, &01, &08, &0C, &0E, &0F
 EQUB &08, &84, &C2, &E1, &08, &8C, &CE, &EF
 EQUB &80, &40, &20, &10, &80, &48, &2C, &1E
 EQUB &80, &C0, &E0, &F0, &80, &C8, &EC, &FE
 EQUB &88, &44, &22, &11, &88, &4C, &2E, &1F
 EQUB &88, &C4, &E2, &F1

.L3E7C

 EQUB &88, &CC, &EE, &FF

.L3E80

 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

.L3EC0

 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF

\ ******************************************************************************
\
\       Name: sub_C3F00
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C3F00

 SEC                    \ Set bit 7 of L0CFC ???
 ROR L0CFC

\ ******************************************************************************
\
\       Name: ConfigureMachine
\       Type: Subroutine
\   Category: Setup
\    Summary: Configure the custom screen mode, set the break handler to clear
\             memory, move code, reset timers and set the interrupt handler
\
\ ------------------------------------------------------------------------------
\
\ The custom screen mode is based on screen mode 5, but with only 25 character
\ rows rather than 32. This gives the game screen a letterbox appearance.
\
\ The custom mode has a vertical resolution of 25 * 8 = 200 pixels, compared to
\ the 256 pixels of standard mode 5. The horizontal resolution is the same at
\ 160 pixels.
\
\ Screen memory for the custom mode runs from &6000 to &7F3F, with four pixels
\ per byte and four colours per pixel.
\
\ ******************************************************************************

.ConfigureMachine

 LDA #4                 \ Call OSBYTE with A = 4, X = 1 and Y = 0 to disable
 LDY #0                 \ cursor editing
 LDX #1
 JSR OSBYTE

 LDA #144               \ Call OSBYTE with A = 144, X = 0 and Y = 0 to switch
 LDX #0                 \ interlace on
 LDY #0
 JSR OSBYTE

 LDA #22                \ Switch to screen mode 5 with the following VDU
 JSR OSWRCH             \ command:
 LDA #5                 \
 JSR OSWRCH             \   VDU 22, 5

 SEI                    \ Disable interrupts so we can update the 6845 registers

 LDA #6                 \ Set 6845 register R6 = 25
 STA SHEILA+&00         \
 LDA #25                \ This is the "vertical displayed" register, which sets
 STA SHEILA+&01         \ the number of displayed character rows to 25. For
                        \ comparison, this value is 32 for standard mode 5, but
                        \ we claw back seven rows to create the game's letterbox
                        \ screen mode

 LDA #7                 \ Set 6845 register R7 = 32
 STA SHEILA+&00         \
 LDA #32                \ This is the "vertical sync position" register, which
 STA SHEILA+&01         \ determines the vertical sync position with respect to
                        \ the reference, programmed in character row times. For
                        \ comparison this is 34 for mode 5, but it needs to be
                        \ adjusted for our custom screen's vertical sync

 LDA #10                \ Set 6845 register R10 = %00100000
 STA SHEILA+&00         \
 LDA #%00100000         \ This is the "cursor start" register, and bits 5 and 6
 STA SHEILA+&01         \ define the "cursor display mode", as follows:
                        \
                        \   * %00 = steady, non-blinking cursor
                        \
                        \   * %01 = do not display a cursor
                        \
                        \   * %10 = fast blinking cursor (blink at 1/16 of the
                        \           field rate)
                        \
                        \   * %11 = slow blinking cursor (blink at 1/32 of the
                        \           field rate)
                        \
                        \ We can therefore turn off the cursor completely by
                        \ setting cursor display mode %01, with bit 6 of R10
                        \ clear and bit 5 of R10 set

 CLI                    \ Re-enable interrupts

 LDA #151               \ Call OSBYTE with A = 151, X = &42 and Y = %11111111 to
 LDX #&42               \ write the value %11111111 to SHEILA+&42
 LDY #%11111111         \
 JSR OSBYTE             \ This sets the direction of all eight ports of the 6522
                        \ System VIA to output by setting the corresponding bits
                        \ in the Data Direction Register B (SHEILA &42)

 LDA #151               \ Call OSBYTE with A = 151, X = &40 and Y = %00000101 to
 LDX #&40               \ write the value %00000101 to SHEILA+&40
 LDY #%00000101         \
 JSR OSBYTE             \ Writing a value of %vaaa to SHEILA+&40 writes to the
                        \ System VIA's addressable latch, setting latch address
                        \ %aaa to value v
                        \
                        \ This therefore sets address %101 to 1, which is
                        \ address B5 in the System VIA
                        \
                        \ We now we set B4 as well

 LDA #151               \ Call OSBYTE with A = 151, X = &40 and Y = %00001100 to
 LDX #&40               \ write the value %00001100 to SHEILA+&40
 LDY #%00001100         \
 JSR OSBYTE             \ Writing a value of %vaaa to SHEILA+&40 writes to the
                        \ System VIA's addressable latch, setting latch address
                        \ %aaa to value v
                        \
                        \ This therefore sets address %100 to 0, which is
                        \ address B4 in the System VIA
                        \
                        \ B4 and B5 in the System VIA control the address of the
                        \ start of screen memory and the screen size, so this
                        \ sets screen memory to &6000 and screen size to 8K (see
                        \ page 429 of the "Advanced User Guide for the BBC
                        \ Micro" by Bray, Dickens and Holmes for details)

 LDA #0                 \ Call OSBYTE with A = 0 and X = 255 to fetch the
 LDX #255               \ operating system version into X
 JSR OSBYTE

 CPX #0                 \ If X = 0 then this is either a BBC Micro running an
 BEQ setp1              \ operating system version of 1.00 or earlier, or it's
                        \ an Electron, so in either case jump to setp1 to skip
                        \ the following

                        \ If we get here then this is not an Electron or an
                        \ early operating system, so it must be a BBC Micro with
                        \ MOS 1.20 or later, or a BBC Master

 LDA #200               \ Call OSBYTE with A = 200, X = 2 and Y = 0 to set the
 LDX #2                 \ normal action for the ESCAPE key and clear memory if
 LDY #0                 \ the BREAK key is pressed
 JSR OSBYTE

 JMP setp3              \ Jump to setp3 to skip the setup for the Electron

.setp1

                        \ If we get here then this is either a BBC Micro running
                        \ MOS 1.00 or earlier, or it's an Electron
                        \
                        \ In MOS 0.10, OSBYTE 200 does not let you set the BREAK
                        \ key to clear memory, so we need to set this up by hand
                        \ (otherwise hackers could load the game on MOS 0.10 and
                        \ simply press BREAK to access the loaded game code).
                        \
                        \ The Electron and MOS 1.00 do not need this code, as
                        \ OSBYTE 200 is supported in these versions of the
                        \ operating system, but OSBYTE 0 doesn't distinguish
                        \ between the Electron and MOS 1.00 and earlier (they
                        \ all return X = 0)
                        \
                        \ There's no harm in manually clearing memory on those
                        \ systems, though, so the following code is run on
                        \ BREAK on MOS 1.00 and earlier and on the Electron
                        \
                        \ To set this up, we copy the break handler routine from
                        \ ClearMemory to address BRKI (this points to the
                        \ cassette filing system workspace, which is unused
                        \ now that the game is loaded, so it's a suitable
                        \ location for our handler)

 LDX #&1C               \ Set a counter in X for the size of the ClearMemory
                        \ routine

.setp2

 LDA ClearMemory,X      \ Copy the X-th byte of the ClearMemory routine into the
 STA BRKI,X             \ X-th byte of BRKI

 DEX                    \ Decrement the byte counter

 BPL setp2              \ Loop back until we have copied the whole ClearMemory
                        \ routine to BRKI

 LDA #&4C               \ Set the Break Intercept code to the following, so that
 STA BRKIV              \ BRKI gets called when the BREAK key is pressed:
 LDA #LO(BRKI)          \
 STA BRKIV+1            \    4C 80 03   JMP BRKI
 LDA #HI(BRKI)          \
 STA BRKIV+2            \ &4C is the opcode for the JMP instruction, and BRKI is
                        \ at address &0380 (part of the cassette filing system
                        \ workspace)

.setp3

                        \ Next we copy a block of game code in memory as
                        \ follows:
                        \
                        \   * &4100-&49FF is copied to &5800-&60FF
                        \
                        \ The game binary could easily have been structured to
                        \ avoid this copy, so presumably it's just done to make
                        \ the game code harder to crack

 LDA #&00               \ Set (Q P) = &4100
 STA P                  \
 STA R                  \ We use this as the source address for the copy
 LDA #&41
 STA Q

 LDA #&58               \ Set (S R) = &5800
 STA S                  \
                        \ We use this as the destination address for the copy

.setp4

 LDY #0                 \ Set up a byte counter in Y

.setp5

 LDA (P),Y              \ Copy the Y-th byte of (Q P) to the Y-th byte of (S R)
 STA (R),Y

 DEY                    \ Decrement the byte counter

 BNE setp5              \ Loop back until we have copied a whole page of bytes

 INC Q                  \ Increment the high byte of (Q P) to point to the next
                        \ page in memory

 INC S                  \ Increment the high byte of (S R) to point to the next
                        \ page in memory

 LDA Q                  \ Loop back until (Q P) reaches &4A00, at which point we
 CMP #&4A               \ have copied the whole block of memory
 BCC setp4

 SEI                    \ Disable interrupts so we can update the interrupt
                        \ vector and VIA

 LDA IRQ1V              \ Store the current address from the IRQ1V vector in
 STA irq1Address        \ irq1Address, so the IRQ handler can jump to it after
 LDA IRQ1V+1            \ implementing the custom interrupt handler
 STA irq1Address+1

                        \ We now wait for the vertical sync, which we can check
                        \ by reading bit 1 of the 6522 System VIA status byte
                        \ (SHEILA &4D), which is set if vertical sync has
                        \ occurred on the video system

 LDA #%00000010         \ Set a bit mask in A that we can use to read bit 1 of
                        \ the 6522 System VIA status byte

.setp6

 BIT SHEILA+&4D         \ Loop around until bit 1 of the 6522 System VIA status
 BEQ setp6              \ byte is set, so we wait until the vertical sync

 LDA #%01000000         \ Set 6522 User VIA auxiliary control register ACR
 STA SHEILA+&6B         \ (SHEILA &6B) bits 7 and 6 to disable PB7 (which is one
                        \ of the pins on the user port) and set continuous
                        \ interrupts for timer 1

 LDA #%11000000         \ Set 6522 User VIA interrupt enable register IER
 STA SHEILA+&6E         \ (SHEILA &4E) bits 6 and 7 (i.e. enable the Timer1
                        \ interrupt from the User VIA)

 LDA #&00               \ Set 6522 User VIA T1C-L timer 1 low-order counter
 STA SHEILA+&64         \ (SHEILA &64) to &00 (so this sets the low-order
                        \ counter but does not start counting until the
                        \ high-order counter is set)

 LDA #&39               \ Set 6522 User VIA T1C-H timer 1 high-order counter
 STA SHEILA+&65         \ (SHEILA &45) to &39 to start the T1 counter
                        \ counting down from &3900 (14592) at a rate of 1 MHz

 LDA #&1E               \ Set 6522 User VIA T1L-L timer 1 low-order latches
 STA SHEILA+&66         \ to &1E (so this sets the low-order counter but does
                        \ not start counting until the high-order counter is
                        \ set)

 LDA #&4E               \ Set 6522 User VIA T1L-H timer 1 high-order latches
 STA SHEILA+&67         \ to &4E (so this sets the timer to &4E1E (19998) but
                        \ does not start counting until the current timer has
                        \ run down)

 LDA #HI(IRQHandler)    \ Set the IRQ1V vector to IRQHandler, so the IRQHandler
 STA IRQ1V+1            \ routine is now the interrupt handler
 LDA #LO(IRQHandler)
 STA IRQ1V

 CLI                    \ Re-enable interrupts

 JMP MainLoop           \ Jump to MainLoop to start the main game loop, where
                        \ we display the title screen, fetch the landscape
                        \ number, play the game and repeat

\ ******************************************************************************
\
\       Name: ClearMemory
\       Type: Subroutine
\   Category: Setup
\    Summary: Clear game memory, so that the BREAK key can remove all trace of
\             the game code in early versions of the operating system
\
\ ******************************************************************************

.ClearMemory

 LDA #&04               \ Set (Q P) = &0400
 STA Q                  \
 LDA #&00               \ We use this as the start address for clearing memory,
 STA P                  \ which is where the game code starts
                        \
                        \ This also sets A = 0, which we can use to zero memory

.cmem1

 LDY #&FF               \ Set Y = &FF to use as a byte counter

.cmem2

 STA (P),Y              \ Zero the Y-th byte at (Q P)

 DEY                    \ Decrement the byte counter

 BNE cmem2              \ Loop back until we have zeroed a whole page of memory

 INC Q                  \ Increment the high byte of (Q P) to point to the next
                        \ page in memory

 LDX Q                  \ Loop back until (Q P) reaches &7C00, at which point we
 CPX #&7C               \ have zeroed all the game code (including any code
 BCC cmem1              \ still left at the higher memory address where it's
                        \ first loaded)

 LDA #&00               \ Set the Break Intercept code to a BRK instruction to
 STA BRKIV              \ reinstate the default break handler

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: L400A
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ This variable contains original fragments of source code.
\
\ ******************************************************************************

.L400A

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


 ORG &4A00              \ Set the assembly address to &4A00

L49A0                = &49A0
L49A1                = &49A1
L49AB                = &49AB
L49AC                = &49AC
L49B6                = &49B6
L49C1                = &49C1

\ ******************************************************************************
\
\       Name: L4A00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L4A00

 EQUB &4B, &4A, &46, &4B, &47, &4D, &4C, &47
 EQUB &4B, &4E, &4A, &4B, &4C, &4D, &4F, &4C
 EQUB &4C, &4F, &4E, &4B, &4C, &46, &4A, &49
 EQUB &46, &47, &48, &4D, &47, &4A, &50, &49
 EQUB &4A, &48, &51, &4D, &48, &4A, &4E, &50
 EQUB &4A, &4D, &51, &4F, &4D, &49, &50, &51
 EQUB &48, &49, &4F, &51, &50, &4E, &4F

.L4A37

 EQUB &00
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

\ ******************************************************************************
\
\       Name: L4AE0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L4C20
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L4D60
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L4EA0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L4F40
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L4FE0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L5080
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L5120
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L51C0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L5260
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L54A0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L5500
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5500

 EQUB &01, &01, &02, &02, &03, &03, &04, &04
 EQUB &05, &05, &06, &06, &07, &07, &08, &08
 EQUB &09, &09, &0A, &0A, &0B, &0B, &0C, &0C
 EQUB &0C, &0D, &0D, &0E, &0E, &0F, &0F, &0F

\ ******************************************************************************
\
\       Name: L5520
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5520

 EQUB &01, &01, &02, &02, &03, &03, &04, &04
 EQUB &05, &05, &06, &06, &07, &07, &08, &08
 EQUB &09, &09, &0A, &0A, &0A, &0B, &0B, &0C
 EQUB &0C, &0D, &0D, &0E, &0E, &0E, &0F, &0F
 EQUB &0D, &0D, &0D, &0D, &0D, &0D, &0D, &0D
 EQUB &14, &15, &14, &12, &12, &13, &12, &11
 EQUB &11, &12, &11, &11, &10, &13, &11, &11
 EQUB &12, &11, &12, &11, &11, &12, &FF, &FF

\ ******************************************************************************
\
\       Name: sub_C5560
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5560

 STA L007E
 STA L008A
 STA L008B
 RTS

\ ******************************************************************************
\
\       Name: sub_C5567
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 BEQ sub_C5560
 LDA L0085
 JMP C55E3

.P55A1

 ASL L0082
 ROL L0085

.C55A5

 ASL L0080
 ROL A
 BCC P55A1
 ROR A
 ROR L0080
 STA V
 LDA L0082
 STA T
 LDA L0080
 AND #&FC
 STA W
 LDA L0085
 JSR sub_C0D4A
 LDA L0086
 EOR L0088
 BMI C55D1
 LDA #0
 SEC
 SBC L008A
 STA L008A
 LDA #0
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

.P55DF

 ASL L0080
 ROL L0083

.C55E3

 ASL L0082
 ROL A
 BCC P55DF
 ROR A
 ROR L0082
 STA V
 LDA L0080
 STA T
 LDA L0082
 AND #&FC
 STA W
 LDA L0083
 JSR sub_C0D4A
 LDA L0086
 EOR L0088
 BPL C560F
 LDA #0
 SEC
 SBC L008A
 STA L008A
 LDA #0
 SBC L008B
 STA L008B

.C560F

 LDA #0
 BIT L0088
 BPL C5617
 LDA #&80

.C5617

 CLC
 ADC L008B
 STA L008B
 RTS

\ ******************************************************************************
\
\       Name: sub_C561D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C561D

 STA L0086
 TAY
 BPL C562D
 LDA #0
 SEC
 SBC L0080
 STA L0080
 LDA #0
 SBC L0086

.C562D

 STA L0083
 LDA L007C
 STA L0082
 LDA L007D
 STA L0085
 LDA #0
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

\ ******************************************************************************
\
\       Name: sub_C565F
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C565F

 STY L568D
 LDA L007E
 LSR A
 ADC #&00
 TAY
 LDA L3D02,Y
 STA U
 LDA L005C
 STA T
 LDA L005D
 STA V
 JSR Multiply8x16
 LSR U
 ROR T
 LDA T
 CLC
 ADC L007A
 STA L007C
 LDA U
 ADC L007B
 STA L007D
 LDY L568D
 RTS

\ ******************************************************************************
\
\       Name: L568D
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L568D

 EQUB &41

\ ******************************************************************************
\
\       Name: sub_C568E
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L56CF
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L56CF

 EQUB &01

\ ******************************************************************************
\
\       Name: L56D0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L56D0

 EQUB &00

\ ******************************************************************************
\
\       Name: L56D1
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L56D1

 EQUB &00

\ ******************************************************************************
\
\       Name: L56D2
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L56D2

 EQUB &01

\ ******************************************************************************
\
\       Name: L56D3
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L56D3

 EQUB &00

\ ******************************************************************************
\
\       Name: L56D4
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L56D4

 EQUB &00

\ ******************************************************************************
\
\       Name: sub_C56D5
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C56D5

 LDA #&80
 BNE C56DB

\ ******************************************************************************
\
\       Name: sub_C56D9
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C56D9

 LDA #0

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
 LDY #0
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

\ ******************************************************************************
\
\       Name: L572E
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L572E

 EQUB &00

\ ******************************************************************************
\
\       Name: L572F
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L572F

 EQUB &00

\ ******************************************************************************
\
\       Name: L5730
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5730

 EQUB &08, &04, &02, &01

\ ******************************************************************************
\
\       Name: sub_C5734
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5734

 STA L0C04
 LDX #&28

.C5739

 DEY
 BNE C5739
 DEX
 BNE C5739
 RTS

\ ******************************************************************************
\
\       Name: L5740
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

 EQUB &FF, &FF, &FF, &FF

\ ******************************************************************************
\
\       Name: sub_C5744
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5744

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

.P575B

 LDA L5796,X
 JSR OSWRCH
 DEX
 BPL P575B
 PLA
 TAX
 RTS

.C5767

 JMP OSWRCH

.C576A

 CMP #&19
 BEQ C5775
 JMP sub_C5744

.P5771

 INY
 LDA L5796,Y

.C5775

 JSR OSWRCH
 DEC L5783
 BNE P5771
 LDA #&06
 STA L5783
 RTS

\ ******************************************************************************
\
\       Name: L5783
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5783

 EQUB &06

.L5784

 EQUB &17, &1D, &30, &39, &4E, &57, &5D
 EQUB &60, &67, &6E, &75, &7A, &7F, &86, &90
 EQUB &A2, &A8, &AC

.L5796

 EQUB &43

.L5797

 EQUB &02, &00, &12, &00
 EQUB &04, &00, &00, &00, &19, &08

.L57A1

 EQUB &43

.L57A2

 EQUB &03
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

\ ******************************************************************************
\
\       Name: L5850
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L58B0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

\ ******************************************************************************
\
\       Name: L5900
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5900

 EQUB &10, &00, &01, &00

.L5904

 EQUB &07, &00, &05, &00
 EQUB &11, &00, &00, &00

.L590C

 EQUB &78, &00, &0A, &00

.L5910

 EQUB &12, &00

.L5912

 EQUB &03, &00

.L5914

 EQUB &22, &00, &14, &00
 EQUB &13, &00, &04, &00

.L591C

 EQUB &90, &00, &14, &00
 EQUB &10, &00, &02, &00, &04, &00, &28, &00

.L5928

 EQUB &01, &02, &00, &00, &00, &00, &00, &00
 EQUB &14, &00, &EC, &EC, &78, &78, &02, &04
 EQUB &00, &00, &00, &00, &00, &00, &02, &FF
 EQUB &00, &00, &78, &78, &04, &02, &01, &FF
 EQUB &00, &01, &01, &08, &78, &FF, &00, &FF
 EQUB &78

.L5951

 EQUB &08, &03, &01, &06, &FA, &00, &01
 EQUB &01, &00, &01, &FF, &00, &00, &78

.L595F

 EQUB &08
 EQUB &04, &82, &01, &FF, &00, &02, &01, &07
 EQUB &78, &FA, &FE, &FE, &78, &00, &01, &01
 EQUB &00, &00, &00, &00, &00, &00, &78, &88
 EQUB &FF, &FF, &78, &00, &00, &00, &00, &00

\ ******************************************************************************
\
\       Name: sin
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Table for sin values
\
\ ******************************************************************************

.sin

 FOR I%, 0, 127

  N = INT(0.5 + 256 * SIN((I% / 128) * (PI / 2)))

  IF N >= 255
   EQUB 255
  ELSE
   EQUB N
  ENDIF

 NEXT

\ ******************************************************************************
\
\       Name: L5A00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ This variable contains original fragments of source code.
\
\ ******************************************************************************

.L5A00

 EQUB &44

.L5A01

 EQUB &58

.L5A02

 EQUB &20

.L5A03

 EQUB &45, &54, &45, &4D, &0D
 EQUB &14, &3C, &05, &20, &0D, &14, &46, &23
 EQUB &20, &20, &20, &20, &20, &20, &54, &59
 EQUB &41, &3A, &4A, &53, &52, &20, &45, &4D
 EQUB &49, &52, &54, &45, &53, &54, &3A, &42
 EQUB &43, &43, &20, &6D, &65, &61

.L5A2E

 EQUB &32, &0D
 EQUB &14, &50, &05, &20, &0D, &14, &5A, &1A
 EQUB &20, &20, &20, &20, &20, &20, &54, &59

.L5A40

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

\ ******************************************************************************
\
\       Name: L5B00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ This variable contains original fragments of source code.
\
\ ******************************************************************************

.L5B00

L5B07 = L5B00+7
L5B08 = L5B00+8
L5B09 = L5B00+9
L5B0F = L5B00+15
L5B10 = L5B00+16
L5B11 = L5B00+17
L5B17 = L5B00+23
L5B18 = L5B00+24
L5B19 = L5B00+25
L5B60 = L5B00+96
L5B9E = L5B00+158
L5B9F = L5B00+159
L5BA0 = L5B00+160

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

\ ******************************************************************************
\
\       Name: sub_C5C00
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5C00

 RTS

\ ******************************************************************************
\
\       Name: sub_C5C01
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDA #0
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
 LDA #0
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

\ ******************************************************************************
\
\       Name: sub_C5C75
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 STA T
 LDA L005A
 CLC
 ADC L4AE0,Y
 JSR sub_C0F70
 LDY L004E
 LDA L4D60,Y
 STA U
 LDA L008F
 JSR Multiply8x8
 STA T
 LDA #0
 BIT H
 BVC C5CA9
 JSR Negate16Bit

.C5CA9

 STA U
 LDA L0C5D
 CLC
 ADC T
 STA L0082
 LDA L0C5E
 ADC U
 STA L0088
 BPL C5CC7
 LDA #0
 SEC
 SBC L0082
 STA L0082
 LDA #0
 SBC L0088

.C5CC7

 STA L0085
 LDA L4D60,Y
 STA U
 LDA L008E
 JSR Multiply8x8
 STA L0080
 LDA #0
 STA L0083
 LDA H
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
 STA T
 LDA #0
 BCC C5D05
 JSR Negate16Bit

.C5D05

 STA U
 LDA T
 CLC
 ADC L0C5B
 STA L0080
 LDA U
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
 BEQ CRE39
 JMP C5C85

.CRE39

 RTS

\ ******************************************************************************
\
\       Name: sub_C5D33
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5D33

 JSR sub_C5C01
 LDA L007D
 CMP #&0F
 ROR L0C7A
 JSR sub_C5C75
 LDA #&40
 STA L003B
 LDA #0
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
 JSR sub_C2A79
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

\ ******************************************************************************
\
\       Name: sub_C5DC4
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5DC4

 LDA #0
 STA L0080
 SEC
 LDA L0900,Y
 SBC L0900,X
 SEC
 SBC L0C78
 STA L0086
 BPL C5DDC
 SEC
 LDA #0
 SBC L0086

.C5DDC

 STA L0083
 LDA #0
 STA L0082
 SEC
 LDA L0980,Y
 SBC L0980,X
 STA L0088
 BPL C5DF2
 SEC
 LDA #0
 SBC L0088

.C5DF2

 STA L0085
 RTS

\ ******************************************************************************
\
\       Name: sub_C5DF5
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5DF5

 LDA L0A00,Y
 SEC
 SBC L0A00,X
 STA L0081
 LDA L0940,Y
 SBC L0940,X
 STA L0084
 RTS

\ ******************************************************************************
\
\       Name: sub_C5E07
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5E07

 JSR sub_C5E20

\ ******************************************************************************
\
\       Name: sub_C5E0A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5E0A

 JSR OSRDCH
 BCC CRE40
 CMP #&1B
 BNE CRE40
 TYA
 PHA
 LDA #126               \ osbyte_acknowledge_escape
 JSR OSBYTE
 PLA
 TAY
 JMP sub_C5E0A

.CRE40

 RTS

\ ******************************************************************************
\
\       Name: sub_C5E20
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5E20

 LDA #2                 \ osbyte_select_input_stream
 LDX #0
 JSR OSBYTE
 LDX #0
 JMP sub_C3555

\ ******************************************************************************
\
\       Name: SetColourPalette
\       Type: Subroutine
\   Category: Screen mode
\    Summary: Set the logical colours for each of the four physical colours in
\             screen mode 5
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Defines how the four physical colours in the mode 5
\                       palette are set:
\
\                         * If bit 7 is clear then bits 0-6 contain the physical
\                           colour to set for all four logical colours (so the
\                           screen is effectively blanked to this colour)
\
\                         * If bit 7 is set then bits 0-6 contain the offset
\                           within the colourPalettes table of the last of the
\                           four physical colours to set for logical colours
\                           3, 2, 1 and 0 (so we work backwards through the
\                           table from the offset in bits 0-6)
\
\ ******************************************************************************

.SetColourPalette

 STA T                  \ Store the argument in T

 AND #%01111111         \ Extract bits 0-6 of the argument into Y
 TAY

 LDA #3                 \ We now work through the logical colours from 3 down
 STA U                  \ to 0, setting the physical colour for each one in
                        \ turn, so set a logical colour counter in U

.pall1

 LDX T                  \ Set X to the argument in T

 BPL pall2              \ If bit 7 of the argument in T is clear, skip the
                        \ following instruction, so X contains the physical
                        \ colour in the routine's argument (i.e. the colour to
                        \ which we set all four logical colours)

                        \ If we get here then bit 7 of the argument in T is set,
                        \ which means bits 0-6 contain the offset within the
                        \ colourPalettes table of the four physical colours in
                        \ the palette
                        \
                        \ We set Y above to the value of bits 0-6, so we can use
                        \ this as the index into the colourPalettes table (we
                        \ will decrement Y below for each of the four colours,
                        \ so we end up setting all four logical colours to the
                        \ four values in the table)

 LDX colourPalettes,Y   \ Fetch the physical colour from the Y-th entry in
                        \ colourPalettes, which we now want to allocate to
                        \ logical colour U

.pall2

 LDA #19                \ Start a VDU 19 command, which sets a logical colour to
 JSR OSWRCH             \ a physical colour using the following format:
                        \
                        \   VDU 19, logical, physical, 0, 0, 0
                        \
                        \ which we output as follows:
                        \
                        \   VDU 19, U, X, 0, 0, 0

 LDA U                  \ Write the value in U, which is the logical colour we
 JSR OSWRCH             \ want to define

 TXA                    \ Set A to the value in X

 LDX #4                 \ Set X = 4 to use as a byte counter as we output the
                        \ physical colour and three zeroes

.pall3

 JSR OSWRCH             \ Write the value in A, which is the physical colour we
                        \ want to set (in the first iteration of the loop), or
                        \ one of three trailing zeroes (in later iterations)

 LDA #0                 \ Set A = 0 so the remaining three iterations of the
                        \ loop output the trailing zeroes

 DEX                    \ Decrement the byte counter

 BNE pall3              \ Loop back until we have output the whole VDU command

 DEY                    \ Decrement the colourPalettes index in Y

 DEC U                  \ Decrement the logical colour counter in U

 BPL pall1              \ Loop back until we have defined the logical colours
                        \ for all four physical colours

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: colourPalettes
\       Type: Variable
\   Category: Screen mode
\    Summary: The logical colours for two mode 5 palettes
\
\ ------------------------------------------------------------------------------
\
\ This table contains the logical colours that are set in the SetColourPalette
\ routine when it is called with an argument with bit 7 set. This routine is
\ only ever called with an argument of &83 or &87.
\
\ If the argument to SetColourPalette is &83, the palette is set as follows:
\
\   * Colour 0 = 4 (blue)
\   * Colour 1 = 0 (black)
\   * Colour 2 = 6 (cyan)
\   * Colour 3 = 3 (yellow)
\
\ If the argument to SetColourPalette is &87, the palette is set as follows:
\
\   * Colour 0 = 4 (blue)
\   * Colour 1 = 0 (black)
\   * Colour 2 = 1 (red)
\   * Colour 3 = 3 (yellow)
\
\ ******************************************************************************

.colourPalettes

 EQUB 4, 0, 6, 3        \ Palette with SetColourPalette offset 3

 EQUB 4, 0, 1, 3        \ Palette with SetColourPalette offset 7

\ ******************************************************************************
\
\       Name: sub_C5E5F
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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

.P5E74

 ASL A
 INY
 BCC P5E74
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
 LDA #0
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
 LDY #0
 LDA (L0062),Y
 AND L227F,X
 STA L0013
 LDA (L0064),Y
 AND L36BF,X
 ORA L0013
 STA (L0064),Y
 BIT L0C1E
 BMI CRE41
 DEC L0CD2
 BNE C5F20
 JSR sub_C355A
 DEC L2094
 BEQ CRE41

.C5F20

 JMP C5E7E

.CRE41

 RTS

\ ******************************************************************************
\
\       Name: sub_C5F24
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDY #0
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

\ ******************************************************************************
\
\       Name: sub_C5F68
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5F68

 STA L001E

.P5F6A

 LDA #&1E
 STA L0015

.P5F6E

 JSR sub_C56D9
 JSR sub_C355A
 DEC L0015
 BNE P5F6E
 DEC L001E
 BNE P5F6A
 RTS

\ ******************************************************************************
\
\       Name: sub_C5F7D
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5F7D

 EQUB &4C
 BMI sub_C5FBF

\ ******************************************************************************
\
\       Name: sub_C5F80
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

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
 LDA #0
 STA L0A02
 STA L0A01
 LDA L5FDF,Y
 STA L09C1
 LDX #&02
 STX L006E
 RTS

\ ******************************************************************************
\
\       Name: L5FBC
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5FBC

 EQUB &05, &07, &07

\ ******************************************************************************
\
\       Name: sub_C5FBF
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5FBF

 JSR sub_C1410
 LDX #&03
 LDY #0
 LDA #&80
 JSR DrawObject
 LDX #&04
 JSR sub_C36AD
 JSR sub_C33AB
 JSR sub_C1440
 JMP main5

\ ******************************************************************************
\
\       Name: L5FD9
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5FD9

 EQUB &F4, &FB, &FB

.L5FDC

 EQUB &00, &01, &00

.L5FDF

 EQUB &80, &8E
 EQUB &CE

.L5FE2

 EQUB &00, &F8, &F8

\ ******************************************************************************
\
\       Name: sub_C5FE5
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5FE5

 LDY #&01
 JSR sub_C5FEE
 LDY #&02
 LDA #&06

\ ******************************************************************************
\
\       Name: sub_C5FEE
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5FEE

 JSR sub_C5F80
 LDY #&01
 JMP sub_C5D33

\ ******************************************************************************
\
\       Name: sub_C5FF6
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5FF6

 STA L0CE7
 LDA #&03
 STA L0C73
 RTS

\ ******************************************************************************
\
\       Name: L5FFF
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5FFF

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

\ ******************************************************************************
\
\       Name: Entry
\       Type: Subroutine
\   Category: Setup
\    Summary: The main entry point for the game
\
\ ******************************************************************************

 ORG &6D00              \ Set the assembly address to &6D00

.Entry

                        \ We start by copying the game code in memory as
                        \ follows:
                        \
                        \   * &1900-&6CFF is copied to &0400-&57FF
                        \
                        \ The game binary has a load address of &1900 and an
                        \ execution address of &6D00 (the address of this
                        \ routine)

 LDA #&00               \ Set (Q P) = &1900
 STA P                  \
 STA R                  \ We use this as the source address for the copy
 LDA #&19
 STA Q

 LDA #&04               \ Set (S R) = &0400
 STA S                  \
                        \ We use this as the destination address for the copy

.entr1

 LDY #0                 \ Set up a byte counter in Y

.entr2

 LDA (P),Y              \ Copy the Y-th byte of (Q P) to the Y-th byte of (S R)
 STA (R),Y

 INY                    \ Increment the byte counter

 BNE entr2              \ Loop back until we have copied a whole page of bytes

 INC Q                  \ Increment the high byte of (Q P) to point to the next
                        \ page in memory

 INC S                  \ Increment the high byte of (S R) to point to the next
                        \ page in memory

 LDA Q                  \ Loop back until (Q P) reaches &6D00, at which point we
 CMP #&6D               \ have copied all the game code
 BNE entr1

 JMP ConfigureMachine   \ Jump to ConfigureMachine to configure the computer,
                        \ ready for a new game

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
