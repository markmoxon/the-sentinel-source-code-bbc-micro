\ ******************************************************************************
\
\ THE SENTINEL SOURCE
\
\ The Sentinel was written by Geoff Crammond and is copyright Firebird 1985
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
\    Address: &0000 to &008F
\   Category: Workspaces
\    Summary: Mainly temporary variables that are used a lot
\
\ ******************************************************************************

 ORG &0000              \ Set the assembly address to &0000

.enemyObject

 SKIP 1                 \ An enemy object number, 0-7 ???

.currentObject

 SKIP 1                 \ Used to store the number of the object we are
                        \ currently processing

.L0002

 SKIP 1                 \ ???

.L0003

 SKIP 1                 \ ???

.L0004

 SKIP 1                 \ ???

.L0005

 SKIP 1                 \ ???

.tileAltitude

 SKIP 1                 \ Used to store a tile altitude

.L0007

 SKIP 1                 \ ???

.lastPanKeyPressed

 SKIP 1                 \ The direction of the last pan key that was pressed
                        \ (which may still be being held down)
                        \
                        \   * Bit 7 set = not currently panning
                        \
                        \   * 0 = pan right
                        \
                        \   * 1 = pan left
                        \
                        \   * 2 = pan up
                        \
                        \   * 3 = pan down

.panKeyBeingPressed

 SKIP 1                 \ The direction in which the player is currently panning
                        \
                        \   * Bit 7 set = not currently panning
                        \
                        \   * 0 = pan right
                        \
                        \   * 1 = pan left
                        \
                        \   * 2 = pan up
                        \
                        \   * 3 = pan down

.L000A

 SKIP 1                 \ ???

.playerObject

 SKIP 1                 \ The number of the player object

.L000C
.zCounter
.stashAddr

 SKIP 1                 \ ???

.L000D
.xCounter

 SKIP 1                 \ ???

.L000E

 SKIP 1                 \ ???

.L000F

 SKIP 1                 \ ???

.L0010

 SKIP 1                 \ ???

.L0011

 SKIP 1                 \ ???

.L0012

 SKIP 1                 \ ???

.L0013

 SKIP 1                 \ ???

.L0014

 SKIP 1                 \ ???

.loopCounter

 SKIP 1                 \ Used to store a loop counter

.L0016

 SKIP 1                 \ ???

.L0017

 SKIP 1                 \ ???

.L0018
.xBlock

 SKIP 1                 \ Used to store the tile x-coordinate of the tile we are
                        \ analysing when calculating the highest tile in a block

.L0019

 SKIP 1                 \ ???

.L001A
.zBlock

 SKIP 1                 \ Used to store the tile z-coordinate of the tile we are
                        \ analysing when calculating the highest tile in a block

.L001B

 SKIP 1                 \ ???

.processAction

 SKIP 1                 \ Defines the following:
                        \
                        \   * The action that's applied to tile data by the
                        \     ProcessTileData routine
                        \
                        \   * The action that's applied to tile data by the
                        \     SmoothTileData routine
                        \
                        \ See the ProcessTileData and SmoothTileData routines
                        \ for details

.L001D

 SKIP 1                 \ ???

.L001E
.treeCounter

 SKIP 1                 \ Used as a loop counter when adding trees to the
                        \ landscape

.L001F

 SKIP 1                 \ ???

.L0020

 SKIP 1                 \ ???

.L0021

 SKIP 1                 \ ???

.L0022

 SKIP 1                 \ ???

.L0023

 SKIP 1                 \ ???

.xTile

 SKIP 1                 \ Tile corner x-coordinate
                        \
                        \ The tile corner coordinate along the x-axis, where the
                        \ x-axis goes from left to right across the screen, with
                        \ one x-coordinate per tile (so this is also the corner
                        \ number along the axis)
                        \
                        \ Each tile in the landscape is defined by a tile
                        \ corner (the "anchor") and the tile shape, with the
                        \ anchor being in the front-left corner of the tile,
                        \ nearest the origin
                        \
                        \ As a result we tend to use the terms "tile" and "tile
                        \ corner" interchangeably, depending on the context

.yTile

 SKIP 1                 \ Tile corner y-coordinate
                        \
                        \ The tile corner coordinate along the y-axis, where the
                        \ y-axis goes up the screen (so this is also the corner
                        \ number along the axis)
                        \
                        \ Each tile in the landscape is defined by a tile
                        \ corner (the "anchor") and the tile shape, with the
                        \ anchor being in the front-left corner of the tile,
                        \ nearest the origin
                        \
                        \ As a result we tend to use the terms "tile" and "tile
                        \ corner" interchangeably, depending on the context

.zTile

 SKIP 1                 \ Tile corner z-coordinate
                        \
                        \ The tile corner coordinate along the z-axis, where the
                        \ z-axis goes into the screen, with one z-coordinate per
                        \ tile (so this is also the corner number along the
                        \ axis)
                        \
                        \ Each tile in the landscape is defined by a tile
                        \ corner (the "anchor") and the tile shape, with the
                        \ anchor being in the front-left corner of the tile,
                        \ nearest the origin
                        \
                        \ As a result we tend to use the terms "tile" and "tile
                        \ corner" interchangeably, depending on the context

.bitMask

 SKIP 1                 \ Used to return a bit mask from the GetTilesAtAltitude
                        \ routine that has a matching number of leading zeroes
                        \ as the number of tile blocks at a specific altitude

.L0028

 SKIP 1                 \ ???

.L0029

 SKIP 1                 \ ???

.L002A

 SKIP 1                 \ ???

.L002B

 SKIP 1                 \ ???

.xSightsVectorLo

 SKIP 1                 \ The x-coordinate of the vector from the player's eyes
                        \ to the sights within the 3D world (low byte)

.ySightsVectorLo

 SKIP 1                 \ The y-coordinate of the vector from the player's eyes
                        \ to the sights within the 3D world (low byte)

.zSightsVectorLo

 SKIP 1                 \ The z-coordinate of the vector from the player's eyes
                        \ to the sights within the 3D world (low byte)

.xSightsVectorHi

 SKIP 1                 \ The x-coordinate of the vector from the player's eyes
                        \ to the sights within the 3D world (high byte)

.ySightsVectorHi

 SKIP 1                 \ The y-coordinate of the vector from the player's eyes
                        \ to the sights within the 3D world (high byte)

.zSightsVectorHi

 SKIP 1                 \ The z-coordinate of the vector from the player's eyes
                        \ to the sights within the 3D world (high byte)

.cosSightsPitchLo

 SKIP 1                 \ ???

.cosSightsPitchHi

 SKIP 1                 \ ???

.L0034

 SKIP 1                 \ ???

.L0035

 SKIP 1                 \ ???

.L0036

 SKIP 1                 \ ???

.L0037

 SKIP 1                 \ ???

.L0038

 SKIP 1                 \ ???

.L0039

 SKIP 1                 \ ???

.L003A

 SKIP 1                 \ ???

.L003B

 SKIP 1                 \ ???

.L003C

 SKIP 1                 \ ???

.sightsYawAngleLo

 SKIP 1                 \ ???

.sightsYawAngleHi

 SKIP 1                 \ ???

.sightsPitchAngleLo

 SKIP 1                 \ ???

.sightsPitchAngleHi

 SKIP 1                 \ ???

.L0041

 SKIP 1                 \ ???

.L0042

 SKIP 1                 \ ???

.L0043

 SKIP 2                 \ ???

.L0045

 SKIP 5                 \ ???

.L004A

 SKIP 1                 \ ???

.L004B

 SKIP 1                 \ ???

.L004C

 SKIP 2                 \ ???

.L004E

 SKIP 1                 \ ???

.L004F

 SKIP 1                 \ ???

.L0050

 SKIP 1                 \ ???

.L0051

 SKIP 1                 \ ???

.L0052

 SKIP 1                 \ ???

.L0053

 SKIP 1                 \ ???

.L0054

 SKIP 1                 \ ???

.L0055

 SKIP 1                 \ ???

.L0056

 SKIP 1                 \ ???

.L0057

 SKIP 1                 \ ???

.L0058

 SKIP 1                 \ ???

.L0059

 SKIP 1                 \ ???

.L005A

 SKIP 2                 \ ???

.bLo

 SKIP 1                 \ The low byte of the opposite side of a triangle

.bHi

 SKIP 1                 \ The high byte of the opposite side of a triangle

.tileDataPage

 SKIP 2                 \ The address of the tileData page containing the
                        \ current tile's data

.secondAxis

 SKIP 1                 \ The number of the second axis to calculate in the
                        \ GetRotationMatrix routine

.L0061

 SKIP 1                 \ ???

.fromAddr

 SKIP 2                 \ An address, typically used as a source address when
                        \ copying

.toAddr

 SKIP 2                 \ An address, typically used as a destination address
                        \ when copying

.smoothingAction

 SKIP 1                 \ The action that's applied to tile data by the
                        \ SmoothTileData routine
                        \
                        \ See the SmoothTileData routine for details

.H

 SKIP 1                 \ Temporary storage, used in the maths routines

.RR

 SKIP 1                 \ Temporary storage, used in the maths routines

.SS

 SKIP 1                 \ Temporary storage, used in the maths routines

.PP

 SKIP 1                 \ Temporary storage, used in the maths routines

.QQ

 SKIP 1                 \ Temporary storage, used in the maths routines

.L006C

 SKIP 1                 \ ???

.screenAddrHi

 SKIP 1                 \ Storage for the high byte of the screen memory address
                        \ in the ScrollPlayerView routine

.anotherObject

 SKIP 0                 \ Another object number, to go along with currentObject
                        \
                        \ Set to object #16 in DrawTitleObject
                        \ Set to enemyData5,X in sub_C16A8
                        \ Set to enemyObject in sub_C197D
                        \ Set to playerObject in sub_C16A8, sub_C1AF3, MainGameLoop
                        \ Set to object #2 in sub_C5F80

.enemyCounter

 SKIP 1                 \ Used as a loop counter when adding enemies to the
                        \ landscape

.L006F

 SKIP 1                 \ ???

.P

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.R

 SKIP 1                 \ Temporary storage, used in a number of places

.S

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

.U

 SKIP 1                 \ Temporary storage, used in a number of places

.V

 SKIP 1                 \ Temporary storage, used in a number of places

.W

 SKIP 1                 \ Temporary storage, used in a number of places

.G

 SKIP 1                 \ Temporary storage, used in a number of places

.L0079

 SKIP 1                 \ ???

.aLo

 SKIP 1                 \ The low byte of the adjacent side of a triangle

.aHi

 SKIP 1                 \ The high byte of the adjacent side of a triangle

.hypotenuseLo

 SKIP 1                 \ The low byte of the hypotenuse of a triangle

.hypotenuseHi

 SKIP 1                 \ The high byte of the hypotenuse of a triangle

.angleTangent

 SKIP 1                 \ Used to store a tangent angle

.L007F

 SKIP 1                 \ ???

.L0080

 SKIP 1                 \ ???

.L0081

 SKIP 1                 \ ???

.L0082

 SKIP 1                 \ ???

.L0083

 SKIP 1                 \ ???

.L0084

 SKIP 1                 \ ???

.L0085

 SKIP 1                 \ ???

.L0086

 SKIP 2                 \ ???

.L0088

 SKIP 2                 \ ???

.angleLo

 SKIP 1                 \ The high byte of an angle

.angleHi

 SKIP 1                 \ The low byte of an angle

 SKIP 1                 \ This byte appears to be unused

.L008D

 SKIP 1                 \ ???

.sinA

 SKIP 1                 \ The result of the sin(A) calculation in the
                        \ GetSineAndCosine routine

.cosA

 SKIP 1                 \ The result of the cos(A) calculation in the
                        \ GetSineAndCosine routine

\ ******************************************************************************
\
\       Name: Stack variables
\       Type: Workspace
\    Address: &0100 to &01BF
\   Category: Workspaces
\    Summary: Variables that share page 1 with the stack
\
\ ******************************************************************************

 ORG &0100              \ Set the assembly address to &0100

.objectFlags

 SKIP 64                \ Object flags for up to 64 objects
                        \
                        \   * Bits 0-5 = the number of the object beneath this
                        \                one, if bit 6 is set (0 to 63)
                        \
                        \   * Bit 6 = is this object stacked on top of another
                        \             object?
                        \
                        \       * Clear = no
                        \
                        \       * Set = this object is on top of another object
                        \               and the number of the object beneath
                        \               this one is in bits 0-5
                        \
                        \   * Bit 7 = has this object number been allocated to
                        \             an object or is it unused?
                        \
                        \       * Clear = this object number has been allocated
                        \                 to an object
                        \
                        \       * Set = this object number is unused

.objectPitchAngle

 SKIP 64                \ The pitch angle for each object (i.e. the vertical
                        \ direction in which they are facing)

.L0180

 SKIP 32                \ ???

.L01A0

 SKIP 32                \ ???

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
\       Name: tileData
\       Type: Variable
\   Category: Landscape
\    Summary: Altitude and shape data for landscape tiles
\
\ ------------------------------------------------------------------------------
\
\ The landscape in The Sentinel consists of a tiled area of 31x31 tiles, like an
\ undulating chess board that's sitting on a table in front of us, going into
\ the screen.
\
\ The shape of the landscape is defined by the altitude of the corners of each
\ tile, so that's a 32x32 grid of altitudes, one for each tile corner.
\
\ The x-axis is along the front edge, from left to right, while the z-axis goes
\ into the screen from front to back, away from us.
\
\ This table contains one byte of data for each tile corner in the landscape.
\
\ If there is no object placed on the tile, then the data contained in each byte
\ is as follows:
\
\   * The low nibble of each byte contains the tile shape, which describes the
\     layout and structure of the landscape on that tile (0 to 15).
\
\   * The high nibble of each byte contains the altitude of the tile corner in
\     the front-left corner of the tile (i.e. the corner closest to the origin
\     of the landscape). We call this tile corner the "anchor". The altitude is
\     in the range 1 to 11, so the top nibble never has both bit 6 and 7 set.
\
\ If there is an object placed on the tile, then the data contained in each byte
\ is as follows:
\
\   * Bits 0 to 5 contain the number of the object on the tile (0 to 63). If
\     there are multiple objects stacked on the tile, this is the number of the
\     object on the top of the stack.
\
\   * Bits 6 and 7 of the byte are set.
\
\ We can therefore test for the presence of an object on a tile by checking
\ whether both bit 6 and 7 are set (as empty tiles have the tile altitude in the
\ top nibble, and this is in the range 1 to 11).
\
\ As each tile is defined by a tile corner and a shape, we tend to use the terms
\ "tile" and "tile corner" interchangeably, depending on the context. That said,
\ for tile corners along the furthest back and rightmost edges of the landscape,
\ the shape data is ignored, as there is no landscape beyond the edges.
\
\ See the SetTileShape routine for information on the different types of tile
\ shape.
\
\ ******************************************************************************

.tileData

 EQUB &00, &00, &00, &00, &00, &00, &00, &27        \ These values are workspace
 EQUB &29, &20, &27, &29, &29, &27, &20, &00        \ noise and have no meaning
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
\       Name: xObject
\       Type: Variable
\   Category: 3D objects
\    Summary: The x-coordinates in 3D space for the 3D objects
\
\ ******************************************************************************

.xObject

 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &18

\ ******************************************************************************
\
\       Name: yObjectHi
\       Type: Variable
\   Category: 3D objects
\    Summary: The y-coordinates in 3D space for the 3D objects (high byte)
\
\ ------------------------------------------------------------------------------
\
\ The y-coordinate (i.e. the altitude) of each object is stored as a 16-bit
\ number of the form (yObjectHi yObjectLo). The low byte is effectively a
\ fractional part, as a y-coordinate of (1 0) is the same magnitude as an
\ x-coordinate or z-coordinate of 1.
\
\ A full coordinate in the 3D space is therefore in the form:
\
\   (xObject, (yObjectHi yObjectLo), zObject)
\
\ ******************************************************************************

.yObjectHi

 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &4B, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &02

\ ******************************************************************************
\
\       Name: zObject
\       Type: Variable
\   Category: 3D objects
\    Summary: The z-coordinates in 3D space for the 3D objects
\
\ ******************************************************************************

.zObject

 EQUB &00, &07, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &BF, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &07

\ ******************************************************************************
\
\       Name: objectYawAngle
\       Type: Variable
\   Category: 3D objects
\    Summary: The yaw angle for each object (i.e. the horizontal direction in
\             which they are facing)
\
\ ******************************************************************************

.objectYawAngle

 EQUB &00, &CE, &F8, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &12, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &80

\ ******************************************************************************
\
\       Name: yObjectLo
\       Type: Variable
\   Category: 3D objects
\    Summary: The y-coordinates in 3D space for the 3D objects (low byte)
\
\ ------------------------------------------------------------------------------
\
\ The y-coordinate (i.e. the altitude) of each object is stored as a 16-bit
\ number of the form (yObjectHi yObjectLo). The low byte is effectively a
\ fractional part, as a y-coordinate of (1 0) is the same magnitude as an
\ x-coordinate or z-coordinate of 1.
\
\ A full coordinate in the 3D space is therefore in the form:
\
\   (xObject, (yObjectHi yObjectLo), zObject)
\
\ ******************************************************************************

.yObjectLo

 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &E0

\ ******************************************************************************
\
\       Name: objectTypes
\       Type: Variable
\   Category: 3D objects
\    Summary: The object types table for up to 64 objects
\
\ ------------------------------------------------------------------------------
\
\ The different object types are as follows:
\
\   * 0 = Robot (one of which is the player)
\
\   * 1 = Sentry
\
\   * 2 = Tree
\
\   * 3 = Boulder
\
\   * 4 = Meanie
\
\   * 5 = The Sentinel
\
\   * 6 = The Sentinel's tower
\
\ ******************************************************************************

.objectTypes

 EQUB &00, &06, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &09

\ ******************************************************************************
\
\       Name: L0A80
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L0A80

 EQUB &6F, &70, &71, &73, &74, &75, &76, &78        \ These values are workspace
 EQUB &79, &7B, &7C, &7E, &7F, &81, &82, &84        \ noise and have no meaning
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

\ ******************************************************************************
\
\       Name: L0AE0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L0AE0

 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
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

 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ These values are workspace
 EQUB &00, &00, &00, &00, &00, &00, &00, &00        \ noise and have no meaning
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &10, &10

\ ******************************************************************************
\
\       Name: L0B40
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L0B40

 EQUB &10, &10, &10, &10, &10, &10, &10, &10        \ These values are workspace
 EQUB &10, &10, &10, &10, &10, &10, &10, &10        \ noise and have no meaning
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

\ ******************************************************************************
\
\       Name: L0BA0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L0BA0

 EQUB &3B, &C1, &48, &D6, &5A, &DD, &69, &EB        \ These values are workspace
 EQUB &6B, &F3, &71, &EE, &73, &ED, &67, &E7        \ noise and have no meaning
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
\       Name: Main variable workspace
\       Type: Workspace
\    Address: &0C00 to &0CFF
\   Category: Workspaces
\    Summary: The main block of game variables
\
\ ******************************************************************************

.sinAngleLo

 EQUB 0                 \ The low byte of the sine of a pitch or yaw angle,
                        \ as calculated by the GetRotationMatrix routine

.cosAngleLo

 EQUB 0                 \ The low byte of the cosine of a pitch or yaw angle,
                        \ as calculated by the GetRotationMatrix routine

.sinAngleHi

 EQUB 0                 \ The high byte of the sine of a pitch or yaw angle,
                        \ as calculated by the GetRotationMatrix routine

.cosAngleHi

 EQUB 0                 \ The high byte of the cosine of a pitch or yaw angle,
                        \ as calculated by the GetRotationMatrix routine

.L0C04

 EQUB 0                 \ ???

.xIconCounter

 EQUB &28               \ A counter for drawing the icons in the top-left of the
                        \ screen that show the player's energy level, as we work
                        \ from left top right along the x-axis

.minEnemyAltitude

 EQUB 0                 \ The altitude of the lowest enemy on the landscape

.maxNumberOfEnemies

 EQUB 0                 \ The maximum number of enemies that can appear on the
                        \ current landscape, which is calculated as follows:
                        \
                        \   min(8, 1 + (landscapeNumber div 10))
                        \
                        \ So landscapes 0000 to 0009 have a maximum enemy count
                        \ of 1, landscapes 0010 to 0019 have a maximum enemy
                        \ count of 2, and so on up to landscapes 0070 and up,
                        \ which have a maximum enemy count of 8

.tileDataMultiplier

 EQUB 0                 \ A multiplier that we apply to the altitudes of the
                        \ tile corners to alter the steepness of the landscape
                        \ during landscape generation

.L0C09

 EQUB 0                 \ ???

.playerEnergy

 EQUB 0                 \ The player's energy level (in the range 0 to 63)

 EQUB 0                 \ This byte appears to be unused

.J

 SKIP 1                 \ Temporary storage, used in the maths routines from
                        \ Revs

.L0C0D

 EQUB 0                 \ ???

.L0C0E

 EQUB 0                 \ ???

.textDropShadow

 EQUB 0                 \ Controls whether text in text tokens is printed with a
                        \ drop shadow
                        \
                        \   * Bit 7 clear = drop shadow
                        \
                        \   * Bit 7 set = no drop shadow

.L0C10

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0
 EQUB 0

.xTileSentinel

 EQUB 0                 \ The tile x-coordinate of the Sentinel

.zTileSentinel

 EQUB 0                 \ The tile z-coordinate of the Sentinel

.L0C1B

 EQUB 0                 \ ???

.titleObjectToDraw

 EQUB 5                 \ The object we are drawing in the DrawTitleObject
                        \ routine

.latestPanKeyPress

 EQUB 0                 \ The key logger value of the latest pan key press,
                        \ which will either be a current key press or the value
                        \ from the last pan key press to be made
                        \
                        \   * 0 = pan right
                        \
                        \   * 1 = pan left
                        \
                        \   * 2 = pan up
                        \
                        \   * 3 = pan down

.L0C1E

 EQUB 0                 \ ???

.samePanKeyPress

 EQUB 0                 \ Records whether the same pan key is being held down
                        \ compared to the last time we checked
                        \
                        \   * Bit 7 clear = same pan key is bot being held down
                        \
                        \   * Bit 7 set = same pan key is being held down

.L0C20

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.L0C28

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.objRotationTimer

 EQUB 0, 0, 0, 0        \ A timer that counts down on each iteration of the main
 EQUB 0, 0, 0, 0        \ game loop for each object, to control when that object
 EQUB 0, 0, 0, 0        \ rotates
 EQUB 0, 0, 0, 0

.L0C40

 EQUB 0                 \ ???

.L0C41

 EQUB 0                 \ ???

.L0C42

 EQUB 0                 \ ???

.L0C43

 EQUB 0                 \ ???

.L0C44

 EQUB 0

 EQUB 0, 0              \ These bytes appear to be unused

.L0C47

 EQUB 0                 \ ???

.L0C48

 EQUB 2                 \ ???

.L0C49

 EQUB 32                \ ???

.L0C4A

 EQUB 7                 \ ???

.drawingTitleScreen

 EQUB %10000000         \ A flag to indicate whether we are currently drawing
                        \ the title screen in the DrawTitleScreen routine
                        \
                        \   * Bit 7 clear = we are not drawing the title screen
                        \
                        \   * Bit 7 set = we are drawing the title screen

.L0C4C

 EQUB 1                 \ ???

.L0C4D

 EQUB 0                 \ ???

.sentinelHasWon

 EQUB 0                 \ A flag to record when the player runs out of energy
                        \ (i.e. the energy level goes negative), at which point
                        \ the Sentinel wins
                        \
                        \   * Bit 7 clear = player still has positive energy
                        \
                        \   * Bit 7 set = player has run out of energy and the
                        \                 Sentinel has won

.L0C4F

 EQUB 0                 \ ???

.L0C50

 EQUB 0                 \ ???

.uTurnStatus

 EQUB 0                 \ A flag to record whether we are performing or have
                        \ just performed a U-turn
                        \
                        \   * Bit 6 clear = do not perform a U-turn if "U" is
                        \                   pressed
                        \
                        \   * Bit 6 set = do a U-turn if "U" is pressed
                        \
                        \ Bit 6 is set in CheckForKeyPresses (which is called by
                        \ the interrupt handler) if "U" is not being pressed, so
                        \ this flag ensures that pressing and holding the "U"
                        \ key does not continuously perform U-turns, and instead
                        \ only performs a single U-turn
                        \
                        \ When a "U" key press is detected in ProcessActionKeys,
                        \ uTurnStatus is shifted left, so for the first
                        \ iteration of the main game loop after "U" is pressed,
                        \ bit 7 is set to indicate that we just performed a
                        \ U-turn

.landscapeZero

 EQUB 0                 \ A flag that is set depending on whether we are playing
                        \ landscape 0000
                        \
                        \   * Zero = this is landscape 0000
                        \
                        \   * Non-zero = this is not landscape 0000

.G2

 EQUB 0                 \ Temporary storage, used in the maths routines from
                        \ Revs, where the original variable name was G (this
                        \ variable has been renamed to G2 to prevent a clash
                        \ with the G variable that is used by The Sentinel)

.H2

 EQUB 0                 \ Temporary storage, used in the maths routines from
                        \ Revs, where the original variable name was H (this
                        \ variable has been renamed to H2 to prevent a clash
                        \ with the H variable that is used by The Sentinel)

.stashOffset

 EQUB 0                 \ The offset into the secretCodeStash where we store a
                        \ set of generated values for later checking in the
                        \ sub_C24EA routine ???
                        \
                        \ sub_C2A1B writes a value to this location
                        \
                        \ e.g. &8D for landscape 0, &BF for landscape 1
                        \
                        \ using the STA instruction at &2A2A
                        \
                        \ So this value seems to be set by the landscape drawing
                        \ process in some way ???

.L0C56

 EQUB 0                 \ ???

.L0C57

 EQUB 13                \ ???

.L0C58

 EQUB 0                 \ ???

.L0C59

 EQUB &16               \ ???

 EQUB 0                 \ This byte appears to be unused

.L0C5B

 EQUB &E0               \ ???

.L0C5C

 EQUB &B7               \ ???

.L0C5D

 EQUB &E4               \ ???

.L0C5E

 EQUB &52               \ ???

.sightsAreVisible

 EQUB 0                 \ Controls whether the sights are being shown
                        \
                        \   * Bit 7 clear = sights are not being shown
                        \
                        \   * Bit 7 set = sights are being shown

.printTextIn3D

 EQUB 0                 \ Controls whether we are printing text normally or in
                        \ 3D (as in the game's title on the title screen)
                        \
                        \   * Bit 7 clear = normal text
                        \
                        \   * Bit 7 set = 3D text

.objectType

 SKIP 0                 \ Storage for the type of object that we are spawning
                        \
                        \ This shares the same memory location as keyPress

.keyPress

 EQUB 0                 \ Storage for the key logger value for a key press
                        \
                        \ This shares the same memory location as objectType
                        \
                        \ This means that if the player presses one of the
                        \ "create" keys, then the value in the key logger (as
                        \ defined in the keyLoggerConfig table) can be used as
                        \ the object type to create, as "Create robot" puts a 0
                        \ in the key logger (the object type for a robot),
                        \ "Create tree" puts a 2 in the logger (the object type
                        \ for a tree) and "Create boulder" puts a 3 in the
                        \ logger (the object type for a boulder)

.L0C62

 EQUB 0                 \ ???

.playerHasMovedTile

 EQUB 0                 \ A flag to record whether the player has moved to a new
                        \ tile by transferring or hyperspacing, so we can decide
                        \ whether to regenerate the player's landscape view
                        \
                        \   * Bit 7 clear = player has not moved to a new tile
                        \
                        \   * Bit 7 set = player has moved to a new tile

.quitGame

 EQUB 0                 \ A flag to record whether the player has pressed
                        \ function key f1 to quit the game
                        \
                        \   * Bit 7 clear = do not quit the game
                        \
                        \   * Bit 7 set = quit the game

.secretCodeChecks

 EQUB 0                 \ Bits 1 to 4 store the results of checking each of the
                        \ four two-digit numbers in a landscape's secret entry
                        \ code
                        \
                        \ A set bit indicates a match while a clear bit
                        \ indicates a failure

 EQUB 0                 \ This byte appears to be unused

.L0C67

 EQUB 0                 \ ???

.L0C68

 EQUB 0                 \ ???

.L0C69

 EQUB 0                 \ ???

.L0C6A

 EQUB 0                 \ ???

.L0C6B

 EQUB 0                 \ ???

.L0C6C

 EQUB 0                 \ ???

.L0C6D

 EQUB 0                 \ ???

.L0C6E

 EQUB 0                 \ Another bit 7 flag ???

.numberOfEnemies

 EQUB 0                 \ The number of enemies in the current landscape,
                        \ including the Sentinel (in the range 1 to 8)

.L0C70

 EQUB 0                 \ ???

.doNotPlayLandscape

 EQUB 0                 \ A flag that controls whether we preview and play the
                        \ landscape after generating it
                        \
                        \   * Bit 7 clear = preview and play the landscape
                        \
                        \   * Bit 7 set = do not preview or play the landscape
                        \
                        \ This allows us to generate a landscape and its secret
                        \ code without actually playing it, which we need to do
                        \ in two cases:
                        \
                        \   * When the player enters an incorrect secret code
                        \
                        \   * When displaying a landscape's secet code after the
                        \     level is completed
                        \
                        \ In both cases we need to generate the landscape before
                        \ we can check or display the secret code, but we don't
                        \ want to go on to preview or play the landscape
                        \
                        \ This variable is reset to zero by the ResetVariables
                        \ routine, so when a new game starts the default
                        \ behaviour is to preview and play the landscape after
                        \ generating it in the GenerateLandscape routine

.gamePaused

 EQUB 0                 \ A flag to record whether the game is paused
                        \
                        \   * Bit 7 clear = the game is not paused
                        \
                        \   * Bit 7 set = the game is paused

.L0C73

 EQUB 0                 \ ???

.L0C74

 EQUB 0                 \ ???

.L0C75

 EQUB 0                 \ ???

.L0C76

 EQUB 0                 \ ???

 EQUB 0                 \ This byte appears to be unused

.L0C78

 EQUB &EF               \ ???

 EQUB 0                 \ This byte appears to be unused

.L0C7A

 EQUB &AA               \ ???

.seedNumberLFSR

 EQUB 0                 \ A five-byte linear feedback shift register for
 EQUB 0                 \ generating a sequence of seed numbers for each
 EQUB 1                 \ landscape
 EQUB 0
 EQUB 0

.enemyData1

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData2

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData3

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData4

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData5

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData6

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData7

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

.enemyData8

 EQUB 0, 0, 0, 0        \ ???
 EQUB 0, 0, 0, 0

 EQUB 0                 \ ???

.scrollCounter

 EQUB 0                 \ A counter for the number of columns or rows we still
                        \ need to scroll in the player's scrolling landscape
                        \ view when the player pans
                        \
                        \ Scrolling is implemented in the interrupt handler one
                        \ column or row at a time, scrolling one character block
                        \ width or height at each step via the ScrollPlayerView
                        \ routine
                        \
                        \ This counter keeps track of each step, decrementing
                        \ after each column or row is scrolled, so we only
                        \ scroll when scrollCounter is non-zero

.viewScreenAddr

 EQUW &60C0             \ The screen address of the player's scrolling landscape
                        \ view, which is just below the icon and scanner row at
                        \ the top of the screen

.L0CC4

 EQUB 0                 \ ???

.L0CC5

 EQUB 0                 \ ???

.xSights

 EQUB 0                 \ The x-coordinate of the sights

.ySights

 EQUB 0                 \ The y-coordinate of the sights

.sightsInitialMoves

 EQUB 0                 \ Controls the initial movement of the sights over the
                        \ first eight calls to the CheckForKeyPresses routine
                        \
                        \ Movement in the first eight calls is determined by
                        \ the settings of bit 7 to bit 0, where a set bit
                        \ indicates a pause and a clear bit indicates a move

.L0CC9

 EQUB 0                 \ ???

.iconRowAddr

 EQUW &7F80             \ The screen address of the icon and scanner row along
                        \ the top of the screen

.L0CCC

 EQUB 0                 \ ???

.L0CCD

 EQUB 0                 \ ???

.L0CCE

 EQUB 0                 \ ???

.L0CCF

 EQUB 0                 \ ???

.L0CD0

 EQUB 0                 \ ???

.numberOfScrolls

 EQUB 0                 \ The total number of scrolls that we need to perform
                        \ for the current panning operation
                        \
                        \ This is used to initialise the value of the scroll
                        \ counter in scrollCounter before we start scrolling

.L0CD2

 EQUB 0                 \ ???

.L0CD3

 EQUB 0                 \ ???

.L0CD4

 EQUB 0, 0, 0           \ ???

.L0CD7

 EQUB 0, 0, 0, 0, 0     \ ???

.previousDoNotScan

 EQUB 0                 \ Storage for the current setting of doNotScanKeyboard
                        \ in the sub_C1200 routine, so we can check whether
                        \ doNotScanKeyboard has changed in sub_C1264 ???

.L0CDD

 EQUB 0                 \ ???

.L0CDE

 EQUB 0                 \ ???

.soundCounter

 EQUB 0                 \ A counter for the sound currently being made, which
                        \ counts down in the IRQHandler routine at a rate of 50
                        \ times a second
                        \
                        \ When the counter reaches zero, it indicates that the
                        \ sound has finished

 EQUB 0, 0, 0, 0        \ These bytes appear to be unused

.doNotScanKeyboard

 EQUB %10000000         \ A flag that controls whether we scan the keyboard
                        \
                        \   * Bit 7 clear = scan the keyboard
                        \
                        \   * Bit 7 set = do not scan the keyboard
                        \
                        \ Specifically, setting bit 7 disables the following
                        \ keyboard scans:
                        \
                        \   * Volume keys in ProcessVolumeKeys
                        \
                        \   * Game key presses in IRQHandler
                        \
                        \   * Game key presses in sub_C1264

.activateSentinel

 EQUB %10000000         \ A flag to record when the Sentinel is activated at the
                        \ start of the game (by the player pressing a key that
                        \ expends or absorbs energy
                        \
                        \   * Bit 7 clear = the Sentinel is activated
                        \
                        \   * Bit 7 set = the Sentinel is not yet activated
                        \
                        \ This gives the player time to get their bearings when
                        \ they first start a landscape

.playerIsOnTower

 EQUB 128               \ A flag to record whether the player is on top of the
                        \ the Sentinel's tower
                        \
                        \   * 6 = the player is on top of the Sentinel's tower
                        \
                        \   * Any other value = the player is not on top of the
                        \                       Sentinel's tower
                        \
                        \ This value is used when generating the secret code on
                        \ completion of a level, where an incorrect value will
                        \ corrupt the code (so this forms part of the cracker
                        \ protection code)

.L0CE7

 EQUB %10000000         \ ???

.keyLogger

 EQUB &80, &80          \ The four-byte key logger for logging game key presses
 EQUB &80, &80

 EQUB &80, &80          \ These bytes appear to be unused
 EQUB &80, &80

.inputBuffer

 EQUB 0, 0, 0, 0        \ The eight-byte keyboard input buffer
 EQUB 0, 0, 0, 0        \
                        \ Key presses are stored in the input buffer using an
                        \ ascending stack, with new input being pushed into
                        \ inputBuffer, and any existing content in the buffer
                        \ moving up in memory

 EQUB 0, 0, 0, 0        \ These bytes appear to be unused

.gameInProgress

 EQUB %11000000         \ Flags whether or not a game is in progress (i.e. the
                        \ player is playing a landscape rather than interacting
                        \ with the title and preview screens)
                        \
                        \   * Bit 7 clear = game is in progress
                        \
                        \   * Bit 7 set = game is not in progress
                        \
                        \ This controls whether or not the interrupt handler
                        \ updates the game

.landscapeNumberLo

 EQUB 0                 \ The low byte of the four-digit binary coded decimal
                        \ landscape number (0000 to 9999)

.landscapeNumberHi

 EQUB 0                 \ The high byte of the four-digit binary coded decimal
                        \ landscape number (0000 to 9999)

 EQUB 0                 \ This byte appears to be unused

\ ******************************************************************************
\
\       Name: NMIHandler
\       Type: Subroutine
\   Category: Setup
\    Summary: The NMI handler at the start of the NMI workspace
\
\ ******************************************************************************

.NMIHandler

 RTI                    \ This is the address of the current NMI handler, at
                        \ the start of the NMI workspace at address &0D00
                        \
                        \ We put an RTI instruction here to make sure we return
                        \ successfully from any NMIs that call this workspace

\ ******************************************************************************
\
\       Name: irq1Address
\       Type: Variable
\   Category: Main game loop
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
\       Name: GetAngleFromCoords (Part 1 of 3)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Given the coordinates along two axes, calculate the pitch or yaw
\             angle to those coordinates
\
\ ------------------------------------------------------------------------------
\
\ The first part of this routine is based on the Divide16x16 routine in Revs,
\ Geoff Crammond's previous game, except it supports a divisor (V W) instead of
\ (V 0), though only the top three bits of W are included in the calculation.
\
\ The calculation is as follows:
\
\   (angleHi angleLo) = arctan( (A T) / (V W) )
\
\ where (A T) < (V W).
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               First coordinate as an unsigned integer
\
\   (V W)               Second coordinate as an unsigned integer
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   (angleHi angleLo)   The pitch or yaw angle from the origin to the coordinate
\
\   angleTangent        Contains 256 * (A T) / (V W), which is the tangent of
\                       the pitch or yaw angle
\
\ ******************************************************************************

.GetAngleFromCoords

                        \ We start by calculating the following using a similar
                        \ shift-and-subtract algorithm as Revs:
                        \
                        \   T = 256 * (A T) / (V W)
                        \
                        \ In Revs, W is always zero, so there is some extra code
                        \ below to cater for a full 16-bit value in (V W)

 ASL T                  \ Shift T left, which clears bit 0 of T, ready for us to
                        \ start building the result in T at the same time as we
                        \ shift the low byte of (A T) out to the left

                        \ We now repeat the following seven-instruction block
                        \ eight times, one for each bit in T

 ROL A                  \ Shift the high byte of (A T) to the left to extract
                        \ the next bit from the number being divided

 BCS gang1              \ If we just shifted a 1 out of A, skip the next few
                        \ instructions and jump straight to the subtraction

 CMP V                  \ If A < V then jump to gang2 with the C flag clear, so
 BCC gang2              \ we shift a 0 into the result in T

                        \ This part of the routine has been added to the Revs
                        \ algorithm to cater for both arguments being full
                        \ 16-bit values (in Revs the second value always has a
                        \ low byte of zero)

 BNE gang1              \ If A > V then jump to gang1 to calculate a full 16-bit
                        \ subtraction

                        \ If we get here then A = V

 LDY T                  \ If T < W then jump to gang2 with the C flag clear, so
 CPY W                  \ we shift a 0 into the result in T
 BCC gang2

.gang1

                        \ If we get here then T >= W and A >= V, so we know that
                        \ (A T) >= (V W)
                        \
                        \ We now calculate (A T) - (V W) as the subtraction part
                        \ of the shift-and-subtract algorithm

 STA U                  \ Store A in U so we can retrieve it after the following
                        \ calculation

 LDA T                  \ Subtract the low bytes as T = T - W
 SBC W                  \
 STA T                  \ This calculation works as we know the C flag is set,
                        \ as we passed through a BCC above

 LDA U                  \ Restore the value of A from before the subtraction

 SBC V                  \ Subtract the high bytes as A = A - V

 SEC                    \ Set the C flag so we shift a 1 into the result in T

.gang2

 ROL T                  \ Shift the result in T to the left, pulling the C flag
                        \ into bit 0

 ROL A                  \ Repeat the 16-bit shift-and-subtract loop for the
 BCS gang3              \ second shift
 CMP V
 BCC gang4
 BNE gang3
 LDY T
 CPY W
 BCC gang4

.gang3

 STA U                  \ Repeat the 16-bit subtraction for the second shift
 LDA T
 SBC W
 STA T
 LDA U
 SBC V
 SEC

.gang4

 ROL T                  \ Shift the result for the second shift into T

 ROL A                  \ Repeat the 16-bit shift-and-subtract loop for the
 BCS gang5              \ third shift
 CMP V
 BCC gang6
 BNE gang5
 LDY T
 CPY W
 BCC gang6

.gang5

 STA U                  \ Repeat the 16-bit subtraction for the third shift
 LDA T
 SBC W
 STA T
 LDA U
 SBC V
 SEC

.gang6

 PHP                    \ Store the C flag on the stack, so the stack contains
                        \ the result bit from shifting and subtracting the third
                        \ shift

 CMP V                  \ If A = V then jump to gang10 with the C flag set, as
 BEQ gang10             \ we can skip the rest of the shifts and still get a
                        \ good result ???

 ASL T                  \ Shift a zero for the third shift into T, so bit 5 of
                        \ the result is always clear
                        \
                        \ We do this so we can set this bit later, depending on
                        \ the value that we stored on the stack above

 ROL A                  \ Repeat the shift-and-subtract loop for the fourth
 BCS P%+6               \ shift
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for the fifth shift
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for the sixth shift
 BCS P%+6
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for the seventh
 BCS P%+6               \ shift
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

 ROL A                  \ Repeat the shift-and-subtract loop for the eighth
 BCS P%+6               \ shift
 CMP V
 BCC P%+5
 SBC V
 SEC
 ROL T

                        \ We now have the division result that we want:
                        \
                        \   T = 256 * (A T) / (V W)
                        \
                        \
                        \ but with bit 5 clear rather than the actual result
                        \
                        \ This result can be used to look up the resulting angle
                        \ from the arctangent table, but first we continue the
                        \ division to enable us to improve accuracy

\ ******************************************************************************
\
\       Name: GetAngleFromCoords (Part 2 of 3)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Overflow and accuracy calculations
\
\ ******************************************************************************

                        \ We now do two more shift-and-subtracts to see if we
                        \ can should make the result more accurate in part 3
                        \ with interpolation and rounding

 ROL A                  \ Repeat the shift-and-subtract loop for the ninth
 BCS P%+6               \ shift, but without updating the result in T
 CMP V
 BCC P%+5
 SBC V
 SEC

 ROR G                  \ Shift the carry into bit 7 of G, so it contains the
                        \ result from shifting and subtracting bit 8

 ROL A                  \ Repeat the shift-and-subtract loop for the tenth
 BCS gang7              \ shift, but without subtracting or updating the result
 CMP V                  \ in T

.gang7

 ROR G                  \ Shift the carry into bit 7 of G, so it contains the
                        \ result from shifting and subtracting the tenth shift,
                        \ and the result from the ninth shift is now in bit 6
                        \ of G
                        \
                        \ So G now contains two results bits as follows:
                        \
                        \   * Bit 6 is the first extra bit from the result,
                        \     and if it is set then we apply interpolation to
                        \     the result in part 3
                        \
                        \   * Bit 7 is the second extra bit from the result,
                        \     and if it is set then we apply rounding to the
                        \     result in part 3
                        \
                        \ We use these below to work out whether to interpolate
                        \ results from the arctan lookup table, to improve the
                        \ accuracy of the result

 LDA T                  \ Set A to the result of the division we did above, so
                        \ we now have the following:
                        \
                        \   A = 256 * (A T) / (V W)
                        \
                        \ but with bit 5 clear rather than the actual result
                        \ and the next two result bits in bits 6 and 7 of Q

.gang8

                        \ We now use the result of the third shift of the
                        \ shift-and-subtract calculation to set bit 5 in the
                        \ result, which we cleared in the calculation above

 PLP                    \ Retrieve the result bit from the third shift, which
                        \ we stored on the stack in part 1
                        \
                        \ This bit repesents the third bit pushed into the
                        \ result, so that's what should be bit 5 of the result
                        \
                        \ It is now in the C flag (because it was in the C flag
                        \ when we performed the PHP to push it onto the stack)

 BCC gang9              \ If the C flag is clear then bit 5 of the result should
                        \ remain clear, so skip the following

                        \ Otherwise bit 5 of the result should be set, which we
                        \ can do with the following addition (in which we know
                        \ that the C flag is set, as we just passed through a
                        \ BCC instruction)

 ADC #%00100000 - 1     \ Set A = A + %00100000 - 1 + C
                        \       = A + %00100000
                        \
                        \ If we get here having done all ten shifts, then we
                        \ know that bit 5 of the result in A is clear, as we
                        \ cleared it with the ASL T instruction just after gang6
                        \ above, so this just sets bit 5 of the result in A
                        \ without any risk of the addition overflowing
                        \
                        \ If, however, we get here by aborting the sequence of
                        \ shifts after the second shift and jumping to gang10,
                        \ then we have already set bit 5 of the result with an
                        \ ORA instruction in gang10 before jumping back to
                        \ gang8, so there is a possibility for this addition to
                        \ overflow ???

.gang9

 BCC gang11             \ If the above addition was skipped, or it was applied
                        \ and didn't overflow, then jump to gang11 to continue
                        \ with the calculation

                        \ If we get here then the above addition overflowed, so
                        \ we return the highest angle possible from the table,
                        \ which is 45 degrees

 LDA #255               \ Set angleTangent = 255, which is the closest we can
 STA angleTangent       \ get to the tangent of 45 degrees, which should really
                        \ be represented by (1 0) in our scale

 LDA #&00               \ Set (angleHi angleLo) = (&20 0)
 STA angleLo            \
 LDA #&20               \ This represents an angle of 45 degrees, as a full
 STA angleHi            \ circle of 360 degrees is represented by (1 0 0), and:
                        \
                        \   360 degrees / 8 = 45
                        \
                        \   256 / 8 = &20

 RTS                    \ Return from the subroutine

.gang10

                        \ If we get here then we have stopped shifting and
                        \ subtracting after just three shifts
                        \
                        \ We stored the first two shifts in T, but didn't store
                        \ the third shift in T

 LDA #0                 \ Clear bits 6 and 7 of G to indicate that we should not
 STA G                  \ apply interpolation or rounding in part 3

 ROR T                  \ Set A to the bottom two bits of T, which is the same
 ROR A                  \ result as if we had shifted T left through the rest of
 ROR T                  \ the shift-and-subtract process that we've skipped
 ROR A

 ORA #%00100000         \ Set bit 5 of the result in A ???
                        \
                        \ So we now have the result of the division in A

 JMP gang8              \ Jump to gang8 to continue the processing from the end
                        \ of the division process

\ ******************************************************************************
\
\       Name: GetAngleFromCoords (Part 3 of 3)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the arctangent to get the angle
\
\ ******************************************************************************

.gang11

                        \ By this point we have calculated the following:
                        \
                        \   A = 256 * (A T) / (V W)
                        \
                        \ so now we calculate arctan(A)

 TAY                    \ Set Y to the value of A so we can use it as an index
                        \ into the arctan tables

 STA angleTangent       \ Set angleTangent = 256 * (A T) / (V W)
                        \
                        \ So we return the tangent from the routine in
                        \ angleTangent

 LDA arctanLo,Y         \ Set (angleHi angleLo) = arctan(Y)
 STA angleLo
 LDA arctanHi,Y
 STA angleHi

                        \ We now improve the accuracy of this result by applying
                        \ interpolation and rounding, but only if one of bit 6
                        \ or bit 7 is set in G

 BIT G                  \ If bit 7 of G is set, jump to gang12 to calculate
 BMI gang12             \ a value in (U T) that we can then use for rounding up
                        \ the result of the interpolation

 BVS gang14             \ If bit 7 of G is clear and bit 6 of G is set, jump to
                        \ gang14 to interpolate the result with the next entry
                        \ in the arctan table, without using rounding

 JMP gang16             \ Otherwise both bit 7 and bit 6 of G must be clear, so
                        \ jump to gang16 to return from the subroutine, as the
                        \ result in (angleHi angleLo) is already accurate and
                        \ doesn't need interpolating

.gang12

                        \ If we get here then we need to apply rounding to the
                        \ result as well as interpolating the result between
                        \ arctan(Y) and arctan(Y + 1)

 LDA angleLo            \ Set (A T) = (angleHi angleLo) - arctan(Y + 1)
 SEC                    \           = arctan(Y) - arctan(Y + 1)
 SBC arctanLo+1,Y       \
 STA T                  \ So (A T) contains the amount of rounding we need to
 LDA angleHi            \ add to the result (the result is divided by two below)
 SBC arctanHi+1,Y

 BIT G                  \ If bit 6 of G is set, negate (A T) to give the correct
 BVC gang13             \ sign to the amount of rounding
 JSR Negate16Bit

.gang13

 STA U                  \ Set (U T) = (A T)
                        \           = arctan(Y) - arctan(Y + 1)

 ROL A                  \ Set the C flag to bit 7 of A, which is the top bit of
                        \ (U T), so the next instruction rotates the correct
                        \ bit into bit 7 of U to retain the sign of the result

 ROR U                  \ Set (U T) = (U T) / 2
 ROR T                  \           = arctan(Y) - arctan(Y + 1)
                        \
                        \ So (U T) contains half the difference between
                        \ arctan(Y) and arctan(Y + 1)
                        \
                        \ This is effectively half the difference between the
                        \ two values, so this is the equivalent of the 0.5 in
                        \ INT(x + 0.5) when rounding x to the nearest integer,
                        \ just with the arctan results in our calculation

.gang14

                        \ If we get here then we need to interpolate the result
                        \ between arctan(Y) and arctan(Y + 1)

 LDA angleLo            \ Set (angleHi angleLo) = (angleHi angleLo)
 CLC                    \                                        + arctan(Y + 1)
 ADC arctanLo+1,Y       \                       = arctan(Y) and arctan(Y + 1)
 STA angleLo            \
 LDA angleHi            \ We will divide this value by two to get the average
 ADC arctanHi+1,Y       \ of arctan(Y) and arctan(Y + 1), but first we need to
 STA angleHi            \ add the rounding in (U T), if applicable

 BIT G                  \ If bit 7 of G is clear, jump to gang15 to skip the
 BPL gang15             \ following, as the rounding in (U T) is only applied
                        \ when bit 7 of G is set

                        \ If we get here then bit 7 of G is set and we need to
                        \ add on the rounding in (U T)

 LDA angleLo            \ Set (angleHi angleLo) = (angleHi angleLo) + (U T)
 CLC
 ADC T
 STA angleLo
 LDA angleHi
 ADC U
 STA angleHi

.gang15

 LSR angleHi            \ Set (angleHi angleLo) = (angleHi angleLo) / 2
 ROR angleLo            \
                        \ So we now have the average value of arctan(Y) and
                        \ arctan(Y + 1), including rounding if applicable, so
                        \ the result has now been interpolated for more accuracy

.gang16

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetRotationMatrix (Part 1 of 5)
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the rotation matrix for rotating the pitch or yaw angle
\             for the sights into the global 3D coordinate system
\
\ ------------------------------------------------------------------------------
\
\ This routine is used to calculate the following:
\
\   sinAngle = sin(sightsPitchAngle)
\   cosAngle = cos(sightsPitchAngle)
\
\ or:
\
\   sinAngle = sin(sightsYawAngle)
\   cosAngle = cos(sightsYawAngle)
\
\ We can use these to create a rotation matrix that rotates the pitch or yaw
\ angle from the player's frame of reference into the global 3D coordinate
\ system, so we can take the vector describing the direction of gaze from the
\ player through the sights, and rotate it into a vector within the 3D world.
\
\ This routine is from Revs, Geoff Crammond's previous game. There are only
\ minor differences: the argument is (A T) instead of (A X), and the value of X
\ is preserved. Note that to avoid clashing names, the variables G and H have
\ been renamed to G2 and H2, but the routine is otherwise the same.
\
\ Also, because this routine comes from Revs, where it is only used to rotate
\ through the driver's yaw angle, I have renamed the result variables from
\ sinYawAngle and cosYawAngle to sinAngle and cosAngle, as The Sentinel uses
\ the routine to rotate through both yaw angles and pitch angles. To keep things
\ simple the commentary still refers to yaw angles, but the calculations apply
\ equally to pitch angles.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               The pitch or yaw angle to encapsulate in the rotation
\                       matrix
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
                        \           = sightsYawAngle or sightsPitchAngle
                        \
                        \ Note that because this routine is copied almost
                        \ verbatim from Revs, the commentary only refers to yaw
                        \ angles, but this routine can work just as well with
                        \ pitch angles as arguments

 STX xStoreMatrix       \ Store X in xStoreMatrix so it can be preserved across
                        \ calls to the routine

 JSR GetAngleInRadians  \ Set (U A) to the sightsYawAngle, reduced to a quarter
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
 STX secondAxis         \ into sinAngle and cos(H G) into cosAngle
 LDX #0

 BIT J                  \ If bit 6 of J is clear, then sightsYawAngle is in one
 BVC rotm1              \ of these ranges:
                        \
                        \   * 0 to 63 (%00000000 to %00111111)
                        \
                        \   * -128 to -65 (%10000000 to %10111111)
                        \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of player
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
                        \ So sightsYawAngle is in the top-right or bottom-left
                        \ quarter in the above diagram
                        \
                        \ In both cases we jump to rotm1 to set sinAngle and
                        \ cosAngle

                        \ If we get here then bit 6 of J is set, so
                        \ sightsYawAngle is in one of these ranges:
                        \
                        \   * 64 to 127 (%01000000 to %01111111)
                        \
                        \   * -64 to -1 (%11000000 to %11111111)
                        \
                        \ So sightsYawAngle is in the bottom-right or top-left
                        \ quarter in the above diagram
                        \
                        \ In both cases we set the variables the other way
                        \ round, as the triangle we draw to calculate the angle
                        \ is the opposite way round (i.e. it's reflected in the
                        \ x-axis or y-axis)

 INX                    \ Set X = 1 and secondAxis = 0, so we project sin(H G)
 DEC secondAxis         \ into cosAngle and cos(H G) into sinAngle

                        \ We now enter a loop that sets sinAngle + X to
                        \ sin(H G) on the first iteration, and sets
                        \ sinAngle + secondAxis to cos(H G) on the second
                        \ iteration
                        \
                        \ The commentary is for the sin(H G) iteration, see the
                        \ end of the loop for details of how the second
                        \ iteration calculates cos(H G) instead

.rotm1

                        \ If we get here, then we are set up to calculate the
                        \ following:
                        \
                        \   * If sightsYawAngle is top-right or bottom-left:
                        \
                        \     sinAngle = sin(sightsYawAngle)
                        \     cosAngle = cos(sightsYawAngle)
                        \
                        \   * If sightsYawAngle is bottom-right or top-left:
                        \
                        \     sinAngle = cos(sightsYawAngle)
                        \     cosAngle = sin(sightsYawAngle)
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

 STA sinAngleHi,X       \ Set (sinAngleHi sinAngleLo) = (A T)
 LDA T                  \
 AND #%11111110         \ with the sign bit cleared in bit 0 of sinAngleLo to
 STA sinAngleLo,X       \ denote a positive result

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

 AND #%11111110         \ Which we store in sinAngleLo, with bit 0 cleared to
 STA sinAngleLo,X       \ denote a positive result (as it's a sign-magnitude
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
                        \ high byte of the result in sinAngleHi
                        \
                        \ If the C flag is set, then the result is (1 A T), but
                        \ the highest possible value for sin or cos is 1, so
                        \ that's what we return
                        \
                        \ Because sinAngle is a sign-magnitude number with
                        \ the sign bit in bit 0, we return the following value
                        \ to represent the closest value to 1 that we can fit
                        \ into 16 bits:
                        \
                        \   (11111111 11111110)

 LDA #%11111110         \ Set sinAngleLo to the highest possible positive
 STA sinAngleLo,X       \ value (i.e. all ones except for the sign in bit 0)

 LDA #%11111111         \ Set A to the highest possible value of sinAngleHi,
                        \ so we can store it in the next instruction

.rotm4

 STA sinAngleHi,X       \ Store A in the high byte in sinAngleHi

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
 BEQ rotm6              \ now set both sinAngle and cosAngle, so jump to
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

 JMP rotm1              \ Loop back to set the other variable of sinAngle and
                        \ cosAngle to the cosine of the angle

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
                        \ x-coordinate in sinAngle and the y-coordinate in
                        \ cosAngle
                        \
                        \ The above calculations were done on an angle that was
                        \ reduced to a quarter-circle, so now we need to add the
                        \ correct signs according to which quarter-circle the
                        \ original sightsYawAngle in (J T) was in

 LDA J                  \ If J is positive then sightsYawAngle is positive (as
 BPL rotm7              \ J contains sightsYawAngleHi), so jump to rotm7 to skip
                        \ the following

                        \ If we get here then sightsYawAngle is negative
                        \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of player
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
                        \ So sightsYawAngle is in the left half of the above
                        \ diagram, where the x-coordinates are negative, so we
                        \ need to negate the x-coordinate

 LDA #1                 \ Negate sinAngle by setting bit 0 of the low byte,
 ORA sinAngleLo         \ as sinAngle is a sign-magnitude number
 STA sinAngleLo

.rotm7

 LDA J                  \ If bits 6 and 7 of J are the same (i.e. their EOR is
 ASL A                  \ zero), jump to rotm8 to return from the subroutine as
 EOR J                  \ the sign of cosAngle is correct
 BPL rotm8

                        \ Bits 6 and 7 of J, i.e. of sightsYawAngleHi, are
                        \ different, so the angle is in one of these ranges:
                        \
                        \   * 64 to 127 (%01000000 to %01111111)
                        \
                        \   * -128 to -65 (%10000000 to %10111111)
                        \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of player
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
                        \ So sightsYawAngle is in the bottom half of the above
                        \ diagram, where the y-coordinates are negative, so we
                        \ need to negate the y-coordinate

 LDA #1                 \ Negate cosAngle by setting bit 0 of the low byte,
 ORA cosAngleLo         \ as cosAngle is a sign-magnitude number
 STA cosAngleLo

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
\   (A T)               A yaw angle (-128 to +127)
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
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of player
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
\       Name: GetSineAndCosine
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the absolute sine and the cosine of an angle
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (A T)               The angle, representing a full circle with the range
\                       A = 0 to 255, and T representing the fractional part
\                       (though only bit 7 of T is used)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   sinA                The value of |sin(A)|
\
\   cosA                The value of |cos(A)|
\
\ ******************************************************************************

.GetSineAndCosine

 BPL scos1              \ If A is in the range 128 to 255, flip bit 6
 EOR #%01000000         \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of player
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
                        \ Bit 7 is set in the left half, so this operation only
                        \ affects angles in that half
                        \
                        \ In the left half, bit 6 is as follows:
                        \
                        \   * -1 to -64 (%11111111 to %11000000)
                        \
                        \   * -65 to -128 (%10111111 to %10000000)
                        \
                        \ so flipping bit 6 effectively swaps the two quarters
                        \ from this:
                        \
                        \            0
                        \      -32   |
                        \         \  |
                        \          \ |
                        \           \|
                        \   -64 -----+
                        \           /|
                        \          / |
                        \         /  |
                        \      -96   |
                        \           128
                        \
                        \ into this:
                        \
                        \           -64
                        \      -96   |
                        \         \  |
                        \          \ |
                        \           \|
                        \   128 -----+
                        \
                        \ and this:
                        \
                        \     0 -----+
                        \           /|
                        \          / |
                        \         /  |
                        \      -32   |
                        \           -64
                        \
                        \ by doing these conversions:
                        \
                        \   * -1 to -64 (%11111111 to %11000000)
                        \     -> -65 to -128 (%10111111 to %10000000)
                        \
                        \   * -65 to -128 (%10111111 to %10000000)
                        \   * -1 to -64 (%11111111 to %11000000)
                        \
                        \ This is the same as rotating the angle through 90
                        \ degrees, which is the same as adding PI/2 to the angle
                        \
                        \ It's a trigonometric identity that:
                        \
                        \   cos(x) = sin(x + PI/2)
                        \
                        \ so this shifts the angle so that when we fetch from
                        \ sine lookup table, we are actually getting the cosine
                        \
                        \ We use this fact below to determine which result to
                        \ return in sinA and cosA after we have done the lookups
                        \ from the sine table

.scos1

 STA H                  \ Store the updated angle argument in H so we can fetch
                        \ bits 6 and 7 from the angle below

 ASL T                  \ Set (A T) = (A T) << 1
 ROL A                  \
                        \ The original argument represents a full circle in the
                        \ range A = 0 to 255, so this reduces that range to a
                        \ half circle with A = 0 to 255, as bit 7 is shifted out
                        \ of the top
                        \
                        \ This effectively drops the left half of the angle
                        \ circle, to leave us with an angle in this range:
                        \
                        \            0
                        \            |   +64
                        \            |  /
                        \            | /
                        \            |/
                        \            +----- +128
                        \            |\
                        \            | \
                        \            |  \
                        \            |   +192
                        \           256

 AND #%01111111         \ Clear bit 6 of the result, so A represents a quarter
                        \ circle in the range 0 to 127
                        \
                        \ This effectively drops the bottom-right quarter of the
                        \ angle circle, to leave us with an angle in this range:
                        \
                        \            0
                        \            |   +64
                        \            |  /
                        \            | /
                        \            |/
                        \            +----- +127
                        \
                        \ So by this point we have discarded bits 6 and 7 of the
                        \ original angle and scaled the angle to be in the range
                        \ 0 to 127, so we can use the result as an index into
                        \ the sine table (which contains 128 values)
                        \
                        \ The sine table only covers angles in the first quarter
                        \ of the circle, which means the result of looking up a
                        \ value from the sine table will always be positive, so
                        \ this will return the absolute value, i.e. |sin(x)|

 TAX                    \ Copy A into X so we can use it as an index to fetch
                        \ the sine of our angle

 EOR #%01111111         \ Negate A using two's complement, leaving bit 7 clear
 CLC                    \
 ADC #1                 \ Because A was in the range 0 to 127 before being
                        \ negated, this is effectively the same as subtracting
                        \ A from 127, like this:
                        \
                        \   A = 127 - X

 BPL scos2              \ If A > 127 then set A = 127, so A is capped to the
 LDA #127               \ range 0 to 127 and is suitable for looking up the
                        \ result from the sine table

.scos2

 TAY                    \ Copy A into Y so we can use it as an index into the
                        \ sine table, so we have the following:
                        \
                        \   Y = 127 - X

                        \ Because our angle is in the first quadrant where 127
                        \ represents a quarter circle of 90 degrees or PI/2
                        \ radians, we can now look up the sine and cosine as
                        \ follows:

 LDA sin,X              \ Set A = sin(X)

 LDX sin,Y              \ Set X = sin(Y)
                        \       = sin(127 - X)
                        \       = sin(PI/2 - X)
                        \
                        \ And because X is in the range 0 to PI/2, we have:
                        \
                        \   X = sin(PI/2 - X)
                        \     = cos(X)

                        \ Because the sine table only contains positive values
                        \ from the first quadrant, this means we have the
                        \ following:
                        \
                        \   A = |sin(X)|
                        \
                        \   X = |cos(X)|
                        \
                        \ We now need to analyse the original angle argument A
                        \ (via bits 6 and 7 of the angle in H) to make sure we
                        \ return the correct result
                        \
                        \ Here's the angle system again:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of player
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
                        \ If our original angle argument A is the top-right
                        \ quadrant then the result above will be correct
                        \
                        \ If our original angle argument A is the bottom-right
                        \ quadrant then we can apply the following trigonometric
                        \ identities:
                        \
                        \   sin(A) = sin(X + PI/2)
                        \          = cos(X)
                        \
                        \   cos(A) = cos(X + PI/2)
                        \          = -sin(X)
                        \
                        \ So for the original argument A, we have:
                        \
                        \   |sin(A)| = |cos(X)|
                        \
                        \   |cos(A)| = |-sin(X)|
                        \            = |sin(X)|
                        \
                        \ So it follows that for this angle range, we need to
                        \ return the current value of X for the sine result and
                        \ the current value of A for the cosine result
                        \
                        \ If our original angle argument A is the bottom-left
                        \ quadrant then we can apply the following trigonometric
                        \ identities:
                        \
                        \   sin(A) = sin(X + PI)
                        \          = -sin(X)
                        \
                        \   cos(A) = cos(X + PI)
                        \          = -cos(X)
                        \
                        \ And given that we are returning the absolute value,
                        \ this means for this quadrant, the return values are
                        \ correct
                        \
                        \ If our original angle argument A is the top-left
                        \ quadrant then we can apply the following trigonometric
                        \ identities:
                        \
                        \   sin(A) = sin(X - PI/2)
                        \          = -cos(X)
                        \
                        \   cos(A) = cos(X - PI/2)
                        \          = sin(X)
                        \
                        \ So again we need to return the current value of X for
                        \ the sine result and the current value of A for the
                        \ cosine result
                        \
                        \ In terms of the original angle A, then, we have the
                        \ following:
                        \
                        \   * Top-right quadrant = results are correct
                        \
                        \   * Bottom-right quadrant = swap sin and cos
                        \
                        \   * Bottom-left quadrant = results are correct
                        \
                        \   * Top-left quadrant = swap sin and cos
                        \
                        \ In terms of bits 6 and 7 of H, we swapped the left two
                        \ quadrants, so this means:
                        \
                        \   * Top-right quadrant = both clear
                        \
                        \   * Bottom-right quadrant = bit 7 clear, bit 6 set
                        \
                        \   * Bottom-left quadrant = both set
                        \
                        \   * Top-left quadrant = bit 7 set, bit 6 clear
                        \
                        \ So the return values are correct when bits 6 and 7 are
                        \ either both clear or both set, and we need to swap the
                        \ sine and cosine results if one is set and the other is
                        \ clear

 BIT H                  \ If bit 7 of H is set, jump to scos4
 BMI scos4

                        \ If we get here then bit 7 of H is clear

 BVS scos5              \ If bit 6 of H is set, jump to scos5

.scos3


                        \ If we get here then one of these is true:
                        \
                        \   * Bit 7 of H is clear and bit 6 of H is clear
                        \
                        \   * Bit 7 of H is set and bit 6 of H is set
                        \
                        \ So the results we calculated above are correct:
                        \
                        \   A = |sin(X)|
                        \
                        \   X = |cos(X)|
                        \
                        \ and they will be the same for |sin(A)| and |cos(A)|
                        \ for the original argument A:

 STA sinA               \ Store A in sinA to return |sin(A)|

 STX cosA               \ Store X in cosA to return |cos(A)|

 RTS                    \ Return from the subroutine

.scos4

                        \ If we get here then bit 7 of H is set

 BVS scos3              \ If bit 6 of H is set, jump to scos3

.scos5

                        \ If we get here then one of these is true:
                        \
                        \   * Bit 7 of H is clear and bit 6 of H is set
                        \
                        \   * Bit 7 of H is set and bit 6 of H is clear
                        \
                        \ So the results we calculated above:
                        \
                        \   A = |sin(X)|
                        \
                        \   X = |cos(X)|
                        \
                        \ need to be swapped around to be correct for |sin(A)|
                        \ and |cos(A)| for the original argument A:
                        \
                        \   A = |cos(A)|
                        \
                        \   X = |sin(A)|


 STA cosA               \ Store A in cosA to return |cos(A)|

 STX sinA               \ Store X in sinA to return |sin(A)|

 RTS                    \ Return from the subroutine

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

 BPL MainTitleLoop-1    \ If the high byte in A is already positive, return from
                        \ the subroutine (as MainTitleLoop-1 contains an RTS)

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
\       Name: MainTitleLoop
\       Type: Subroutine
\   Category: Main title loop
\    Summary: The main title loop: display the title screen, fetch the landscape
\             number/code, preview the landscape and jump to the main game loop
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   MainTitleLoop-1     Contains an RTS
\
\   main1               The entry point for rejoining the main title loop after
\                       the player enters an incorrect secret code
\
\   main4               The entry point for restarting a landscape after dying,
\                       so the player doesn't have to enter the landscape's
\                       secret code again
\
\ ******************************************************************************

.MainTitleLoop

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack
                        \
                        \ This means that the JSR GenerateLandscape instruction
                        \ below will put its return address onto the top of the
                        \ stack, so we can maniupulate the return address by
                        \ modifying (&01FE &01FF)
                        \
                        \ See the notes on the JSR GenerateLandscape instruction
                        \ below for more details

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 JSR ResetVariables     \ Reset all the game's main variables

 LDA #0                 \ Call DrawTitleScreen with A = 0 to draw the title
 JSR DrawTitleScreen    \ screen

 LDX #0                 \ Print text token 0: Background colour blue, print
 JSR PrintTextToken     \ "PRESS ANY KEY" at (64, 100), set text background to
                        \ black

 LDA #&87               \ Set the palette to the second set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, red, yellow)

 JSR ReadKeyboard       \ Enable the keyboard, flush the keyboard buffer and
                        \ read a character from it (so this waits for a key
                        \ press)

.main1

 JSR ResetVariables     \ Reset all the game's main variables

 LDX #1                 \ Print text token 1: Print 13 spaces at (64, 100),
 JSR PrintTextToken     \ print "LANDSCAPE NUMBER?" at (64, 768), switch to text
                        \ cursor, move text cursor to (5, 27)

 LDA #4                 \ Read a four-digit number from the keyboard into the
 JSR ReadNumber         \ input buffer, showing the key presses on-screen and
                        \ supporting the DELETE and RETURN keys

 JSR StringToNumber     \ Convert the string of four ASCII digits in the input
                        \ buffer into a BCD number in inputBuffer(1 0)

 LDY inputBuffer+1      \ Set (Y X) = inputBuffer(1 0)
 LDX inputBuffer        \
                        \ So (Y X) is the entered landscape number in BCD

 JSR InitialiseSeeds    \ Initialise the seed number generator to generate the
                        \ sequence of seed numbers for the landscape number in
                        \ (Y X) and set maxNumberOfEnemies and the landscapeZero
                        \ flag accordingly

 LDA landscapeZero      \ If the landscape number is not 0000, jump to main3
 BNE main3              \ to ask for the landscape's secret entry code

                        \ This is landscape 0000, so we don't ask for a secret
                        \ entry code, but instead we copy the landscape's secret
                        \ code from secretCode0000 into the input buffer, so
                        \ it's as if the player has typed in the code themselves

 LDX #3                 \ We are copying four bytes of secret code into the
                        \ input buffer, so set a byte index in X

.main2

 LDA secretCode0000,X   \ Copy the X-th byte of secretCode0000 to the X-th byte
 STA inputBuffer,X      \ of the input buffer

 DEX                    \ Decrement the byte index

 BPL main2              \ Loop back until we have copied all four bytes

 BMI main4              \ Jump to main4 to skip asking the player to enter the
                        \ code (this BMI is effectively a JMP as we just passed
                        \ through a BPL)

.main3

 LDX #2                 \ Print text token 2: Background colour blue, print
 JSR PrintTextToken     \ "SECRET ENTRY CODE?" at (64, 768), switch to text
                        \ cursor, move text cursor to (2, 27)

 LDA #8                 \ Read an eight-digit number from the keyboard into the
 JSR ReadNumber         \ input buffer, showing the key presses on-screen and
                        \ supporting the DELETE and RETURN keys

 JSR StringToNumber     \ Convert the string of eight ASCII digits in the input
                        \ buffer into a BCD number in inputBuffer(3 2 1 0)

.main4

                        \ The player has now chosen a landscape number and has
                        \ entered the secret code (or, in the case of landscape
                        \ 0000, we have entered the secret code for them)
                        \
                        \ We also jump here if we are restarting a landscape
                        \ after dying, so the player doesn't have to enter the
                        \ landscape's secret code again

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 JSR GenerateLandscape  \ Call GenerateLandscape to generate the landscape and
                        \ play the game
                        \
                        \ Calling this subroutine puts a return address of
                        \ SecretCodeError on the stack (as that's the routine
                        \ that follows directly after this JSR instruction, so
                        \ performing a normal RTS at the end of the
                        \ GenerateLandscape routine will return to the following
                        \ code, which is what happens if the secret code entered
                        \ doesn't match the landscape's secret code
                        \
                        \ However, if the secret code does match the landscape,
                        \ then the SmoothTileData routine that is called from
                        \ GenerateLandscape alters the return address on the
                        \ stack, so instead of returning here, the RTS at the
                        \ end of the GenerateLandscape routine actually takes us
                        \ to the PreviewLandscape routine
                        \
                        \ Because we reset the stack with a YSX instruction at
                        \ the start of the MainTitleLoop routine, we know that
                        \ the JSR GenerateLandscape instruction will put its
                        \ return address onto the top of the stack, so we can
                        \ maniupulate the return address in the SmoothTileData
                        \ routine by modifying (&01FE &01FF)
                        \
                        \ See the SmoothTileData routine for more details

\ ******************************************************************************
\
\       Name: SecretCodeError
\       Type: Subroutine
\   Category: Main title loop
\    Summary: Display the "WRONG SECRET CODE" error, wait for a key press and
\             rejoin the main title loop
\
\ ******************************************************************************

.SecretCodeError

 JSR ResetVariables     \ Reset all the game's main variables

 LDA #0                 \ Call DrawTitleScreen with A = 0 to draw the title
 JSR DrawTitleScreen    \ screen

 LDA #&87               \ Set the palette to the second set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, red, yellow)

 LDX #3                 \ Print text token 3: Background colour blue, print
 JSR PrintTextToken     \ "WRONG SECRET CODE" at (64, 768), print "PRESS ANY
                        \ KEY" at (64, 100), set text background to black

 JSR ReadKeyboard       \ Enable the keyboard, flush the keyboard buffer and
                        \ read a character from it (so this waits for a key
                        \ press)

 JMP main1              \ Loop back to main1 to restart the main title loop

\ ******************************************************************************
\
\       Name: secretCode0000
\       Type: Variable
\   Category: Landscape
\    Summary: The secret entry code for landscape 0000 (06045387)
\
\ ******************************************************************************

.secretCode0000

 EQUD &06045387

\ ******************************************************************************
\
\       Name: sub_C1090
\       Type: Subroutine
\   Category: Graphics
\    Summary: ???
\
\ ******************************************************************************

.sub_C1090

 JSR ResetScreenAddress \ Reset the address of the start of screen memory

 JSR ClearIconsScanner  \ Clear the energy icon and scanner row at the top of
                        \ the screen

 LDA #0
 JSR sub_C2963

 LDA #0
 LDY #&18
 LDX #&28
 JSR sub_C2202

 LDA L0C4C
 CMP #3
 BNE CRE04

 LDA #3
 STA loopCounter

.P10AF

 JSR sub_C56D5

 DEC loopCounter

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

 LDY lastPanKeyPressed
 LDX anotherObject
 CPY #&02
 BCS C10FD
 LDA objectYawAngle,X
 CLC
 ADC L38F4,Y
 STA objectYawAngle,X
 LDA #&19
 LDY #&18
 LDX #&10
 STX L0C69
 JSR sub_C2202
 JSR sub_C391E
 JSR sub_C2624
 LDX anotherObject
 LDY lastPanKeyPressed
 BCS C10F2
 BNE C10EC
 LDA objectYawAngle,X
 SEC
 SBC #&0C
 STA objectYawAngle,X

.C10EC

 LDA #&10
 JSR SetNumberOfScrolls
 RTS

.C10F2

 LDA objectYawAngle,X
 SEC
 SBC L38F4,Y
 STA objectYawAngle,X
 RTS

.C10FD

 LDA objectPitchAngle,X
 CMP L1145,Y
 BEQ CRE05
 CLC
 ADC L38F4,Y
 STA objectPitchAngle,X
 LDA #&19
 LDY #&08
 LDX #&28
 STX L0C69
 JSR sub_C2202
 JSR sub_C3908
 JSR sub_C2624
 LDX playerObject
 LDY lastPanKeyPressed
 BCS C113A
 CPY #&03
 BNE C1131
 LDA objectPitchAngle,X
 CLC
 ADC #&08
 STA objectPitchAngle,X

.C1131

 LDA #&08
 JSR SetNumberOfScrolls

.P1136

 JSR sub_C3923

.CRE05

 RTS

.C113A

 LDA objectPitchAngle,X
 SEC
 SBC L38F4,Y
 STA objectPitchAngle,X

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
\   Category: Main title Loop
\    Summary: Reset all the game's main variables
\
\ ******************************************************************************

.ResetVariables

 SEC                    \ Set bit 7 of gameInProgress to indicate that a game is
 ROR gameInProgress     \ not currently in progress and that we are in the title
                        \ and preview screens (so the interrupt handler doesn't
                        \ update the game)

                        \ We now zero the following variable blocks:
                        \
                        \   * &0000 to &008F (Zero page workspace)
                        \
                        \   * &0100 to &01BF (Stack variables workspace)
                        \
                        \   * &0900 to &09EF (xObject)
                        \
                        \   * &0A00 to &0AEF (yObjectLo)
                        \
                        \   * &0C00 to &0CE3 (Main variable workspace)
                        \
                        \ and set the following variable block to %10000000:
                        \
                        \   * &0CE4 to &0CEF (Main variable workspace)

 LDX #0                 \ Set X to use as a byte counter to run from 0 to &EF

.rese1

 LDA #0                 \ Set A = 0 so we can zero the following variable blocks

 STA xObject,X          \ Zero the X-th byte of xObject

 STA yObjectLo,X        \ Zero the X-th byte of yObjectLo

 CPX #&90               \ If X >= &90 then skip the following instruction
 BCS rese2

 STA &0000,X            \ Zero the X-th byte of zero page

.rese2

 CPX #&C0               \ If X >= &C0 then skip the following instruction
 BCS rese3

 STA &0100,X            \ Zero the X-th byte of &0100

.rese3

 CPX #&E4               \ If X < &E4 then skip the following instruction,
 BCC rese4              \ leaving A = 0, so we zero &0C00 to &0CE3

 LDA #%10000000         \ If we get here then X >= &E4, so set A = %10000000 to
                        \ set bit 7 of &0CE4 to &0CEF

.rese4

 STA &0C00,X            \ Set the X-th byte of &0CE4 to A

 INX                    \ Increment the byte counter

 CPX #&F0               \ Loop back until we have processed X from &E4 to &EF
 BCC rese1              \ to set &0CE4 to &0CEF to &80

                        \ Fall through into ResetVariables2 to ???

\ ******************************************************************************
\
\       Name: ResetVariables2
\       Type: Subroutine
\   Category: Main title Loop
\    Summary: Reset the L3E80, L3EC0 and objectFlags variable blocks ???
\
\ ******************************************************************************

.ResetVariables2

                        \ We now set the following variable blocks to &FF:
                        \
                        \   * &3E80 to &3EBF
                        \
                        \   * &3EC0 to &3EFF
                        \
                        \ and set the following variable block to %10000000:
                        \
                        \   * objectFlags to objectFlags+63

 LDX #&3F               \ Set X to use as a byte counter to run from &3F to 0

.resv1

 LDA #&FF               \ Set the X-th byte of L3E80 to &FF ???
 STA L3E80,X

 STA L3EC0,X            \ Set the X-th byte of L3EC0 to &FF ???

 LDA #%10000000         \ Set bit 7 of the X-th byte of objectFlags, to denote
 STA objectFlags,X      \ that object #X is not allocated to an object

 DEX                    \ Decrement the byte counter

 BPL resv1              \ Loop back until we have processed X from &3F to 0

 INC seedNumberLFSR+2   \ Set bit 16 of the five-byte linear feedback shift
                        \ register in seedNumberLFSR(4 3 2 1 0), as we need a
                        \ non-zero element for the seed number generator to
                        \ work (as otherwise the EOR feedback will not affect
                        \ the contents of the shift register and it won't start
                        \ generating non-zero numbers)

 JSR sub_C3923          \ Sets L0051, L0052 ???

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CheckForKeyPresses
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Check for various game key presses and update the key logger and
\             relevant variables (during the interrupt routine)
\
\ ******************************************************************************

.CheckForKeyPresses

 LDA #%10000000         \ Set bit 7 of panKeyBeingPressed to indicate that no
 STA panKeyBeingPressed \ pan key is being pressed (we will update this below
                        \ if a pan key is being pressed)

 LDX #&8E               \ Scan the keyboard to see if function key f1 is being
 JSR ScanKeyboard       \ pressed ("Quit game")

 BNE ckey1              \ If function key f1 is not being pressed, jump to ckey1
                        \ to skip the following

 SEC                    \ Function key f1 is not being pressed, which quits the
 ROR quitGame           \ game, so set bit 7 of quitGame so that when we return
                        \ to the start of the main game loop it jumps to the
                        \ main title loop to restart the game

.ckey1

 LDX #&9D               \ Scan the keyboard to see if SPACE is being pressed
 JSR ScanKeyboard       \ ("Toggle sights on/off")

 BNE ckey4              \ If SPACE is not being pressed, jump to ckey4 to reset
                        \ the value of spaceKeyDebounce to flag that SPACE is
                        \ not being pressed

                        \ If we get here then SPACE is being pressed

 LDA spaceKeyDebounce   \ If spaceKeyDebounce is non-zero then we have already
 BNE ckey6              \ toggled the sights but the player is still holding
                        \ down SPACE, so jump to ckey6 to avoid toggling the
                        \ sights again

 LDA sightsAreVisible   \ Flip bit 7 of sightsAreVisible to toggle the sights on
 EOR #%10000000         \ and off
 STA sightsAreVisible

 BPL ckey2              \ If bit 7 is now clear then we just turned the sights
                        \ off, so jump to ckey2 to remove them from the screen

                        \ Otherwise bit 7 is now set, so we need to show the
                        \ sights

 JSR SetupSights        \ Calculate the position of the sights on the screen

 JSR ShowSights         \ Draw the sights on the screen

 JMP ckey3              \ Jump to ckey3 to skip the following

.ckey2

 JSR HideSights         \ Remove the sights from the screen

.ckey3

 LDA #%10000000         \ Set bit 7 of A to store in spaceKeyDebounce, to flag
                        \ that we have toggled the sights (so we can make sure
                        \ we don't keep toggling the sights if SPACE is being
                        \ held down)

 BNE ckey5              \ Jump to ckey5 to set spaceKeyDebounce to the value of
                        \ A in (this BNE is effectively a JMP as A is never
                        \ zero)

.ckey4

                        \ If we get here then SPACE is not being pressed

 LDA #0                 \ Clear bit 7 of spaceKeyDebounce to record that SPACE
                        \ is not being pressed

.ckey5

 STA spaceKeyDebounce   \ Set spaceKeyDebounce to the value of A, so we record
                        \ whether or not SPACE is being pressed to make sure
                        \ we don't keep toggling the sights if SPACE is held
                        \ down

.ckey6

 LDY #14                \ Scan the keyboard for all 14 game keys in the gameKeys
 JSR ScanForGameKeys    \ table

 BPL ckey7              \ ScanForGameKeys will clear bit 7 of the result if at
                        \ least one pan key is being pressed, in which case jump
                        \ to ckey7 to skip the following, so pan keys take
                        \ precedence over the other game keys (which are ignored
                        \ while panning is taking place)

                        \ If we get here then no pan keys are being pressed

 LDA #%01101011         \ Set a bit pattern in sightsInitialMoves to control the
 STA sightsInitialMoves \ initial movement of the sights when a pan key is
                        \ pressed and held down
                        \
                        \ Specifically, this value is shifted left once on each
                        \ call to this routine, with a zero shifted into bit 0,
                        \ and we only move the sights when a zero is shifted out
                        \ of bit 7
                        \
                        \ This means that when we start moving the sights, they
                        \ move like this, with each step happening on one call
                        \ of the interrupt handler:
                        \
                        \   0 = Move
                        \   1 = Pause
                        \   1 = Pause
                        \   0 = Move
                        \   1 = Pause
                        \   0 = Move
                        \   1 = Pause
                        \   1 = Pause
                        \
                        \ ...and then we move on every subsequent shift, as by
                        \ now all bits of sightsInitialMoves are clear
                        \
                        \ This means the sights move more slowly at the start,
                        \ with a slight judder, before speeding up fully after
                        \ eight steps (so this applies a bit of inertia to the
                        \ movement of the sights)

 LDA keyLogger+1        \ Set A to the key logger entry for "A", "Q", "R", "T",
                        \ "B", "H", or "U" (absorb, transfer, create robot,
                        \ create tree, create boulder, hyperspace, U-turn)

 BPL sub_C1200          \ If there is a key press in the key logger entry, jump
                        \ to sub_C1200 to ??? and return from the subroutine
                        \ using a tail call

                        \ If we get here then the player is not pressing "A",
                        \ "Q", "R", "T", "B", "H", or "U" (absorb, transfer,
                        \ create robot, create tree, create boulder, hyperspace,
                        \ U-turn)

 LDA #%01000000         \ Set bit 6 of uTurnStatus so that when the "U" key is
 STA uTurnStatus        \ next pressed, this will trigger a U-turn in the
                        \ ProcessActionKeys routine
                        \
                        \ This implements debounce so that holding down "U" will
                        \ not continuously perform U-turns, and instead the
                        \ player has to release "U" before they can do a second
                        \ U-turn
                        \
                        \ A U-turn is only performed in ProcessActionKeys when
                        \ bit 6 of uTurnStatus is set, at which point bit 6 is
                        \ cleared, and this is the only place where bit 6 is
                        \ set, so this ensures only one U-turn is performed
                        \ until we get here again, when "U" has been released

 BNE C1208              \ Jump to C1208 to finish off and return from the
                        \ subroutine (this BNE is effectively a JMP as A is
                        \ never zero)

.ckey7

                        \ If we get here then at least one pan key is being
                        \ pressed

 LDX sightsAreVisible   \ If bit 7 of sightsAreVisible is clear then the sights
 BPL ckey8              \ are not being shown, so jump to ckey8 to skip the
                        \ following, as we don't need to move the sights when
                        \ they aren't on-screen

                        \ If we get here then the sights are visible, so the pan
                        \ keys move the sights rather than panning the view

 ASL sightsInitialMoves \ Shift sightsInitialMoves to the left, so we pull the
                        \ next bit from the pattern that determines the initial
                        \ movement of the sights

 BCS C1208              \ If we shifted a 1 out of bit 7 of sightsInitialMoves,
                        \ jump to C1208 to return from the subroutine without
                        \ moving the sights, as a set bit indicates a pause in
                        \ the initial movement of the sights

 JSR MoveSights         \ Move the sights according to the pan key presses in
                        \ the key logger

 JMP ckey10             \ Jump to ckey10 to skip the following (where we will
                        \ then jump to C1208 to finish off and return from the
                        \ subroutine, as we set bit 7 of panKeyBeingPressed at
                        \ the start of the routine)

.ckey8

 LDA keyLogger          \ Set A to the key logger entry for "S" and "D" (pan
                        \ left, pan right), which are used to move the sights

 BPL ckey9              \ If there is a key press in the key logger entry, jump
                        \ to ckey9 to store this value in panKeyBeingPressed (so
                        \ panning left or right takes precedence over panning up
                        \ or down)

 LDA keyLogger+2        \ Set A to the key logger entry for "L" and "," (pan
                        \ up, pan down), which are used to move the sights

 BMI C1208              \ If there is no key press in the key logger entry then
                        \ no pan keys are being pressed, so jump to C1208 to
                        \ finish off and return from the subroutine without
                        \ recording a pan key press in panKeyBeingPressed

.ckey9

 STA panKeyBeingPressed \ Set panKeyBeingPressed to the key logger value of the
                        \ pan key that's being pressed, as follows:
                        \
                        \   * 0 = pan right
                        \
                        \   * 1 = pan left
                        \
                        \   * 2 = pan up
                        \
                        \   * 3 = pan down

.ckey10

 LDA panKeyBeingPressed \ If bit 7 of panKeyBeingPressed is set then no pan keys
 BMI C1208              \ are being pressed, so jump to C1208 to finish off and
                        \ return from the subroutine

 STA latestPanKeyPress  \ Set latestPanKeyPress to the key logger value of the
                        \ pan key that's being pressed, so it contains the most
                        \ recent pan key press (i.e. the current one)

                        \ Fall through into sub_C1200 to ???

\ ******************************************************************************
\
\       Name: sub_C1200
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   C1208               ???
\
\ ******************************************************************************

.sub_C1200

 LDA #%10000000         \ Set bit 7 of doNotScanKeyboard to disable keyboard
 STA doNotScanKeyboard  \ scans ???

 STA L0C1E              \ Set bit 7 of L0C1E ???

.C1208

 LDA doNotScanKeyboard  \ Set previousDoNotScan = doNotScanKeyboard so we can
 STA previousDoNotScan  \ work out whether the value of doNotScanKeyboard has
                        \ changed in the sub_C1264 routine ???

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CheckForSamePanKey
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Check to see whether the same pan key is being held down compared
\             to the last time we checked
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   Z flag              Determines whether the same pan key is being held down
\                       compared to the last time we checked:
\
\                         * Z flag will be set if the same pan key is being held
\                           down (so a BEQ branch will be taken)
\
\                         * Z flag will be clear otherwise (so a BNE branch will
\                           be taken)
\
\ ******************************************************************************

.CheckForSamePanKey

 SEI                    \ Disable interrupts so the key logger doesn't get
                        \ updated while we check it for pan key presses

 LDY #3                 \ Scan the keyboard for the first four game keys ("S",
 JSR ScanForGameKeys    \ "D", "L" and ",", for pan left, right up and down)

 LDA latestPanKeyPress  \ Set A to the key logger value of the latest pan key
                        \ press, which will either be a current key press or the
                        \ value from the last pan key press to be made

 CMP keyLogger          \ Compare with the key logger entry for "S" and "D"
                        \ (pan left and right)

 BEQ cpan1              \ If the key logger entry is unchanged from the previous
                        \ pan key press in latestPanKeyPress, then the same pan
                        \ key is being held down, so jump to cpan1 with the
                        \ Z flag set accordingly

 CMP keyLogger+2        \ Compare with the key logger entry for "L" and ","
                        \ (pan up and down), so the Z flag will be set if the
                        \ same pan key is being held down

.cpan1

 CLI                    \ Re-enable interrupts

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: spaceKeyDebounce
\       Type: Variable
\   Category: Leyboard
\    Summary: A variable to flag whether the SPACE key has been pressed, so we
\             can implement debounce
\
\ ******************************************************************************

.spaceKeyDebounce

 EQUB 0

 EQUB 0                 \ This byte appears to be unused

\ ******************************************************************************
\
\       Name: PlaceObjectBelow
\       Type: Subroutine
\   Category: 3D objects
\    Summary: Attempt to place the player object on a tile that is below the
\             maximum altitude specified in A
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The maximum desired altitude of the object (though we
\                       may end up placing the object higher than this)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Status flag:
\
\                         * Clear if the object was successfully placed on a
\                           tile
\
\                         * Set if the object was not placed on a suitable tile
\
\ ******************************************************************************

.PlaceObjectBelow

 STA tileAltitude       \ Store the maximum altitude in tileAltitude

 LDA #0                 \ We now loop through the landscape tiles, trying to
 STA loopCounter        \ find a suitable location for the object, so set a
                        \ loop counter to count 255 iterations for each loop

.objb1

 DEC loopCounter        \ Decrement the loop counter

 BNE objb2              \ If we have not counted all 255 iterations yet, jump to
                        \ objb2 to skip the following

                        \ If we get here then we have tried 255 tiles at the
                        \ altitude in tileAltitude, but without success, so we
                        \ move to a higher altitude and try again

 INC tileAltitude       \ Increment the altitude in tileAltitude to move up by
                        \ one coordinate (where a tile-sized cube is one
                        \ coordinate across)

 LDA tileAltitude       \ If we just incremented tileAltitude to 12 then we have
 CMP #12                \ gone past the highest altitude possible, so jump to
 BCS objb3              \ objb3 to return from the subroutine with the C flag
                        \ set to indicate failure

                        \ Otherwise keep going to look for a suitable tile at
                        \ the new, higher altitude

.objb2

                        \ We now try to pick a tile in the landscape that might
                        \ be suitable for placing our object

 JSR GetNextSeed0To30   \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, converted to the range 0 to 30

 STA xTile              \ Set xTile to this seed number, so it points to a
                        \ tile corner that anchors a tile (so the tile corner
                        \ isn't along the right edge of the landscape)

 JSR GetNextSeed0To30   \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, converted to the range 0 to 30

 STA zTile              \ Set zTile to this seed number, so it points to a
                        \ tile corner that anchors a tile (so the tile corner
                        \ isn't along the far edge of the landscape)

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), setting the C flag if the tile
                        \ contains an object

 BCS objb1              \ If the tile already contains an object, jump to objb1
                        \ to try another tile from the landscape's sequence of
                        \ seed numbers

 AND #%00001111         \ If the tile shape in the low nibble of the tile data
 BNE objb1              \ is non-zero, then the tile is not flat, so jump to
                        \ objb1 to try another tile from the landscape's
                        \ sequence of seed numbers

 LDA (tileDataPage),Y   \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 LSR A                  \ Set A to the tile altitude, which is in the top nibble
 LSR A                  \ of the tile data
 LSR A
 LSR A

 CMP tileAltitude       \ If the altitude of the chosen tile is equal to or
 BCS objb1              \ higher than the minimum altitude in tileAltitude, then
                        \ this tile is too high, so jump to objb1 to try another
                        \ tile from the landscape's sequence of seed numbers

                        \ If we get here then we have found a tile that is below
                        \ the altitude in tileAltitude and which doesn't already
                        \ contain an object, so we can use this for placing our
                        \ object

 JSR PlaceObjectOnTile  \ Place object #X on the tile anchored at (xTile, zTile)

 CLC                    \ Clear the C flag to indicate that we have successfully
                        \ placed the object on a tile

 RTS                    \ Return from the subroutine

.objb3

 SEC                    \ Set the C flag to indicate that we have failed to
                        \ place the object on a suitable tile

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetNextSeed0To30
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set A to the next number from the landscape's sequence of seed
\             numbers, converted to the range 0 to 30
\
\ ******************************************************************************

.GetNextSeed0To30

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 AND #31                \ Convert A into a number into the range 0 to 31

 CMP #31                \ If A >= 31 or greater, repeat the process until we
 BCS GetNextSeed0To30   \ get a number in the range 0 to 30

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: sub_C1264
\       Type: Subroutine
\   Category: Gameplay
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   anotherObject       This is always set to the object number of the player
\                       (it is set in MainGameLoop before it calls this routine)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Status flag:
\
\                         * Clear if any of the following are true:
\
\                           * Keyboard scans are disabled (bit 7 of
\                             doNotScanKeyboard is set) and a pan key is being
\                             pressed (bit 7 of panKeyBeingPressed is clear)
\
\                         * Set if any of the following are true:
\
\                           * The Sentinel has won
\
\                           * The player has moved to a new tile
\
\                           * The player has pressed the quit game key
\
\ ******************************************************************************

.sub_C1264

 LDA #0                 \ Clear bit 7 of doNotScanKeyboard to enable keyboard
 STA doNotScanKeyboard  \ scans ???

 STA uTurnStatus        \ Clear bit 6 of uTurnStatus to prevent the "U" key
                        \ from performing a U-turn, so that the "U" key has to
                        \ be released before a second U-turn can be performed
                        \ ???

.C126C

 LDA doNotScanKeyboard  \ If bit 7 of doNotScanKeyboard is set then keyboard
 BMI C12AD              \ scans are disabled, so jump to C12AD to skip the
                        \ following

 LSR samePanKeyPress    \ Clear bit 7 of samePanKeyPress to record that the same
                        \ pan key is not being held down, which we will change
                        \ below if this is not the case

 LDA previousDoNotScan  \ If bit 7 of previousDoNotScan is clear then it matches
 BPL C1282              \ the current value of doNotScanKeyboard (so the value
                        \ of previousDoNotScan has not changed since the last
                        \ time we were in the sub_C1200 routine, and at both
                        \ points key scanning was enabled), so jump to C1282 to
                        \ skip the following and leave samePanKeyPress with bit
                        \ 7 clear, to record that the same pan key is not being
                        \ held down ???

 JSR CheckForSamePanKey \ Check to see whether the same pan key is being
                        \ held down compared to the last time we checked

 BNE C1282              \ If the same pan key is not being held down, jump to
                        \ C1282 to skip the following

 SEC                    \ The same pan key is still being held down, so set bit
 ROR samePanKeyPress    \ 7 of samePanKeyPress to record this

.C1282

 JSR sub_C16A8          \ Something to do with enemies ???

 LDA sentinelHasWon     \ If bit 7 of sentinelHasWon is clear then the player
 BEQ C1294              \ has not been absorbed by the Sentinel, so jump to
                        \ C1294 to progress the game

 LDA #30                \ The Sentinel has won, so display the game over screen
 JSR DisplayGameOver    \ with A = 30 ???

.C128F

 JSR sub_C1200          \ Sets variables that control key scans etc. ???

 SEC                    \ Set the C flag to indicate that ???

 RTS                    \ Return from the subroutine

.C1294

 ASL playerHasMovedTile \ Shift bit 7 of playerHasMovedTile into the C flag so
                        \ we can check it in the next instruction, and clear bit
                        \ 7 to clear the flag as we are about to process any
                        \ tile move that has occurred

 BCS C128F              \ If the C flag is set then bit 7 of playerHasMovedTile
                        \ was set before we cleared it, which indicates that the
                        \ player has moved to a new tile, so jump to C128F to
                        \ return from the subroutine with the C flag set ???

 BIT quitGame           \ If bit 7 of quitGame is set then the player has
 BMI C128F              \ pressed function key f1 to quit the game, so jump to
                        \ C128F to finish up and return from the subroutine with
                        \ the C flag set ???

 JSR sub_C191A          \ Something to do with player and enemy objects ???

 JSR ProcessPauseKeys   \ Pause or unpause the game when COPY or DELETE are
                        \ pressed

 JSR sub_C355A          \ Sound related ???

 JSR ProcessVolumeKeys  \ Adjust the volume of the sound envelopes when the
                        \ volume keys are pressed

 JMP C126C              \ Jump back to C126C to repeat the main game loop

.C12AD

 LDA panKeyBeingPressed \ If no pan key is currently being pressed, jump to
 BMI C12B3              \ C12B3 to process any action key presses

 CLC                    \ Clear the C flag to indicate that ???

 RTS                    \ Return from the subroutine

.C12B3

 LDA keyLogger+1        \ Set A to the key logger entry for "A", "Q", "R", "T",
                        \ "B", "H", or "U" (absorb, transfer, create robot,
                        \ create tree, create boulder, hyperspace, U-turn)

 BMI C12EB              \ If there is no key press in the key logger entry, jump
                        \ back to the start of the routine via C12EB to ???

                        \ If we get here then the player is pressing "A", "Q",
                        \ "R", "T", "B", "H" or "U" (absorb, transfer, create
                        \ robot, create tree, create boulder, hyperspace,
                        \ U-turn), so the possible values for A are:
                        \
                        \   * 0  for key press "R" (Create robot)
                        \   * 2  for key press "T" (Create tree)
                        \   * 3  for key press "B" (Create boulder)
                        \   * 32 for key press "A" (Absorb)
                        \   * 33 for key press "Q" (Transfer)
                        \   * 34 for key press "H" (Hyperspace)
                        \   * 35 for key press "U" (U-turn)

 CMP #34                \ If A >= 34 then "H" (hyperspace) or "U" (U-turn) is
 BCS C12C1              \ being pressed, so jump to C12C1 to skip the following
                        \ check, as we can hyperspace and U-turn at any point,
                        \ irrespective of whether the sights are being shown

 BIT sightsAreVisible   \ If bit 7 of sightsAreVisible is clear then the sights
 BPL C12EB              \ are not being shown, so jump back to the start of the
                        \ routine via C12EB to ???, as we can only create,
                        \ absorb and transfer when the sights are visible

                        \ If we get here then the sights are being shown, so we
                        \ can process the key press

.C12C1

 STA keyPress           \ Record the value from the key logger in keyPress, so
                        \ we can refer to it in the call to ProcessActionKeys

 LSR activateSentinel   \ The player has pressed a key that expends or absorbs
                        \ energy, which activates the Sentinel at the very start
                        \ of each level (the Sentinel and Sentries are inactive
                        \ until this point, giving the player time to get their
                        \ bearings when they first start a landscape)
                        \
                        \ So clear bit 7 of activateSentinel to indicate that
                        \ the Sentinal is activated and the game has started

 JSR ProcessActionKeys  \ Process any key presses in key logger entry 1, which
                        \ is where action key presses are stored (absorb,
                        \ transfer, create, hyperspace, U-turn)

 BCS C12E5              \ If the C flag is set, jump to C12E5 to skip the
                        \ following ???

 JSR FlushSoundBuffer0  \ Flush the sound channel 0 buffer

 LDA #2                 \ Make sound #2 (???)
 JSR MakeSound

 LDA #%11000000
 STA L0C6D

 LSR L0C1E

 JSR sub_C1F84

 JSR FlushSoundBuffer0  \ Flush the sound channel 0 buffer

 JSR UpdateIconsScanner \ Update the icons in the top-left corner of the screen
                        \ to show the player's current energy level and redraw
                        \ the scanner box

.C12E5

 ASL playerHasMovedTile \ Shift bit 7 of playerHasMovedTile into the C flag so
                        \ we can check it in the next instruction, and clear bit
                        \ 7 to clear the flag as we are about to process any
                        \ tile move that has occurred

 BCC C12EB              \ If bit 7 of playerHasMovedTile was clear before we
                        \ cleared it, then the plater has not moved to a new
                        \ tile, so jump back to the start of the routine via
                        \ C12EB to continue progressing the game ???

                        \ If we get here then bit 7 of playerHasMovedTile was
                        \ set before we cleared it, which indicates that the
                        \ player has moved to a new tile, so return from the
                        \ subroutine with the C flag set ???

 RTS                    \ Return from the subroutine

.C12EB

 JMP sub_C1264          \ Jump back to the start of the sub_C1264 routine

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
\       Name: ResetScreenAddress
\       Type: Subroutine
\   Category: Graphics
\    Summary: Reset the address of the start of screen memory
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the screen addresses as follows:
\
\   * Address of the start of screen memory in the 6845 CRTC registers = &7F80
\
\   * Address of the icon and scanner row at the top of the screen in
\     iconRowAddr(1 0) = &7F80
\
\   * Address of the player's scrolling landscape view in viewScreenAddr(1 0) =
\     &60C0
\
\ Note that &7F80 + 320 = &60C0, when the wrapping of screen memory is taken
\ into consideration, so the player's scrolling landscape view in memory is one
\ character line after the icon and scanner row at the top of the screen.
\
\ ******************************************************************************

.ResetScreenAddress

 SEI                    \ Disable interrupts so we can update the 6845 registers

 LDA #&C0               \ Set viewScreenAddr(1 0) = &60C0
 STA viewScreenAddr
 LDA #&60
 STA viewScreenAddr+1

 JSR GetIconRowAddress  \ Set iconRowAddr(1 0) to the address in screen memory
                        \ of the icon and scanner row at the top of the screen

                        \ We now set the address of screen memory to &7F80

 LDA #&0F               \ Store &0F on the stack to use as the value of R12 in
 PHA                    \ the following

 LDA #&F0               \ Set 6845 register R13 = &F0, for the low byte
 LDX #13                \
 STX SHEILA+&00         \ We do this by writing the register number (13) to
 STA SHEILA+&01         \ SHEILA &00, and then the value (&F0) to SHEILA &01

 DEX                    \ Set 6845 register R12 = &0F, for the high byte
 STX SHEILA+&00         \
 PLA                    \ We do this by writing the register number (12) to
 STA SHEILA+&01         \ SHEILA &00, and then the value (&0F) to SHEILA &01

                        \ This sets 6845 registers (R12 R13) = &0FF0 to point
                        \ to the start of screen memory in terms of character
                        \ rows. There are 8 pixel lines in each character row,
                        \ so to get the actual address of the start of screen
                        \ memory, we multiply by 8:
                        \
                        \   &0FF0 * 8 = &7F80
                        \
                        \ So this sets the start of screen memory to &7F80

 CLI                    \ Re-enable interrupts

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetupSights
\       Type: Subroutine
\   Category: Sights
\    Summary: Calculate the position of the sights on the screen
\
\ ******************************************************************************

.SetupSights

 LDA viewScreenAddr
 CLC
 ADC #&A0
 STA L0CC4

 LDA viewScreenAddr+1
 ADC #&0F
 CMP #&80
 BCC C1345
 SBC #&20

.C1345

 STA L0CC5

 LDA #&50
 STA xSights

 LDA #&5F
 STA ySights

 RTS

\ ******************************************************************************
\
\       Name: ScanForGameKeys
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan for game key presses and update the key logger
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The offset within gameKeys where we start the scan, with
\                       the scan working towards the start of gameKeys
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   N flag              Determines whether a pan key is being pressed:
\
\                         * Bit 7 of A will be set if no pan keys are being
\                           pressed (so a BMI branch will be taken)
\
\                         * Bit 7 of A will be clear if at least one pan key is
\                           being pressed (so a BPL branch will be taken)
\
\ ******************************************************************************

.ScanForGameKeys

 LDX #3                 \ We start by resetting the key logger, so set a loop
                        \ counter in X for resetting all four entries

 LDA #%10000000         \ Set A = %10000000 to reset all four entries, as the
                        \ set bit 7 indicates an empty entry in the logger

.gkey1

 STA keyLogger,X        \ Reset the X-th entry in the key logger

 DEX                    \ Decrement the loop counter

 BPL gkey1              \ Loop back until we have reset all four entries

                        \ We now work our way backwards through the gameKey
                        \ table, starting at offset Y, and checking to see if
                        \ each key is being pressed and logging the results in
                        \ the key logger

.gkey2

 LDX gameKeys,Y         \ Set X to the internal key number for the Y-th key in
                        \ the gameKey table

 JSR ScanKeyboard       \ Scan the keyboard to see if this key is being pressed

 BNE gkey3              \ If the key in X is not being pressed, jump to gkey3 to
                        \ move on to the next key in the table

 LDA keyLoggerConfig,Y  \ Set X to the key logger entry where we should store
 AND #%00000011         \ this key press, which is in bits 0 and 1 of the
 TAX                    \ corresponding entry in the keyLoggerConfig table

 LDA keyLoggerConfig,Y  \ Set A to the value to store in the key logger for this
 LSR A                  \ key, which is in bits 2 to 7 of the corresponding
 LSR A                  \ entry in the keyLoggerConfig table

 STA keyLogger,X        \ Store the configured value in the configured entry
                        \ for this key press

.gkey3

 DEY                    \ Decrement the index in Y to move on to the next key
                        \ in the gameKey table

 BPL gkey2              \ Loop back until we have checked all the keys up to the
                        \ start of the gameKey table

 LDA keyLogger          \ Combine the key logger entry for "S" and "D" (pan left
 AND keyLogger+2        \ and right) with the key logger entry for "L" and ","
                        \ (pan left and right and set the status flags according
                        \ to the result
                        \
                        \ Specifically, if bit 7 is set in both entries, then no
                        \ pan keys are being pressed, so a BMI following the
                        \ call to ScanForGameKeys will be taken
                        \
                        \ If, however, bit 7 is clear in either entry, then at
                        \ least one pan key is being pressed, so a BPL following
                        \ the call to ScanForGameKeys will be taken

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: gameKeys
\       Type: Variable
\   Category: Keyboard
\    Summary: Negative inkey values for the game keys
\
\ ------------------------------------------------------------------------------
\
\ For a full list of negative inkey values, see Appendix C of the "Advanced User
\ Guide for the BBC Micro" by Bray, Dickens and Holmes.

\ ******************************************************************************

.gameKeys

 EQUB &AE               \ Negative inkey value for "S" (pan left)
 EQUB &CD               \ Negative inkey value for "D" (pan right)
 EQUB &A9               \ Negative inkey value for "L" (pan up)
 EQUB &99               \ Negative inkey value for "," (pan down)
 EQUB &BE               \ Negative inkey value for "A" (absorb)
 EQUB &EF               \ Negative inkey value for "Q" (transfer)
 EQUB &CC               \ Negative inkey value for "R" (create robot)
 EQUB &DC               \ Negative inkey value for "T" (create tree)
 EQUB &9B               \ Negative inkey value for "B" (create boulder)
 EQUB &AB               \ Negative inkey value for "H" (hyperspace)
 EQUB &DB               \ Negative inkey value for "7" (volume down)
 EQUB &EA               \ Negative inkey value for "8" (volume up)
 EQUB &96               \ Negative inkey value for COPY (pause)
 EQUB &A6               \ Negative inkey value for DELETE (unpause)
 EQUB &CA               \ Negative inkey value for "U" (U-turn)

\ ******************************************************************************
\
\       Name: keyLoggerConfig
\       Type: Variable
\   Category: Keyboard
\    Summary: The configuration table for storing keys the key logger
\
\ ------------------------------------------------------------------------------
\
\ Each game key has an entry in the keyLoggerConfig table that corresponds with
\ the internal key number in the gameKeys table.
\
\ Bits 0 and 1 determine the entry in the four-byte key logger where we should
\ record each key press (entry numbers are 0 to 3).
\
\ Bits 2 to 7 contain the value to store in the key logger at that entry.
\
\ The key logger entries fall into four categories:
\
\   * Entry 0 is for sideways movement keys (pan left, pan right)
\
\   * Entry 1 is for action keys (absorb, transfer, create, hyperspace, U-turn)
\
\   * Entry 2 is for vertical movement keys (pan up, pan down)
\
\   * Entry 3 is for utility keys (volume control, pause)
\
\ ******************************************************************************

.keyLoggerConfig

 EQUB 0 +  1 << 2       \ Put  1 in logger entry 0 for "S" (pan left)
 EQUB 0 +  0 << 2       \ Put  0 in logger entry 0 for "D" (pan right)

 EQUB 2 +  2 << 2       \ Put  2 in logger entry 2 for "L" (pan up)
 EQUB 2 +  3 << 2       \ Put  3 in logger entry 2 for "," (pan down)

 EQUB 1 + 32 << 2       \ Put 32 in logger entry 1 for "A" (absorb)
 EQUB 1 + 33 << 2       \ Put 33 in logger entry 1 for "Q" (transfer)
 EQUB 1 +  0 << 2       \ Put  0 in logger entry 1 for "R" (create robot)
 EQUB 1 +  2 << 2       \ Put  2 in logger entry 1 for "T" (create tree)
 EQUB 1 +  3 << 2       \ Put  3 in logger entry 1 for "B" (create boulder)
 EQUB 1 + 34 << 2       \ Put 34 in logger entry 1 for "H" (hyperspace)

 EQUB 3 +  0 << 2       \ Put  0 in logger entry 3 for "7" (volume down)
 EQUB 3 +  1 << 2       \ Put  1 in logger entry 3 for "8" (volume up)
 EQUB 3 +  2 << 2       \ Put  2 in logger entry 3 for COPY (pause)
 EQUB 3 +  3 << 2       \ Put  3 in logger entry 3 for DELETE (unpause)

 EQUB 1 + 35 << 2       \ Put 35 in logger entry 1 for "U" (U-turn)

\ ******************************************************************************
\
\       Name: DrawTitleObject
\       Type: Subroutine
\   Category: Title screen
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The object to draw on the title screen (or subsequent
\                       screens):
\
\                         * 0 = draw a robot on the right of the screen (for the
\                               secret code screen)
\
\                         * 5 = draw the Sentinel on the right of the screen
\                               (for the title screen)
\
\                         * &80 = draw the landscape preview
\
\   X                   ???
\
\                         * 0 = ???
\
\                         * 1 = ???
\
\                         * 3 = ???
\
\   Y                   ???
\
\                         * 0 = ???
\
\                         * 1 = ???
\
\ ******************************************************************************

.DrawTitleObject

 STA titleObjectToDraw  \ Set titleObjectToDraw to the object that we are
                        \ drawing so we can refer to it later

 STX L0C4C              \ Store the X argument in L0C4C (0, 1, 3)

 TXA

 LDX #&02
 EOR #&03
 STA vduShadowFront+1
 BEQ C13AC
 INX

.C13AC

 STX vduShadowRear+1

 STY L140F              \ Store the Y argument in L140F (0, 1)

 LDA L1403,Y
 STA yObjectHi+16
 LDA L1405,Y
 STA objectPitchAngle+16
 LDA L1407,Y
 STA xObject+16
 LDA L140B,Y
 STA zObject+16
 LDA L140D,Y
 STA objectYawAngle+16
 LDA L1409,Y
 PHA
 JSR sub_C1090
 LDA titleObjectToDraw
 BMI C13DF
 JSR sub_C5FE5

.C13DF

 PLA
 STA L0C78
 LDX #&10
 STX anotherObject
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
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L1403

 EQUB &21, &4B

\ ******************************************************************************
\
\       Name: L1405
\       Type: Variable
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L1405

 EQUB &EA, &D9

\ ******************************************************************************
\
\       Name: L1407
\       Type: Variable
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L1407

 EQUB &0F, &00

\ ******************************************************************************
\
\       Name: L1409
\       Type: Variable
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L1409

 EQUB &00, &EF

\ ******************************************************************************
\
\       Name: L140B
\       Type: Variable
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L140B

 EQUB &C2, &BF

\ ******************************************************************************
\
\       Name: L140D
\       Type: Variable
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L140D

 EQUB &00, &12

\ ******************************************************************************
\
\       Name: L140F
\       Type: Variable
\   Category: Title screen
\    Summary: ???
\
\ ******************************************************************************

.L140F

 EQUB &01

\ ******************************************************************************
\
\       Name: SpawnEnemies
\       Type: Subroutine
\   Category: Landscape
\    Summary: Calculate the number of enemies for this landscape, add them to
\             the landscape and set the palette accordingly
\
\ ******************************************************************************

.SpawnEnemies

 LDA landscapeZero      \ If this is not landscape 0000, jump to popu1 to
 BNE popu1              \ calculate the number of enemies to spawn

 LDA #1                 \ This is landscape 0000, so set A = 1 to use for the
                        \ total number of enemies

 BNE popu2              \ Jump to popu2 to set numberOfEnemies to the value of A

.popu1

 JSR GetEnemyCount      \ Set A to the enemy count for this landscape, which is
                        \ derived from the top digit of the landscape number and
                        \ the next number in the landscape's sequence of seed
                        \ numbers, so it is always the same value for the same
                        \ landscape number
                        \
                        \ At this point A is in the range 1 to 8, with higher
                        \ values for higher landscape numbers

 CMP maxNumberOfEnemies \ If A < maxNumberOfEnemies then skip the following
 BCC popu2              \ instruction

 LDA maxNumberOfEnemies \ Set A = maxNumberOfEnemies, so the number of enemies
                        \ does not exceed the value of maxNumberOfEnemies that
                        \ we set in the InitialiseSeeds routine
                        \
                        \ So landscapes 0000 to 0009 have a maximum enemy count
                        \ of 1, landscapes 0010 to 0019 have a maximum enemy
                        \ count of 2, and so on up to landscapes 0070 and up,
                        \ which have a maximum enemy count of 8

.popu2

 STA numberOfEnemies    \ Store the number of enemies for this landscape in
                        \ numberOfEnemies

 JSR AddEnemiesToTiles  \ Add the required number of enemies to the landscape,
                        \ starting from the highest altitude and working down,
                        \ with no more than one enemy on each contour

                        \ We now update colours 2 and 3 in the first palette in
                        \ colourPalettes according to the number of enemies

 LDA numberOfEnemies    \ Set X = (numberOfEnemies - 1) mod 8
 SEC                    \
 SBC #1                 \ The mod 8 is not strictly necessary as numberOfEnemies
 AND #7                 \ is in the range 1 to 8, but doing this ensures we can
 TAX                    \ safely use X as an index into the landscapeColour
                        \ tables

 LDA landscapeColour3,X \ Set colour 3 in the game palette to the X-th entry
 STA colourPalettes+3   \ from landscapeColour3

 LDA landscapeColour2,X \ Set colour 2 in the game palette to the X-th entry
 STA colourPalettes+2   \ from landscapeColour2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SpawnPlayer
\       Type: Subroutine
\   Category: Landscape
\    Summary: Add the player object to the landscape, ideally placing it below
\             all the enemies and in the bottom half of the landscape
\
\ ******************************************************************************

.SpawnPlayer

 LDA #0                 \ Spawn the player's robot (an object of type 0),
 JSR SpawnObject        \ returning the object number of the new object in X
                        \ and currentObject

 STX playerObject       \ Set playerObject to the object number of the newly
                        \ spawned object

 LDA #10                \ Set the player's energy level to 10
 STA playerEnergy

 LDA landscapeZero      \ If the landscape number is not 0000, jump to sply1
 BNE sply1

 LDA #8                 \ Set (xTile, zTile) = (8, 17)
 STA xTile              \
 LDA #17                \ So the player always starts on this tile in the first
 STA zTile              \ landscape

 JSR PlaceObjectOnTile  \ Place object #X on the tile anchored at (xTile, zTile)

 JMP SpawnTrees         \ Jump to SpawnTrees to add trees to the landscape and
                        \ move towards playing the game

.sply1

                        \ If we get here then this is not landscape 0000

 LDA minEnemyAltitude   \ Set A to the altitude of the lowest enemy on the
                        \ landscape

 CMP #6                 \ If A >= 6 then set A = 6
 BCC sply2              \
 LDA #6                 \ So A = min(6, minEnemyAltitude)

.sply2

                        \ By this point A contains an altitude that is no higher
                        \ than any enemies and is no greater than 6
                        \
                        \ We can use this as a cap on the player's starting
                        \ altitude to ensure that the player starts below all
                        \ the enemies, and in the bottom half of the landscape
                        \ (which ranges from altitude 1 to 11)

 JSR PlaceObjectBelow   \ Attempt to place the player object on a tile that is
                        \ below the maximum altitude specified in A (though we
                        \ may end up placing the object higher than this)

 BCS sply1              \ If the call to PlaceObjectBelow sets the C flag then
                        \ the object has not been successfully placed, so loop
                        \ back to sply1 to keep trying, working through the
                        \ landscape's sequence of seed numbers until we do
                        \ manage to place the player on a tile

                        \ Otherwise we have placed the player object on a tile,
                        \ so now we fall through into SpawnTrees to add trees to
                        \ the landscape

\ ******************************************************************************
\
\       Name: SpawnTrees
\       Type: Subroutine
\   Category: Landscape
\    Summary: Add trees to the landscape, ideally placing them below all the
\             enemies in the landscape
\
\ ******************************************************************************

.SpawnTrees

 LDA #48                \ Set U = 48 - 3 * numberOfEnemies
 SEC                    \
 SBC numberOfEnemies    \ We use this to cap the number of trees we add to the
 SBC numberOfEnemies    \ landscape (though it only affects higher levels)
 SBC numberOfEnemies
 STA U

 JSR GetNextSeed0To22   \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, converted to the range 0 to 22

 CLC                    \ Set A to this number, converted to the range 10 to 32
 ADC #10

 CMP U                  \ If A >= U then set A = U
 BCC tree1              \
 LDA U                  \ So A = min(U, A)

.tree1

 STA treeCounter        \ By this point A contains a value in the range 10 to 32
                        \ that's no greater than 48 - 3 * numberOfEnemies
                        \
                        \ So when numberOfEnemies is six or more, this reduces
                        \ the value of A as follows:
                        \
                        \   * When numberOfEnemies = 6, range is 10 to 30
                        \   * When numberOfEnemies = 7, range is 10 to 27
                        \   * When numberOfEnemies = 8, range is 10 to 24
                        \
                        \ As the number of trees determines the total amount of
                        \ energy in the landscape, this makes the levels get
                        \ even more difficult when there are higher enemy counts
                        \
                        \ We now try to add this number of trees to the
                        \ landscape, so store the result in treeCounter to use
                        \ as a counter in the following loop

.tree2

 LDA #2                 \ Spawn a tree (an object of type 2), returning the
 JSR SpawnObject        \ object number of the new object in X and currentObject

 LDA minEnemyAltitude   \ Set A to the altitude of the lowest enemy on the
                        \ landscape, so we try to spawn all the trees at a lower
                        \ altitude to the enemies

 JSR PlaceObjectBelow   \ Attempt to place the player object on a tile that is
                        \ below the maximum altitude specified in A (though we
                        \ may end up placing the object higher than this)

 BCS tree3              \ If the call to PlaceObjectBelow sets the C flag then
                        \ the object has not been successfully placed, so jump
                        \ to tree3 to stop adding trees to the landscape

 DEC treeCounter        \ Decrement the tree counter

 BNE tree2              \ Loop back until we have spawned the number of trees
                        \ in treeCounter

.tree3

                        \ We have now placed all the objects on the landscape,
                        \ so now we fall through into CheckSecretCode to check
                        \ that the player entered the correct secret code for
                        \ this landscape

\ ******************************************************************************
\
\       Name: CheckSecretCode (Part 1 of 2)
\       Type: Subroutine
\   Category: Landscape
\    Summary: Generate the secret code for this landscape and optionally check
\             it against the entered code in the keyboard input buffer
\
\ ------------------------------------------------------------------------------
\
\ At this point we have generated the landscape and populated it with enemies,
\ the player and trees, all using the landscape's sequence of seed numbers. This
\ sequence will be different for each individual level, but will be exactly the
\ same sequence every time we generate a specific level.
\
\ We now keep generating the landscape's sequence of seed numbers to get the
\ landscape's secret code, as follows:
\
\   * Generate another 38 numbers from the sequence
\
\   * The next four numbers in the sequence form the secret code
\
\ To get a secret code of the form 12345678, we take the last four numbers and
\ convert them into binary coded decimal (BCD) by using the GetNextSeedAsBCD
\ routine. These four two-digit pairs then form the secret code, with each of
\ the four numbers producing a pair of digits, building up the secret code from
\ left to right (so in the order that they are written down).
\
\ If we are displaying the landscape number on-screen at the end of a level,
\ then the last four numbers are generated in the DrawSecretCode routine, but if
\ we are checking the secret code entered by the player, then we generate the
\ last four numbers in this routine (plus one extra number that is ignored).
\ This behaviour is controlled by the doNotPlayLandscape variable.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   doNotPlayLandscape  Controls how we generate the secret code and how we
\                       return from the subroutine:
\
\                         * If bit 7 is set, return from part 1 of the routine
\                           after generating the secret code sequence up to, but
\                           not including, the last four BCD numbers (i.e. the
\                           secret code itself), so these can be generated and
\                           drawn by the DrawSecretCode routine
\
\                         * If bit 7 is clear, jump to part 2 after generating
\                           the whole secret code sequence, plus one more code,
\                           checking the generated code against the code entered
\                           into the input buffer as we go
\
\                       The first one is used when displaying a landscape number
\                       for a completed level, while the second is used to check
\                       an entered secret code before playing the landscape
\
\ ******************************************************************************

.CheckSecretCode

 LDX #170               \ Set X = 170 to use as a loop counter for when we
                        \ calculate the secret code, so the following loop
                        \ counts down from 170 to 128 (inclusive, so that's a
                        \ total of 38 + 4 + 1 iterations)
                        \
                        \ This is the value for when bit 7 of doNotPlayLandscape
                        \ is clear, so that's when we are about to play the game
                        \ and we need to generate the secret code in the
                        \ following loop so we can check it against the code
                        \ entered by the player (which is still in the keyboard
                        \ input buffer from when they typed it in)

 LDY stashOffset-170,X  \ Set Y = stashOffset
                        \
                        \ The stashOffset variable is set by the landscape
                        \ drawing process to  value that depends on the
                        \ landscape generation process
                        \
                        \ We use it as an offset into the secretCodeStash list
                        \ below, so the stash moves around in memory depending
                        \ on the landscape number, making this whole process
                        \ harder to follow (and therefore harder to crack)

 BIT doNotPlayLandscape \ If bit 7 of doNotPlayLandscape is clear then the next
 BPL srct1              \ step is to play the landscape, so skip the following
                        \ to leave X set to 170

 LDX #165               \ Set X = 165 to use as a loop counter for when we
                        \ calculate the secret code, so the following loop
                        \ counts down from 165 to 128 (inclusive, so that's a
                        \ total of 38 iterations)
                        \
                        \ This is the value for when bit 7 of doNotPlayLandscape
                        \ is set, so that's when we are not going to play the
                        \ game but are just generating the secret code, in which
                        \ case we stop iterating just before the secret code is
                        \ generated so the DrawSecretCode can finish the job

                        \ We now loop through a number of iterations, counting
                        \ X down towards 128
                        \
                        \ On each iteration we do three things:
                        \
                        \   * We generate the next number from the landscape's
                        \     sequence of seed numbers, converted to BCD
                        \
                        \   * We test this against the contents of memory from
                        \     either &0D19 or &0D14 down to &0CEF and rotate the
                        \     result into bit 0 of secretCodeChecks (the result
                        \     is only relevant if we are checking the secret
                        \     code against an entered code)
                        \
                        \   * We add the objectFlags for the Sentinel (which is
                        \     simply a way of incorporating a known value, in
                        \     this case %01111111) and store the results in the
                        \     table at secretCodeStash, from the offset in Y
                        \     onwards, i.e. from offest stashOffset onwards
                        \
                        \ If we are checking the code against an entered code,
                        \ then the second step is the important part, and this
                        \ is how it works
                        \
                        \ The inputBuffer is at &0CF0, and it still holds the
                        \ code that the player entered in &0CF0 to &0CF3, with
                        \ the first two digits of the code in &0CF3 and the last
                        \ two digits in &0CF0
                        \
                        \ This means that when X = 170, the last five checks in
                        \ each iteration test against the four BCD numbers in
                        \ the entered code, in the correct order, with one extra
                        \ generation and check that is ignored (presumably to
                        \ make this whole process harder to follow)
                        \
                        \ So if bits 1 to 4 of secretCodeChecks are set by the
                        \ end of the process, the secret code in the keyboard
                        \ input buffer matches the secret code that we just
                        \ generated for this level
                        \
                        \ The third step is only relevant if we are going on to
                        \ play the game, as this feeds into a second secret code
                        \ check that is performed in the sub_C24EA routine,
                        \ which looks like it is only run during gameplay ???

.srct1

 JSR GetNextSeedAsBCD   \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, converted to a binary coded decimal
                        \ (BCD) number

                        \ We now compare this generated number with the contents
                        \ of memory, working our way down towards the keyboard
                        \ input buffer (towards the end of the iterations)
                        \
                        \ X counts down to 128, and for each iteration we check
                        \ the generated number against a location in memory
                        \
                        \ For the checks to work, we need the last five bytes
                        \ to be the four secret code numbers in inputBuffer,
                        \ plus one more, so:
                        \
                        \   * When X > 132, we are checking against memory that
                        \     comes after the inputBuffer, and we can safely
                        \     ignore the results
                        \
                        \   * When X = 132, 131, 130 and 129 we need to be
                        \     checking against the four numbers in inputBuffer
                        \
                        \   * When X = 128, we are doing the very last check,
                        \     which we can also ignore
                        \
                        \ The comparison is done by subtracting the contents of
                        \ the memory location we are checking from the BCD
                        \ number we just generated
                        \
                        \ This is done with a SBC byteToCheck,X instruction
                        \
                        \ To work out what byteToCheck should be, consider that:
                        \
                        \   * When X = 129, we check the byte at inputBuffer
                        \                   (i.e. the last 2 digits of the code
                        \                   when written down or typed in)
                        \
                        \   * When X = 130, we check the byte at inputBuffer+1
                        \
                        \   * When X = 131, we check the byte at inputBuffer+2
                        \
                        \   * When X = 132, we check the byte at inputBuffer+3
                        \                   (i.e. the first 2 digits of the code
                        \                   when written down or typed in)
                        \
                        \ To make this work, then, we need this instruction:
                        \
                        \   SBC inputBuffer-129,X
                        \
                        \ BeebAsm can't parse this instruction, however, so we
                        \ have to set up a variable instead to get around this

 byteToCheck = inputBuffer - 129

 SEC                    \ Subtract the byte from memory that we are checking
 SBC byteToCheck,X      \ from the generated number

 BEQ srct2              \ If A = 0 then we have a match between the number in
                        \ memory and the generated number, so jump to srct2 to
                        \ keep the C flag set, so we can rotate this into
                        \ secretCodeChecks to indicate a success

 CLC                    \ Otherwise we do not have a match, so clear the C flag
                        \ and rotate this into secretCodeChecks to indicate a
                        \ failure

.srct2

 ROL secretCodeChecks   \ Rotate the C flag into bit 0 of secretCodeChecks, so
                        \ secretCodeChecks contains a record of the last eight
                        \ matches between memory and the generated sequence of
                        \ numbers
                        \
                        \ We only care about the last five comparisons, of which
                        \ we ignore the very last, as the preceding four results
                        \ are for the four BCD numbers in the keyboard input
                        \ buffer (i.e. the entered number)

                        \ We now move on to poulate the secret code stash, which
                        \ contains the result of each of the comparisons with
                        \ %01111111 added to them
                        \
                        \ The stash is checked in the sub_C24EA routine and will
                        \ abort the game if the values aren't correct, so this
                        \ enables a second secret code check once the game has
                        \ started
                        \
                        \ The secret stash adds a known value into the mix, by
                        \ fetching the value of objectFlags, which contains the
                        \ object flags for object #0
                        \
                        \ Object #0 is always the Sentinel, and the Sentinel
                        \ is always placed on top of the Sentinel's tower, so
                        \ the object flags for the Sentinel are constructed as
                        \ follows:
                        \
                        \   * Bits 0-5 = the number of the object beneath this
                        \                one
                        \
                        \   * Bit 6 = set to indicate that this object is on top
                        \             of another object
                        \
                        \   * Bit 7 = clear to indicate that this object number
                        \             is allocated to an object
                        \
                        \ The Sentinel's tower is always the first object to be
                        \ spawned, and object numberss are allocated from 63 and
                        \ down, so this means the tower is always object #63, or
                        \ %111111
                        \
                        \ The Sentinel's object flags are therefore %01111111
                        \
                        \ See the PlaceObjectOnTile routine for details of how
                        \ the Sentinel's object flags are constructed

 CLC                    \ Set A = A + %01111111
 ADC objectFlags

 STA secretCodeStash,Y  \ Store A in the Y-th entry in the secretCodeStash list
                        \
                        \ The addition above means that an entry of %01111111 in
                        \ that stash indicates that A was zero before the
                        \ addition, which also indicates a match
                        \
                        \ If the entered code matches the generated sequence of
                        \ numbers (i.e. it matches the landscape's secret code)
                        \ then the four corresponding entries in secretCodeStash
                        \ will be %01111111
                        \
                        \ See the sub_C24EA routine to see this in action

 INY                    \ Increment the index in Y so we build the stash upwards
                        \ in memory

 DEX                    \ Decrement the loop counter so the comparisons move
                        \ down in memory, towards inputBuffer

 BMI srct1              \ Look back to compare the next byte until we have
                        \ compared the bytes all the way down to X = 128

 ASL doNotPlayLandscape \ Set the C flag to bit 7 of doNotPlayLandscape and
                        \ clear bit 7 of doNotPlayLandscape, so from this point
                        \ on any calls to GenerateLandscape will preview and
                        \ play the game

 BCC srct4              \ If bit 7 of doNotPlayLandscape was clear then jump to
                        \ part 2 to check the secret code and either show the
                        \ "WRONG SECRET CODE" error or play the game

                        \ Otherwise bit 7 of doNotPlayLandscape was set, so we
                        \ return from the subroutine normally without playing
                        \ the game

.srct3

 RTS                    \ Return from the subroutine
                        \
                        \ We get to this point by calling the SpawnPlayer
                        \ routine from one of two places:
                        \
                        \   * PreviewLandscape
                        \
                        \   * FinishLandscape
                        \
                        \ and then either failing the secret code checks or
                        \ finishing the current landscape
                        \
                        \ If we got here from PreviewLandscape, then the next
                        \ instruction jumps to SecretCodeError to display the
                        \ "WRONG SECRET CODE" error, wait for a key press and
                        \ rejoin the main title loop
                        \
                        \ If we got here from FinishLandscape, then the next
                        \ instructions display the landscape's secret code on
                        \ completion of the level

\ ******************************************************************************
\
\       Name: landscapeColour3
\       Type: Variable
\   Category: Landscape
\    Summary: Physical colours for colour 3 in the game palette for the
\             different numbers of enemies
\
\ ******************************************************************************

.landscapeColour3

 EQUB 2                 \ Enemy count = 1: blue, black, white, green

 EQUB 1                 \ Enemy count = 2: blue, black, yellow, red

 EQUB 3                 \ Enemy count = 3: blue, black, cyan, yellow

 EQUB 6                 \ Enemy count = 4: blue, black, red, cyan

 EQUB 1                 \ Enemy count = 5: blue, black, white, red

 EQUB 6                 \ Enemy count = 6: blue, black, yellow, cyan

 EQUB 1                 \ Enemy count = 7: blue, black, cyan, red

 EQUB 3                 \ Enemy count = 8: blue, black, red, yellow

\ ******************************************************************************
\
\       Name: CheckSecretCode (Part 2 of 2)
\       Type: Subroutine
\   Category: Landscape
\    Summary: Check the results of the secret code matching process, and if the
\             secret codes match, jump to PlayGame to play the game
\
\ ******************************************************************************

.srct4

 LDA secretCodeChecks   \ If bits 1 to 4 of secretCodeChecks are not all set,
 AND #%00011110         \ then one or more of the four BCD bytes in the secret
 CMP #%00011110         \ code do not match, so jump to srct3 to return from the
 BNE srct3              \ subroutine normally, to display the "WRONG SECRET
                        \ CODE" error page

                        \ If get here then bits 1 to 4 of secretCodeChecks are
                        \ all set, so the entered secret entry code matches the
                        \ generated code, so we can now proceed to playing the
                        \ landscape
                        \
                        \ The following code simply jumps to the PlayGame
                        \ routine, but in an obfuscated way that changes the
                        \ return address on the stack to PlayGame-1, so the RTS
                        \ instruction will jump to PlayGame (as that's how the
                        \ RTS instruction works)

 PLA                    \ Remove the return address from the stack and discard
 PLA                    \ it

                        \ In the following we use the value in objectFlags,
                        \ which contains the object flags for the object #0
                        \
                        \ Object #0 is always the Sentinel, and the Sentinel
                        \ is always placed on top of the Sentinel's tower, so
                        \ the object flags for the Sentinel are constructed as
                        \ follows:
                        \
                        \   * Bits 0-5 = the number of the object beneath this
                        \                one
                        \
                        \   * Bit 6 = set to indicate that this object is on top
                        \             of another object
                        \
                        \   * Bit 7 = clear to indicate that this object number
                        \             is allocated to an object
                        \
                        \ The Sentinel's tower is always the first object to be
                        \ spawned, and object numberss are allocated from 63 and
                        \ down, so this means the tower is always object #63, or
                        \ %111111
                        \
                        \ The Sentinel's object flags are therefore %01111111
                        \
                        \ The following code uses this fact to push the address
                        \ of PlayGame-1 onto the stack, but in a totally
                        \ obfuscated manner
                        \
                        \ It calculates the high byte as follows:
                        \
                        \     objectFlags + HI(PlayGame-1) - %01111111
                        \   = %01111111 + HI(PlayGame-1) - %01111111
                        \   = HI(PlayGame-1)
                        \
                        \ and the low byte as follows:
                        \
                        \     high byte + LO(PlayGame-1) - HI(PlayGame-1)
                        \   = HI(PlayGame-1) + LO(PlayGame-1) - HI(PlayGame-1)
                        \   = LO(PlayGame-1)
                        \
                        \ For the first calculation, we need to apply a little
                        \ hack to the code to get around a limitation in BeebAsm
                        \ that rejects negative constants
                        \
                        \ HI(PlayGame-1) - %01111111 in the first calculation is
                        \ negative, so to persuade BeebAsm to accept it as a
                        \ constant, we can wrap it in LO() to convert it into
                        \ a two's complement value that BeebAsm will accept
                        \
                        \ The LO() part is effectively applying MOD 256 in a way
                        \ that works with negative arguments

 CLC                    \ Push PlayGame-1 onto the stack, high byte first
 LDA objectFlags
 ADC #LO(HI(PlayGame-1) - %01111111)
 PHA
 CLC
 ADC #LO(PlayGame-1) - HI(PlayGame-1)
 PHA

 RTS                    \ Return from the subroutine, which will take the
                        \ address off the stack, increment it and jump to that
                        \ address
                        \
                        \ So this jumps to PlayGame to play the actual game

\ ******************************************************************************
\
\       Name: landscapeColour2
\       Type: Variable
\   Category: Landscape
\    Summary: Physical colours for colour 2 in the game palette for the
\             different numbers of enemies
\
\ ******************************************************************************

.landscapeColour2

 EQUB 7                 \ Enemy count = 1: blue, black, white, green

 EQUB 3                 \ Enemy count = 2: blue, black, yellow, red

 EQUB 6                 \ Enemy count = 3: blue, black, cyan, yellow

 EQUB 1                 \ Enemy count = 4: blue, black, red, cyan

 EQUB 7                 \ Enemy count = 5: blue, black, white, red

 EQUB 3                 \ Enemy count = 6: blue, black, yellow, cyan

 EQUB 6                 \ Enemy count = 7: blue, black, cyan, red

 EQUB 1                 \ Enemy count = 8: blue, black, red, yellow

\ ******************************************************************************
\
\       Name: AddEnemiesToTiles
\       Type: Subroutine
\   Category: Landscape
\    Summary: Add the required number of enemies to the landscape, starting from
\             the highest altitude and working down, with one enemy per contour
\
\ ******************************************************************************

.AddEnemiesToTiles

 JSR GetHighestTiles    \ Calculate both the highest tiles in each 4x4 block of
                        \ tiles in the landscape and the altitude of the highest
                        \ tile, putting the results in the following variables:
                        \
                        \   * maxAltitude contains the altitude of the highest
                        \     tile in each 4x4 block in the landscape
                        \
                        \   * xTileMaxAltitude contains the tile x-coordinate of
                        \     the highest tile in each 4x4 block in the
                        \     landscape
                        \
                        \   * zTileMaxAltitude contains the tile z-coordinate of
                        \     the highest tile in each 4x4 block in the
                        \     landscape
                        \
                        \   * tileAltitude contains the altitude of the highest
                        \     tile in the entire landscape

 LDX #0                 \ We now loop through the number of enemies, adding one
                        \ enemy for each loop and iterating numberOfEnemies
                        \ times, so set an enemy counter in X to count the
                        \ enemies as we add them
                        \
                        \ If this is a level with only one enemy, then that
                        \ enemy must be the Sentinel, so when X = 0, we add the
                        \ Sentinel to the landscape, otherwise we add a sentry
                        \
                        \ Enemies are allocated object numbers from 0 to 7, with
                        \ the Sentinel in object #0, and sentries from object #1
                        \ to object #7 (if there are any)

.aden1

 STX enemyCounter       \ Set enemyCounter to the enemy counter in X, so we can
                        \ retrieve it later in the loop

 LDA #1                 \ Set the object type for object #X to type 1, which
 STA objectTypes,X      \ denotes a sentry, so we spawn sentries in objects #1
                        \ to #numberOfEnemies (this also sets the type for
                        \ object #0 to type 1, but this gets overridden when
                        \ the Sentinel is spawned as object #0 below)

                        \ We now work down the landscape, from the highest peaks
                        \ down to lower altitudes, looking for suitable tile
                        \ blocks to place an enemy
                        \
                        \ To do this we start with tile blocks that are at an
                        \ altitude of tileAltitude (which we set above to the
                        \ altitude of the highest tile in the landscape), and we
                        \ work down in steps of 16

.aden2

 JSR GetTilesAtAltitude \ Set tilesAtAltitude to a list of tile block numbers
                        \ whose highest tiles in the 4x4 block are at an
                        \ altitude of tileAltitude, returning the length of the
                        \ list in T and a bit mask in bitMask that has a
                        \ matching number of leading zeroes as T

 BCC aden3              \ If the call to GetTilesAtAltitude returns at least one
                        \ tile block at this altitude then the C flag will be
                        \ clear, so jump to aden3 to add an enemy to one of the
                        \ matched tile blocks

 LDA tileAltitude       \ Otherwise we didn't find any tile blocks at this
 SEC                    \ altitude, so subtract 1 from the high nibble of
 SBC #%00010000         \ tileAltitude to move down one level (we subtract from
 STA tileAltitude       \ the high nibble because tileAltitude contains tile
                        \ data, which has the tile altitude in the high nibble
                        \ and the tile shape in the low nibble)

 BNE aden2              \ Loop back to check for tile blocks at the lower
                        \ altitude until we have reached an altitude of zero

 STX numberOfEnemies    \ When the GetTilesAtAltitude routine returns with no
                        \ matching tile blocks, it also returns a value of &FF
                        \ in X, so this sets numberOfEnemies to -1

 JMP aden6              \ Jump to aden6 to set the value of minEnemyAltitude
                        \ and return from the subroutine

.aden3

                        \ If we get here then we have found at least one tile
                        \ block at the current altitude, so we now pick one of
                        \ them, using the next seed number to choose which one,
                        \ and we then add an enemy to the highest tile in the
                        \ block
                        \
                        \ We only pick one tile at this altitude so that the
                        \ enemies are spread out over various altitudes

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 AND bitMask            \ The call to GetTilesAtAltitude above sets bitMask to a
                        \ bit mask that has a matching number of leading zeroes
                        \ as the number of tile blocks at this altitude, so this
                        \ instruction converts A into a number with the same
                        \ range of non-zero bits as T

 CMP T                  \ If A >= T then jump back to fetch another seed number
 BCS aden3

                        \ When we get here, A is a seed number and A < T, so
                        \ A can be used as an offset into the list of tile
                        \ blocks in tilesAtAltitude (which contains T entries)

 TAY                    \ Set Y to the seed number in A so we can use it as an
                        \ index in the following instruction

 LDX tilesAtAltitude,Y  \ Set X to the Y-th tile block number in the list of
                        \ tile blocks at an altitude of tilesAtAltitude

                        \ We now zero the maximum tile altitudes for tile block
                        \ X and the eight surrounding tile blocks, so that
                        \ further calls to GetTilesAtAltitude won't match these
                        \ tiles, so we therefore won't put any enemies on those
                        \ blocks (this ensures we don't create enemies too close
                        \ to each other)

 LDA #0                 \ Set A = 0 so we can zero the maximum tile altitudes
                        \ for tile block X and the eight surrounding blocks

 STA maxAltitude-9,X    \ Zero the altitudes of the three tile blocks in the row
 STA maxAltitude-8,X    \ in front of tile block X
 STA maxAltitude-7,X

 STA maxAltitude-1,X    \ Zero the altitudes of tile block X and the two blocks
 STA maxAltitude,X      \ to the left and right
 STA maxAltitude+1,X

 STA maxAltitude+7,X    \ Zero the altitudes of the three tile blocks in the row
 STA maxAltitude+8,X    \ behind tile block X
 STA maxAltitude+9,X

 LDA xTileMaxAltitude,X \ Set (xTile, zTile) to the tile coordinates of the
 STA xTile              \ highest tile in the tile block, which is where we can
 LDA zTileMaxAltitude,X \ place an enemy
 STA zTile

 LDX enemyCounter       \ Set X to the loop counter that we stored above

 BNE aden4              \ If the loop number is non-zero then we are adding a
                        \ sentry, so jump to aden4

                        \ If we get here then the enemy counter is zero, so we
                        \ are adding the Sentinel and the Sentinel's tower

 STA zTileSentinel      \ Set (xTileSentinel, zTileSentinel) to the tile
 LDA xTile              \ coordinates of the highest tile in the tile block,
 STA xTileSentinel      \ which we put in (xTile, zTile) above, so this is the
                        \ tile coordinate where we now spawn the Sentinel

 LDA #5                 \ Set the object type for object #0 to type 5, which
 STA objectTypes        \ denotes the Sentinel (so the Sentinel is always
                        \ object #0, while other objects that are spawned are
                        \ allocated to object #63 and work down the bumbers)

 LDA #6                 \ Spawn the Sentinel's tower (an object of type 6),
 JSR SpawnObject        \ returning the object number of the new object in X
                        \ and currentObject

 JSR PlaceObjectOnTile  \ Place object #X on the tile anchored at (xTile, zTile)
                        \ to place the tower on the landscape

 LDA #0                 \ Set the tower object's objectYawAngle to 0, so it's
 STA objectYawAngle,X   \ facing forwards and into the screen

 LDX enemyCounter       \ Set X to the enemy counter, so X now contains the
                        \ object number of the Sentinel (which is always zero
                        \ as we only add the Sentinel on the first iteration of
                        \ the loop)
                        \
                        \ We now place the Sentinel object on the tile, which
                        \ therefore places the Sentinel on top of the tower

.aden4

 JSR PlaceObjectOnTile  \ Place object #X on the tile anchored at (xTile, zTile)
                        \ to place the Sentinel or sentry in the correct place
                        \ on the landscape

 JSR SetEnemyData       \ ???

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 LSR A                  \ Set the C flag to bit 7 of A (this also clears bit 7
                        \ of A but that doesn't matter as we are about to clear
                        \ it in the next instruction anyway)

 AND #%00111111         \ Set A to a number in the range 5 to 63
 ORA #5

 STA objRotationTimer,X \ Set the object's entry in objRotationTimer to the
                        \ number in A, so this determines how often the object
                        \ rotates in iterations of the main game loop

 LDA #20                \ Set A to either 20 or 236, depending on the value that
 BCC aden5              \ we gave to the C flag above
 LDA #236

.aden5

 STA objRotationSpeed,X \ Set the object's entry in objRotationSpeed to the
                        \ value of A, which is either 20 or 236
                        \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of object
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
                        \ The rotation speed is the size of the angle through
                        \ which the object yaws on each rotation, so this means
                        \ we are setting the rotation speed to +20 degrees (a
                        \ clockwise turn) or -20 degrees (an anticlockwise turn)

 INX                    \ Increment the enemy loop counter in X

 CPX numberOfEnemies    \ If we have added a total of numberOfEnemies enemies,
 BCS aden6              \ jump to aden6 to finish off

 JMP aden1              \ Otherwise loop back to add another enemy

.aden6

 LDA tileAltitude       \ Extract the altitude from tileAltitude, which is in
 LSR A                  \ the high nibble (as tileAltitude contains tile data,
 LSR A                  \ which has the tile altitude in the high nibble and
 LSR A                  \ the tile shape in the low nibble)
 LSR A

 STA minEnemyAltitude   \ Store the result in minEnemyAltitude, so it contains
                        \ the lowest altitude of the enemies we just added to
                        \ the landscape

 CLC                    \ Clear the C flag (though this has no effect as the C
                        \ flag is set as soon as we return to the SpawnEnemies
                        \ routine)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetTilesAtAltitude
\       Type: Subroutine
\   Category: Landscape
\    Summary: Return a list of tile blocks at a specified altitude
\
\ ------------------------------------------------------------------------------
\
\ Argument:
\
\   tileAltitude        The altitude to search for
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Status flag:
\
\                         * Clear if at least one tile block is at an altitude
\                           of tileAltitude
\
\                         * Set if no tile blocks are at an altitude of
\                           tileAltitude, in which case X is set to &FF
\
\   tilesAtAltitude     A list of tile block numbers whose highest tiles match
\                       the altitude in tileAltitude
\
\   T                   The number of entries in the list at tilesAtAltitude
\
\   bitMask             A bit mask with a matching number of leading zeroes as T
\
\ ******************************************************************************

.GetTilesAtAltitude

                        \ We start by fetching all the 4x4 tile blocks from the
                        \ landscape whose altitude matches tileAltitude (so
                        \ that's all the 4x4 blocks whose highest tile is at an
                        \ altitude of tileAltitude)

 LDX #63                \ Set an index in X to work through all 4x4 tile blocks,
                        \ of which there are 64

 LDY #0                 \ Set Y = 0 to count the number of tile blocks whose
                        \ altitude matches tileAltitude

.galt1

 LDA maxAltitude,X      \ If the highest tile in the X-th tile block does not
 CMP tileAltitude       \ have an altitude of tileAltitude, jump to galt2 to
 BNE galt2              \ move on to the next tile block

 TXA                    \ Store the number of the tile block in the Y-th byte of
 STA tilesAtAltitude,Y  \ tilesAtAltitude, so we end up compiling a list of all
                        \ the tile blocks that have an altitude of tileAltitude

 INY                    \ Increment the counter in Y as we have just added a
                        \ block number to tilesAtAltitude

.galt2

 DEX                    \ Decrement the block counter in X

 BPL galt1              \ Loop back until we have checked the altitudes of all
                        \ the tile blocks

                        \ By this point we have all the tile blocks with an
                        \ altitude of tileAltitude in a list of length Y at
                        \ tilesAtAltitude

 TYA                    \ Set A to the length of the list at tilesAtAltitude

 BEQ galt4              \ If the list is empty then jump to galt4 return from
                        \ the subroutine with the C flag clear

 STA T                  \ Set T to the length of the list at tilesAtAltitude

                        \ We now set bitMask to a bit mask that covers all the
                        \ non-zero bits in the list length in A, so if A is of
                        \ the form %001xxxxx, for example, then bitMask will
                        \ contain %00111111, while A being like %000001xx will
                        \ give a bitMask of %00000111
                        \
                        \ To do this we count the number of continuous clear
                        \ bits at the top of A, and then use this as an index
                        \ into the bitMasks table
                        \
                        \ So we count zeroes from bit 7 down until we hit a 1,
                        \ and put the result into Y

 LDY #&FF               \ Set Y = -1 so the following loop counts the number of
                        \ zeroes correctly

.galt3

 ASL A                  \ Shift A to the left, moving the top bit into the C
                        \ flag

 INY                    \ Increment the zero counter in Y

 BCC galt3              \ Loop back to keep shifting and counting zeroes until
                        \ we shift a 1 out of bit 7, at which point Y contains
                        \ the length of the run of zeroes in bits 7 to 0 of the
                        \ length of the list at tilesAtAltitude

 LDA bitMasks,Y         \ Set bitMask to the Y-th entry from the bitMasks table,
 STA bitMask            \ which will give us a bit mask with a matching number
                        \ of leading zeroes as A

 CLC                    \ Clear the C flag to indicate that we have successfully
                        \ found at least one tile block that matches the
                        \ altitude in tileAltitude

 RTS                    \ Return from the subroutine

.galt4

 SEC                    \ If we get here then we have checked all 64 tile blocks
                        \ and none of them are at aan altitude of tileAltitude,
                        \ so set the C flag to indicate that the returned list
                        \ is empty

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: bitMasks
\       Type: Variable
\   Category: Landscape
\    Summary: A table for converting the number of leading clear bits in a
\             number into a bit mask with the same number of leading zeroes
\
\ ******************************************************************************

.bitMasks

 EQUB %11111111
 EQUB %01111111
 EQUB %00111111
 EQUB %00011111
 EQUB %00001111
 EQUB %00000111
 EQUB %00000011
 EQUB %00000001

\ ******************************************************************************
\
\       Name: GetHighestTiles
\       Type: Subroutine
\   Category: Landscape
\    Summary: Calculate both the highest tiles in each 4x4 block of tiles in the
\             landscape and the altitude of the highest tile in the landscape
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   maxAltitude         The altitude (i.e. y-coordinate) of the highest tile in
\                       each 4x4 block in the landscape
\
\   xTileMaxAltitude    The tile x-coordinate of the highest tile in each 4x4
\                       block in the landscape
\
\   zTileMaxAltitude    The tile z-coordinate of the highest tile in each 4x4
\                       block in the landscape
\
\   tileAltitude        The altitude of the highest tile in the landscape
\
\ ******************************************************************************

.GetHighestTiles

                        \ This routine works through the tile corners in the
                        \ landscape in 4x4 blocks and finds the highest flat
                        \ tile within each block, so we can consider putting an
                        \ enemy there
                        \
                        \ To do this we split the 32x32-corner landscape up into
                        \ 8x8 blocks of 4x4 tile corners each, iterating along
                        \ each row of 4x4 blocks from left to right, and then
                        \ moving back four rows to the next row of 4x4 blocks
                        \ behind
                        \
                        \ Because the tile corners along the right and back
                        \ edges of the landscape don't have tile altitudes
                        \ associated with them, we ignore those corners

 LDX #0                 \ Set X to loop from 0 to 63, to use as a block counter
                        \ while we work through the landscape in blocks of 4x4
                        \ tiles, of which there are 64 in total

 STX tileAltitude       \ Set tileAltitude = 0 so we can use it to store the
                        \ maximum tile altitude as we work through the landscape
                        \ (so that's the altitude of the landscape's highest
                        \ tile)

.high1

 TXA                    \ Set A = X mod 8
 AND #7                 \
                        \ The 32x32-tile landscape splits up into 8x8 blocks of
                        \ 4x4 tiles each, so this sets A to the number of the
                        \ block along the left-to-right x-axis row that we are
                        \ working along (so A goes from 0 to 7 and around again)

 ASL A                  \ Set xBlock = A * 4
 ASL A                  \
 STA xBlock             \ So xBlock is the tile x-coordinate of the tile in the
                        \ front-left corner of the 4x4 block we are analysing
                        \ (so xBlock goes 0, 4, 8 ... 24, 28)

 TXA                    \ Set A = X div 8
 AND #%00111000         \
                        \ X is in the range 0 to 64, so this instruction has the
                        \ same effect as AND #%11111000, which is equivalent to
                        \ a div 8 operation
                        \
                        \ The 32x32-tile landscape splits up into 8x8 blocks of
                        \ 4x4 tiles each, so this sets A to the number of the
                        \ row of 4x4 blocks along the front-to-back z-axis row
                        \ that we are working along (so A goes 0, 8, 16 ... 56)

 LSR A                  \ Set zBlock = A / 2
 STA zBlock             \
                        \ So zBlock is the tile z-coordinate of the tile in the
                        \ front-left corner of each of the 4x4 blocks in the row
                        \ that we are analysing (so zBlock goes 0, 4, 8 ... 24,
                        \ 28)

                        \ Essentially, by this point we have converted the loop
                        \ counter in X from the sequence 0 to 63 into an inner
                        \ loop of xBlock and an outer loop of zBlock, with both
                        \ variables counting 0, 4, 8 ... 24, 28
                        \
                        \ We can now use (xBlock, zBlock) as a tile coordinate
                        \ and we can store the highest tile altitude within each
                        \ 4x4 block using the index in X

 LDA #0                 \ Zero the X-th entry in the maxAltitude table, which
 STA maxAltitude,X      \ is where we will store the highest tile altitude
                        \ within block X

 LDA #4                 \ Set zCounter = 4 to iterate along the z-axis through
 STA zCounter           \ each tile in the 4x4 block we are analysing, so
                        \ zCounter iterates from 4 down to 1

 LDA zBlock             \ Set zTile = zBlock
 STA zTile              \
                        \ So we can use zTile as the tile z-coordinate of the
                        \ tile to analyse within the 4x4 block

 CMP #28                \ If zBlock < 28 then then we are not on the tile row at
 BCC high2              \ the back of the landscape, so jump to high2 to skip
                        \ the following instruction

 DEC zCounter           \ We are on the tile row at the back of the landscape,
                        \ so set zCounter = 3 so it iterates from 3 down to 1
                        \ for this block, because the blocks along the back row
                        \ are only three tiles deep (as the landscape is 31
                        \ tiles deep)

.high2

 LDA #4                 \ Set xCounter = 4 to iterate along the x-axis through
 STA xCounter           \ each tile in the 4x4 block we are analysing, so
                        \ xCounter iterates from 4 down to 1

 LDA xBlock             \ Set xTile = xBlock
 STA xTile              \
                        \ So we can use xTile as the tile x-coordinate of the
                        \ tile to analyse within the 4x4 block

 CMP #28                \ If xBlock < 28 then we are not at the right end of the
 BCC high3              \ tile row, so jump to high3 to skip the following
                        \ instruction

 DEC xCounter           \ We are at the right end of the tile row, so set
                        \ xCounter = 3 so it iterates from 3 down to 1 for this
                        \ block, because the last block on the row is only three
                        \ tiles across (as the landscape is 31 tiles across)

.high3

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)
                        \
                        \ This also sets the tile page in tileDataPage and the
                        \ tile number in Y, so tileDataPage+Y now points to the
                        \ tile data entry in the tileData table

 AND #%00001111         \ Set A to the tile shape for the tile, which is in the
                        \ bottom nibble of the tile data

 BNE high5              \ If the shape is non-zero then the tile is not flat, so
                        \ jump to high5 to move on to the next tile in the

 LDA (tileDataPage),Y   \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 AND #%11110000         \ Set A to the tile altitude, which is in the top nibble
                        \ of the tile data

 CMP maxAltitude,X      \ If the altitude of the tile we are analysing is lower
 BCC high5              \ than the altitude we have currently stored in the
                        \ maxAltitude table for this 4x4 tile block, jump to
                        \ high5 to move on to the next tile, as this one isn't
                        \ the highest in either this block or the landscape

 STA maxAltitude,X      \ If we get here then ths tile we are analysing is the
                        \ highest in the 4x4 block so far, so store the altitude
                        \ in the maxAltitude table forthis 4x4 tile block so
                        \ the table ends up recording the highest tile altitude
                        \ in each 4x4 block

 CMP tileAltitude       \ Set tileAltitude = max(tileAltitude, A)
 BCC high4              \
 STA tileAltitude       \ So tileAltitude contains the altitude of the highest
                        \ tile that we've analysed so far, which means that
                        \ tileAltitude ends up being set to the highest value
                        \ in the entire landscape, which is the altitude of the
                        \ highest tile of all

.high4

 LDA xTile              \ Store the x-coordinate of the highest tile corner in
 STA xTileMaxAltitude,X \ this block (so far) in the xTileMaxAltitude table
                        \ entry for this 4x4 block

 LDA zTile              \ Store the z-coordinate of the highest tile corner in
 STA zTileMaxAltitude,X \ this block (so far) in the zTileMaxAltitude table
                        \ entry for this 4x4 block

.high5

 INC xTile              \ Increment xTile to move on to the next tile to the
                        \ right, for the inner loop

 DEC xCounter           \ Decrement the x-axis counter within this 4x4 block

 BNE high3              \ Loop back until we have processed all the tiles in the
                        \ 4x4 block, working from left to right

 INC zTile              \ Increment zTile to move on to the next tile towards
                        \ the back, for the outer loop

 DEC zCounter           \ Decrement the z-axis counter within this 4x4 block

 BNE high2              \ Loop back until we have processed all the tile rows in
                        \ the 4x4 block, working from front to back

 INX                    \ Increment the block counter in X

 CPX #64                \ Loop back until we have processed all 63 4x4 blocks
 BCC high1

 RTS                    \ Return from the subroutine

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
 BNE UpdateScanner
 CMP L0C09
 BEQ CRE07

\ ******************************************************************************
\
\       Name: UpdateScanner
\       Type: Subroutine
\   Category: Graphics
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The update action:
\
\                         * 0 = fill scanner with black
\
\                         * 8 = fill scanner with green
\
\                         * ???
\
\ ******************************************************************************

.UpdateScanner

 STA L0C09
 STA L169B
 LDA viewScreenAddr
 SEC
 SBC #&4F
 STA L0022
 LDA viewScreenAddr+1
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
 LDX enemyObject
 LDA objectTypes,X
 CMP #&01
 BEQ C16B9
 CMP #&05
 BNE C16C9

.C16B9

 STA titleObjectToDraw

 LDA objectFlags,X      \ Set A to the object flags for object #X

 BPL C16D9
 JSR sub_C1A54
 BCS C16C9
 JMP C1871

.C16C9

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 DEC enemyObject        \ ??? This is the only place enemyObject is updated, it
 BPL C16D4              \ seems to contain an enemy object number, 0 to 7
 LDA #&07
 STA enemyObject

.C16D4

 LDA playerObject       \ Set anotherObject to the object number of the player
 STA anotherObject

 RTS

.C16D9

 LDA objRotationTimer,X
 CMP #&02
 BCS C16C9
 LDA #&04
 STA objRotationTimer,X
 LDA #&14
 STA L0C68
 LDA enemyData5,X
 BPL C16F2
 JMP C176A

.C16F2

 STA anotherObject
 LDY enemyData6,X
 LDA objectFlags,Y
 BMI C174F
 LDA #0
 JSR sub_C1882
 LDA L0C57
 CMP #&14
 BCS C171B
 CPY playerObject
 BNE C174F
 LDA L0014
 BEQ C1754

 JSR PerformHyperspace  \ Hyperspace the player to a brand new tile

 LDA #4
 STA titleObjectToDraw

 JMP C16C9

.C171B

 LDA #&08
 BIT L0C57
 BPL C1724
 LDA #&F8

.C1724

 STA L0C0E
 LDY enemyObject
 LDX enemyData5,Y
 TXA
 JSR sub_C1AE7
 LDA objectYawAngle,X
 CLC
 ADC L0C0E
 STA objectYawAngle,X
 LDA #&0A
 STA objRotationTimer,Y
 TXA
 PHA
 LDX #&03
 LDY #&46

 LDA #1                 \ Make sound #1 (???) with the pitch in X and Y
 JSR MakeSound-6

 PLA
 TAX
 JMP C1876

.C174F

 LDA #0
 STA L0C20,X

.C1754

 LDY enemyObject
 LDX enemyData5,Y
 TXA
 JSR sub_C1AE7
 LDA #&80
 STA enemyData5,Y
 LDA #&02
 STA objectTypes,X
 JMP C1871

.C176A

 STX anotherObject
 JSR sub_C1A54
 BCS C1774
 JMP C1871

.C1774

 LDX enemyObject
 LDA enemyData8,X
 BPL C178C
 JSR sub_C1AA7
 LDX enemyObject
 BCS C1789
 LDA #&40
 STA enemyData1,X
 BNE C17E1

.C1789

 LSR enemyData8,X

.C178C

 LDA L0C20,X
 BEQ C17A3
 LDY enemyData6,X
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
 CPY playerObject
 BNE C17C1
 STY L000F

.C17C1

 DEY
 BPL P17A9
 LDY L000F
 BMI C17D7
 TYA
 CMP enemyData3,X
 BEQ C17D7
 JSR SetEnemyData
 LDA #&40
 STA L0014
 BNE C1820

.C17D7

 LDA #0
 STA L0C20,X
 JSR sub_C1AA7
 BCS C17F0

.C17E1

 JSR DrainObjectEnergy
 BCS C17F9
 LDY enemyObject
 LDA #&1E
 STA objRotationTimer,Y
 JMP C1871

.C17F0

 LDX enemyObject
 LDA L0C28,X
 CMP #&02
 BCC C17FC

.C17F9

 JMP C16C9

.C17FC

 TXA
 JSR sub_C1AE7
 LDA objectYawAngle,X
 CLC
 ADC objRotationSpeed,X
 STA objectYawAngle,X
 LDA #&C8
 STA L0C28,X
 JSR SetEnemyData
 LDX #&07
 LDY #&78

 LDA #0                 \ Make sound #0 (???) with the pitch in X and Y
 JSR MakeSound-6

 LDX enemyObject
 JMP C1876

.C1820

 TYA
 STA enemyData6,X
 LDA L0014
 STA enemyData7,X
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
 JSR DrainObjectEnergy
 LDY enemyObject
 LDA #&1E
 STA objRotationTimer,Y
 BCS C187F
 JMP C1871

.C184D

 JSR sub_C197D
 LDY enemyObject
 BCC C1869
 LDA enemyData4,Y
 CMP #&02
 BCS C1862
 LDA #&80
 STA enemyData8,Y
 BNE C187F

.C1862

 LDA #0
 STA L0C20,Y
 BEQ C187F

.C1869

 LDA #&32
 STA objRotationTimer,Y
 LDX enemyData5,Y

.C1871

 LDA #&40
 STA L0C6D

.C1876

 STX currentObject

 LDA playerObject       \ Set anotherObject to the object number of the player
 STA anotherObject

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
 LDA objectFlags,Y
 BMI C1911
 LDA objectTypes,Y
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
 LDA angleLo
 STA sightsYawAngleLo
 LDA angleHi
 STA sightsYawAngleHi
 LDA #&02
 STA L001E
 LDA L004C
 BNE C18FF

 SEC                    \ Set bit 7 of L0C6E ???
 ROR L0C6E

 LDA L0081
 STA L0080
 LDA L0084

.C18E1

 JSR sub_C561D
 LDA angleLo
 STA sightsPitchAngleLo
 STA T
 LDA angleHi
 STA sightsPitchAngleHi
 JSR sub_C1C43
 JSR sub_C1CCC
 ROL L0C56
 ROR L0014
 ROL L0CDD
 ROR L0C76

.C18FF

 LSR L0C6E              \ Clear bit 7 of L0C6E ???

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

 LDA objectFlags,X      \ Set A to the object flags for object #X

 BMI C1945

 LDA objectTypes,X

 CMP #&01
 BEQ C1930
 CMP #&05
 BNE C1945

.C1930

 LDA enemyData6,X
 CMP playerObject
 BNE C1945
 LDA L0C20,X
 BEQ C1945
 LDY #&04
 LDA enemyData7,X
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
 STY soundData+16       \ First parameter of sound block #2 (channel)
 CMP #&03
 BEQ CRE08
 LDX #&06
 JSR FlushBuffer

.CRE08

 RTS

\ ******************************************************************************
\
\       Name: SetEnemyData
\       Type: Subroutine
\   Category: Landscape
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The object number of the enemy being added
\
\ ******************************************************************************

.SetEnemyData

 LDA #%10000000         \ Set bit 7 of enemyData5 for object #X ???
 STA enemyData5,X

 STA enemyData3,X       \ Set bit 7 of enemyData3 for object #X ???

 LDA #0                 \ Zero enemyData4 for object #X ???
 STA enemyData4,X

 LDA #%01000000         \ Clear bit 7 and set bit 6 of enemyData1 for object #X
 STA enemyData1,X       \ ???

 RTS                    \ Return from the subroutine

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
 LDX enemyObject
 STX anotherObject

.C1986

 LDX enemyObject
 LDY enemyData1,X
 BNE C1998
 INC enemyData4,X
 LDA enemyData6,X
 STA enemyData3,X
 SEC
 RTS

.C1998

 DEC enemyData1,X
 DEY
 LDA objectFlags,Y
 BMI C1986
 LDA objectTypes,Y
 CMP #&02
 BNE C1986
 LDA enemyData6,X
 TAX
 LDA xObject,X
 SEC
 SBC xObject,Y
 BPL C19BA
 EOR #&FF
 CLC
 ADC #&01

.C19BA

 CMP #&0A
 BCS C1986
 LDA zObject,X
 SEC
 SBC zObject,Y
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
 LDX enemyObject
 TYA
 JSR sub_C1AF3
 BCC C19F1
 TYA
 STA enemyData5,X
 LDA #&04
 STA objectTypes,Y
 LDA #&68
 STA L0CD4
 CLC
 RTS

.C19F1

 INC enemyData1,X
 JMP sub_C1AEC

\ ******************************************************************************
\
\       Name: DrainObjectEnergy
\       Type: Subroutine
\   Category: Gameplay
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Result flag:
\
\                         * Set if the player still has a positive energy
\                           level after the update
\
\                         * Clear if the player now has a negative energy level,
\                           which means the Sentinel has won
\
\ ******************************************************************************

.dobj1

                        \ If we jump here from below here then the player has
                        \ run out of energy

 LDA #%10000000         \ Set bit 7 of sentinelHasWon to indicate that the
 STA sentinelHasWon     \ player has run out of energy and the Sentinel has won

 JMP sub_C1AEC          \ This resets the stack - restart of some kind ??? and
                        \ return from the subroutine using a tail call

.DrainObjectEnergy

 LDX L0C58              \ Set X to an object number ???

 CPX playerObject       \ If this is not the player object, jump to dobj2 to
 BNE dobj2              \ drain energy from object #X rather than the player

                        \ If we get here then this is the player object, so we
                        \ now drain energy from the player

 LDA playerEnergy       \ If the player has no energy then draining more energy
 BEQ dobj1              \ will kill them, so jump to dobj1 to process this

 SEC                    \ Subtract 1 from the player's energy
 SBC #1
 STA playerEnergy

 JSR UpdateIconsScanner \ Update the icons in the top-left corner of the screen
                        \ to show the player's current energy level and redraw
                        \ the scanner box

 LDA #5                 \ Make sound #5 (ping)
 JSR MakeSound

 SEC                    \ Set the C flag to indicate that the player still has a
                        \ non-zero energy level

 JMP dobj7              \ Jump to dobj7 to finish up and return from the
                        \ subroutine

.dobj2

                        \ If we get here then we need to drain energy from
                        \ object #X

 TXA
 JSR sub_C1AE7
 LDA objectTypes,X
 BNE dobj3
 LDY enemyObject
 LDA #0
 STA L0C20,Y
 LDA #&03
 BNE dobj5

.dobj3

 CMP #&02
 BNE dobj4

 JSR DeleteObject       \ Delete object #X and remove it from the landscape

 JMP dobj6

.dobj4

 LDA #&74
 STA L0CD4
 LDA #&02

.dobj5

 STA objectTypes,X

.dobj6

 CLC

.dobj7

 PHP
 LDY enemyObject
 LDA enemyData2,Y
 CLC
 ADC #&01
 STA enemyData2,Y
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

 LDX enemyObject
 SEC
 LDA enemyData2,X
 BEQ CRE09

 LDA #2                 \ Spawn a tree (an object of type 2), returning the
 JSR SpawnObject        \ object number of the new object in X and currentObject

 LDA minEnemyAltitude

 JSR PlaceObjectBelow   \ Attempt to place the object on a tile that is
                        \ below the maximum altitude specified in A (though we
                        \ may end up placing the object higher than this)

 BCS CRE09              \ If the call to PlaceObjectBelow sets the C flag then
                        \ the object has not been successfully placed, so jump
                        \ to CRE09 to return from the subroutine with the C flag
                        \ set

 TXA
 JSR sub_C1AF3
 BCC C1A78
 LDX enemyObject
 DEC enemyData2,X
 LDX currentObject
 CLC

.CRE09

 RTS

.C1A78

 JSR DeleteObject       \ Delete object #X and remove it from the landscape

 JMP sub_C1AEC

\ ******************************************************************************
\
\       Name: FinishLandscape
\       Type: Subroutine
\   Category: Main game loop
\    Summary: Add the player's energy to the landscape number to get the number
\             of the next landscape and display that landscape's secret code
\
\ ******************************************************************************

.FinishLandscape

 SED                    \ Set the D flag to switch arithmetic to binary coded
                        \ decimal (BCD), so the call to GetPlayerEnergyBCD and
                        \ the following addition are all done in BCD

 JSR GetPlayerEnergyBCD \ Set A to the player's energy in BCD

 CLC                    \ Set (Y X) = (landscapeNumberHi landscapeNumberLo) + A
 ADC landscapeNumberLo  \
 TAX                    \ This addition is done in BCD so the result is a new
 LDA landscapeNumberHi  \ landscape number that's also in BCD (which we need to
 ADC #0                 \ do as landscape numbers are in BCD)
 TAY

 CLD                    \ Clear the D flag to switch arithmetic to normal

 JSR InitialiseSeeds    \ Initialise the seed number generator to generate the
                        \ sequence of seed numbers for the landscape number in
                        \ (Y X) and set maxNumberOfEnemies and the landscapeZero
                        \ flag accordingly

                        \ We set bit 7 of doNotPlayLandscape when the landscape
                        \ was completed in the PerformHyperspace routine, so the
                        \ following calls to GenerateLandscape and SpawnPlayer
                        \ return normally, without previewing the landscape
                        \ (GenerateLandscape) or starting the game (SpawnPlayer)

 JSR GenerateLandscape  \ Call GenerateLandscape to generate the landscape

 JSR SpawnEnemies       \ Calculate the number of enemies for this landscape,
                        \ add them to the landscape and set the palette
                        \ accordingly

 JSR SpawnPlayer        \ Add the player and trees to the landscape

 LDA #&80               \ Call DrawTitleScreen with A = &80 to draw the screen
 JSR DrawTitleScreen    \ showing the landscape's secret code

 LDX #5                 \ Print text token 5: Print "SECRET ENTRY CODE" at
 JSR PrintTextToken     \ (64, 768), "LANDSCAPE" at (192, 704), move cursor
                        \ right

 JMP PrintLandscapeNum  \ Print the four-digit landscape (0000 to 9999) and
                        \ return from the subroutine using a tail call

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

 LDA objectFlags,X      \ Set A to the object flags for object #X

 BMI C1AE2

 CMP #&40
 BCS C1AB9
 LDA objectTypes,X
 CMP #&03
 BNE C1AE2

.C1AB9

 LDA xObject,X          \ Set (xTile, zTile) to the tile coordinates of the
 STA xTile              \ tile containing object #X
 LDA zObject,X
 STA zTile

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), setting the C flag if the tile
                        \ contains an object

 BCC C1AE2
 AND #&3F
 TAY
 LDA objectTypes,Y
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

 BIT samePanKeyPress
 BPL CRE10

 STA currentObject

 LDA playerObject       \ Set anotherObject to the object number of the player
 STA anotherObject

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
\       Name: ProcessActionKeys
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Process an action key press from key logger entry 1 (absorb,
\             transfer, create, hyperspace, U-turn)
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   anotherObject       This is always set to the object number of the player
\                       (it is set in MainGameLoop before it calls sub_C1264 and
\                       this routine)
\                       
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Status flag:
\
\                         * Clear if:
\
\                           * Player has absorbed an object
\
\                           * Player has created an object
\
\                         * Set if:
\
\                           * Player has hyperspaced
\
\                           * Player has done a U-turn
\
\                           * Player tries to do something that results in an
\                             error sound
\
\ ******************************************************************************

.ProcessActionKeys

 LDA keyPress           \ Set A to the value from the key logger for the key
                        \ press we want to process, which we know contains a
                        \ valid key press as we only call this routine when
                        \ bit 7 of the key logger value is clear
                        \
                        \ The possible values for key logger entry 1 are:
                        \
                        \   * 0  for key press "R" (Create robot)
                        \   * 2  for key press "T" (Create tree)
                        \   * 3  for key press "B" (Create boulder)
                        \   * 32 for key press "A" (Absorb)
                        \   * 33 for key press "Q" (Transfer)
                        \   * 34 for key press "H" (Hyperspace)
                        \   * 35 for key press "U" (U-turn)
                        \
                        \ So now we perform the correct action for the key press
                        \ in A

 CMP #34                \ If A <> 34 then the "H" key (hyperspace) is not being
 BNE pkey2              \ pressed, so jump to pkey2 to move on to the next check

                        \ If we get here then "H" (hyperspace) is being pressed

 JSR PerformHyperspace  \ Hyperspace the player to a brand new tile

 LDA #0                 \ Set titleObjectToDraw to the object type for a robot
 STA titleObjectToDraw  \ ???

.pkey1

 SEC                    \ Set the C flag to denote ???

 RTS                    \ Return from the subroutine

.pkey2

 LDX anotherObject      \ Set X to the object number of the player, which we set
                        \ in MainGameLoop before getting here via sub_C1264

 CMP #35                \ If A <> 35 then the "U" key (U-turn) is not being
 BNE pkey3              \ pressed, so jump to pkey3 to move on to the next check

                        \ If we get here then "U" (U-turn) is being pressed

                        \ If we get here with bit 6 of uTurnStatus set, then
                        \ this is the first time we have reached this point
                        \ since the key was pressed (as we are about to clear
                        \ bit 6), so we can perform the requested U-turn
                        \
                        \ If we get here with bit 6 of uTurnStatus clear, then
                        \ this isn't the first time we've reached this point
                        \ since the key was pressed, so in this case we don't
                        \ do another U-turn, as we're already done one

 ASL uTurnStatus        \ Clear bit 6 uTurnStatus to prevent the "U" key from
                        \ performing a U-turn, so that the "U" key has to be
                        \ released before a second U-turn can be performed

 BPL pkey1              \ If bit 7 of uTurnStatus is now clear, then that means
                        \ that bit 6 was clear before the above shift, which
                        \ means we are currently ignoring the "U" key to prevent
                        \ doing a second U-turn, so jump to pkey1 to skip doing
                        \ another U-turn and instead return from the subroutine
                        \ with the C flag set to indicate ???

                        \ If we get here then "U" is being pressed and bit 6 of
                        \ uTurnStatus was set before being cleared above, so we
                        \ now perform a U-turn

 LDA objectYawAngle,X   \ Rotate the player's yaw angle through 180 degrees by
 EOR #%10000000         \ flipping bit 7, which turns the player around
 STA objectYawAngle,X

 LDA #40                \ Set A = 40 to set as the value of L0CE7 ???

 BNE pkey6              \ Jump to pkey6 to set L0CE7 = 40, L0C73 = 3,
                        \ playerHasMovedTile bit 7 set and the C flag and return
                        \ from the subroutine (this BNE is effectively a JMP as
                        \ A is never zero) ???

.pkey3

                        \ If we get here then the key press is either create,
                        \ absorb or transfer

 LSR L0C6E              \ Clear bit 7 of L0C6E ???

 JSR sub_C1BFF          \ ??? Called with X = player object

 JSR sub_C1CCC          \ Something to do with vectors? (secondAxis is involved)
                        \ Is it working out if we are able to see the tile ???

 BCS pkey9              \ If the C flag is set then this means ???, so jump to
                        \ pkey9 to make an error sound and return from the
                        \ subroutine as we can't ???

 LDA keyPress           \ If bit 5 of keypress is clear then A is not 32 or 33,
 AND #%00100000         \ so A must be 0, 2 or 3 (one of the create keys), so
 BEQ pkey10             \ jump to pkey10 to spawn a robot, tree or boulder

                        \ If we get here then A must be 32 or 33, so the key
                        \ press is either absorb or transfer

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), setting the C flag if the tile
                        \ contains an object

 BCC pkey9              \ The tile does not contain an object, so jump to pkey9
                        \ to make an error sound and return from the subroutine
                        \ as we can't absorb or transfer to an empty tile

 AND #%00111111         \ The number of the object on the tile is in bits 0 to 5
 TAX                    \ of the tile data, so extract this into X

 LDA keyPress           \ If bit 0 of keypress is clear then A must be 32, which
 LSR A                  \ is absorb, so jump to pkey7 to absorb the object on
 BCC pkey7              \ the tile anchored at (xTile, zTile)

                        \ If we get here then A must be 33, so the key press is
                        \ transfer and the player is trying to transfer to the
                        \ tile anchored at (xTile, zTile), which contains
                        \ object #X

 LDY objectTypes,X      \ Set Y to the type of object #X

 BNE pkey9              \ If object #X is not a robot (i.e. not an object of
                        \ type 0), jump to pkey9 to make an error sound and
                        \ return from the subroutine as the player can only
                        \ transfer into other robots

 JSR sub_C1200          \ Sets variables that control key scans etc. ???

 STX playerObject       \ Set the player's object number to that of the robot
                        \ on the tile anchored at (xTile, zTile), so this
                        \ effectively performs the transfer across to the new
                        \ robot

                        \ We now work out whether the player just transferred
                        \ into a robot on the Sentinel's tower
                        \
                        \ We do this by starting at object #X, which is the
                        \ robot that the player just transferred into, and if
                        \ it's on top of another object or stack of objects, we
                        \ work our way down the stack, checking to see if the
                        \ stack contains the Sentinel's tower
                        \
                        \ The Sentinel's tower is always the first object to be
                        \ spawned, and object numbers are allocated from 63 and
                        \ down, so this means the tower is always object #63, or
                        \ %111111, so that's what we look for while working
                        \ through the object stack
                        \
                        \ This forms part of the code to protect the game from
                        \ crackers, as all we do with this information is to set
                        \ playerIsOnTower to the object type of the tower (which
                        \ is 6). This value is then used to generate the secret
                        \ code for the completed landscape, so if crackers have
                        \ jumped straight to the end of the level without
                        \ setting playerIsOnTower to 6, then the wrong code will
                        \ be generated in the DrawSecretCode routine

.pkey4

 LDA objectFlags,X      \ Set A to the object flags for object #X

 CMP #%01000000         \ If both bits 6 and 7 of the object flags for object #X
 BCC pkey5              \ are clear then object #X is not stacked on top of
                        \ another object (so if we have looped back here from
                        \ below, we have reached the bottom of the stack), so
                        \ jump to pkey5 to stop looping through the object stack
                        \ and move on to the next task

                        \ If we get here then object #X is stacked on top of
                        \ another object, and the number of the object below
                        \ object #X is in bits 0 to 5 of the object flags for
                        \ object #X, which is currently in A

 AND #%00111111         \ Extract bits 0 to 5 of the object flags into A and X,
 TAX                    \ so X now contains the object number of the next object
                        \ down in the stack

 EOR #%00111111         \ If the object number in A is not the Sentinel's tower
 BNE pkey4              \ (i.e. it is not 63, or %111111), then loop back to
                        \ check the next object down in the stack

                        \ If we get here then the player has just transferred
                        \ into a robot on the Sentinel's tower

 LDA objectTypes,X      \ Set playerIsOnTower = 6 (which is the object type of
 STA playerIsOnTower    \ the Sentinel's tower, whose object number is in X)

.pkey5

 LDA #25                \ Set A = 25 to set as the value of L0CE7 ???

.pkey6

 JSR sub_C5FF6          \ Set L0CE7 = A, L0C73 = 3 ???

 LDA #%10000000         \ Set bit 7 of playerHasMovedTile to indicate that the
 STA playerHasMovedTile \ player has moved to a new tile

 SEC                    \ Set the C flag to denote ???

 RTS                    \ Return from the subroutine

.pkey7

                        \ If we get here then we are absorbing an object of type
                        \ X from the tile anchored at (xTile, zTile)

 LDA objectFlags        \ The Sentinel is always object #0, so this checks
 BMI pkey9              \ whether bit 7 of the Sentinel's object is set, which
                        \ indicates that the Sentinel's object number is not
                        \ allocated
                        \
                        \ This means that the Sentinel no longer exists and has
                        \ been absorbed by the player, at which point the player
                        \ is no longer allowed to absorb other objects, so jump
                        \ to pkey9 to make an error sound and return from the
                        \ subroutine

 LDA objectTypes,X      \ If the player is trying to absorb a meanie (an object
 CMP #4                 \ of type 4), jump to pkey13 to implement this
 BEQ pkey13

 CMP #6                 \ If the player is trying to absorb the Sentinel's tower
 BEQ pkey9              \ (an object of type 6), jump to pkey9 to make an error
                        \ sound and return from the subroutine

.pkey8

 JSR DeleteObject       \ Delete object #X and remove it from the landscape

 STX currentObject      \ Set currentObject to the number of the deleted object

 CLC                    \ Call UpdatePlayerEnergy with the C flag clear to add
 JSR UpdatePlayerEnergy \ the amount of energy in the now-deleted object #X to
                        \ the player's energy

 CLC                    \ Clear the C flag to denote ???

 RTS                    \ Return from the subroutine

.pkey9

                        \ If we get here then the player has tried to:
                        \
                        \   * Absorb or transfer to an empty tile
                        \
                        \   * Create, absorb or transfer to a tile that they
                        \     can't see directly (sub_C1CCC returns with C flag
                        \     set, this explanation is a total guess) ???
                        \
                        \   * Transfer to an object that is not a robot
                        \
                        \   * Absorb an object after the Sentinel has been
                        \     absorbed
                        \
                        \   * Absorb the Sentinel's tower
                        \
                        \   * Create an object when there are no unallocated
                        \     object numbers
                        \
                        \   * Create an object that takes their energy level
                        \     below zero
                        \
                        \   * Create an object that can't be added to the tile
                        \     (if the tile is occupied by an object that is not
                        \     a boulder or tower, for example)
                        \
                        \ In each case we make an error sound and return from
                        \ the subroutine

 LDA #170               \ Set the third parameter of sound data block #3 (the
 STA soundData+28       \ pitch) to 170

 LDA #5                 \ Make sound #5 (ping)
 JSR MakeSound

 LDA #144               \ Set the third parameter of sound data block #3 (the
 STA soundData+28       \ pitch) to 144

 SEC                    \ Set the C flag to denote ???

 RTS                    \ Return from the subroutine

.pkey10

                        \ If we get here then the player is trying to create an
                        \ object of the type given in keyPress

 JSR SpawnObject+3      \ Spawn an object of type keyPress, returning the object
                        \ number of the new object in X and currentObject

 BCS pkey9              \ If there are no free object numbers then the call to
                        \ SpawnObject will return with the C flag set and the
                        \ object will not have been created, so jump to pkey9 to
                        \ make an error sound and return from the subroutine

 SEC                    \ Call UpdatePlayerEnergy with the C flag set to
 JSR UpdatePlayerEnergy \ subtract the amount of energy in object #X from the
                        \ player's energy, so this subtracts the energy required
                        \ to create the object from the player

 BCS pkey9              \ If the creation of object #X reduces the player's
                        \ energy below zero, then the call to UpdatePlayerEnergy
                        \ will return with the C flag set, so jump to pkey9 to
                        \ make an error sound and return from the subroutine

 LDX currentObject      \ Set X to the object number of the object we just
                        \ created

 LDA L003A              \ Set (xTile, zTile) = (L003A, L003C) ???
 STA xTile
 LDA L003C
 STA zTile

 JSR PlaceObjectOnTile  \ Place object #X on the tile anchored at (xTile, zTile)

 BCC pkey11             \ If the object was successfully placed on the tile then
                        \ the call to PlaceObjectOnTile will return with the C
                        \ flag clear, so jump to pkey11 to keep going

 CLC                    \ Otherwise we failed to add the object to the tile, so
 JSR UpdatePlayerEnergy \ call UpdatePlayerEnergy with the C flag clear to
                        \ refund the energy that we used to create the object
                        \ back to the player

 JMP pkey9              \ We failed to place the object on the tile, so jump to
                        \ pkey9 to make an error sound and return from the
                        \ subroutine

.pkey11

                        \ If we get here then a new object has been successfully
                        \ created and added to a tile, as object #X

 LDA objectTypes,X      \ If the type of object that was added is not a robot
 BNE pkey12             \ (type 0), jump to pkey12 to return from the subroutine

                        \ We just created a robot, so we now rotate it so that
                        \ it faces the player

 LDY playerObject       \ Set A to the yaw angle of the player object
 LDA objectYawAngle,Y

 EOR #%10000000         \ Flip bit 7 to rotate the angle through 180 degrees
                        \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of object
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
                        \ Flipping bit 7 changes 0 into 128, +32 into -96, +64
                        \ into -64 and so on, so it's the same as rotating by
                        \ 180 degrees

 STA objectYawAngle,X   \ Set the yaw angle for the newly created robot to the
                        \ player's yaw angle rotated through 180 degrees, so the
                        \ new robot faces the player

.pkey12

 CLC                    \ Clear the C flag to denote ???

 RTS                    \ Return from the subroutine

.pkey13

                        \ If we get here then the player is trying to absorb a
                        \ meanie in object #X

                        \ We now loop through all the enemy objects, of which
                        \ there are up to eight, looking for the object whose
                        \ enemyData5 entry is X (i.e. the object number of the
                        \ meanie) ???

 LDY #7                 \ The enemies have object numbers 0 (for the Sentinel)
                        \ or 1 to 7 (for any meanies in the landscape), so set
                        \ a counter in Y to work through the enemy object
                        \ numbers

.pkey14

 LDA objectFlags,Y      \ If bit 7 is set for object #Y then this object number
 BMI pkey16             \ is not allocated to an object, so jump to pkey16 to
                        \ move on to the next enemy object

 LDA objectTypes,Y      \ Set A to the object type for object #Y

 CMP #1                 \ If object #Y is a sentry (object type 1), jump to
 BEQ pkey15             \ pkey15

 CMP #5                 \ If object #Y is not the Sentinel, jump to pkey16 to
 BNE pkey16             \ move on to the next enemy object


.pkey15

                        \ If we get here then object #Y is the Sentinel or a
                        \ sentry

 TXA                    \ Set A to the object number of the meanie that the
                        \ player is trying to absorb

 CMP enemyData5,Y       \ If A <> enemyData5 for object #Y, jump to pkey16 to
 BNE pkey16             \ move on to the next enemy object ???

 LDA #%10000000         \ Set bit 7 of enemyData5 for object #Y (the sentry or
 STA enemyData5,Y       \ Sentinel) ???

 BNE pkey8              \ Jump to pkey8 to delete the meanie in object #X, add
                        \ the meanie's energy to the player's energy, and return
                        \ from the subroutine with the C flag clear (this BNE is
                        \ effectively a JMP as A is never zero)

.pkey16

 DEY                    \ Decrement the counter in Y to move on to the next
                        \ enemy object number

 BPL pkey14             \ Loop back until we have processed all eight possible
                        \ enemy objects

 BMI pkey8              \ Jump to pkey8 to delete the meanie in object #X, add
                        \ the meanie's energy to the player's energy, and return
                        \ from the subroutine with the C flag clear

\ ******************************************************************************
\
\       Name: sub_C1BFF
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   This is always set to the object number of the player
\                       (it is set in ProcessActionKeys before it calls this
\                       routine)
\
\ ******************************************************************************

.sub_C1BFF

 LDA xSights            \ Set (U A) = xSights * 256
 STA U
 LDA #0

 LSR U                  \ Set (U A) = (U A) / 8
 ROR A                  \           = xSights * 32
 LSR U
 ROR A
 LSR U
 ROR A
                        \ We now calculate the following:
                        \
                        \   (U A) + (objectYawAngle,X 0) - (10 0)
                        \
                        \ and store it in (sightsYawAngleHi sightsYawAngleLo)

 CLC                    \ Clear the C flag for the following

 STA sightsYawAngleLo   \ Store the low byte of the calculation (which we know
                        \ will be A) in sightsYawAngleLo

 LDA U                  \ Calculate the high byte of the calculation as
 ADC objectYawAngle,X   \ follows:
 SEC                    \
 SBC #10                \   U + objectYawAngle,X - 10
 STA sightsYawAngleHi   \
                        \ and store it in sightsYawAngleHi

                        \ So (sightsYawAngleHi sightsYawAngleLo) is now equal to
                        \ the following:
                        \
                        \   (xSights * 32) + (objectYawAngle,X 0) - (10 0)

 LDA ySights            \ Set (U A) = (ySights - 5) * 256
 SEC
 SBC #5
 STA U
 LDA #0

 LSR U                  \ Set (U A) = (U A) / 16
 ROR A                  \           = (ySights - 5) * 16
 LSR U
 ROR A
 LSR U
 ROR A
 LSR U
 ROR A

                        \ We now calculate the following:
                        \
                        \   (U A) + (objectPitchAngle,X 0) + (3 32)
                        \
                        \ and store it in both (A T) and in
                        \ (sightsPitchAngleHi sightsPitchAngleLo)

 CLC                    \ Calculate the low byte and store it in both T and
 ADC #32                \ sightsPitchAngleLo
 STA sightsPitchAngleLo
 STA T

 LDA U                  \ Calculate the high byte, keep it in A and store it in
 ADC objectPitchAngle,X \ sightsPitchAngleHi
 CLC
 ADC #3
 STA sightsPitchAngleHi

                        \ So by this point we have the following:
                        \
                        \ (sightsYawAngleHi sightsYawAngleLo)
                        \   = (xSights * 32) + (objectYawAngle,X 0) - (10 0)
                        \
                        \ (sightsPitchAngleHi sightsPitchAngleLo)
                        \   = (ySights-5) * 16 + (objectPitchAngle,X 0) + (3 32)
                        \
                        \ We now fall through into sub_C1C43 to convert these
                        \ angles into an (x, y, z) vector in the 3D world ???

\ ******************************************************************************
\
\       Name: sub_C1C43
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C1C43

                        \ We start by rotating the pitch angle of the vector
                        \ from the player's eyes to the sights into the global
                        \ 3D coordinate system, storing the result in the 16-bit
                        \ ySightsVector variable (as pitch angles map to the
                        \ position on the up-down axis, which is the y-axis in
                        \ the 3D world)

 JSR GetRotationMatrix  \ Calculate the rotation matrix for rotating the
                        \ pitch angle for the sights into the global 3D
                        \ coordinate system, as follows:
                        \
                        \   [ cosSightsPitchAngle   0   -sinSightsPitchAngle ]
                        \   [          0            1             0          ]
                        \   [ sinSightsPitchAngle   0    cosSightsPitchAngle ]
                        \
                        \ Note that because GetRotationMatrix is copied from
                        \ Revs, where we only rotate through the yaw angle,
                        \ the matrix values are actually returned in the various
                        \ yawAngle variables, but let's pretend they are
                        \ returned as above

 LDY #1                 \ Set (A X) = cosSightsPitchAngle / 16
 JSR DivideBy16

 STA cosSightsPitchHi   \ Set (cosSightsPitchHi cosSightsPitchLo)
 STX cosSightsPitchLo   \                             = cosSightsPitchAngle / 16

 LDY #0                 \ Set (A X) = sinSightsPitchAngle / 16
 JSR DivideBy16

 STA ySightsVectorHi    \ Set (ySightsVectorHi ySightsVectorLo)
 STX ySightsVectorLo    \                             = sinSightsPitchAngle / 16

                        \ And now we rotate the yaw angle of the vector from the
                        \ player's eyes to the sights into the global 3D
                        \ coordinate system, storing the result in the 16-bit
                        \ xSightsVector and zSightsVector variables (as yaw
                        \ angles map to the position on the left-right and
                        \ in-out axes, which are the x-axis and z-axis in the
                        \ 3D world)

 LDA sightsYawAngleLo   \ Set (A T) = (sightsYawAngleHi sightsYawAngleLo)
 STA T
 LDA sightsYawAngleHi

 JSR GetRotationMatrix  \ Calculate the rotation matrix for rotating the
                        \ player's yaw angle into the global 3D coordinate
                        \ system, as follows:
                        \
                        \   [ cosSightsYawAngle   0   -sinSightsYawAngle ]
                        \   [         0           1            0         ]
                        \   [ sinSightsYawAngle   0    cosSightsYawAngle ]

 LDY #1                 \ Call MultiplyCoords with Y = 1 and X = 2 to calculate
 LDX #2                 \ the following:
 JSR MultiplyCoords     \
                        \   (zSightsVectorHi zSightsVectorLo)
                        \       = cosSightsPitchAngle * cosSightsYawAngle / 16

 LDY #0                 \ Zero X and Y and fall through into MultiplyCoords to
 LDX #0                 \ calculate the following:
                        \
                        \   (xSightsVectorHi xSightsVectorLo)
                        \        = cosSightsPitchAngle * sinSightsYawAngle / 16
                        \
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: MultiplyCoords
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Multiply a 16-bit signed number and a 16-bit sign-magnitude value
\
\ ------------------------------------------------------------------------------
\
\ This routine multiplies two 16-bit values and stores the result according to
\ the arguments, as follows.
\
\ When Y = 0, it calculates:
\
\   (cosSightsPitchHi cosSightsPitchLo) * (sinAngleHi sinAngleLo)
\
\ i.e. cosSightsPitch * sinAngle
\
\ When Y = 1, it calculates:
\
\   (cosSightsPitchHi cosSightsPitchLo) * (cosAngleHi cosAngleLo)
\
\ i.e. cosSightsPitch * cosAngle
\
\ When X = 0, store the result in (xSightsVectorHi xSightsVectorLo).
\
\ When X = 2, store the result in (zSightsVectorHi zSightsVectorLo).
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   cosSightsPitchHi    The 16-bit signed number to multiply (high byte)
\
\   cosSightsPitchLo    The 16-bit signed number to multiply (low byte)
\
\   Y                   Offset of the 16-bit sign-magnitude value to multiply:
\
\                         * 0 = sinAngle
\
\                         * 1 = cosAngle
\
\   X                   Offset of the variable to store the result in:
\
\                         * 0 = (xSightsVectorHi xSightsVectorLo)
\
\                         * 2 = (zSightsVectorHi zSightsVectorLo)
\
\ ******************************************************************************

.MultiplyCoords

 LDA #0                 \ Set H to sign to apply to the result of Multiply16x16
 STA H                  \ (in bit 7), so setting H  0 ensures that that the
                        \ result is positive

 LDA cosSightsPitchLo   \ Set (QQ PP) = (cosSightsPitchHi cosSightsPitchLo)
 STA PP                 \
 LDA cosSightsPitchHi   \ where (QQ PP) is a 16-bit signed number
 STA QQ

 LDA sinAngleLo,Y       \ Set (SS RR) to the 16-bit sign-magnitude number
 STA RR                 \ pointed to by Y
 LDA sinAngleHi,Y
 STA SS

 JSR Multiply16x16      \ Set (A T) = (QQ PP) * (SS RR)
                        \
                        \ And apply the sign from bit 7 of H to ensure the
                        \ result is positive

 STA xSightsVectorHi,X  \ Store the result in:
 LDA T                  \
 STA xSightsVectorLo,X  \   * (xSightsVectorHi xSightsVectorLo) when X = 0
                        \
                        \   * (zSightsVectorHi zSightsVectorLo) when X = 2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DivideBy16
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Divide a 16-bit sign-magnitude number by 16
\
\ ------------------------------------------------------------------------------
\
\ This routine divides a 16-bit sign-magnitude number by 16 and returns the
\ result as a signed 16-bit number.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   Offset of the 16-bit sign-magnitude number to divide:
\
\                         * 0 = sinAngle
\
\                         * 1 = cosAngle
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   (A X)               The 16-bit signed number containing the result

\ ******************************************************************************

.DivideBy16

 LDA sinAngleLo,Y       \ Set (A T) to the 16-bit sign-magnitude number pointed
 STA T                  \ to by Y
 LDA sinAngleHi,Y

 LSR A                  \ Set (A T) = (A T) / 16
 ROR T                  \
 PHP                    \ We store bit 0 of the original 16-bit sign-magnitude
 LSR A                  \ number on the stack in the C flag (as it gets rotated
 ROR T                  \ out from bit 0 on the first ROR T)
 LSR A
 ROR T
 LSR A
 ROR T

 PLP                    \ We stored the sign bit from the original 16-bit
                        \ sign-magnitude number on the stack, so fetch it into
                        \ the C flag

 BCC divi1              \ If the sign bit was 0 then the original number was
                        \ positivem so skip the following

 JSR Negate16Bit        \ The original 16-bit sign-magnitude number was negative
                        \ so call Negate16Bit to negate the result as follows:
                        \
                        \   (A T) = -(A T)

.divi1

 LDX T                  \ Set (A X) = (A T)

 RTS                    \ Return from the subroutine

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
 ADC xSightsVectorLo,X
 STA L0034,X
 LDA xSightsVectorHi,X
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

 LDX anotherObject
 LSR L0C56
 LSR L0CDD
 JSR sub_C1EB5

.C1CD7

 JSR sub_C1CAA
 LDA L003A
 STA xTile
 CMP #&1F
 BCS C1D33
 LDA L003C
 STA zTile
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

 LDA L0C6E              \ If bit 7 is set in one or both of L0C6E and L0C67,
 ORA L0C67              \ skip the following test ???
 BMI C1D21

 LDA ySightsVectorHi
 BPL C1D33

.C1D21

 LDX anotherObject
 LDA xTile
 CMP xObject,X
 BNE C1D31
 LDA zTile
 CMP zObject,X
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
 INC xTile
 JSR sub_C1DE6
 STA V
 INC zTile
 JSR sub_C1DE6
 STA U
 DEC xTile
 JSR sub_C1DE6
 STA T
 DEC zTile

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

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

 JSR Multiply8x8        \ Set (A T) = A * U

 PLP                    \ Restore the sign of ??? which we stored on the
                        \ stack above, so the N flag is positive if ???,
                        \ or negative if ???

 JSR Absolute16Bit      \ Set the sign of (A T) to match the result of the
                        \ subtraction above, so A is now ???

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

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), setting the C flag if the tile
                        \ contains an object

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

 LDA objectTypes,Y
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
 LDA yObjectLo,Y
 CLC
 ADC #&20
 STA L0079
 LDA yObjectHi,Y
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
 LDA objectTypes,Y
 CMP #&02
 BEQ C1E52
 SEC
 ROR L0C67
 LDA yObjectLo,Y
 SEC
 SBC #&60
 STA L0079
 LDA yObjectHi,Y
 SBC #&00
 CLC
 RTS

.C1E52

 LDA yObjectLo,Y
 SEC
 SBC L0038
 STA U
 LDA yObjectHi,Y
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

 LDA objectTypes,Y
 CMP #&02
 BEQ C1E8D
 LDA #&C0
 STA secondAxis

.C1E8D

 LDA objectFlags,Y
 CMP #&40
 BCS C1E28
 LDA yObjectHi,Y
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
 LDA yObjectLo,X
 STA L0038
 LDA xObject,X
 STA L003A
 LDA yObjectHi,X
 STA L003B
 LDA zObject,X
 STA L003C
 RTS

\ ******************************************************************************
\
\       Name: DeleteObject
\       Type: Subroutine
\   Category: 3D objects
\    Summary: Delete an object, removing it from the landscape and vacating its
\             object number
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The number of the object to delete
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X is preserved
\
\ ******************************************************************************

.DeleteObject

 LDA xObject,X          \ Set (xTile, zTile) to the tile coordinates of the
 STA xTile              \ tile containing object #X
 LDA zObject,X
 STA zTile

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), which we ignore, but this also sets
                        \ the tile page in tileDataPage and the index in Y, so
                        \ tileDataPage+Y now points to the tile data entry in
                        \ the tileData table for object #X

 LDA objectFlags,X      \ Set A to the object flags for object #X

 CMP #%01000000         \ If both bits 6 and 7 of the object flags for object #X
 BCC delo1              \ are clear then object #X is not stacked on top of
                        \ another object, so jump to delo1 to remove object #X
                        \ from the tile itself

                        \ If we get here then object #X is stacked on top of
                        \ another object, and the number of that object is in
                        \ bits 0 to 5 of the object flags for object #X, which
                        \ is currently in A

 ORA #%11000000         \ Set bits of 6 and 7 of A to create a byte with the
                        \ number of the object below object #X in bits 0 to 5,
                        \ and bits 6 and 7 set
                        \
                        \ We now set this as the updated tile data for the tile
                        \ that used to contain object #X at the top of the
                        \ stack, but which now contains the next object down on
                        \ the top of the stack instead

 BNE delo2              \ Jump to delo2 to store A as the new tile data for this
                        \ tile (this BNE is effectively a JMP as the value of A
                        \ before the ORA has to have at least one of bits 6 and
                        \ 7 set, so the result of the ORA is never zero)

.delo1

                        \ If we get here then object #X is not stacked on top of
                        \ another object, so we can remove the object from the
                        \ tile by changing the tile data into the following
                        \ format:
                        \
                        \   * The low nibble contains the tile shape, which in
                        \     this case is flat because only flat tiles can
                        \     contain objects, so we need to set the low nibble
                        \     to shape 0 (to indicate a flat tile)
                        \
                        \   * The high nibble contains the altitude of the tile
                        \     corner in the front-left corner of the tile
                        \
                        \ The altitude of object #X is a 16-bit value in
                        \ (yObjectHi yObjectLo), where the yObjectLo part is
                        \ effectively a fractional part of the altitude that
                        \ describes how far the object is above the tile itself
                        \
                        \ Tile altitudes are whole numbers, so the altitude of
                        \ the tile on which object #X is placed is given in the
                        \ high byte of the object's 16-bit altitude

 LDA yObjectHi,X        \ Set the high nibble of A to the high byte of the
 ASL A                  \ altitude of object #X (which is the tile's altitude)
 ASL A                  \ and set the low nibble to zero to indicate a flat tile
 ASL A                  \
 ASL A                  \ A is now in the format required for the tileData table
                        \ for a flat tile that doesn't contain an object, so we
                        \ can update the tile's data to remove object #X from
                        \ the tile

.delo2

 STA (tileDataPage),Y   \ Update the tile data for object #X to the value in A
                        \ (as we set Y to the relevant index with the call to
                        \ GetTileData above)

 LDA #%10000000         \ Set bit 7 of the object flags for object #X to denote
 STA objectFlags,X      \ that object number X has not been allocated to an
                        \ object and is reusable, so this effectively deletes
                        \ the object

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PlaceObjectOnTile
\       Type: Subroutine
\   Category: 3D objects
\    Summary: Place an object on a tile, putting it on top of any existing
\             boulders or towers
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following (if successful):
\
\   * X-th entry in (xObject, yObject, zObject) is set to the 3D coordinate of
\     the newly added object, where the y-coordinate is (yObjectHi yObjectLo)
\
\   * X-th entry in objectFlags, bit 7 is clear to indicate that object #X has
\     been allocated to an object
\
\   * X-th entry in objectFlags, bit 6 is set if we add the object on top of a
\     boulder or tower (and the object number of the boulder/tower is in bits
\     0-5)
\
\   * X-th entry in yObjectLo = &E0 ???
\
\   * X-th entry in objectPitchAngle = &F5 ???
\
\   * X-th entry in objectYawAngle is set to a multiple of 11.25 degrees, as
\     determined by the next seed
\
\   * tileData for the tile is set to the object number in X in bits 0 to 5, and
\     bits 6 and 7 are set to indicate that the tile contains an object
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The number of the object to add to the tile
\
\   (xTile, zTile)      The tile coordinate where we place the object
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Status flag:
\
\                         * Clear if we successfully added the object to the
\                           tile
\
\                         * Set if we failed to add the object to the tile (if
\                           the tile is occupied by an object that is not a
\                           a boulder or tower, for example)
\
\ ******************************************************************************

.PlaceObjectOnTile

 LDA xTile              \ Set the 3D coordinate for object #X to (xTile, yTile)
 STA xObject,X          \ by updating the X-th entries in the xObject and
 LDA zTile              \ zObject tables
 STA zObject,X          \
                        \ So this sets the x- and z-coordinates of the 3D
                        \ coordinate for our object; we set the y-coordinate
                        \ later

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), setting the C flag if the tile
                        \ contains an object
                        \
                        \ This also sets the tile page in tileDataPage and the
                        \ tile number in Y, so tileDataPage+Y now points to the
                        \ tile data entry in the tileData table

 BCC objt4              \ If C flag is clear then this tile does not already
                        \ have an object placed on it, so jump to objt4 to place
                        \ object #X on the tile

 STY tileNumber         \ Store the tile number in tileNumber so we can refer to
                        \ it later

 AND #%00111111         \ Because the tile already has an object on it, the tile
 TAY                    \ data contains the existing object's number in bits 0
                        \ to 5, so extract the object number into Y

 LDA objectTypes,Y      \ Set A to the type of object that's already on the tile
                        \ (i.e. the type of object #Y)

 CMP #3                 \ If the tile contains an object of type 3 (a boulder),
 BEQ objt1              \ jump to objt1 to put the new object on top of the
                        \ boulder

 CMP #6                 \ If the tile doesn't contain the Sentinel's tower (type
 BNE objt6              \ 6) then it must contain an object on which we can't
                        \ place our new object, so jump to objt6 to return from
                        \ the subroutine without adding the object to the tile

.objt1

                        \ If we get here then the object already on the tile is
                        \ either a boulder (type 3) or the Sentinel's tower
                        \ (type 6)
                        \
                        \ In either case, we want to place our object on top of
                        \ the object that is already there, which we can do by
                        \ setting bit 6 of the object flags for the new object
                        \ and putting the number of the existing object into
                        \ bits 0 to 5

 TYA                    \ Set the object flags for the object that we are adding
 ORA #%01000000         \ (i.e. object #X) so that bit 6 is set, and bits 0 to 5
 STA objectFlags,X      \ contain the number of the object that is already on
                        \ the tile
                        \
                        \ This denotes that our new object, object #X, is on top
                        \ of object #Y

 LDA objectTypes,Y      \ If the object that's already on the tile is not the
 CMP #6                 \ Sentinel's tower (type 6), jump to objt2
 BNE objt2

                        \ If we get here then we are placing object #X on top of
                        \ the Sentinel's tower (type 6) in object #Y
                        \
                        \ The next task is to calculate the altitude of the
                        \ object when it is placed on top of the tower (i.e. the
                        \ y-coordinate of the object, as the y-axis goes up and
                        \ down in our 3D world)
                        \
                        \ The tower is defined with a height of one coordinate
                        \ (where a tile-sized cube is one coordinate across)
                        \
                        \ Object y-coordinates are stored as 16-bit numbers in
                        \ the form (yObjectHi yObjectLo), with the low byte
                        \ effectively acting like a fractional part, so to work
                        \ out the y-coordinate for the object we are placing on
                        \ top of the boulder, we need to add (1 0) to the
                        \ tower's current y-coordinate, like this:
                        \
                        \   yObject,X = yObject,Y + (1 0)
                        \
                        \ We need to do this calculation for both bytes,
                        \ starting with the low byte

 LDA yObjectLo,Y        \ First we add the low bytes, by adding 0 to the Y-th
 STA yObjectLo,X        \ entry in yObjectLo and storing this in the low byte of
                        \ the X-th entry in yObjectLo (which we can do by simply
                        \ copying the Y-th entry into the X-th entry)

 CLC                    \ Clear the C flag and set A = 1 so the addition at
 LDA #1                 \ objt3 will do the following:
                        \
                        \   A = yObjectHi,Y + 1
                        \
                        \ This will add the high bytes of the calculation to
                        \ give the result we want:
                        \
                        \   (A yObjectLo,X) = (yObjectHi,Y yObjectLo,Y) + (1 0)
                        \
                        \                   = ((yObjectHi,Y + 1) yObjectLo,Y)
                        \
                        \ with the subsequent jump to objt5 storing A in
                        \ yObjectHi,X as required

 BNE objt3              \ Jump to objt3 to do the calculation (this BNE is
                        \ effectively a JMP as A is never zero)

.objt2

                        \ If we get here then we are placing our new object #X
                        \ on top of the boulder (type 3) in object #Y
                        \
                        \ The next task is to calculate the altitude of the
                        \ object when it is placed on top of the boulder (i.e.
                        \ the y-coordinate of the object, as the y-axis goes up
                        \ and down in our 3D world)
                        \
                        \ Boulder are defined with a height of 0.5 coordinates
                        \ (where a tile-sized cube is one coordinate across)
                        \
                        \ Object y-coordinates are stored as 16-bit numbers in
                        \ the form (yObjectHi yObjectLo), with the low byte
                        \ effectively acting like a fractional part, so to work
                        \ out the y-coordinate for the object we are placing on
                        \ top of the boulder, we need to add (0 128) to the
                        \ boulder's current y-coordinate, like this:
                        \
                        \   yObject,X = yObject,Y + (0 128)
                        \
                        \ We need to do this calculation for both bytes,
                        \ starting with the low byte

 LDA yObjectLo,Y        \ First we add the low bytes, by adding 128 to the Y-th
 CLC                    \ entry in yObjectLo and storing this in the low byte of
 ADC #128               \ the result in the X-th entry in yObjectLo
 STA yObjectLo,X

 LDA #0                 \ Set A = 0 so the following addition will add the high
                        \ bytes to give the result we want:
                        \
                        \   (A yObjectLo,X) = (yObjectHi,Y yObjectLo,Y)
                        \                     + (0 128)
                        \
                        \                   = (yObjectHi,Y (yObjectLo,Y + 128))
                        \
                        \ with the subsequent jump to objt5 storing A in
                        \ yObjectHi,X as required

.objt3

 ADC yObjectHi,Y        \ Add A to the high byte of the y-coordinate of the
                        \ object beneath the one we are adding and store the
                        \ result in A
                        \
                        \ So (A yObjectLo,X) now contains the y-coordinate of
                        \ the new object that we are placing on top of the
                        \ boulder or tower

 LDY tileNumber         \ Set Y to the tile number where we are adding the
                        \ object, which we stored above

 JMP objt5              \ Jump to objt5 to store A as the y-coordinate of the
                        \ new object on the tile, and update the various other
                        \ object and tile tables for the new object

.objt4

 PHA                    \ Store the tile data for the tile on the stack so we
                        \ can retrieve it below

 LDA #0                 \ Clear bit 7 of the object's flags to indicate that
 STA objectFlags,X      \ object #X is allocated to an object

 LDA #224               \ Set the object's entry in yObjectLo to 224
 STA yObjectLo,X        \
                        \ This appears to place objects well above the tile, at
                        \ a height of 224/256 = 0.875 coordinates above the tile
                        \ itself ???

 PLA                    \ Set A to the tile data for the tile, which we stored
                        \ on the stack above

 LSR A                  \ The top nibble of the tile data contains the tile
 LSR A                  \ altitude, so this sets A to the tile altitude
 LSR A
 LSR A

                        \ We now fall through into objt5 to set the tile
                        \ y-coordinate for object #X to the tile altitude in A

.objt5

 STA yObjectHi,X        \ Set the high byte of the 3D y-coordinate for object #X
                        \ to the value of A by updating the X-th entry in the
                        \ yObjectHi table
                        \ 
                        \ We now have a full 3D coordinate for the object in
                        \ (xObject, yObject, zObject), where yObject is stored
                        \ as a 16-bit number in (yObjectHi yObjectLo)

 TXA                    \ Set the tile data for this tile to object number X,
 ORA #%11000000         \ with bits 6 and 7 set to indicate that the tile now
 STA (tileDataPage),Y   \ contains an object

 LDA #245               \ Set the object's pitch angle to 245, or -11 degrees
 STA objectPitchAngle,X \ ???

                        \ We now calculate the object's yaw angle, which
                        \ determines the direction in which it is facing
                        \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of object
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
                        \ In this context, looking straight ahead means the
                        \ object is looking into the screen, towards the back of
                        \ the landscape

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 AND #%11111000         \ Convert A to be a multiple of 8 and in the range 0 to
                        \ 248 (i.e. 0 to 31 * 8)
                        \
                        \ This rotates the object so it is looking along one of
                        \ 32 fixed rotations, each of which is a multiple of
                        \ 11.25 degrees

 CLC                    \ Set A = A + 96
 ADC #96                \
                        \ This doesn't change the fact that A is a multiple of
                        \ 11.25 degrees, so it's presumably intended to make the
                        \ player's rotation work well on the starting level

 STA objectYawAngle,X   \ Set the object's objectYawAngle to the angle we just
                        \ calculated in A

 CLC                    \ Clear the C flag to indicate that we have successfully
                        \ added the object to the tile

 RTS                    \ Return from the subroutine

.objt6

                        \ If we get here then the tile already contains an
                        \ object and that object is not a boulder (type 3) or
                        \ tower (type 6), so we can't add the new object to the
                        \ tile

 SEC                    \ Set the C flag to indicate that we have failed to add
                        \ the object to the tile

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: tileNumber
\       Type: Variable
\   Category: 3D objects
\    Summary: The tile number to which we are adding an object in the
\             PlaceObjectOnTile routine
\
\ ******************************************************************************

.tileNumber

 EQUB 0

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
 JSR HideSights
 CLI

.C1F98

 LDX anotherObject
 LDA L0C62
 STA L2095
 LDA #0
 LSR L2095
 ROR A
 STA L001F
 LDA L2095
 ADC objectYawAngle,X
 STA objectYawAngle,X
 LDY #0
 STY lastPanKeyPressed
 LDA L0C69
 JSR sub_C2997
 LDA #&19
 LDY #&18
 LDX L0C69
 JSR sub_C2202
 BIT L0C4D
 BPL C1FD2
 LDY currentObject
 JSR sub_C5D33
 JMP C1FD5

.C1FD2

 JSR sub_C2624

.C1FD5

 LDY #0
 JSR SetViewBufferAddr
 LDX anotherObject
 LDA #0
 STA L001F
 SEC
 LDA objectYawAngle,X
 SBC L2095
 STA objectYawAngle,X
 LDA #0
 STA U
 LDA L0C62
 ASL A
 ASL A
 ASL A
 ROL U
 CLC
 ADC viewScreenAddr
 STA L2092
 LDA viewScreenAddr+1
 ADC U
 CMP #&80
 BCC C2008
 SBC #&20

.C2008

 STA L2093
 BIT L0C6D
 BVC C2022
 BIT sentinelHasWon
 BPL C201A
 LDA #&28
 STA L2094

.C201A

 JSR sub_C5E5F
 LDA sentinelHasWon
 BMI C2061

.C2022

 SEI
 JSR HideSights
 SEC
 ROR L0CD7
 CLI
 LDA L2092
 STA toAddr
 LDA L2093
 STA toAddr+1
 LDA L0C69
 STA loopCounter
 JMP C2058

.C203D

 LDA L2092
 CLC
 ADC #&08
 STA L2092
 STA toAddr
 LDA L2093
 ADC #&00
 CMP #&80
 BCC C2053
 SBC #&20

.C2053

 STA L2093
 STA toAddr+1

.C2058

 LDY lastPanKeyPressed

 JSR DisplayViewBuffer  \ Update the player's scrolling landscape view by
                        \ copying the relevant parts of the view screen buffer
                        \ into screen memory

 DEC loopCounter
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
 LDA sightsAreVisible
 BPL C208D
 SEI
 JSR ShowSights
 CLI

.C208D

 JMP C1F78

\ ******************************************************************************
\
\       Name: viewBufferAddr
\       Type: Variable
\   Category: Graphics
\    Summary: ???
\
\ ******************************************************************************

.viewBufferAddr

 EQUW &0000

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

 LDY currentObject
 CPY playerObject
 BEQ C2105
 JSR sub_C5C01
 LDY currentObject
 LDX objectTypes,Y
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
 SBC angleLo
 STA T
 LDA L0C57
 SBC angleHi
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
 ADC angleLo
 STA T
 LDA L0C57
 ADC angleHi
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
\       Name: SpawnObject
\       Type: Subroutine
\   Category: 3D objects
\    Summary: Add a new object of the specified type to the objectTypes table
\
\ ------------------------------------------------------------------------------
\
\ This routine spawns a new object by searching the objectFlags table for a free
\ number to allocate. If there is no free number then the routine returns with
\ the C flag set, otherwise the C flag is clear, X and currentObject are set to
\ the number of the new object, and the object type is added to the objectTypes
\ table.
\
\ Note that this routine only adds the object to the objectTypes table; it
\ doesn't update the flags or add any other information about the object.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The type of object to spawn:
\
\                         * 0 = Robot (one of which is the player)
\
\                         * 1 = Sentry
\
\                         * 2 = Tree
\
\                         * 3 = Boulder
\
\                         * 4 = Meanie
\
\                         * 5 = The Sentinel
\
\                         * 6 = The Sentinel's tower
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   The number of the new object (if successful)
\
\   currentObject       The number of the new object (if successful)
\
\   C flag              Status flag:
\
\                         * Clear if the object was successfully spawned
\
\                         * Set if there is no free number for the new object
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   SpawnObject+3       Spawn an object of the type specified in keyPress
\
\                       The keyPress and objectType variables share the same
\                       memory location, so this lets us store object types in
\                       the key press codes in keyLoggerConfig, so that pressing
\                       one of the "create" keys will automatically spawn that
\                       type of object
\
\ ******************************************************************************

.SpawnObject

 STA objectType         \ Store the object type in objectType for future
                        \ reference

 LDX #63                \ In order to be able to create a new object, we need to
                        \ find an unallocated object number in the objectFlags
                        \ table
                        \
                        \ The game can support up to 64 objects, each with its
                        \ own number (0 to 63), so set a counter in X to work
                        \ through the object numbers until we find one that is
                        \ not allocated to an object

.sobj1

 LDA objectFlags,X      \ Set A to the object flags for object #X, which are
                        \ stored in the X-th entry in the objectFlags table

 BMI sobj2              \ If bit 7 of object flags for object #X is set then
                        \ this object number is not yet allocated to an object,
                        \ so jump to sobj2 use this number for our new object

 DEX                    \ Otherwise decrement the counter in X to move on to the
                        \ next object number

 BPL sobj1              \ Loop back to sobj1 to check the next object number

 SEC                    \ If we get here then we have checked all 64 object
                        \ numbers and none of them are free, so set the C flag
                        \ to indicate that we have failed to spawn the object

 RTS                    \ Return from the subroutine

.sobj2

                        \ If we get here then we have found an unallocated
                        \ object number in the objectFlags table at index X

 STX currentObject      \ Set currentObject to the object number in X

 LDA objectType         \ Set the corresponding entry in the objectTypes table
 STA objectTypes,X      \ to the object type that we are spawning, which we
                        \ stored in objectType above

 CLC                    \ Clear the C flag to indicate that we have successfully
                        \ added a new object to the objectFlags table

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: UpdatePlayerEnergy
\       Type: Subroutine
\   Category: Gameplay
\    Summary: Update the player's energy levels by adding or subtracting the
\             amount of energy in a specific object
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The number of the object whose energy is being added to
\                       or subtracted from the player's energy
\
\   C flag              Controls whether we add or subtract the energy:
\
\                         * Clear = add object #X's energy to the player's
\                                   energy
\
\                         * Set = Subtract object #X's energy from the player's
\                                 energy
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Result flag:
\
\                         * Clear if the player still has a positive energy
\                           level after the update
\
\                         * Set if the player now has a negative energy level,
\                           which means the Sentinel has won
\
\ ******************************************************************************

.UpdatePlayerEnergy

 LDY objectTypes,X      \ Set Y to the object type of object #X

 LDA playerEnergy       \ Set A to the player's current energy level

 BCC uple1              \ If the C flag argument is clear, jump to uple1 to add
                        \ the energies

                        \ Otherwise the C flag argument is set, so we subtract
                        \ object #X's energy from the player's energy in A

 SBC objectTypeEnergy,Y \ The objectTypeEnergy table contains the energy levels
                        \ for each of the object types, so this subtracts the
                        \ energy of object #X from the player's energy in A
                        \
                        \ The subtraction works because we know the C flag is
                        \ set, as we just passed through a BCC

 BCS uple2              \ If the subtraction didn't underflow then the player
                        \ still has some energy left, so jump to uple2 to return
                        \ from the subroutine with the C flag clear

 SEC                    \ The player now has negative energy, so return from the
                        \ subroutine with the C flag set to indicate this

 RTS                    \ Return from the subroutine

.uple1

                        \ If we get here then the C flag argument is clear, so
                        \ we add object #X's energy to the player's energy in A


 ADC objectTypeEnergy,Y \ The objectTypeEnergy table contains the energy levels
                        \ for each of the object types, so this adds the energy
                        \ of object #X to the player's energy in A
                        \
                        \ The addition works because we know the C flag is
                        \ clear, as we got here by taking a BCC

.uple2

 AND #63                \ Cap the value in A to a maximum of 63, so the player's
                        \ energy is always in the range 0 to 63

 STA playerEnergy       \ Update the player's energy level to the new level in A

 CLC                    \ Clear the C flag to indicate that the player still has
                        \ a positive amount of energy (i.e. 0 or above)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: objectTypeEnergy
\       Type: Variable
\   Category: 3D objects
\    Summary: The amout of energy required to create each object or the amount
\             energy acquired when absorbing each object
\
\ ******************************************************************************

.objectTypeEnergy

 EQUB 3                 \ Robot = 3 energy

 EQUB 3                 \ Sentry = 3 energy

 EQUB 1                 \ Tree = 1 energy

 EQUB 2                 \ Boulder = 2 energy

 EQUB 1                 \ Meanie = 1 energy

 EQUB 4                 \ The Sentinel = 4 energy

 EQUB 0                 \ The Sentinel's tower = 0 energy

\ ******************************************************************************
\
\       Name: PerformHyperspace
\       Type: Subroutine
\   Category: Gameplay
\    Summary: Hyperspace the player to a brand new tile, ideally at the same
\             altitude as the current tile
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   C flag              Returns:
\
\                         * Clear if the hyperspace was a success, or if the
\                           player didn't have enough energy to hyperspace
\
\                         * Set if we could not spawn a robot to use as the
\                           destination for the hyperspace
\
\ ******************************************************************************

.PerformHyperspace

 LDA #0                 \ Spawn a robot (an object of type 0), returning the
 JSR SpawnObject        \ object number of the new object in X and currentObject

 LDX playerObject       \ Set A to the high byte of the altitude of the player
 LDA yObjectHi,X        \ object (i.e. the high byte of the player object's
                        \ y-coordinate in yObjectHi)

 CLC                    \ Increment A so it's one coordinate higher than the
 ADC #1                 \ player object, so the call to PlaceObjectBelow will
                        \ try to hyperspace the player to the same height as
                        \ before

 LDX currentObject      \ Set X to the object number of the new robot that we
                        \ spawned above

 JSR PlaceObjectBelow   \ Attempt to place the new robot on a tile that is below
                        \ the maximum altitude specified in A (though we may end
                        \ up placing the object higher than this)

 BCS hypr4              \ If the call to PlaceObjectBelow sets the C flag then
                        \ the object has not been successfully placed, so jump
                        \ to hypr4 to return from the subroutine with the C flag
                        \ set to indicate that we haven't managed to hyperspace
                        \ the player

 SEC                    \ Call UpdatePlayerEnergy with the C flag set to
 JSR UpdatePlayerEnergy \ subtract the amount of energy in object #X from the
                        \ player's energy
                        \
                        \ Object #X is the robot we just spawned, so this will
                        \ subtract three energy points from the player

 BCC hypr1              \ If the player still has positive energy then the call
                        \ to UpdatePlayerEnergy will clear the C flag, so jump
                        \ to hypr1 to keep going

                        \ If we get here then the player doesn't have enough
                        \ energy to create a robot for hyperspacing

 JSR DeleteObject       \ Delete object #X and remove it from the landscape, so
                        \ we remove the robot that we just spawned

 LDA #3                 \ Set L0C4C = 3 ???
 STA L0C4C

 LDA #%10000000         \ Set bit 7 and clear bit 6 of L0CDE ???
 STA L0CDE

 BNE hypr3              \ Jump to hypr3 to return from the subroutine (this BNE
                        \ is effectively a JMP as A is never zero)

.hypr1

 LDA #0                 \ Set L0CE7 = 0, L0C73 = 3 ???
 JSR sub_C5FF6

 LDX playerObject       \ If the player is not on the Sentinel's tile in terms
 LDA xObject,X          \ of the x-coordinate, jump to hypr2
 CMP xTileSentinel
 BNE hypr2

 LDA zObject,X          \ If the player is not on the Sentinel's tile in terms
 CMP zTileSentinel      \ of the z-coordinate, jump to hypr2
 BNE hypr2

                        \ The player is on the Sentinel's tile in both axes, so
                        \ they must have hyperspaced while standing on top of
                        \ the Sentinel's tower, so they have just completed this
                        \ landscape

 LDA #%11000000         \ Set bits 6 and 7 of L0CDE ???
 STA L0CDE

 LDA #%10000000         \ Set bit 7 of doNotPlayLandscape so that when we finish
 STA doNotPlayLandscape \ the landscape, the landscape generation process will
                        \ return normally, without previewing the landscape
                        \
                        \ As the last step in winning a game is to hyperspace
                        \ onto the Sentinel's tower, this ensures that winning a
                        \ level will then display that landscape's secret code
                        \ rather than displaying the preview and making us play
                        \ it again

.hypr2

 JSR sub_C1200          \ Sets variables that control key scans etc. ???

 LDX currentObject      \ Set the player's object number to that of the new
 STX playerObject       \ robot that we spawned above, so this effectively
                        \ performs the hyperspace into the new robot

.hypr3

 LDA #%10000000         \ Set bit 7 of playerHasMovedTile to indicate that the
 STA playerHasMovedTile \ player has moved to a new tile

 CLC                    \ Clear the C flag to indicate that we have successfully
                        \ hyperspaced the player

.hypr4

 RTS                    \ Return from the subroutine

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
 LDA objectFlags,Y
 CMP #&40
 BCS P21A6
 DEX
 STX L0C6B
 BEQ C21F3

.C21B7

 LDX playerObject
 LDA yObjectLo,X
 SEC
 SBC yObjectLo,Y
 STA T
 LDA yObjectHi,X
 SBC yObjectHi,Y
 BMI C21F0
 ORA T
 BNE C21D5
 LDA objectTypes,Y
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

 LDA objectFlags,Y
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
 LDA objectFlags,Y
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

 STA zTile
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
 STX yTile
 LDX L0C4C
 LDA L2277,X
 STA T
 LDA L227B,X
 STA U

.C2224

 LDX zTile
 LDA L3D83,X
 STA P
 LDA L3DB5,X
 STA Q
 LDX yTile
 LDA #&01
 STA loopCounter

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
 DEC loopCounter
 BMI C2270
 LDX L001E
 BMI C2270
 INC Q
 JMP C2236

.C2270

 INC zTile
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
 STA xSightsVectorLo
 STA ySightsVectorLo
 LDA tileAltitude
 CLC
 ADC L0004
 ROR A
 TAX
 LDA L5B00,X
 CMP L5A00,X
 BCC CRE13
 LDA #&F0
 CLC
 SBC tileAltitude
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
 LDY tileAltitude
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
 STA ySightsVectorLo
 BEQ sub_C230D

.C2339

 LDA #0
 STA xSightsVectorLo
 BEQ sub_C230D

.C233F

 LDA L0061
 ASL A
 STA L0056
 STA xSightsVectorLo
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
 STA ySightsVectorLo
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
 LDX playerObject
 LDA yObjectHi,X
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
 STA bitMask
 LDA L0180,X
 ORA L0180+1,X
 ORA L01A0,X
 ORA L01A0+1,X
 AND W
 AND L24E2,Y
 STA U
 LDY T
 LDA L3E80,Y
 AND bitMask
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
 LDX playerObject
 JSR sub_C1EB5
 LDX #&02

.C250D

 LDA #0
 STA L0086,X
 SEC
 SBC L0037,X
 STA xSightsVectorLo,X
 LDA L0018,X
 SBC L003A,X
 STA xSightsVectorHi,X
 BPL C2529
 DEC L0086,X
 LDA #0
 SEC
 SBC xSightsVectorLo,X
 LDA #0
 SBC xSightsVectorHi,X

.C2529

 CMP T
 BCC C252F
 STA T

.C252F

 DEX

 BPL C250D

                        \ At this point X is set to 255, which we use below when
                        \ checking the secret entry code

 LDA T
 ASL A
 ASL A
 CMP #&06
 BCC C25AF

.P253A

 ASL xSightsVectorLo
 ROL xSightsVectorHi
 ASL ySightsVectorLo
 ROL ySightsVectorHi
 ASL zSightsVectorLo
 ROL zSightsVectorHi
 LSR L0017
 ASL A
 BCC P253A
 LDA L003C
 CLC
 ADC #&60
 STA L003C
 LDA L0CCE
 BMI C257E

                        \ The following code does a check on the secret entry
                        \ code for the current landscape to ensure that it
                        \ matches the entered code in the keyboard input buffer
                        \
                        \ If the check fails, then the game restarts by jumping
                        \ to MainTitleLoop to display the title screen
                        \
                        \ Specifically, the following code checks for four bytes
                        \ in the secretCodeStash that correspond to the results
                        \ of the comparisons made in the CheckSecretCode routine
                        \
                        \ This ensures that crackers who manage to bypass the
                        \ CheckSecretCode routine will find that the game
                        \ restarts, unless they also disable this rather well
                        \ hiddden check

 LDA stashOffset-255,X  \ We know that X is 255 from the loop above, so this
                        \ sets A = stashOffset

                        \ We now set stashAddr(1 0) to point to the four bytes
                        \ in the secretCodeStash that correspond to the four
                        \ comparisons we made for the secret entry code in the
                        \ CheckSecretCode routine

 CLC                    \ Set stashAddr = A + 41
 ADC #41                \
 STA stashAddr          \ So that's the low byte

 LDX #3                 \ Set X = 3 so we can use it to count four bytes in the
                        \ loop below (as well as in the following calculation)

 TXA                    \ Set stashAddr+1 = HI(secretCodeStash) - 3 + 3
 CLC                    \                 = HI(secretCodeStash)
 ADC #HI(secretCodeStash) - 3
 STA stashAddr+1

                        \ So we now have the following:
                        \
                        \   stashAddr(1 0) = secretCodeStash + stashOffset + 41
                        \
                        \ When the secretCodeStash gets populated in the
                        \ CheckSecretCode routine, we add one byte for each
                        \ iteration and comparison in the secret code generation
                        \ process
                        \
                        \ That process starts by performing 38 iterations and
                        \ storing the results in the secretCodeStash from offset
                        \ stashOffset to stashOffset + 37
                        \
                        \ It then generates the four BCD numbers that make up
                        \ the secret code, storing the results in the stash from
                        \ offset stashOffset + 38 to stashOffset + 41
                        \
                        \ (And it then generates one more result, but we ignore
                        \ that)
                        \
                        \ So stashAddr(1 0) points to the last of those bytes in
                        \ the secretCodeStash, i.e. the byte at stashOffset + 41
                        \
                        \ The value that is stashed in the secretCodeStash is
                        \ the result of subtracting the entered code from the
                        \ generated code, which will be zero if they match, and
                        \ then %01111111 is added to the result (%01111111 being
                        \ the object flags for the Sentinel, which is all part
                        \ of the obfuscation of this process)
                        \
                        \ So if the secretCodeStash contains %01111111, this
                        \ means that particular byte matched, so if all four
                        \ bytes at offset stashOffset + 38 to stashOffset + 41
                        \ equal %01111111, this means the secret code was deemed
                        \ correct by CheckSecretCode

 LDY #0                 \ Set Y = 0 so we can fetch a value from the address in
                        \ stashAddr(1 0) in the following (we don't change its
                        \ value)

                        \ We use X as the loop counter to work through all four
                        \ bytes, as we set it to 3 above

.P2569

 LDA (stashAddr),Y      \ Fetch the contents of address stashAddr(1 0)

 CMP #%01111111         \ If it does not match %01111111 then this byte from the
 BNE C25D7              \ secret code was not matched by the CheckSecretCode
                        \ routine (so it must have been bypassed by crackers),
                        \ so jump to MainTitleLoop via C25D7 to restart the game

 DEC stashAddr          \ Decrement stashAddr(1 0) to point to the previous byte
                        \ in memory (we decrement as we initialised stashAddr
                        \ above to point to the last result byte in memory, so
                        \ this moves on to the next of the four bytes)

 DEX                    \ Decrement the loop counter

 BPL P2569              \ Loop back until we have checked all four secret code
                        \ bytes

                        \ The four code bytes have now been checked, but we have
                        \ one more check to do, that of the comparison just
                        \ before the four bytes
                        \
                        \ This comparison would have been between inputBuffer+4
                        \ and a BCD number from the landscape's sequence of seed
                        \ numbers
                        \
                        \ When the landscape code is entered, it is converted
                        \ into four BCD numbers in inputBuffer, and the rest of
                        \ the buffer is padded out with &FF, so inputBuffer+4
                        \ contains &FF at the point of comparison
                        \
                        \ &FF is not a valud BCD number, so it can never match a
                        \ BCD number from the landscape's sequence of seed
                        \ numbers, so we know that this comparison can never
                        \ have matched
                        \
                        \ So if stashAddr(1 0) contains %01111111 to indicate a
                        \ match, then we know that the stash has been modified
                        \ by a cracker, so we restart the game

 LDA (stashAddr),Y      \ Fetch the contents of address stashAddr(1 0)

 CMP #%01111111         \ If it matches %01111111 then we know the stash has
 BEQ C25D7              \ been compromised, so jump to Mainloop via C25D7 to
                        \ restart the game

 SEC
 ROR L0CCE

.C257E

 LDX #&02
 CLC
 BCC C2589

.P2583

 LDA L0034,X
 ADC xSightsVectorLo,X
 STA L0034,X

.C2589

 LDA L0037,X
 ADC xSightsVectorHi,X
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
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   C25D7               Jump to MainTitleLoop via game10
\
\ ******************************************************************************

.sub_C25C3

 LDA #0
 STA P
 STA secondAxis
 LDA #&7F
 STA Q
 LDA #&1F
 STA zTile

.P25D1

 LDA #&1F
 STA xTile
 BNE C25DA

.C25D7

 JMP game10             \ Jump to MainTitleLoop to restart the game

.C25DA

 JSR sub_C1DE6
 LDY xTile
 ROL A
 STA (P),Y
 DEC xTile
 BPL C25DA
 DEC Q
 DEC zTile
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

 LDX anotherObject
 LDA #&40
 STA L003C
 LDA #&0C
 STA sightsYawAngleLo
 LDA objectYawAngle,X
 CLC
 ADC #&20
 STA processAction
 AND #&3F
 SEC
 SBC #&20
 STA T
 LDA processAction
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
 STA smoothingAction
 TYA
 SEC
 SBC #&02
 STA L004B
 LDA T
 SEC
 SBC #&0A
 STA L0020
 BIT processAction
 BMI C267F
 BVS C266F
 LDA xObject,X
 STA L0003
 LDA zObject,X
 STA L001D
 JMP C26A1

.C266F

 CLC
 LDA #&1F
 SBC zObject,X
 STA L0003
 LDA xObject,X
 STA L001D
 JMP C26A1

.C267F

 BVS C2694
 CLC
 LDA #&1F
 SBC xObject,X
 STA L0003
 CLC
 LDA #&1F
 SBC zObject,X
 STA L001D
 JMP C26A1

.C2694

 LDA zObject,X
 STA L0003
 CLC
 LDA #&1F
 SBC xObject,X
 STA L001D

.C26A1

 LDA #&1F
 STA zTile
 LDA L0C48
 STA cosSightsPitchLo
 LDA #0
 STA L0005
 JSR sub_C27AF
 LDA cosSightsPitchLo
 STA L0C48

.C26B6

 LDA L0005
 EOR #&20
 STA L0005
 LDA cosSightsPitchLo
 STA L0037
 LDA cosSightsPitchHi
 STA L0038
 JSR sub_C355A
 DEC zTile
 BMI C26D4
 LDY zTile
 CPY L001D
 BNE C26D6
 JMP C2747

.C26D4

 CLC
 RTS

.C26D6

 JSR sub_C27AF
 LDY cosSightsPitchLo
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
 INC zTile
 LDY L0037

.P26F5

 DEY
 JSR sub_C2815
 CPY cosSightsPitchLo
 BNE P26F5
 STY L0037
 DEC zTile
 LDA L0005
 EOR #&20
 STA L0005

.C2707

 LDY cosSightsPitchHi
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
 INC zTile
 LDY L0038

.P2723

 INY
 JSR sub_C2815
 CPY cosSightsPitchHi
 BNE P2723
 STY L0038
 DEC zTile
 LDA L0005
 EOR #&20
 STA L0005

.C2735

 JSR sub_C292D
 BIT L0C1B
 BPL C2742

 JSR CheckForSamePanKey \ Check to see whether the same pan key is being
                        \ held down compared to the last time we checked

 BNE C2745              \ If the same pan key is not being held down, jump to
                        \ C2745 to return from the subroutine with the C flag
                        \ set ???

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
 INC zTile
 LDY L0003
 JSR sub_C2815
 LDA L0AE0,Y
 CMP #&02
 BCS C27A9
 STA L0AE0+1,Y
 LDA L0A80,Y
 STA L0A80+1,Y
 LDA #&20
 STA L0005
 DEC zTile
 LDA #&FF
 STA L0B00,Y
 STA L0B00+1,Y
 STA L5520,Y
 STA L5500,Y
 LDA #&14
 STA L5520+1,Y
 STA L5500+1,Y
 LDA L0003
 STA yTile
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

 LDY cosSightsPitchLo
 JSR sub_C2815
 BEQ C27E9
 CMP #&80
 BEQ C27D7

.P27BA

 LDA xTile
 STA cosSightsPitchLo
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

 LDA xTile
 STA cosSightsPitchHi
 RTS

.C27D7

 LDA xTile
 STA cosSightsPitchHi
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

 LDA xTile
 STA cosSightsPitchHi
 LDA cosSightsPitchLo
 STA xTile

.P27F8

 JSR sub_C2806
 BCS C27FF

.C27FD

 BEQ P27F8

.C27FF

 LDA xTile
 STA cosSightsPitchLo
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

 LDY xTile
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

 LDY xTile
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

 STY xTile
 STY L000F
 TYA
 ORA L0005
 STA L0021
 LDA #0
 STA L007F
 LDX anotherObject
 LDA #&80
 STA L0080
 CLC
 LDA xTile
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
 LDA zTile
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
 LDA angleLo
 SEC
 SBC L001F
 STA L0BA0,Y
 LDA angleHi
 SBC L0020
 STA L5500,Y
 JSR GetHypotenuse
 BIT processAction
 BMI C288B
 BVS C2880
 LDX xTile
 LDY zTile
 JMP C28A4

.C2880

 LDX zTile
 LDA #&1F
 SEC
 SBC xTile
 TAY
 JMP C28A4

.C288B

 BVS C289C
 LDA #&1F
 SEC
 SBC xTile
 TAX
 LDA #&1F
 SEC
 SBC zTile
 TAY
 JMP C28A4

.C289C

 LDA #&1F
 SEC
 SBC zTile
 TAX
 LDY xTile

.C28A4

                        \ We now fetch the tile data for the tile anchored at
                        \ (X, Y), using code that's very similar to the
                        \ GetTileData routine
                        \
                        \ In the following comments I will refer to (X, Y) as
                        \ (xTile, zTile), just as in GetTileData, as that's
                        \ easier to follow

 STY T                  \ Store zTile in T, so we can use it in the following
                        \ calculation

 TXA                    \ Set Y = (xTile << 3 and %11100000) + zTile
 ASL A                  \       = (xTile >> 2 and %00000111) << 5 + zTile
 ASL A                  \       = (xTile div 4) * &20 + zTile
 ASL A
 AND #%11100000
 ORA T
 TAY

 TXA                    \ Set A = bits 0-1 of xTile
 AND #%00000011         \       = xTile mod 4

 STA T                  \ Store A in T so we can use it later ???

                        \ The low byte of tileDataPage(1 0) gets set to zero in
                        \ ResetVariables and is never changed
                        \
                        \ The low byte of tileData is also zero, as we know that
                        \ tileData is &0400
                        \
                        \ So in the following, we are just adding the high bytes
                        \ to get a result that is on a page boundary

 CLC                    \ Set the following:
 ADC #HI(tileData)      \
 STA tileDataPage+1     \   tileDataPage(1 0) = tileData + (A 0)
                        \                     = tileData + (xTile mod 4) * &100

                        \ So we now have the following:
                        \
                        \   tileDataPage(1 0) = tileData + (xTile mod 4) * &100
                        \
                        \   Y = (xTile div 4) * &20 + zTile
                        \
                        \ The address in tileDataPage(1 0) is the page within
                        \ tileData for the tile anchored at (xTile, zTile), and
                        \ is always one of &0400, &0500, &0600 or &0700 because
                        \ (xTile mod 4) is one of 0, 1, 2 or 3
                        \
                        \ The value of Y is the offset within that page of the
                        \ tile data for the tile anchored at (xTile, zTile)
                        \
                        \ We can therefore fetch the tile data for the specified
                        \ tile using Y as an index offset from tileDataPage(1 0)

 LDA (tileDataPage),Y   \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 LDX L0021
 STA L0180,X
 CMP #&C0
 BCC C28D6

.P28C4

 AND #&3F
 TAY
 LDA objectFlags,Y
 CMP #&40
 BCS P28C4
 LDA yObjectHi,Y
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

 LDX anotherObject
 LDA #0
 SEC
 SBC yObjectLo,X
 STA L0080
 LDA U
 SBC yObjectHi,X
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
 STA yTile

.P2931

 CMP L0038
 BCS CRE16
 CMP L0003
 BCS C2943
 JSR sub_C29E2
 INC yTile
 LDA yTile
 JMP P2931

.C2943

 LDA L0038

.P2945

 SEC
 SBC #&01
 BMI CRE16
 STA yTile
 CMP L0037
 BCC CRE16
 CMP L0003
 BCC CRE16
 JSR sub_C29E2
 LDA yTile
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
 STA objectTypes+63
 BEQ CRE17
 LDA yTile
 STA xObject+63
 LDA zTile
 STA zObject+63
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
 LDA yTile
 ORA L0005
 CLC
 ADC L001B
 AND #&3F
 TAX
 BIT drawingTitleScreen
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
 LDA yTile
 EOR zTile
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
 SBC smoothingAction
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
 LDA xSightsVectorLo,Y
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
\       Name: GenerateLandscape
\       Type: Subroutine
\   Category: Landscape
\    Summary: Generate tile data for the landscape
\
\ ------------------------------------------------------------------------------
\
\ This routine populates the tileData table with tile data for each of the tile
\ corners in the landscape. The landscape consists of 31x31 square tiles, made
\ up of a 32x32 grid of tile corners.
\
\ One byte of tile data is generated for each tile corner in the landscape. Each
\ byte of tile data contains two pieces of information:
\
\   * The low nibble of each byte contains the tile shape, which describes the
\     layout and structure of the landscape on that tile.
\
\   * The high nibble of each byte contains the altitude of the tile corner in
\     the front-left corner of the tile (i.e. the corner closest to the
\     landscape origin). We call this tile corner the "anchor".
\
\ As each tile is defined by a tile corner and a shape, we tend to use the terms
\ "tile" and "tile corner" interchangeably, depending on the context. That said,
\ for tile corners along the furthest back and rightmost edges of the landscape,
\ the shape data is ignored, as there is no landscape beyond the edges.
\
\ See the SetTileShape routine for information on the different types of tile
\ shape.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   doNotPlayLandscape  Controls how we return from the subroutine:
\
\                         * If bit 7 is set, return from the subroutine normally
\
\                         * If bit 7 is clear, jump to PreviewLandscape once the
\                           landscape is generated
\
\ ******************************************************************************

.GenerateLandscape

                        \ We start by generating 81 seed numbers, though these
                        \ are ignored (they get stored in the stripData table
                        \ but there's no reason for this - they could just as
                        \ easily be discarded)
                        \
                        \ The purpose of this step is to get the seed number
                        \ generator to a point where the output is predictable
                        \ and stable, so that every time we generate a sequence
                        \ of seed numbers for a landscape, they are exactly the
                        \ same each time while being unique to that landscape
                        \ number

 LDX #80                \ Set a counter in X so we can generate 81 seed numbers

.land1

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 STA stripData,X        \ Set the X-th entry in the stripData table to the seed
                        \ number in A

 DEX                    \ Decrement the counter

 BPL land1              \ Loop back until we have generated all 81 seed numbers

                        \ We now set the value of tileDataMultiplier for this
                        \ landscape, which is a multiplier that we apply to the
                        \ altitudes of the tile corners to alter the steepness
                        \ of the landscape

 LDA landscapeZero      \ If this is not landscape 0000, jump to land2
 BNE land2

 LDA #24                \ This is landscape 0000, so set A = 24 to use for the
                        \ tile data multiplier in tileDataMultiplier

 BNE land3              \ Jump to land3 to skip the following (this BNE is
                        \ effectively a JMP as A is never zero)

.land2

 JSR GetNextSeed0To22   \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, converted to the range 0 to 22

 CLC                    \ Set A = A + 14
 ADC #14                \
                        \ So A is now a number in the range 14 to 36

.land3

 STA tileDataMultiplier \ Set tileDataMultiplier = A
                        \
                        \ So this is 24 for landscape 0000 and in the range 14
                        \ to 36 for all other landscapes

                        \ We now populate the tileData table with tile corner
                        \ altitudes, which we store in the low nibble of the
                        \ tile data (for now)

 LDA #&80               \ Call ProcessTileData with A = &80 to set the tile data
 JSR ProcessTileData    \ for the whole landscape to the next set of numbers
                        \ from the landscape's sequence of seed numbers

 LDA #%00000000         \ Call SmoothTileData with bit 6 of A clear, to smooth
 JSR SmoothTileData     \ the landscape in lines of tile corners, working along
                        \ rows from left to right and along columns from front
                        \ to back, and smoothing each tile by setting each tile
                        \ corner's altitude to the average of its altitude with
                        \ the three following tile corners
                        \
                        \ This process is repeated twice by the single call to
                        \ SmoothTileData

 LDA #1                 \ Call ProcessTileData with A = 1 to scale the tile data
 JSR ProcessTileData    \ for the whole landscape by the tileDataMultiplier
                        \ before capping each byte of data to between 1 and 11
                        \
                        \ This capping process ensures that when we place the
                        \ tile altitude in the top nibble of the tile data, we
                        \ never have both bits 6 and 7 set (these bits can
                        \ therefore be used to identify whether or not a tile
                        \ contains an object)

 LDA #%01000000         \ Call SmoothTileData with bit 6 of A set, to smooth
 JSR SmoothTileData     \ the landscape in lines of tile corners, from the rear
                        \ row to the front row and then from the right column to
                        \ the left column, smoothing each outlier tile corner by
                        \ setting its altitude to that of its closest immediate
                        \ neighbour (where "closest" is in terms of altitude)
                        \
                        \ This smooths over any single-point spikes or troughs
                        \ in each row and column
                        \
                        \ This process is repeated twice by the single call to
                        \ SmoothTileData

                        \ The tileData table now contains the altitude of each
                        \ tile corner, with each altitude in the range 1 to 11,
                        \ so the altitude data is in the low nibble of each byte
                        \ of tile data
                        \
                        \ We now calculate the tile shape for the tiles anchored
                        \ at each tile corner in turn, where the anchor is in
                        \ the front-left corner of the tile (i.e. nearest the
                        \ origin)
                        \
                        \ Note that the last tile corners at the right end of
                        \ each row or at the back of each column do not anchor
                        \ any tiles, as they are at the edge (so their shapes
                        \ are not calculated)
                        \
                        \ We put the tile shape into the high nibble of the tile
                        \ data (for now)

 LDA #30                \ Set zTile = 30 so we start iterating from the rear,
 STA zTile              \ skipping the row right at the back as the tile corners
                        \ in that row do not anchor any tiles (so zTile iterates
                        \ from 30 to 0 in the outer loop)

.land4

 LDA #30                \ Set xTile = 30 so we start iterating from the right,
 STA xTile              \ skipping the rightmost column as the tile corners
                        \ in that column do not anchor any tiles (so xTile
                        \ iterates from 30 to 0 in the inner loop)

.land5

 JSR SetTileShape       \ Set X to the shape of the tile anchored at
                        \ (xTile, zTile)
                        \
                        \ This will be in the range 1 to 11 (so it fits into
                        \ the low nibble)

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), which we ignore, but this also sets
                        \ the tile page in tileDataPage and the index in Y, so
                        \ tileDataPage+Y now points to the tile data entry in
                        \ the tileData table

                        \ We now put the tile shape into the high nibble of the
                        \ tile data, so the low nibble of the tile data contains
                        \ the tile altitude and the high nibble contains the
                        \ tile shape (for now)

 TXA                    \ Put the tile shape in X into the high nibble of A by
 ASL A                  \ shifting X to the left by three spaces and OR'ing the
 ASL A                  \ result into the tile data at tileData + Y
 ASL A                  \
 ASL A                  \ This works because both the tile altitude and tile
 ORA (tileDataPage),Y   \ shape fit into the range 0 to 15, or four bits
 STA (tileDataPage),Y

 DEC xTile              \ Decrement the tile x-coordinate in the inner loop

 BPL land5              \ Loop back until we have processed all the tile corners
                        \ in the tile row at z-coordinate zTile, working from
                        \ right to left

 DEC zTile              \ Decrement outer loop counter

 BPL land4              \ Loop back until we have processed all the tile rows in
                        \ the landscape, working from the back of the landscape
                        \ all the way to the front row

                        \ By this point the high nibble of each byte of tile
                        \ data contains the tile shape and the low nibble
                        \ contains the tile altitude, so now we swap these
                        \ around
                        \
                        \ We do this so that we can reuse bits 6 and 7 to in
                        \ each byte of tile data to store the presence of an
                        \ object on the tile, as moving the tile altitude into
                        \ the high nibble means that bits 6 and 7 will never
                        \ be set (as the altitude is in the range 0 to 11)
                        \
                        \ We can therefore set both bit 6 and 7 to indicate that
                        \ a tile contains an object, and we can reuse the other
                        \ bits to store the object information (as we only ever
                        \ place objects on flat tiles, so we can discard the
                        \ shape data)

 LDA #2                 \ Call ProcessTileData with A = 2 to swap the high and
 JSR ProcessTileData    \ low nibbles of all the tile data for the whole
                        \ landscape
                        \
                        \ So now the low nibble of each byte of tile data
                        \ contains the tile shape and the high nibble contains
                        \ the tile altitude, as required
                        \
                        \ This also sets the N flag, so a BMI branch would be
                        \ taken at this point (see the following instruction)

 RTS                    \ Return from the subroutine
                        \
                        \ If the SmoothTileCorners routine has modified the
                        \ return address on the stack, then this RTS instruction
                        \ will actually take us to JumpToPreview+1, and the BMI
                        \ branch instruction at JumpToPreview+1 will be taken
                        \ because the call to ProcessTileData sets the N flag,
                        \ so this RTS will end up taking us to PreviewLandscape
                        \
                        \ If the SmoothTileCorners routine has not modified the
                        \ return address, then the RTS will take us to the
                        \ SecretCodeError routine, just after the original
                        \ caller, i.e. just after the JSR GenerateLandscape
                        \ instruction (which will either be at the end of the
                        \ main title loop if the player enters an incorrect
                        \ secret code, or when displaying a landscape's secet
                        \ code after the level is completed)

\ ******************************************************************************
\
\       Name: ProcessTileData
\       Type: Subroutine
\   Category: Landscape
\    Summary: Process the tile data for all tiles in the landscape
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Controls what we do to the tile data:
\
\                         * 0 = zero all the tile data
\
\                         * 1 = scale all the tile data by the multiplier in
\                               tileDataMultiplier before capping it to a value
\                               between 1 and 11
\
\                         * 2 = swap the high and low nibbles of all the tile
\                               data
\
\                         * &80 = set the tile data to the next set of numbers
\                                 from the landscape's sequence of seed numbers
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   N flag              The N flag is set (so a BMI branch will be taken)
\
\ ******************************************************************************

.ProcessTileData

 STA processAction      \ Store the action in processAction for later

                        \ We now loop through all the tiles in the landscape
                        \
                        \ The landscape consists of 31x31 square tiles, like a
                        \ chess board that's sitting on a table in front of us,
                        \ going into the screen
                        \
                        \ The landscape is defined by the altitudes of the
                        \ corners of each of the tile, so that's a 32x32 grid of
                        \ altitudes
                        \
                        \ The x-axis is along the front edge, from left to
                        \ right, while the z-axis goes into the screen, away
                        \ from us
                        \
                        \ We iterate through the tile corners with a nested
                        \ loop, with zTile going from 31 to 0 (so that's from
                        \ back to front)
                        \
                        \ For each zTile, xTile also goes from 31 to 0, so
                        \ that's from right to left
                        \
                        \ So we work through the landscape, starting with the
                        \ row of tile corners at the back (which we work through
                        \ from right to left), and then doing the next row
                        \ forward, looping until we reach the front row

 LDA #31                \ Set zTile = 31 so we start iterating from the back row
 STA zTile              \ (so zTile iterates from 31 to 0 in the outer loop)

.proc1

 LDA #31                \ Set xTile = 31 so we start iterating from the right
 STA xTile              \ end of the current row (so xTile iterates from 31 to 0
                        \ in the inner loop)

.proc2

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), which we ignore, but this also sets
                        \ the tile page in tileDataPage and the index in Y, so
                        \ tileDataPage+Y now points to the tile data entry in
                        \ the tileData table

 LDA processAction      \ Set A to the argument that was passed to the routine
                        \ and which we stored in processAction,
                        \
                        \ This specifies how we process the tile data

 BEQ proc8              \ If processAction = 0 then jump to proc8 to zero the
                        \ tile data for the tile anchored at (xTile, zTile)

 BMI proc7              \ If processAction = &80 then jump to proc7 to set the
                        \ tile data for the tile anchored at (xTile, zTile) to
                        \ the next number from the landscape's sequence of seed
                        \ numbers

                        \ If we get here then processAction must be 1 or 2 (as
                        \ the routine is only ever called with A = 0, 1, 2 or
                        \ &80)

 LSR A                  \ If processAction = 1 then this sets the C flag,
                        \ otherwise processAction = 2 and this clears the C flag

 LDA (tileDataPage),Y   \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 BCS proc3              \ If the C flag is set then processAction = 1, so jump
                        \ to proc3

                        \ If we get here then processAction = 2, so now we swap
                        \ the high and low nibble of the tile data

 LSR A                  \ Set bits 0-3 of T to the high nibble (bits 4-7) of the
 LSR A                  \ tile data in A
 LSR A
 LSR A
 STA T

 LDA (tileDataPage),Y   \ Set A once again to the tile data for the tile
                        \ anchored at (xTile, zTile)

 ASL A                  \ Set bits 4-7 of A to the low nibble (bits 0-3) of the
 ASL A                  \ tile data in A
 ASL A
 ASL A

 ORA T                  \ Merge A and T, so A now contains its original high
                        \ nibble in bits 0-3 (from T) and its original low
                        \ nibble in bits 4-7 (from A)
                        \
                        \ So this swaps the high and low nibbles around in the
                        \ tile data in A

 JMP proc8              \ Jump to proc8 to store A as the tile data for the tile
                        \ we are processing

.proc3

                        \ If we get here then processAction = 1, so we now do
                        \ various manipulations, including multiplying the
                        \ tile data by the multiplier in tileDataMultiplier
                        \ and capping the result to a positive number between
                        \ 1 and 11
                        \
                        \ At this point the tile data contains a seed number,
                        \ so this processs converts it into a value that we can
                        \ use as the altitude of the tile corner

 SEC                    \ Set A = tile data - 128
 SBC #128

 PHP                    \ Store the flags from the subtraction, so we can set
                        \ the sign of the scaled altitude below

 BPL proc4              \ If the result of the subtraction in A is positive,
                        \ skip the following as A is already positive

 EOR #%11111111         \ The result in A is negative, so negate it using two's
 CLC                    \ complement, so we have:
 ADC #1                 \
                        \   A = |tile data - 128|
                        \
                        \ This negation reflects negative altitudes from below
                        \ sea level to the equivalent altitude above sea level

.proc4

 STA U                  \ Set U = A
                        \       = |tile data - 128|

 LDA tileDataMultiplier \ Set A to the multiplier that we need to apply to the
                        \ tile data, which is in the range 14 to 36

 JSR Multiply8x8        \ Set (A T) = A * U
                        \           = tileDataMultiplier * |tile data - 128|

 PLP                    \ Restore the flags from the subtraction above, so
                        \ the N flag contains the sign of (tile data - 128)
                        \ (clear if it is positive, set if it is negative)

 JSR Absolute16Bit      \ Set the sign of (A T) to match the result of the
                        \ subtraction above, so we now have:
                        \
                        \   (A T) = tileDataMultiplier * (tile data - 128)

                        \ So if the original tile data represents a landscape
                        \ altitude, with "sea level" at altitude 128, then the
                        \ high byte of this calculation in A represents a
                        \ scaling of the altitude by tileDataMultiplier / 256,
                        \ with the scaling centred around sea level
                        \
                        \ This means that mountain peaks get higher and marine
                        \ trenches get deeper, stretching away from sea level
                        \ at altitude 128 in the original data
                        \
                        \ As tileDataMultiplier is in the range 14 to 36, this
                        \ transforms the tile data values as follows:
                        \
                        \   * Values start out in the range 0 to 255
                        \
                        \   * Converting to |tile data - 128| translates them
                        \     into values in the range 0 to 127, representing
                        \     magnitudes of altitude (0 = sea level, 127 = top
                        \     of Everest or bottom of Mariana Trench, stack
                        \     contains flags denoting high altitude or murky
                        \     depths)
                        \
                        \   * Multiplying by 14/256 (the minimum multiplier)
                        \     changes the range into 0 to 6
                        \
                        \   * Multiplying by 36/256 (the maximum multiplier)
                        \     changes the range into 0 to 17
                        \
                        \   * Reapplying the sign converts the magnitudes back
                        \     into depths or heights
                        \
                        \ So the above takes the seed numbers in the original
                        \ tile data and transforms then into values of A with a
                        \ maximum range of -17 to +17 (for higher multipliers)
                        \ or -6 to +6 (for lower multipliers)
                        \
                        \ We now take this result and do various additions and
                        \ cappings to change the result into a positive number
                        \ between 1 and 11

 CLC                    \ Set A = A + 6
 ADC #6                 \
                        \ So the ranges for A are now:
                        \
                        \   * Minimum multiplier range is -1 to +13
                        \
                        \   * Maximum multiplier range is -11 to +23

 BPL proc5              \ If A is positive then jump to proc5 to skip the
                        \ following

 LDA #0                 \ Otherwise A is negative, so set A = 0

.proc5

                        \ By this point A is a positive number and the ranges
                        \ for A are now:
                        \
                        \   * Minimum multiplier range is 0 to 13
                        \
                        \   * Maximum multiplier range is 0 to 23

 CLC                    \ Set A = A + 1
 ADC #1

                        \ By this point A is a positive number and the ranges
                        \ for A are now:
                        \
                        \   * Minimum multiplier range is 1 to 14
                        \
                        \   * Maximum multiplier range is 1 to 24

 CMP #12                \ If A < 12 then jump to proc6 to skip the following
 BCC proc6

 LDA #11                \ Otherwise A >= 12, so set A = 11

.proc6

                        \ By this point, A is a positive number between 1 and 11
                        \
                        \ For minimum values of the multiplier we have only lost
                        \ the very low and very high values in the range
                        \
                        \ For maximum values of the multiplier we have lost
                        \ around one-third at the top end and one-third at the
                        \ bottom end
                        \
                        \ We can now use this as the altitude of the tile
                        \ corner, which we can feed into the smoothing routines
                        \ to generate a gently rolling landscape that is
                        \ suitable for the game

 JMP proc8              \ Jump to proc8 to store A as the tile data for the tile
                        \ we are processing

.proc7

                        \ If we get here then the argument in A is &80, so we
                        \ fill the tile data table with seed numbers

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

.proc8

 STA (tileDataPage),Y   \ Store A as the tile data for the tile anchored at
                        \ (xTile, zTile)

 DEC xTile              \ Decrement the tile x-coordinate in the inner loop

 BPL proc2              \ Loop back until we have processed all the tiles in the
                        \ tile row at z-coordinate zTile, working from right to
                        \ left

 DEC zTile              \ Decrement outer loop counter

 BPL proc1              \ Loop back until we have processed all the tile rows in
                        \ the landscape, working from the back row of the
                        \ landscape all the way to the front row

                        \ Note that by this point the N flag is set, which means
                        \ a BMI branch would be taken (this is important when
                        \ analysing the intentionally confusing flow of the main
                        \ title loop created by the stack modifications in the
                        \ GenerateLandscape, SmoothTileCorners and JumpToPreview
                        \ routines)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SmoothTileData
\       Type: Subroutine
\   Category: Landscape
\    Summary: Smooth the entire landscape
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Controls how we smooth the tile data:
\
\                         * Bit 6 clear = smooth each row/column of tile corners
\                                         by working along the row/column and
\                                         setting each tile corner's altitude to
\                                         the average of its altitude with the
\                                         three following tile corners, working
\                                         along rows from left to right and
\                                         along columns from front to back
\
\                         * Bit 6 set = smooth each row/column of tile corners
\                                       by working along the row/column and
\                                       setting the altitude of each outlier
\                                       tile corner to that of its closest
\                                       immediate neighbour in terms of altitude
\                                       (i.e. smooth out single-point spikes or
\                                       troughs in the row/column)
\
\ ******************************************************************************

.SmoothTileData

 STA smoothingAction    \ Store the action in smoothingAction so the calls to
                        \ SmoothTileCorners can access it

 LDA #2                 \ We perform the smoothing process twice, so set a loop
 STA loopCounter        \ counter in loopCounter to count down from 2

.smoo1

                        \ We start by working our way through the landscape,
                        \ smoothing the row of tile corners at the back (i.e. at
                        \ tile z-coordinate 31), and then smoothing the next row
                        \ forward, looping until we reach the front row

 LDA #31                \ Set zTile = 31 so we start iterating from the back row
 STA zTile              \ (so zTile iterates from 31 to 0 in the following loop)

.smoo2

 LDA #00000000          \ Call SmoothTileCorners with bit 7 of A clear to smooth
 JSR SmoothTileCorners  \ the row of tile corners at z-coordinate zTile

 DEC zTile              \ Decrement the tile z-coordinate to move forward by one
                        \ tile row

 BPL smoo2              \ Loop back until we have smoothed all 32 rows

                        \ Next we work our way through the landscape from right
                        \ to left, smoothing the column of tile corners on the
                        \ right (i.e. the column of tile corners going into the
                        \ screen at tile x-coordinate 31), and then smoothing
                        \ the next column to the left, looping until we reach
                        \ the column along the left edge of the landscape

 LDA #31                \ Set xTile = 31 so we start iterating from the right
 STA xTile              \ column (so xTile iterates from 31 to 0 in the
                        \ following loop)

.smoo3

 LDA #%10000000         \ Call SmoothTileCorners with bit 7 of A set to smooth
 JSR SmoothTileCorners  \ the column of tile corners at x-coordinate xTile

 DEC xTile              \ Decrement the tile x-coordinate to move left by one
                        \ tile column

 BPL smoo3              \ Loop back until we have smoothed all 32 columns

 DEC loopCounter        \ Decrement the loop counter

 BNE smoo1              \ Loop back until we have done the whole smoothing
                        \ process twice

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetTileData
\       Type: Subroutine
\   Category: Landscape
\    Summary: Get the tile data and tile data address for a specific tile
\
\ ------------------------------------------------------------------------------
\
\ The tile data table at tileData is made up of sequences of 32 columns of tile
\ corners going into the screen, where each column goes from z = 0 to 31 along
\ the same x-coordinate, with the columns interleaved in steps of 4 like this:
\
\   &0400-&041F = 32-corner column going into the screen at x =  0
\   &0420-&043F = 32-corner column going into the screen at x =  4
\   &0440-&045F = 32-corner column going into the screen at x =  8
\   &0460-&047F = 32-corner column going into the screen at x = 12
\   &0480-&049F = 32-corner column going into the screen at x = 16
\   &04A0-&04BF = 32-corner column going into the screen at x = 20
\   &04C0-&04DF = 32-corner column going into the screen at x = 24
\   &04E0-&04FF = 32-corner column going into the screen at x = 28
\
\   &0500-&051F = 32-corner column going into the screen at x =  1
\   &0520-&053F = 32-corner column going into the screen at x =  5
\   &0540-&055F = 32-corner column going into the screen at x =  9
\   &0560-&057F = 32-corner column going into the screen at x = 13
\   &0580-&059F = 32-corner column going into the screen at x = 17
\   &05A0-&05BF = 32-corner column going into the screen at x = 21
\   &05C0-&05DF = 32-corner column going into the screen at x = 25
\   &05E0-&05FF = 32-corner column going into the screen at x = 29
\
\   &0600-&061F = 32-corner column going into the screen at x =  2
\   &0620-&063F = 32-corner column going into the screen at x =  6
\   &0640-&065F = 32-corner column going into the screen at x = 10
\   &0660-&067F = 32-corner column going into the screen at x = 14
\   &0680-&069F = 32-corner column going into the screen at x = 18
\   &06A0-&06BF = 32-corner column going into the screen at x = 22
\   &06C0-&06DF = 32-corner column going into the screen at x = 26
\   &06E0-&06FF = 32-corner column going into the screen at x = 30
\
\   &0700-&071F = 32-corner column going into the screen at x =  3
\   &0720-&073F = 32-corner column going into the screen at x =  7
\   &0740-&075F = 32-corner column going into the screen at x = 11
\   &0760-&077F = 32-corner column going into the screen at x = 15
\   &0780-&079F = 32-corner column going into the screen at x = 19
\   &07A0-&07BF = 32-corner column going into the screen at x = 23
\   &07C0-&07DF = 32-corner column going into the screen at x = 27
\   &07E0-&07FF = 32-corner column going into the screen at x = 31
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   xTile               A tile corner x-coordinate (0 to 31)
\
\   zTile               A tile corner z-coordinate (0 to 31)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The tile data for the tile anchored at (xTile, zTile):
\
\                         * If the tile does not contain an object, then:
\
\                           * The tile shape is in the low nibble (0 to 15)
\
\                           * The tile altitude is in the high nibble (1 to 11)
\
\                         * If the tile contains an object, then:
\
\                           * Bits 0 to 5 contain the object number of the
\                             object on the tile (0 to 63)
\
\                           * Bits 6 and 7 are both set
\
\   tileDataPage(1 0)   The address of the page containing the tile data
\
\   Y                   The offset from tileDataPage(1 0) of the tile data
\
\   C flag              Determines whether the tile contains an object:
\
\                         * Set if this tile contains an object
\
\                         * Clear if this tile does not contain an object
\
\ ******************************************************************************

.GetTileData

 LDA xTile              \ Set Y = (xTile << 3 and %11100000) + zTile
 ASL A                  \       = (xTile >> 2 and %00000111) << 5 + zTile
 ASL A                  \       = (xTile div 4) * &20 + zTile
 ASL A
 AND #%11100000
 ORA zTile
 TAY

 LDA xTile              \ Set A = bits 0-1 of xTile
 AND #%00000011         \       = xTile mod 4

                        \ The low byte of tileDataPage(1 0) gets set to zero in
                        \ ResetVariables and is never changed
                        \
                        \ The low byte of tileData is also zero, as we know that
                        \ tileData is &0400
                        \
                        \ So in the following, we are just adding the high bytes
                        \ to get a result that is on a page boundary

 CLC                    \ Set the following:
 ADC #HI(tileData)      \
 STA tileDataPage+1     \   tileDataPage(1 0) = tileData + (A 0)
                        \                     = tileData + (xTile mod 4) * &100

                        \ So we now have the following:
                        \
                        \   tileDataPage(1 0) = tileData + (xTile mod 4) * &100
                        \
                        \   Y = (xTile div 4) * &20 + zTile
                        \
                        \ The address in tileDataPage(1 0) is the page within
                        \ tileData for the tile anchored at (xTile, zTile), and
                        \ is always one of &0400, &0500, &0600 or &0700 because
                        \ (xTile mod 4) is one of 0, 1, 2 or 3
                        \
                        \ The value of Y is the offset within that page of the
                        \ tile data for the tile anchored at (xTile, zTile)
                        \
                        \ We can therefore fetch the tile data for the specified
                        \ tile using Y as an index offset from tileDataPage(1 0)

 LDA (tileDataPage),Y   \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 CMP #%11000000         \ Set the C flag if A >= %11000000, which will be the
                        \ case if both bit 6 and bit 7 of A are set

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SmoothTileCorners (Part 1 of 4)
\       Type: Subroutine
\   Category: Landscape
\    Summary: Smooth a row or column of tile corners (a "strip of tiles")
\
\ ------------------------------------------------------------------------------
\
\ This part copies the row or column of tile corners to a temporary workspace.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Controls which tile corners we smooth in the tile data:
\
\                         * Bit 7 clear = smooth the row of tile corners at
\                                         z-coordinate zTile
\
\                         * Bit 7 set = smooth the column of tile corners at
\                                       x-coordinate xTile
\
\ ******************************************************************************

.SmoothTileCorners

 ORA smoothingAction    \ We configured the smoothing action in bit 6 of
 STA processAction      \ smoothingAction in the SmoothTileData routine before
                        \ calling this routine, and bit 7 of A tells us whether
                        \ to smooth a row or a column of tile cornser, so this
                        \ combines both configurations from bit 6 and bit 7 into
                        \ one byte that we store in processAction

 LDX #34                \ We start by copying the tile data for the row/column
                        \ that we want to smooth into the stripData workspace,
                        \ so we can process it before copying it back into the
                        \ tileData table
                        \
                        \ In the following commentary I will refer to this
                        \ copied row or column of tile corners as a "strip of
                        \ tiles", as saying "row or column of tile corners"
                        \ every time is a bit of a monthful
                        \
                        \ We actually create a strip of tile data containing 35
                        \ tile corners, with offsets 0 to 31 being the tile data
                        \ for the strip we are smoothing and offsets 32 to 34
                        \ being repeats of the data for tile corners 0 to 2
                        \
                        \ So we effectively duplicate the first three tile
                        \ corners onto the end of the strip so we can wrap the
                        \ smoothing calculations around past the end of the
                        \ strip

.stri1

 TXA                    \ Set A = X mod 32
 AND #31                \
                        \ This ensures that for X = 32 to 34, we copy the tile
                        \ data for tiles 0 to 2 (as A = 0 to 2 for X = 32 to 34)

 BIT processAction      \ If bit 7 of processAction is clear then we are
 BPL stri2              \ smoothing a row of tiles at z-coordinate zTile, so
                        \ jump to stri2 to iterate across xTile

 STA zTile              \ If we get here then we are smoothing a column of tiles
                        \ so set zTile to the counter in X so we iterate along
                        \ the z-coordinate (i.e. coming out of the screen)

 JMP stri3              \ Jump to stri3 to skip the following

.stri2

 STA xTile              \ If we get here then we are smoothing a row of tiles
                        \ so set xTile to the counter in X so we iterate along
                        \ the x-coordinate (i.e. from right to left)

.stri3

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 STA stripData,X        \ Store the tile data for (xTile, zTile) into the X-th
                        \ byte in our temporary workspace

 DEX                    \ Decrement the tile counter in X

 BPL stri1              \ Loop back until we have copied tile data for all 32
                        \ tiles in the strip, plus three more tiles on the end

 BIT processAction      \ If bit 6 of processAction is clear then we need to
 BVC stri11             \ smooth the strip by averaging tile altitudes, so jump
                        \ to part 3 to implement this

                        \ Otherwise fall through into part 2 to smooth the strip
                        \ by moving outlier tiles

\ ******************************************************************************
\
\       Name: SmoothTileCorners (Part 2 of 4)
\       Type: Subroutine
\   Category: Landscape
\    Summary: Smooth a strip by moving each outlier tile corner to the altitude
\             of its closest immediate neighbour (in terms of altitude)
\
\ ------------------------------------------------------------------------------
\
\ This part smoothes the strip by working along the strip and applying the
\ following algorithm:
\
\   * If this tile corner is higher then both its neighbours, move it down
\
\   * If this tile corner is lower then both its neighbours, move it up
\
\ In each case, we move the tile corner until it is level with the closest one
\ to its original altitude. This has the effect of smoothing out single-point
\ spikes or troughs in the strip.
\
\ ******************************************************************************

                        \ If we get here then bit 6 of processAction is set, so
                        \ we smooth the tile strip by moving each outlier tile
                        \ to the altitude of its closest immediate neighbour (in
                        \ terms of altitude)
                        \
                        \ This smoothes out single-point spikes or troughs

 LDX #31                \ We now work our way along the strip, smoothing the
                        \ altitudes of tiles 1 to 32, so set a tile counter in X
                        \
                        \ Note that we smooth tiles 1 to 32 rather than tiles
                        \ 0 to 31 (tile 0 remains unchanged by the smoothing
                        \ process)

.stri4

                        \ In the following, we are processing the tile at
                        \ position X + 1, i.e. stripData+1,X
                        \
                        \ We smooth a tile by looking at the altitudes of the
                        \ two tiles either side of that tile, i.e. stripData,X
                        \ and stripData+2,X
                        \
                        \ We are smoothing from high values of X to low values,
                        \ so by this point the tile at stripData+2,X has already
                        \ been smoothed
                        \
                        \ Let's name the tiles as follows:
                        \
                        \   * stripData+2,X = "previous tile" (as it has already
                        \                     been smoothed)
                        \
                        \   * stripData+1,X = "this tile" (as this is the tile
                        \                      we are smoothing)
                        \
                        \   * stripData,X   = "next tile" (as this is the tile
                        \                      we will be smoothing next)
                        \
                        \ The smoothing algorithm is implemented as follows,
                        \ where we are comparing the altitude of each tile (as
                        \ at this stage tileData only contains tile altitudes):
                        \
                        \   * If this = previous, do nothing
                        \
                        \   * If this < previous and this >= next, do nothing
                        \
                        \   * If this < previous and this < next, set
                        \     this = min(previous, next)
                        \
                        \   * If this > previous and this <= next, do nothing
                        \
                        \   * If this > previous and this > next, set
                        \     this = max(previous, next)
                        \
                        \ Or to simplify:
                        \
                        \  * If this tile is higher then both its neighbours,
                        \    move it down until it isn't
                        \
                        \  * If this tile is lower then both its neighbours,
                        \    move it up until it isn't
                        \
                        \ So this algorithm smoothes the landscape by squeezing
                        \ the landscape into a flatter shape, moving outlier
                        \ tiles closer to the landscape's overall line

 LDA stripData+1,X      \ If this tile is at the same altitude as the previous
 CMP stripData+2,X      \ tile, jump to stri9 to move on to smoothing the next
 BEQ stri9              \ tile, as the transition from the previous tile to this
                        \ tile is already flat

 BCS stri5              \ If this tile is higher than the previous tile, jump to
                        \ stri5

                        \ If we get here then this tile is lower than the
                        \ previous tile

 CMP stripData,X        \ If this tile is at the same altitude or higher than
 BEQ stri9              \ the next tile, jump to stri9 to move on to smoothing
 BCS stri9              \ the next tile

                        \ If we get here then this tile is lower than the
                        \ previous tile and lower than the next tile

 LDA stripData+2,X      \ Set the flags from comparing the previous and next
 CMP stripData,X        \ tiles (so in stri6, tile A is the previous tile and
                        \ tile B is the next tile)

 JMP stri6              \ Jump to stri6, so that:
                        \
                        \   * If previous < next, set this = previous
                        \
                        \   * If previous >= next, set this = next
                        \
                        \ In other words, set:
                        \
                        \   this = min(previous, next)
                        \
                        \ before moving on to the next tile

.stri5

                        \ If we get here then this tile is higher than the
                        \ previous tile

 CMP stripData,X        \ If this tile is at the same altitude or lower than the
 BEQ stri9              \ next tile jump to stri9 to move on to smoothing the
 BCC stri9              \ next tile

                        \ If we get here then this tile is higher than the
                        \ previous tile and this tile is higher than the next
                        \ tile

 LDA stripData,X        \ Set the flags from comparing the next and previous
 CMP stripData+2,X      \ tiles (so in stri6, tile A is the next tile and
                        \ tile B is the previous tile)

                        \ Fall through into stri6, so that:
                        \
                        \   * If next < previous, set this = previous
                        \
                        \   * If next >= previous, set this = next
                        \
                        \ In other words, set:
                        \
                        \   this = max(previous, next)
                        \
                        \ before moving on to the next tile
.stri6

                        \ We get here after comparing two tiles; let's call them
                        \ tile A and tile B

 BCC stri7              \ If tile A is lower than tile B, jump to stri7 to set
                        \ the altitude of this tile to the altitude of the
                        \ previous tile

 LDA stripData,X        \ Set A to the altitude of the next tile and jump to
 JMP stri8              \ stri8 to set the altitude of this tile to the altitude
                        \ of the next tile

.stri7

 LDA stripData+2,X      \ Set A to the altitude of the previous tile

.stri8

 STA stripData+1,X      \ Set the altitude of this tile to the value in A

.stri9

 DEX                    \ Decrement the strip tile counter in X

 BPL stri4              \ Loop back until we have worked our way through the
                        \ whole strip

 BIT doNotPlayLandscape \ If bit 7 of doNotPlayLandscape is set then we do not
 BMI stri10             \ want to play the landscape after generating it, so
                        \ jump to stri10 to skip the following, leaving the
                        \ stack unmodified
                        \
                        \ This means that the JSR GenerateLandscape instruction
                        \ that got us here will return normally, so the RTS at
                        \ the end of the GenerateLandscape routine will behave
                        \ as expected, like this:
                        \
                        \   * If we called GenerateLandscape from the
                        \     MainTitleLoop routine, then we return there to
                        \     fall through into SecretCodeError, which displays
                        \     the "WRONG SECRET CODE" error message for when the
                        \     player enters an incorrect secret code
                        \
                        \   * If we called GenerateLandscape from the
                        \     FinishLandscape routine, then we return there to
                        \     display the landscape's secret entry code
                        \     on-screen, for when the player completes a level
                        \
                        \ If bit 7 of doNotPlayLandscape is clear then we keep
                        \ going to modify the return address on the stack, so
                        \ that the RTS at the end of the GenerateLandscape takes
                        \ us to the PreviewLandscape routine

                        \ The above loop ended with X set to &FF, so &0100 + X
                        \ in the following points to the top of the stack at
                        \ &01FF

 LDA #HI(JumpToPreview) \ Set the return address on the bottom of the stack at
 STA &0100,X            \ (&01FE &01FF) to JumpToPreview
 DEX                    \
 LDA #LO(JumpToPreview) \ Note that when an RTS instruction is executed, it pops
 STA &0100,X            \ the address off the top of the stack and then jumps to
                        \ that address + 1, so putting the JumpToPreview address
                        \ on the stack means that the RTS at the end of the
                        \ GenerateLandscape routine will actually send us to
                        \ address JumpToPreview+1
                        \
                        \ This is intentional and is intended to confuse any
                        \ crackers who might have reached this point, because
                        \ the JumpToPreview routine not only contains a JMP
                        \ instruction at JumpToPreview, but it also contains a
                        \ BMI instruction at JumpToPreview+1, if our crackers
                        \ forgot about this subtlty of the RTS instruction, they
                        \ might end up going down a rabbit hole

.stri10

 JMP stri16             \ Jump to stri16 to copy the tile data for the smoothed
                        \ strip back into the tileData table

\ ******************************************************************************
\
\       Name: SmoothTileCorners (Part 3 of 4)
\       Type: Subroutine
\   Category: Landscape
\    Summary: Smooth a strip by setting the tile corner altitudes to the average
\             of the current tile corner altitude and three following corners
\
\ ------------------------------------------------------------------------------
\
\ This part smoothes the strip by working along the strip and replacing the
\ altitude of each tile corner with the average of that corner's altitude plus
\ the next three corners, working along rows from left to right and columns
\ from near to far.
\
\ ******************************************************************************

.stri11

                        \ If we get here then bit 6 of processAction is clear,
                        \ so we smooth the tile strip by working our way along
                        \ the strip and setting each tile's altitude to the
                        \ average of its altitude with the three following tiles

 LDX #0                 \ We now work our way along the strip, smoothing the
                        \ altitudes of tiles 0 to 31, so set a tile counter in X
                        \
                        \ We work along rows from left to right and columns from
                        \ near to far

.stri12

 LDA #0                 \ Set U = 0 to use as the high byte of (U A), which we
 STA U                  \ will use to calculate the sum of the neighbouring tile
                        \ altitudes

 LDA stripData,X        \ Set A to the altitude of the tile we are smoothing
                        \ (the one at index X)

 CLC                    \ Add the altitude of the next tile along
 ADC stripData+1,X

 BCC stri13             \ If the addition overflowed then increment the high
 CLC                    \ byte in U, so we have the correct result of the sum
 INC U                  \ in (U A)

.stri13

 ADC stripData+2,X      \ Add the altitude of the next tile along

 BCC stri14             \ If the addition overflowed then increment the high
 CLC                    \ byte in U, so we have the correct result of the sum
 INC U                  \ in (U A)

.stri14

 ADC stripData+3,X      \ Add the altitude of the next tile along

 BCC stri15             \ If the addition overflowed then increment the high
 CLC                    \ byte in U, so we have the correct result of the sum
 INC U                  \ in (U A)

.stri15

                        \ So by this point (U A) contains the sum of the
                        \ altitudes of the tile we are smoothing, and the next
                        \ three tiles along the strip

 LSR U                  \ Set (U A) = (U A) / 4
 ROR A                  \
 LSR U                  \ So (U A) contains the average of the four altitudes,
 ROR A                  \ and we know that the high byte in U will be zero as
                        \ each of the four elements of the sum fits into one
                        \ byte

 STA stripData,X        \ Set the altitude of the tile we are smoothing to the
                        \ average that we just calculated

 INX                    \ Increment the tile counter to move along the strip

 CPX #32                \ Loop back until we have worked our way through the
 BCC stri12             \ strip and have smoothed tiles 0 to 31
                        \
                        \ This means that when we exit the loop, X = 32

 LDA tilesAtAltitude+14-32,X    \ Copy the contents of tilesAtAltitude+14 into
 STA GetAngleInRadians-1-32,X   \ the operand into GetAngleInRadians-1, which
                                \ contains an unused LDA #0 instruction ???

\ ******************************************************************************
\
\       Name: SmoothTileCorners (Part 4 of 4)
\       Type: Subroutine
\   Category: Landscape
\    Summary: Copy the smoothed strip data back into the tileData table
\
\ ------------------------------------------------------------------------------
\
\ This part copies the smoothed strip back into the tileData table.
\
\ ******************************************************************************

.stri16

                        \ By this point we have smoothed the whole strip, so we
                        \ can now copy the smoothed tile data back into the
                        \ tileData table

 LDX #31                \ Set A counter in X to work through the tile data for
                        \ the 32 tiles in the strip we just smoothed

.stri17

 TXA                    \ Set A to the tile index

 BIT processAction      \ If bit 7 of processAction is clear then we are
 BPL stri18             \ smoothing a row of tiles at z-coordinate zTile, so
                        \ jump to stri18 to iterate across xTile

 STA zTile              \ If we get here then we are smoothing a column of tiles
                        \ so set zTile to the counter in X so we iterate along
                        \ the z-coordinate (i.e. coming out of the screen)

 JMP stri19             \ Jump to stri19 to skip the following

.stri18

 STA xTile              \ If we get here then we are smoothing a row of tiles
                        \ so set xTile to the counter in X so we iterate along
                        \ the x-coordinate (i.e. from right to left)

.stri19

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), which we ignore, but this also sets
                        \ the tile page in tileDataPage and the index in Y, so
                        \ tileDataPage+Y now points to the tile data entry in
                        \ the tileData table

 LDA stripData,X        \ Copy the X-th byte of tile data from the smoothed
 STA (tileDataPage),Y   \ strip into the corresponding entry for (xTile, zTile)
                        \ in the tileData table

 DEX                    \ Decrement the tile counter in X so we work our way
                        \ along to the next tile in the strip we are smoothing

 BPL stri17             \ Loop back to smooth the next tile until we have
                        \ smoothed the whole strip

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetTileShape
\       Type: Subroutine
\   Category: Landscape
\    Summary: Calculate the shape of the tile anchored at (xTile, zTile)
\
\ ------------------------------------------------------------------------------
\
\ Given a tile at altitude S, with neighbouring altitudes T, U and V:
\
\      ^           [T]  [U]
\      |
\      |           [S]  [V]
\   z-axis
\    into
\   screen      x-axis from left to right --->
\
\ The shape is calculated as follows, where:
\
\   * 0, 1, 2 represent arbitrary altitudes that are in that order, with 2 being
\     higher than 1 being higher than 0
\
\   * a, b represent arbitrary altitudes where a <> b <> 1
\
\   * c represents an arbitrary altitude where b <> c (so c can equal 1)
\
\ These are all the different types of shape (note there is no shape 8, and
\ shapes 4 and 12 can have multiple layouts):
\
\   Shape   S vs V      S vs T      S vs U      U vs V      U vs T      Layout
\   -----   ------      ------      ------      ------      ------      ------
\
\   0       S == V      S == T      S == U                              1 1
\                                                                       1 1
\
\   1       S == V      S <> T                  U <  V      U == T      0 0
\                                                                       1 1
\
\   2       S <> V      S <> T      S <= U      U == V      U == T      2 2
\                                                                       1 2
\
\   3       S == V      S == T      S >  U                              1 0
\                                                                       1 1
\
\   4a      S <> V      S <> T                  U == V      U <> T      a 1
\                                                                       b 1
\
\   4b      S <> V      S == T                  U <> V      U <> T      1 a
\                                                                       1 b
\
\   5       S <> V      S == T                  U == V      U <  T      1 0
\                                                                       1 0
\
\   6       S == V      S <> T                  U == V      U <  T      2 1
\                                                                       1 1
\
\   7       S <> V      S == T                  U >= V      U == T      1 1
\                                                                       1 0
\
\   9       S == V      S <> T                  U >= V      U == T      2 2
\                                                                       1 1
\
\   10      S == V      S == T      S <  U                              1 2
\                                                                       1 1
\
\   11      S <> V      S <> T      S >  U      U == V      U == T      0 0
\                                                                       1 0
\
\   12a     S <> V      S <> T                  U <> V                  1 c
\                                                                       a b
\
\   12b     S == V      S <> T                  U <> V      U <> T      a b
\                                                                       1 1
\
\   13      S <> V      S == T                  U == V      U >= T      1 2
\                                                                       1 2
\
\   14      S <> V      S == T                  U <  V      U == T      1 1
\                                                                       1 2
\
\   15      S == V      S <> T                  U == V      U >= T      0 1
\                                                                       1 1
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   The shape of the tile anchored at (xTile, zTile)
\
\ ******************************************************************************

.SetTileShape

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 AND #%00001111         \ Extract the tile altitude from the low nibble and
 STA S                  \ store it in S

 INC xTile              \ Move along the x-axis to fetch the next tile to the
                        \ right

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 AND #%00001111         \ Extract the tile altitude from the low nibble and
 STA V                  \ store it in V

 INC zTile              \ Move along the x-axis to fetch the next tile into the
                        \ screen

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 AND #%00001111         \ Extract the tile altitude from the low nibble and
 STA U                  \ store it in U

 DEC xTile              \ Move back along the x-axis to fetch the next tile to
                        \ the left

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile)

 AND #%00001111         \ Extract the tile altitude from the low nibble and
 STA T                  \ store it in T

 DEC zTile              \ Move out of the screen, back along the z-axis to take
                        \ us back to the tile we are processing

                        \ So at this point we have the altitudes of four tile
                        \ corners, as follows, with the view from above:
                        \
                        \      ^           [T]  [U]
                        \      |
                        \      |           [S]  [V]
                        \   z-axis
                        \    into
                        \   screen      x-axis from left to right --->
                        \
                        \ S is the altitude of the tile corner that anchors the
                        \ tile for which we are calculating the shape, and T, U
                        \ and V are the altitudes of the tile's other three
                        \ corners, so now we can analyse the shape of the tile

 LDA S                  \ If S = V then jump to shap10
 CMP V
 BEQ shap10

 CMP T                  \ If S = T then jump to shap4
 BEQ shap4

 LDA U                  \ If U = V then jump to shap2
 CMP V
 BEQ shap2

.shap1

                        \ If we get here then we either fell through from above:
                        \
                        \   * S <> V
                        \   * S <> T
                        \   * U <> V
                        \
                        \ or we jumped here from shap10 and:
                        \
                        \   * S == V
                        \   * S <> T
                        \   * U <> T
                        \   * U <> V

 LDX #12                \ Return a shape value of 12 in X

 RTS                    \ Return from the subroutine

.shap2

                        \ If we get here then then:
                        \
                        \   * S <> V
                        \   * S <> T
                        \   * U == V
                        \
                        \ and A is set to U

 CMP T                  \ If U <> T then jump to shap5
 BNE shap5

                        \ If we get here then:
                        \
                        \   * S <> V
                        \   * S <> T
                        \   * U == V
                        \   * U == T
                        \
                        \ and A is set to U

 LDX #2                 \ Set X = 2 to return as the shape if U >= S

 CMP S                  \ If U >= S then jump to shap3 to return a shape value
 BCS shap3              \ of 2

 LDX #11                \ U < S so return a shape value of 11 in X

.shap3

 RTS                    \ Return from the subroutine

.shap4

                        \ If we get here then:
                        \
                        \   * S <> V
                        \   * S == T

 LDA U                  \ If U = V then jump to shap8
 CMP V
 BEQ shap8

                        \ If we get here then:
                        \
                        \   * S <> V
                        \   * S == T
                        \   * U <> V
                        \
                        \ and A is set to U

 CMP T                  \ If U = T then jump to shap6
 BEQ shap6

.shap5

                        \ If we get here then either we jumped from shap2:
                        \
                        \   * S <> V
                        \   * S <> T
                        \   * U == V
                        \   * U <> T
                        \
                        \ or we fell through from above:
                        \
                        \   * S <> V
                        \   * S == T
                        \   * U <> V
                        \   * U <> T

 LDX #4                 \ Return a shape value of 4 in X

 RTS                    \ Return from the subroutine

.shap6

                        \ If we get here then:
                        \
                        \   * S <> V
                        \   * S == T
                        \   * U <> V
                        \   * U == T
                        \
                        \ and A is set to U

 LDX #14                \ Set X = 14 to return as the shape if U < V

 CMP V                  \ If U < V then jump to shap7 to return a shape value
 BCC shap7              \ of 14

 LDX #7                 \ U >= V so return a shape value of 7 in X

.shap7

 RTS                    \ Return from the subroutine

.shap8

                        \ If we get here then:
                        \
                        \   * S <> V
                        \   * S == T
                        \   * U == V
                        \
                        \ and A is set to U

 LDX #5                 \ Set X = 5 to return as the shape if U < T

 CMP T                  \ If U < T then jump to shap7 to return a shape value
 BCC shap9              \ of 5

 LDX #13                \ U >= T so return a shape value of 13 in X

.shap9

 RTS                    \ Return from the subroutine

.shap10

                        \ If we get here then:
                        \
                        \   * S == V
                        \
                        \ and A is set to S

 CMP T                  \ If S = T then jump to shap14
 BEQ shap14

 LDA U                  \ If U = T then jump to shap12
 CMP T
 BEQ shap12

                        \ If we get here then:
                        \
                        \   * S == V
                        \   * S <> T
                        \   * U <> T
                        \
                        \ and A is set to U

 CMP V                  \ If U <> V then jump to shap1
 BNE shap1

                        \ If we get here then:
                        \
                        \   * S == V
                        \   * S <> T
                        \   * U <> T
                        \   * U == V
                        \
                        \ and A is set to U

 LDX #6                 \ Set X = 6 to return as the shape if U < T

 CMP T                  \ If U < T then jump to shap11 to return a shape value
 BCC shap11             \ of 6

 LDX #15                \ U >= T so return a shape value of 15 in X

.shap11

 RTS                    \ Return from the subroutine

.shap12

                        \ If we get here then:
                        \
                        \   * S == V
                        \   * S <> T
                        \   * U == T
                        \
                        \ and A is set to U

 LDX #1                 \ Set X = 1 to return as the shape if U < V

 CMP V                  \ If U < V then jump to shap11 to return a shape value
 BCC shap13             \ of 1

 LDX #9                 \ U >= V so return a shape value of 9 in X

.shap13

 RTS                    \ Return from the subroutine

.shap14

                        \ If we get here then:
                        \
                        \   * S == V
                        \   * S == T
                        \
                        \ and A is set to S

 CMP U                  \ If S = U then jump to shap16
 BEQ shap16

 LDX #10                \ Set X = 10 to return as the shape if S < U

 BCC shap15             \ If S < U then jump to shap15 to return a shape value
                        \ of 10

 LDX #3                 \ S > U so return a shape value of 93 in X

.shap15

 RTS                    \ Return from the subroutine

.shap16

                        \ If we get here then:
                        \
                        \   * S == V
                        \   * S == T
                        \   * S == U

 LDX #0                 \ Return a shape value of 0 in X

 RTS                    \ Return from the subroutine

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

 LDA yTile
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
 STA tileAltitude
 STA zSightsVectorHi
 STA L001E
 LDA #&FF
 STA L0004
 STA ySightsVectorHi
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
 STA sightsYawAngleHi
 LDA L0A80,Y
 STA L001A
 LDA L0AE0,X
 STA sightsPitchAngleLo
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
 STY tileAltitude
 LDA ySightsVectorHi
 STA L5A00,Y
 LDA zSightsVectorHi
 STA L5B00,Y
 LDA #0
 STA L007F

.C2E88

 LDA L007F
 BNE C2E94
 LDA tileAltitude
 CMP L0004
 BCC C2E94
 CLC
 RTS

.C2E94

 SEC
 RTS

.C2E96

 LDA L54A0,X
 CMP zSightsVectorHi
 BCC C2E9F
 STA zSightsVectorHi

.C2E9F

 CMP ySightsVectorHi
 BCS C2EA5
 STA ySightsVectorHi

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

 LDA sightsPitchAngleLo
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

 LDA sightsYawAngleHi
 BMI CRE25
 BNE C2EDA
 LDA L001A
 CMP L0052
 BCC CRE25
 CMP tileAltitude
 BCC C2EE1
 CMP L0051
 BCC C2EDF

.C2EDA

 LDA L0051
 SEC
 SBC #&01

.C2EDF

 STA tileAltitude

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
 LDX sightsYawAngleHi
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

 STX xTileMaxAltitude+63
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
 LDX sightsYawAngleHi
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

 STX xTileMaxAltitude+62

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
 STA sightsPitchAngleHi
 LDA L54A0,Y
 SEC
 SBC L54A0,X
 STA T
 LDA L0B40,Y
 SBC L0B40,X
 STA L000A

 JSR Absolute16Bit      \ Set (A T) = |A T|

 STA U
 ORA V
 BEQ C2FFA

.C2FEC

 LSR V
 ROR L000C
 LSR U
 ROR T
 SEC
 ROL sightsPitchAngleHi
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

 JSR Absolute16Bit      \ Set (A T) = |A T|

 STA L0043
 LDA T
 STA L003A
 LDA L54A0,Y
 STA L0039
 LDA L0B40,Y
 STA L0042
 LDA L0AE0,Y
 STA sightsPitchAngleLo
 LDA L0A80,Y
 STA L0016
 LDA sightsPitchAngleHi
 BEQ C3054

.C302B

 LDA L0016
 STA L001A
 SEC
 SBC L000C
 STA L0016
 LDA sightsPitchAngleLo
 STA sightsYawAngleHi
 SBC #&00
 STA sightsPitchAngleLo
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
 DEC sightsPitchAngleHi
 BNE C302B

.C3054

 LDA L0016
 STA L001A
 LDA sightsPitchAngleLo
 STA sightsYawAngleHi
 LDA L0039
 STA L0018
 LDA L0042
 STA L0041
 LDX L000E
 LDA L0A80,X
 STA L0016
 LDA L0AE0,X
 STA sightsPitchAngleLo
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
 LDA sightsYawAngleHi
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

 DEC sightsYawAngleHi
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
 LDA sightsYawAngleHi
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

 DEC sightsYawAngleHi
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
\       Name: CorruptSecretCode
\       Type: Subroutine
\   Category: Landscape
\    Summary: ???
\
\ ******************************************************************************

.CorruptSecretCode

 BCC GetNextSeedNumber  \ We only jump here with the C flag clear, so this
                        \ generates the next number from the landscape's
                        \ sequence of seed numbers, thus corrupting the
                        \ generation of the landscape's secret code
                        \
                        \ We then return to the caller using a tail call, so the
                        \ player doesn't know anything has gone wrong

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
 LDA sightsYawAngleHi
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
\       Name: GetNextSeedNumber
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set A to a seed number
\
\ ------------------------------------------------------------------------------
\
\ Seed numbers in The Sentinel are produced using a five-byte (40-bit) linear
\ feedback shift register (LFSR) with EOR feedback.
\
\ Specifically, to generate a new seed number, we shift the LFSR left by eight
\ places, and on each shift we insert the EOR of bits 19 and 32 into bit 0 of
\ the register. After eight shifts, the top byte is our next seed number.
\
\ ******************************************************************************

.GetNextSeedNumber

 STY yStoreNextSeed     \ Store Y in yStoreNextSeed so it can be preserved
                        \ across calls to the routine

                        \ We generate a new seed number by shifting the
                        \ five-byte linear feedback shift register in
                        \ seedNumberLFSR(4 3 2 1 0) by eight places, inserting
                        \ EOR feedback as we do so

 LDY #8                 \ Set a shift counter in Y

.rand1

 LDA seedNumberLFSR+2   \ Apply EOR feedback to the linear feedback shift
 LSR A                  \ register by taking the middle byte seedNumberLFSR+2,
 LSR A                  \ shifting it right by three places, EOR'ing it with
 LSR A                  \ seedNumberLFSR+4 in the output end of the shift
 EOR seedNumberLFSR+4   \ register and rotating bit 0 of the result into the C
 ROR A                  \ flag
                        \
                        \ This is the same as taking bit 3 of seedNumberLFSR+2
                        \ and EOR'ing it with bit 0 of seedNumberLFSR+4 into the
                        \ C flag
                        \
                        \ We now use the C flag as the next input bit into the
                        \ shift register
                        \
                        \ So this is the same as EOR'ing bits 19 and 32 of our
                        \ 40-bit register and shifting the result into bit 0 of
                        \ the register

 ROL seedNumberLFSR     \ Shift seedNumberLFSR(4 3 2 1 0) to the left by one
 ROL seedNumberLFSR+1   \ place, inserting the C flag into bit 0 of the input
 ROL seedNumberLFSR+2   \ end of the shift register in seedNumberLFSR
 ROL seedNumberLFSR+3
 ROL seedNumberLFSR+4

 DEY                    \ Decrement the shift counter

 BNE rand1              \ Loop back until we have shifted eight times

 LDY yStoreNextSeed     \ Restore the value of Y from yStoreNextSeed that we
                        \ stored at the start of the routine, so that it's
                        \ preserved

 LDA seedNumberLFSR+4   \ Set A to the output end of the shift register in
                        \ seedNumberLFSR+4 to give us our next seed number

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: yStoreNextSeed
\       Type: Variable
\   Category: Maths (Arithmetic)
\    Summary: Temporary storage for Y so it can be preserved through calls to
\             GetNextSeedNumber
\
\ ******************************************************************************

.yStoreNextSeed

 EQUB 0

\ ******************************************************************************
\
\       Name: PrintNumber
\       Type: Subroutine
\   Category: Text
\    Summary: Print a number as a single digit, printing zero as a capital "O"
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number to be printed (0 to 9)
\
\ ******************************************************************************

.PrintNumber

 CLC                    \ Convert the number in A into an ASCII digit by adding
 ADC #'0'               \ ASCII "0"

                        \ Fall into PrintDigit to print the digit in A

\ ******************************************************************************
\
\       Name: PrintDigit
\       Type: Subroutine
\   Category: Text
\    Summary: Print a numerical digit, printing zero as a capital "O"
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The numerical digit to be printed as an ASCII code
\
\ ******************************************************************************

.PrintDigit

 CMP #'0'               \ If the character in A is not a zero, jump to zero1 to
 BNE zero1              \ skip the following

 LDA #'O'               \ The character in A is a zero, so set A to ASCII "O" so
                        \ we print zero as capital "O" instead

.zero1

 BIT printTextIn3D      \ If bit 7 of printTextIn3D is set then we are printing
 BMI DrawLetter3D       \ 3D text, so jump to DrawLetter3D to draw the character
                        \ in 3D

 JMP PrintCharacter     \ Otherwise jump to PrintCharacter to print the single-
                        \ byte VDU command or character in A, returning from the
                        \ subroutine using a tail call

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
 LDY #HI(L0C10)
 LDX #LO(L0C10)
 LDA #10                \ osword_read_char
 JSR OSWORD
 LDA L0C4A
 STA zTile

 LDX #7                 \ Set A = L0C75 ???
 LDA L0C75-7,X

 CMP GetAngleInRadians-1-7,X    \ If A >= the contents of GetAngleInRadians-1,
 BCS C3204                      \ jump to C3204 to skip the following

                        \ We set the contents of GetAngleInRadians-1 to the
                        \ contents of tilesAtAltitude+14 in part 3 of the
                        \ SmoothTileCorners routine when generating the
                        \ landscape, so if we get here then something has gone
                        \ wrong between then and now, presumably because
                        \ something has been tampered with by crackers ???

 JSR CorruptSecretCode  \ At this point A < the contents of GetAngleInRadians-1
                        \ and the C flag is clear, so CorruptSecretCode will
                        \ call the GetNextSeedNumber routine, which will in turn
                        \ corrupt the generation of the landscape's secret code
                        \ by moving one step too far in the landscape's sequence
                        \ of seed numbers

.C3204

 ASL L0C10,X
 LDA L0C49
 STA xTile
 LDA #&04
 STA loopCounter

.P3210

 ASL L0C10,X
 ROL A
 ASL L0C10,X
 ROL A
 AND #&03
 TAY
 LDA L3248,Y
 PHA

 JSR GetTileData        \ Set A to the tile data for the tile anchored at
                        \ (xTile, zTile), which we ignore, but this also sets
                        \ the tile page in tileDataPage and the index in Y, so
                        \ tileDataPage+Y now points to the tile data entry in
                        \ the tileData table

 PLA
 STA (tileDataPage),Y
 INC xTile
 DEC loopCounter
 BNE P3210
 INC zTile
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
\    Summary: Draw the title screen or the screen showing the secret code
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   Determines the type of screen to draw:
\
\                         * If bit 7 = 0 then draw the title screen
\
\                         * If bit 7 = 1 then draw the secret code screen
\
\ ******************************************************************************

.DrawTitleScreen

 STA screenType         \ Store the screen type in A in screenType, so we can
                        \ refer to it below

 LDA #128               \ Set objectYawAngle+63 = 128
 STA objectYawAngle+63  \
                        \ The degree system in the Sentinel looks like this:
                        \
                        \            0
                        \      -32   |   +32         Overhead view of object
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
                        \ So this makes object #63 face directly out of the
                        \ screen

 LDA #&E0               \ Set (yObjectHi yObjectLo) for object #63 to &230,
 STA yObjectLo+63       \ or 736
 LDA #&02
 STA yObjectHi+63

 SEC                    \ Set bit 7 of drawingTitleScreen to indicate that we
 ROR drawingTitleScreen \ are drawing the title screen

 LDA #0                 \ Call ProcessTileData with A = 0 to zero the tile data
 JSR ProcessTileData    \ for the whole landscape

 BIT screenType         \ If bit 7 of the screen type is clear, jump to titl1 to
 BPL titl1              \ print "THE SENTINEL" on the title screen

                        \ If we get here then bit 7 of the argument is set, so
                        \ we now draw the secret code

 JSR DrawSecretCode     \ Draw the secret code in 3D ???

 LDX #3                 \ Set X = 3 to pass to DrawTitleObject ???

 LDA #0                 \ Set A = 0 so the call to DrawTitleObject draws a robot
                        \ on the right of the screen

 BEQ titl3              \ Jump to titl3 to skip the folloiwng and draw the robot
                        \ (this BEQ is effectively a JMP as A is always zero)

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

 LDX #1                 \ Set X = 1 to pass to DrawTitleObject ???

 LDA #5                 \ Set A = 5 so the call to DrawTitleObject draws the
                        \ Sentinel on the right of the screen

.titl3

 LDY #1                 \ Set Y = 1 to pass to DrawTitleObject ???

 JSR DrawTitleObject    \ Draw the Sentinel on the title screen or the robot on
                        \ the secret code screen ???

 LSR drawingTitleScreen \ Clear bit 7 of drawingTitleScreen to indicate we are
                        \ no longer drawing the title screen

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: screenType
\       Type: Variable
\   Category: Title screen
\    Summary: A variable that determines whether we are drawing the title screen
\             or the secret code screen in the DrawTitleScreen routine
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
\       Name: ReadNumber
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Read a number from the keyboard into the input buffer
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The maximum number of digits to read
\
\ ******************************************************************************

.ReadNumber

 STA T                  \ Set T to the maximum number of digits to read

 JSR EnableKeyboard     \ Select the keyboard as the input stream and flush the
                        \ keyboard buffer

                        \ We start by clearing the input buffer by filling it
                        \ with spaces

 LDY #7                 \ The input buffer is eight bytes long, so set a byte
                        \ counter in Y

 LDA #' '               \ Set A to the space character for use when clearing the
                        \ input buffer

.rkey1

 STA inputBuffer,Y      \ Reset the Y-th byte of the input buffer to contain a
                        \ space character

 DEY                    \ Decrement the byte counter

 BPL rkey1              \ Loop back until we have cleared the whole input buffer

 JSR PrintInputBuffer   \ Print the contents of the keyboard input buffer, which
                        \ will erase any existing text on-screen as we just
                        \ filled the input buffer with spaces

.rkey2

 LDY #0                 \ We now read the specified number of key presses, so
                        \ set Y as a counter for the number of valid characters
                        \ in the input buffer, starting from zero (as the buffer
                        \ is empty at the start)

.rkey3

 JSR ReadCharacter      \ Read a character from the keyboard into A, so A is set
                        \ to the ASCII code of the pressed key

 CMP #13                \ If RETURN was pressed then jump to rkey9 to return
 BEQ rkey9              \ from the subroutine, as RETURN terminates the input

 CMP #'0'               \ If the key pressed is less than ACSII "0" then it is a
 BCC rkey3              \ control code, so jump back to rkey3 to keep listening
                        \ for key presses, as control codes are not valid input

 CMP #127               \ If the key pressed is less than ASCII 127 then it is
 BCC rkey5              \ a printable ASCII character, so jump to rkey5 to
                        \ process it

 BNE rkey3              \ If the key pressed is not the DELETE key then jump
                        \ back to rkey3 to keep listening for key presses, as
                        \ this is not a valid input

                        \ If we get here then DELETE has been pressed, so we
                        \ need to delete the most recently entered character
                        \
                        \ Because the input buffer is stored as an ascending
                        \ stack, this means we need to delete the character at
                        \ inputBuffer, which is the top of the buffer stack,
                        \ and shuffle the rest of the stack to the left to
                        \ close up the gap (so that's shuffling then down in
                        \ memory)

 DEY                    \ Decrement Y to reduce the character count by one, as
                        \ we are about to delete a character from the buffer

 BMI rkey2              \ If we just decremented Y past zero then the buffer is
                        \ empty, so jump to rkey2 to reset Y to zero and keep
                        \ reading characters, as there is nothing to delete

 LDX #0                 \ Otherwise we want to delete the character from the top
                        \ of the buffer stack at inputBuffer and shuffle the
                        \ rest of the stack along to the left, so set an index
                        \ in X to work through the buffer from left to right

.rkey4

 LDA inputBuffer+1,X    \ Shuffle the character at index X + 1 to the left and
 STA inputBuffer,X      \ into index X

 INX                    \ Increment the buffer index to point to the next
                        \ character in the buffer as we work from left to right

 CPX #7                 \ Loop back until we have shuffled all seven characters
 BNE rkey4              \ to the left

 LDA #' '               \ Set the last character in the input buffer to a space
 STA inputBuffer+7      \ as the bottom of the stack at inputBuffer+7 is now
                        \ empty

 BNE rkey8              \ Jump to rkey8 to print the updated contents of the
                        \ input buffer, so we can see the character being
                        \ deleted, and loop back to listen for more key presses
                        \ (this BNE is effectively a JMP as A is never zero)

.rkey5

                        \ If we get here then the key press in A is a printable
                        \ ASCII character

 CMP #':'               \ If the character in A is ASCII ":" or greater then it
 BCS rkey3              \ is not a number, so jump to rkey3 to keep listening
                        \ for key presses, as we are only interested in numbers

 CPY T                  \ If Y <> T then the buffer does not yet contain the
 BNE rkey6              \ maximum number of digits allowed, so jump to rkey6 to
                        \ process the number key press

 LDA #7                 \ Otherwise the buffer is already full, so perform a
 JSR OSWRCH             \ VDU 7 command to make a system beep

 JMP rkey3              \ Jump back to rkey3 to listen for more key presses

.rkey6

                        \ If we get here then the key press in A is a number key
                        \ and the input buffer is not full

 INY                    \ Increment Y to increase the character count by one, as
                        \ we are about to add a character to the buffer

 PHA                    \ Store the key number in A on the stack, so we can
                        \ retrieve it after the following loop

 LDX #6                 \ We now want to insert the new character into the top
                        \ of the buffer stack at inputBuffer and shuffle the
                        \ stack along to the right (so that's shuffling then up
                        \ in memory), so set an index in X to work through the
                        \ buffer from right to left

.rkey7

 LDA inputBuffer,X      \ Shuffle the character at index X to the right and into
 STA inputBuffer+1,X    \ index X + 1

 DEX                    \ Decrement the buffer index to point to the next
                        \ character in the buffer as we work from right to left

 BPL rkey7              \ Loop back until we have shuffled all seven characters
                        \ to the right

 PLA                    \ Restore the key number that we stored on the stack
                        \ above

 STA inputBuffer        \ Store the key press at the top of the stack, in
                        \ inputBuffer

.rkey8

 JSR PrintInputBuffer   \ Print the contents of the keyboard input buffer so we
                        \ we can see the characters being entered or deleted

 JMP rkey3              \ Jump back to rkey3 to listen for more key presses

.rkey9

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PrintInputBuffer
\       Type: Subroutine
\   Category: Text
\    Summary: Print the contents of the keyboard input buffer
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   T                   The size of the input buffer
\
\ ******************************************************************************

.PrintInputBuffer

 SEC                    \ Set bit 7 of textDropShadow so the following text is
 ROR textDropShadow     \ printed without a drop shadow

                        \ We now print the contents of the input buffer
                        \
                        \ Key presses are stored in the input buffer using an
                        \ ascending stack, with new input being pushed into
                        \ inputBuffer, so to print the contents of the buffer,
                        \ we need to print it backwards, from the oldest input
                        \ at index T - 1 down to the most recent input at
                        \ index 0

 LDX T                  \ Set X = T - 1 so we can use X as an index into the
 DEX                    \ buffer, starting from the oldest input

.pinb1

 LDA inputBuffer,X      \ Set A to the X-th entry in the input buffer

 JSR PrintDigit         \ Print the numerical digit in A

 DEX                    \ Decrement the buffer index

 BPL pinb1              \ Loop back until we have printed the whole buffer

                        \ We now want to backspace by the number of characters
                        \ we just printed, to leave the cursor at the start of
                        \ the printed number

 LDX T                  \ Set X to the size of the input buffer, which we can
                        \ use as a character counter in the following loop to
                        \ ensure we backspace by the correct number of
                        \ characters to reach the start of printed number

 LDA #8                 \ Set A = 8 to perform a series of VDU 8 commands, each
                        \ of which will backspace the cursor by one character

.pinb2

 JSR PrintDigit         \ Print the character in A, which performs a VDU 8 to
                        \ backspace the cursor by one character

 DEX                    \ Decrement the character counter

 BNE pinb2              \ Loop back until we have backspaced to the start of the
                        \ buffer contents that we just printed

 LSR textDropShadow     \ Clear bit 7 of textDropShadow so text tokens are once
                        \ again printed with drop shadows

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: StringToNumber
\       Type: Subroutine
\   Category: Text
\    Summary: Convert a string of ASCII digits in the input buffer in-place into
\             a multi-byte BCD number
\
\ ******************************************************************************

.StringToNumber

 LDY #0                 \ We want to work through the input buffer, converting
                        \ each character in turn from an ASCII digit into a
                        \ number, so set an index in Y to work through the
                        \ buffer, one ASCII digit at a time

 LDX #0                 \ Each pair of ASCII digits gets converted into a value
                        \ that will fit into a single BCD byte, which we store
                        \ in-place, so set an index in X to work through the
                        \ buffer, so we can store the resulting BCD number one
                        \ byte at a time (i.e. two ASCII digits at a time)

.snum1

                        \ We now fetch two digits from the input buffer and
                        \ convert them into a single BCD number, remembering
                        \ that the input buffer is stored as an ascending stack,
                        \ so the digits on the left of the stack (i.e. those
                        \ that were typed first) are lower significance than
                        \ those on the right of the stack (i.e. those that were
                        \ typed last)
                        \
                        \ Effectively the stack is little-endian, just like the
                        \ 6502 processor
                        \
                        \ The calls to DigitToNumber will backfill the input
                        \ buffer with &FF if we are reading from the last four
                        \ characters of the input buffer, so the final result
                        \ will have four BCD numbers at the start of inputBuffer
                        \ (from inputBuffer to inputBuffer+3), and the rest of
                        \ the buffer will be padded out with four &FF bytes
                        \ (from inputBuffer+4 to inputBuffer+7)

 JSR DigitToNumber      \ Set T to the numerical value of the character at index
 STA T                  \ Y in the input buffer, which is the low significance
                        \ digit of the number we are fetching, and in the range
                        \ 0 to 9

 INY                    \ Increment Y to the next character in the input buffer

 JSR DigitToNumber      \ Set A to the numerical value of the character at index
                        \ Y in the input buffer, which is the high significance
                        \ digit of the number we are fetching, and in the range
                        \ 0 to 9

 ASL A                  \ Shift the high significance digit in A into bits 4-7,
 ASL A                  \ so A contains the first digit of the BCD number
 ASL A
 ASL A

 ORA T                  \ Insert the high significance digit in T into bits 0-3,
                        \ so A now contains both the first and second digits of
                        \ the BCD number

 STA inputBuffer,X      \ Store the BCD number in-place at index X

 INX                    \ Increment the result index in X to move on to the next
                        \ BCD number

 INY                    \ Increment the buffer index in Y to move on to the next
                        \ pair of digits

 CPY #8                 \ Loop back until we have converted the whole string
 BNE snum1              \ into a multi-byte BCD number

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DigitToNumber
\       Type: Subroutine
\   Category: Text
\    Summary: Convert a digit from the input buffer into a number
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The offset into the input buffer of the digit to convert
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The numerical value of the digit (0 to 9), where spaces
\                       are converted to 0
\
\ ******************************************************************************

.DigitToNumber

 LDA inputBuffer,Y      \ Set A to the ASCII digit from the input buffer that we
                        \ want to convert

 CPY #4                 \ If Y < 4 then jump to dnum1 to skip the following
 BCC dnum1

                        \ Y is 4 or more, so we set this character in the input
                        \ buffer to &FF so that as we work through the buffer in
                        \ the StringToNumber routine, converting pairs of ASCII
                        \ digits into single-byte BCD numbers, we backfill the
                        \ buffer with &FF

 PHA                    \ Set the Y-th character in the input buffer to &FF,
 LDA #&FF               \ making sure not to corrupt the value of A
 STA inputBuffer,Y
 PLA

.dnum1

 CMP #' '               \ If the character in the input buffer is not a space
 BNE dnum2              \ then it must be a digit, so jump to dmum2 to convert
                        \ it into a number

 LDA #'0'               \ Otherwise the character from the input buffer is a
                        \ space, so set A to ASCII "0" so we return a value of
                        \ zero in the following subtraction

.dnum2

 SEC                    \ Convert the ASCII digit into a number by subtracting
 SBC #'0'               \ ASCII "0"

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: Print2DigitBCD
\       Type: Subroutine
\   Category: Text
\    Summary: Print a binary coded decimal (BCD) number using two digits
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number to print (in BCD)
\
\ ******************************************************************************

.Print2DigitBCD

 PHA                    \ Store A on the stack so we can retrieve it later

 LSR A                  \ Shift the high nibble of A into bits 0-3, so A
 LSR A                  \ contains the first digit of the BCD number
 LSR A
 LSR A

 JSR PrintNumber        \ Print the number in A as a single digit

 PLA                    \ Retrieve the original value of A, which contains the
                        \ BCD number to print

 AND #%00001111         \ Extract the low nibble of the BCD number into A

 JMP PrintNumber        \ Print the number in A as a single digit and return
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: GetNextSeedAsBCD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set A to the next number from the landscape's sequence of seed
\             numbers, converted to a binary coded decimal (BCD) number
\
\ ******************************************************************************

.GetNextSeedAsBCD

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

                        \ We now convert this into a binary coded decimal (BCD)
                        \ number by ensuring that both the low nibble and high
                        \ nibble are in the range 0 to 9

 PHA                    \ Store A on the stack so we can retrieve it below

 AND #%00001111         \ Extract the low nibble of A, so it's in the range 0 to
                        \ 15

 CMP #10                \ If A >= 10 then set A = A - 6
 BCC rbcd1              \
 SBC #6                 \ This reduces the number in A to the range 0 to 9, so
                        \ it's suitable for the second digit in a BCD number
                        \
                        \ The subtraction will work because the C flag is set by
                        \ the time we reach the SBC instruction

.rbcd1

 STA lowNibbleBCD       \ Store the low nibble of the result in lowNibbleBCD

 PLA                    \ Retrieve the original value of A that we stored on the
                        \ stack above

 AND #%11110000         \ Extract the high nibble of A, so it's in the range 0
                        \ to 15

 CMP #10<<4             \ If the high nibble in A >= 10 then subtract 6 from the
 BCC rbcd2              \ high nibble
 SBC #6<<4              \
                        \ This reduces the high nibble of the number in A to the
                        \ range 0 to 9, so it's suitable for the first digit in
                        \ a BCD number
                        \
                        \ The subtraction will work because the C flag is set by
                        \ the time we reach the SBC instruction

.rbcd2

 ORA lowNibbleBCD       \ By this point A contains a BCD digit in the high
                        \ nibble and lowNibbleBCD contains a BCD digit in the
                        \ low nibble, so we can OR them together to produce a
                        \ BCD number in A, which we can return as our result

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: lowNibbleBCD
\       Type: Variable
\   Category: Maths (Arithmetic)
\    Summary: Storage for the low nibble when constructing a BCD seed number in
\             the GetNextSeedAsBCD routine
\
\ ******************************************************************************

.lowNibbleBCD

 EQUB 0

\ ******************************************************************************
\
\       Name: DrawSecretCode
\       Type: Subroutine
\   Category: Title screen
\    Summary: Draw the landscape's secret code in 3D text
\
\ ******************************************************************************

.DrawSecretCode

 LDA #%10000000         \ Set bit 7 of printTextIn3D so we print the landscape's
 STA printTextIn3D      \ secret code in 3D text when we call Print2DigitBCD
                        \ below

 JSR DrawLetter3D       \ ???

 LDA #&C7               \ ???
 JSR DrawLetter3D

 LSR playerIsOnTower    \ If we got here legally (i.e. without crackers getting
                        \ involved, then the ProcessActionKeys will have set
                        \ playerIsOnTower to 6 when the player transferred into
                        \ the robot on the Sentinel's tower, so this sets the
                        \ value of playerIsOnTower to 3

 LDX playerIsOnTower    \ Set X = 3 to use as a loop in the following code
                        \
                        \ If crackers have jumped straight here instead of
                        \ playing the game properly, then X will not be 3 (it
                        \ will probably be 64, as playerIsOnTower is initialised
                        \ to 128 at the start of each level)
                        \
                        \ The following code picks up where the CheckSecretCode
                        \ routine ends, for when bit 7 of doNotPlayLandscape is
                        \ set
                        \
                        \ In this case, CheckSecretCode only iterates up to the
                        \ point where the secret code is about to be generated,
                        \ and then it stops, so we can finish the generation
                        \ process here
                        \
                        \ For this to work, we need to set X = 3 so we can
                        \ generate the next four BCD numbers in the landscape's
                        \ sequence of seed numbers, as these will give us the
                        \ secret code
                        \
                        \ If X is 64, then the secret code that is generated
                        \ will be incorrect

.dsec1

 JSR GetNextSeedAsBCD   \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, converted to a binary coded decimal
                        \ (BCD) number

 CPX #4                 \ If X >= 4, skip printing the BCD number, so that we
 BCS dsec2              \ skip printing the four correct secret code numbers if
                        \ X starts the loop at 64

 JSR Print2DigitBCD     \ Print the binary coded decimal (BCD) number in A

.dsec2

 DEX                    \ Decrement the loop counter

 BPL dsec1              \ Loop back until we have printed the four BCD numbers
                        \ in the landscape's secret code

 STX playerIsOnTower    \ Set playerIsOnTower = &FF to overwrite the correct
                        \ value, to make it harder for crackers to work out why
                        \ their secret codes aren't valid

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 LSR printTextIn3D      \ Clear bit 7 of printTextIn3D to return to printing
                        \ normal text

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PrintLandscapeNum
\       Type: Subroutine
\   Category: Text
\    Summary: Print the four-digit landscape number (0000 to 9999)
\
\ ******************************************************************************

.PrintLandscapeNum

 LDA landscapeNumberHi  \ Print the high byte of the binary coded decimal (BCD)
 JSR Print2DigitBCD     \ landscape number as a two-digit number

 LDA landscapeNumberLo  \ Print the low byte of the binary coded decimal (BCD)
 JMP Print2DigitBCD     \ landscape number as a two-digit number and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: InitialiseSeeds
\       Type: Subroutine
\   Category: Landscape
\    Summary: Initialise the seed number generator so it generates the sequence
\             of seed numbers for a specific landscape number
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   (Y X)               A landscape number in BCD (0000 to 9999)
\
\ ******************************************************************************

.InitialiseSeeds

 STY seedNumberLFSR+1   \ Initialise the seed number generator by setting bits
 STX seedNumberLFSR     \ 0-15 of the five-byte linear feedback shift register
                        \ to the landscape number
                        \
                        \ This ensures that the GetNextSeedNumber routine (and
                        \ related routines) will generate a unique sequence of
                        \ pseudo-random numbers for this landscape, and which
                        \ will be the exact same sequence every time we need to
                        \ generate this landscape

 STY landscapeNumberHi  \ Set (landscapeNumberHi landscapeNumberLo) = (Y X)
 STX landscapeNumberLo

 STY landscapeZero      \ If the high byte of the landscape number is non-zero,
 TYA                    \ then set landscapeZero to this non-zero value (to
 BNE seed1              \ indicate that we are not playing landscape 0000) and
                        \ jump to seed1 to set maxNumberOfEnemies to 8

 TXA                    \ Set landscapeZero to the low byte of the landscape,
 STA landscapeZero      \ so this sets landscapeZero to zero if we are playing
                        \ landscape 0000, and it sets it to a non-zero value if
                        \ we are not
                        \
                        \ So landscapeZero is now correctly set to indicate
                        \ whether or not we are playing landscape 0000

 LSR A                  \ Set A to the high byte of the BCD landscape number
 LSR A                  \ plus 1, which is the same as saying:
 LSR A                  \
 LSR A                  \   A = 1 + (landscapeNumber div 10)
 CLC                    \
 ADC #1                 \ Or A is 1 plus the "tens" digit of the landscape
                        \ number

 CMP #9                 \ If A < 9 then A is in the range 1 to 8, so jump to
 BCC seed2              \ seed2 to set maxNumberOfEnemies to this value

                        \ Otherwise A is 9 or higher, so we now cap A to 8 as
                        \ the maximum allowed value for maxNumberOfEnemies

.seed1

 LDA #8                 \ Set A = 8 to use as the maximum number of enemies

.seed2

 STA maxNumberOfEnemies \ Set maxNumberOfEnemies to the value in A, so we get
                        \ the following cap on the number of enemies:
                        \
                        \   min(8, 1 + (landscapeNumber div 10))
                        \
                        \ So landscapes 0000 to 0009 have a maximum enemy count
                        \ of 1, landscapes 0010 to 0019 have a maximum enemy
                        \ count of 2, and so on up to landscapes 0070 and up,
                        \ which have a maximum enemy count of 8

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ProcessCharacter
\       Type: Subroutine
\   Category: Text
\    Summary: Process and print a character from a text token, which can encode
\             another text token or be a one-byte character or VDU command
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token character to be printed
\
\   Y                   The offset of the current character within the text
\                       token being printed
\
\ ******************************************************************************

.ProcessCharacter

 CMP #200               \ If the character in A >= 200 then it represents a text
 BCS char1              \ token, so jump to char1 to print the token

 JMP PrintVduCharacter  \ Otherwise the character in A is a simple one-byte
                        \ character or VDU command, so jump to PrintVduCharacter
                        \ to print it

.char1

 SBC #200               \ Set A = A - 200
                        \
                        \ As we store recursive tokens within other tokens by
                        \ encoding then as 200 + the token number, this extracts
                        \ the recursive token number into A, so we can print it
                        \
                        \ This subtraction works because we jumped here with a
                        \ BCS, so we know that the C flag is set

 TAX                    \ Set X to the token we want to print, to pass to the
                        \ PrintTextToken routine

 TYA                    \ Store Y on the stack so we can retrieve it below
 PHA

 JSR PrintTextToken     \ Print the text token in X

 PLA                    \ Retrieve Y from the stack, so Y now contains the
 TAY                    \ offset of the token we just printed within the parent
                        \ token that we are still printing

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetEnemyCount
\       Type: Subroutine
\   Category: Landscape
\    Summary: Calculate the number of enemies for the current landscape
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The enemy count for the landscape (in the range 1 to 8,
\                       with higher values for higher landscape numbers)
\
\ ******************************************************************************

.GetEnemyCount

 LDA landscapeNumberHi  \ Set T = (landscapeNumberHi / 4) + 2
 LSR A                  \
 LSR A                  \ Because the landscape number is in BCD and in the form
 LSR A                  \ 0000 to 9999, this extracts the top digit and adds 2
 LSR A                  \
 CLC                    \ So T is in the range 2 to 11, with higher values of T
 ADC #2                 \ for higher landscape numbers
 STA T

.enem1

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers, which we now use to calculate the
                        \ enemy count for this landscape (so the same number is
                        \ calculated for the same landscape number each time)

 LDY #7                 \ Set Y = 7 to use as the count of clear bits in A when
                        \ A is zero

 ASL A                  \ Set the C flag from bit 7 of this landscape's seed
                        \ number and clear bit 0 of A, leaving bits 6 to 0 of
                        \ the original A in bits 7 to 1

 PHP                    \ Store the status flags on the stack, so we can use the
                        \ C flag below to decide whether to negate the result

                        \ We now count the number of continuous clear bits at
                        \ the top of A, ignoring bit 0, so we count zeroes from
                        \ bit 7 down until we hit a 1, and put the result into Y

 BEQ enem3              \ If A = 0 then jump to enem3 with Y = 7, as we have a
                        \ continuous run of seven clear bits in bits 7 to 1

 LDY #&FF               \ Otherwise set Y = -1 so the following loop counts the
                        \ number of zeroes correctly

.enem2

 INY                    \ Increment the zero counter in Y

 ASL A                  \ Shift A to the left, moving the top bit into the C
                        \ flag

 BCC enem2              \ Loop back to keep shifting and counting zeroes until
                        \ we shift a 1 out of bit 7, at which point Y contains
                        \ the length of the run of zeroes in bits 6 to 0 of the
                        \ landscape's original seed number

.enem3

 TYA                    \ At this point Y contains a number in the range 0 to 7,
                        \ so copy this into A

 PLP                    \ If the C flag we stored on the stack above was set,
 BCC enem4              \ invert A, so this flips the result into the range -1
 EOR #%11111111         \ to -8 if bit 7 of the landscape's original seed number
                        \ was set

.enem4

                        \ At this point A is in the range -8 to 7

 CLC                    \ Set A = A + T
 ADC T                  \
                        \ T is in the range 2 to 11, so A is now in the range
                        \ -6 to 18

 CMP #8                 \ If A < 0 or A >= 8 then loop back to enem1 to try
 BCS enem1              \ again

                        \ If we get here then A is now in the range 0 to 7, with
                        \ higher values for higher landscape numbers

 ADC #1                 \ Set A = A + 1
                        \
                        \ This addition works as we know the C flag is clear
                        \ because we just passed through a BCS

                        \ So A is now a number in the range 1 to 8, with higher
                        \ values for higher landscape numbers, which we can use
                        \ as our enemy count (after capping it to the value of
                        \ maxNumberOfEnemies after we return from the
                        \ subroutine)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetNextSeed0To22
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Set A to the next number from the landscape's sequence of seed
\             numbers, converted to the range 0 to 22
\
\ ******************************************************************************

.GetNextSeed0To22

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 PHA                    \ Set T to bits 0-2 of A
 AND #%00000111         \
 STA T                  \ So T is a number in the range 0 to 7
 PLA

 LSR A                  \ Set A to bits 3-6 of A and clear the C flag
 LSR A                  \
 AND #%00011110         \ So T is a number in the range 0 to 15
 LSR A

 ADC T                  \ Set A = A + T
                        \
                        \ So A is a number in the range 0 to 22

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GetPlayerEnergyBCD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Fetch the player's energy in binary coded decimal (BCD)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The player's energy in BCD
\
\ ******************************************************************************

.GetPlayerEnergyBCD

 LDA #0                 \ Set A = 0 to use as the player's energy in binary
                        \ coded decimal (BCD)

 LDX playerEnergy       \ Set X to the player's energy level

 BEQ plen2              \ If X = 0 then jump to plen2 to return A = 0 as the
                        \ player's energy in BCD

                        \ Otherwise we convert X into BCD by simply adding 1 to
                        \ A and repeating this X times
                        \
                        \ This works because we only call this routine when the
                        \ D flag is set to switch arithmetic to BCD
.plen1

 CLC                    \ Increment the BCD number we are building in A
 ADC #1

 DEX                    \ Decrement the player's energy level in S

 BNE plen1              \ Loop back until we have added 1 to A, X times, so A
                        \ now contains the original value of X but in BCD

.plen2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MakeSound
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a sound
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of the sound to make (0 to 6):
\
\                         * A = 0 for ??? (two-part)
\
\                         * A = 1 for ??? (two-part)
\
\                         * A = 2 for ???
\
\                         * A = 3 for ???
\
\                         * A = 4 for ???
\
\                         * A = 5 for ping
\
\                         * A = 6 for ??? (two-part)
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   MakeSound-6         Make a two-part sound at the pitches defined in X and Y,
\                       where X is the pitch for sound data block #0 and Y is
\                       the pitch for sound data block #1
\
\ ******************************************************************************

 STX soundData+4        \ Set the third parameter of sound data block #0 to X,
                        \ to set the pitch of the first sound

 STY soundData+12       \ Set the third parameter of sound data block #1 to X,
                        \ to set the pitch of the second sound

.MakeSound

 PHA                    \ Store the sound number on the stack

 SEC                    \ Decrement A, keeping the result positive
 SBC #1
 BCS soun1
 ADC #1

.soun1

 JSR DefineEnvelope     \ Define envelope data A from the envelopeData table, so
                        \ sounds #0 and #1 both define envelope data 0, while
                        \ sounds #2 to #6 define envelope data 1 to 5

 PLA                    \ Retrieve the sound number from the stack and put it
 TAX                    \ into X, so we can use it as an index

 LDA soundNumberData,X  \ Set A to the corresponding entry from soundNumberData
                        \ for the sound number in X, which tells us which blocks
                        \ of sound data to use from the soundData table when
                        \ making the sound

 CMP #1                 \ If A <> 1 then jump to soun2 to make the sound using
 BNE soun2              \ the sound data in soundData block number A

                        \ If A = 1 then this is a two-part sound, with the first
                        \ part using the sound data in soundData block number A
                        \ and the second using the sound data in soundData block
                        \ zero

 JSR soun2              \ Call soun2 to make the first sound using the sound
                        \ data in soundData block number A

 LDA #0                 \ Set A = 0 and fall through into soun2 to make the
                        \ second sound using the sound data in soundData block
                        \ zero

.soun2

                        \ At this point we have the number of a soundData block
                        \ in A, in the range 0 to 4, so now we make the sound
                        \ using that sound data

 ASL A                  \ Set (Y X) = soundData + A * 8
 ASL A                  \
 ASL A                  \ starting with the low byte (we set the high byte in
 ADC #LO(soundData)     \ MakeSoundEnvelope)
 TAX                    \
                        \ Each sound data block in soundData contains 8 bytes
                        \ of data, so this sets (Y X) to the address within
                        \ the soundData table of the data block specified in A

 LDA #7                 \ Set A = 7 for the OSWORD command to make a sound

 BNE MakeSoundEnvelope  \ Jump to MakeSoundEnvelope to set up Y and apply the
                        \ OSWORD command to the (Y X) block, which makes the
                        \ relevant sound (this BNE is effectively a JMP as A is
                        \ never zero)

\ ******************************************************************************
\
\       Name: DefineEnvelope
\       Type: Subroutine
\   Category: Sound
\    Summary: Define a sound envelope
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of the sound envelope data block to define in
\                       the envelopeData table (0 to 5)
\
\ ******************************************************************************

.DefineEnvelope

 STA aStoreEnvelope     \ Set (Y X) = envelopeData + (A * 8 - A) * 2
 ASL A                  \           = envelopeData + A * 7 * 2
 ASL A                  \           = envelopeData + A * 14
 ASL A                  \
 SEC                    \ starting with the low byte (we set the high byte in
 SBC aStoreEnvelope     \ MakeSoundEnvelope)
 ASL A                  \
 ADC #LO(envelopeData)  \ Each envelope definition in envelopeData contains 14
 TAX                    \ bytes of data, so this sets A to the address within
                        \ the envelopeData table of the data for the envelope
                        \ number in A

 LDA #8                 \ Set A = 8 for the OSWORD command to define an envelope

                        \ Fall through into MakeSoundEnvelope to set up Y and
                        \ apply the OSWORD command to the (Y X) block, which
                        \ defines the relevant sound envelope

\ ******************************************************************************
\
\       Name: MakeSoundEnvelope
\       Type: Subroutine
\   Category: Sound
\    Summary: Either make a sound or set up an envelope
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The action:
\
\                         * A = 7 to make a sound
\
\                         * A = 8 to define a sound envelope
\
\   X                   The low byte of the address of the OSWORD block
\
\ ******************************************************************************

.MakeSoundEnvelope

 LDY #HI(soundData)     \ Set Y to the high byte of the soundData block address,
                        \ which is the same as the high byte of the envelopeData
                        \ block address, so (Y X) now points to the relevant
                        \ envelope or sound or sound data block

 JMP OSWORD             \ Call OSWORD with action A, as follows:
                        \
                        \  * A = 7 to make the sound at (Y X)
                        \
                        \  * A = 8 to set up the sound envelope at (Y X)
                        \
                        \ and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: aStoreEnvelope
\       Type: Variable
\   Category: Sound
\    Summary: Temporary storage for use in the DefineEnvelope routine
\
\ ******************************************************************************

.aStoreEnvelope

 EQUB 0

\ ******************************************************************************
\
\       Name: soundNumberData
\       Type: Variable
\   Category: Sound
\    Summary: A table to map a sound number (0 to 6) to the sound data block(s)
\             that are used to make the sound
\
\ ******************************************************************************

.soundNumberData

 EQUB 1                 \ Sound #0 = sound data block #1 then block #0

 EQUB 1                 \ Sound #1 = sound data block #1 then block #0

 EQUB 4                 \ Sound #2 = sound data block #4

 EQUB 2                 \ Sound #3 = sound data block #2

 EQUB 2                 \ Sound #4 = sound data block #2

 EQUB 3                 \ Sound #5 = sound data block #3

 EQUB 1                 \ Sound #6 = sound data block #1 then block #0

\ ******************************************************************************
\
\       Name: ProcessVolumeKeys
\       Type: Subroutine
\   Category: Sound
\    Summary: Adjust the volume of the sound envelopes when the volume keys are
\             pressed
\
\ ******************************************************************************

.ProcessVolumeKeys

 LDA doNotScanKeyboard  \ If bit 7 of doNotScanKeyboard is set then keyboard
 BMI volk6              \ scans are disabled, so jump to volk6 to return from
                        \ the subroutine without checking for volume-related
                        \ key presses

 LDA volumeLevel        \ Set A to the current volume level

 LDX keyLogger+3        \ Set X to the key logger entry for "7", "8", COPY and
                        \ DELETE (volume down, volume up, pause, unpause)

 BEQ volk1              \ If X = 0 then "7" (volume down) has been pressed, so
                        \ jump to volk1 ???

                        \ If we get here then X must be 1, 2 or 3 (for "8",
                        \ COPY and DELETE)

 DEX                    \ If X - 1 <> 0 then the original key logger entry must
 BNE volk6              \ be 2 or 3 (COPY or DELETE), so jump to volk6 to
                        \ return from the subroutine

                        \ If we get here then the key logger entry must be 1,
                        \ so "8" (volume up) has been pressed

 CMP #120               \ If A >= 120 then the volume level is already at the
 BCS volk2              \ maximum level of 120, so jump to volk2 without
                        \ changing it

 ADC #8                 \ Otherwise we can turn the volume up, so add 8 to the
                        \ volume level in A (the addition works because we know
                        \ we just passed through a BCS, so we know the C flag is
                        \ clear)

 BNE volk2              \ Jump to volk1 to update the volume level

.volk1

                        \ If we get here then "7" (volume down) has been pressed

 CMP #0                 \ If A = 0 then the volume level is already at the
 BEQ volk2              \ minimum level of 0, so jump to volk2 without changing
                        \ it

 SBC #8                 \ Otherwise we can turn the volume down, so subtract 8
                        \ from the volume level in A (the subtraction works
                        \ because we know that A > 0, so the CMP above will have
                        \ set the C)

.volk2

 LDX soundCounter       \ If soundCounter >= 2 then a sound is currently being
 CPX #2                 \ made (such as the confirmation ping we make when
 BCS ProcessVolumeKeys  \ changing the volume level) and it hasn't finished yet,
                        \ so loop back to the start of the routine to keep
                        \ checking for key presses and without changing the
                        \ volume, as we only want to change the volume when we
                        \ can make a pinging sound so the player can hear the
                        \ effect of the volume change

 STA volumeLevel        \ Update the volume level in volumeLevel to the new
                        \ value

 TAY                    \ Set Y to 0 (if the volume has been turned right down)
 BEQ volk3              \ or to 8 (if the volume level is non-zero)
 LDY #8

.volk3

 STY envelopeData+42+13 \ Set parameter #13 of envelope 3 to Y, to set the ALD
                        \ for the sound (the amplitude target level at the end
                        \ of the decay phase)

 STY envelopeData+28+13 \ Set parameter #13 of envelope 2 to Y, to set the ALD
                        \ for the sound (the amplitude target level at the end
                        \ of the decay phase)

 LDY #11                \ We now work through the envelopeVolumes table, which
                        \ contains offsets into the envelopeData table of the
                        \ bytes that control the volume of each envelope
                        \
                        \ We update each of the bytes to reflect the new volume
                        \ level, so set a counter in Y to work through all 12
                        \ bytes of envelope data

.volk4

 LDX envelopeVolumes,Y  \ Fetch the Y-th entry of the envelopeVolumes table into
                        \ X, so it contains the offset within the envelopeData
                        \ table that we need to update

 CPX #79                \ If this is not the entry at the beginning of the table
 BNE volk5              \ (which will be the last to be processed), jump to
                        \ volk5 to set the envelope byte to the new volume level

 EOR #%11111111         \ If this is the entry at the beginning of the table,
 ADC #0                 \ negate the volume level in A, as this entry is for the
                        \ AD parameter (the change of amplitude per step during
                        \ the decay phase), and we want this aspect to drop more
                        \ quickly at higher volume levels

.volk5

 STA envelopeData,X     \ Set the X-th byte of the envelope data to the volume
                        \ level in A

 DEY                    \ Decrement the envelope byte counter

 BPL volk4              \ Loop back until we have updated all 12 bytes with the
                        \ new volume level

 LDA #12                \ Set soundCounter = 12 to count down while the ping
 STA soundCounter       \ sound is made

 LDA #5                 \ Make sound #5 (ping) so the player can hear the new
 JSR MakeSound          \ volume level

 JMP ProcessVolumeKeys  \ Loop back to the start of the routine to keep checking
                        \ for key presses

.volk6

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: volumeLevel
\       Type: Variable
\   Category: Sound
\    Summary: The volume level, which can be changed by pressing "7" and "8"
\
\ ******************************************************************************

.volumeLevel

 EQUB 88

\ ******************************************************************************
\
\       Name: envelopeVolumes
\       Type: Variable
\   Category: Sound
\    Summary: A table of offsets into the envelope data for bytes that control
\             the volume of each envelope, so we can change their volume levels
\
\ ******************************************************************************

.envelopeVolumes

 EQUB 5 * 14 + 9        \ Offset for parameter #9 of envelope 5
                        \
                        \ AD (change of amplitude per step during decay phase)

 EQUB 0 * 14 + 12       \ Offset for parameter #12 of envelope 0
                        \
                        \ ALA (target amplitude level at end of attack phase)

 EQUB 0 * 14 + 13       \ Offset for parameter #13 of envelope 0
                        \
                        \ ALD (target amplitude level at end of decay phase)

 EQUB 1 * 14 + 12       \ Offset for parameter #12 of envelope 1
                        \
                        \ ALA (target amplitude level at end of attack phase)

 EQUB 1 * 14 + 13       \ Offset for parameter #13 of envelope 1
                        \
                        \ ALD (target amplitude level at end of decay phase)

 EQUB 2 * 14 + 8        \ Offset for parameter #8 of envelope 2
                        \
                        \ AA (change of amplitude per step during attack phase)

 EQUB 2 * 14 + 12       \ Offset for parameter #12 of envelope 2
                        \
                        \ ALA (target amplitude level at end of attack phase)

 EQUB 3 * 14 + 12       \ Offset for parameter #12 of envelope 3
                        \
                        \ ALA (target amplitude level at end of attack phase)

 EQUB 4 * 14 + 8        \ Offset for parameter #8 of envelope 5
                        \
                        \ AA (change of amplitude per step during attack phase)

 EQUB 4 * 14 + 12       \ Offset for parameter #12 of envelope 4
                        \
                        \ ALA (target amplitude level at end of attack phase)

 EQUB 5 * 14 + 8        \ Offset for parameter #8 of envelope 5
                        \
                        \ AA (change of amplitude per step during attack phase)

 EQUB 5 * 14 + 12       \ Offset for parameter #12 of envelope 5
                        \
                        \ ALA (target amplitude level at end of attack phase)

\ ******************************************************************************
\
\       Name: ProcessPauseKeys
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Pause or unpause the game when COPY or DELETE are pressed
\
\ ******************************************************************************

.ProcessPauseKeys

 LDA keyLogger+3        \ Set A to the key logger entry for "7", "8", COPY and
                        \ DELETE (volume down, volume up, pause, unpause)

 BMI paws2              \ If there is no key press in the key logger entry, jump
                        \ to paws2 to return from the subroutine

 CMP #2                 \ If A <> 2 then COPY is not being pressed, so jump to
 BNE paws2              \ paws2 to check for DELETE

                        \ If we get here then COPY is being pressed, so we need
                        \ to pause the game

 ROR gamePaused         \ Set bit 7 of gamePaused to indicate that the game is
                        \ paused (this works because the CMP above returned an
                        \ equality, so the C flag is set and ready to be rotated
                        \ into bit 7 of gamePaused)

 LDA #8                 \ Update the scanner so it's filled with green, to show
 JSR UpdateScanner      \ that the game is paused

 JSR FlushSoundBuffers  \ Flush all four sound channel buffers

.paws1

 LDA keyLogger+3        \ Set A to the key logger entry for "7", "8", COPY and
                        \ DELETE (volume down, volume up, pause, unpause)

 CMP #3                 \ If A <> 3 then DELETE is not being pressed, so jump
 BNE paws1              \ paws1 to check for key presses (or wait until no key
                        \ is being pressed)

 LDA #0                 \ Update the scanner so it's filled with black, so the
 JSR UpdateScanner      \ game can resume with a blank scanner

 LSR gamePaused         \ Clear bit 7 of gamePaused to indicate that the game is
                        \ unpaused

.paws2

 RTS                    \ Return from the subroutine

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

 STA soundData+20       \ Third parameter of sound data block #2 (pitch)
 LDA L0C70
 STA soundCounter
 LDA soundData+16       \ First parameter of sound data block #2 (channel)
 CLC
 ADC #&01
 CMP #&14
 BCC C3537
 LDA #&11

.C3537

 STA soundData+16       \ First parameter of sound data block #2 (channel)
 LDA #&04
 STA soundData+18       \ Second parameter of sound data block #2 (amplitude)

 LDA #3                 \ Make sound #3 (???)
 JMP MakeSound

.C3544

 STA L0CE7

.CRE31

 RTS

\ ******************************************************************************
\
\       Name: FlushSoundBuffers
\       Type: Subroutine
\   Category: Sound
\    Summary: Flush all four sound channel buffers
\
\ ******************************************************************************

.FlushSoundBuffers

 LDX #7                 \ To flush all four sound channel buffers we need to
                        \ pass the values 4, 5, 6 and 7 to the FlushBuffer
                        \ routine, so set X to loop through those values

.fbuf1

 JSR FlushBuffer        \ Call FlushBuffer to flush the buffer specified in X

 DEX                    \ Decrement the loop counter

 CPX #4                 \ Loop back until we have flushed the buffers for all
 BCS fbuf1              \ four sound channels

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FlushSoundBuffer0
\       Type: Subroutine
\   Category: Sound
\    Summary: Flush the sound channel 0 buffer
\
\ ******************************************************************************

.FlushSoundBuffer0

 LDX #4                 \ Set X = 4 to denote the sound channel 0 buffer

                        \ Fall through into FlushBuffer to flush the sound
                        \ channel 0 buffer

\ ******************************************************************************
\
\       Name: FlushBuffer
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Flush the specified buffer
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The number of the buffer to flush:
\
\                         * 4 = sound channel 0 buffer
\
\                         * 5 = sound channel 1 buffer
\
\                         * 6 = sound channel 2 buffer
\
\                         * 7 = sound channel 3 buffer
\
\ ******************************************************************************

.FlushBuffer

 LDA #21                \ Call OSBYTE with A = 21 to flush buffer X, returning
 JMP OSBYTE             \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: sub_C355A
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C355A

 LDA soundCounter
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

 LDA #6                 \ Make sound #6 (???) with the pitch in X and Y
 JSR MakeSound-6

 JSR GetNextSeedNumber  \ Set A to the next number from the landscape's sequence
                        \ of seed numbers

 AND #&03
 CLC
 ADC #&01
 STA soundCounter
 DEC L0C74

.CRE32

 RTS

.C358B

 JMP sub_C3505

.C358E

 LDA #50                \ Set soundCounter = 50 to count down while the next
 STA soundCounter       \ sound is made

 LDA #&22
 STA soundData+20       \ Third parameter of sound data block #2 (pitch)
 LDA #&03
 STA soundData+18       \ Second parameter of sound data block #2 (amplitude)

 LDA #4                 \ Make sound #4 (???)
 JSR MakeSound

 RTS

 EQUB &B9               \ This byte appears to be unused

\ ******************************************************************************
\
\       Name: PlayGame
\       Type: Subroutine
\   Category: Main game loop
\    Summary: Start playing the generated landscape
\
\ ******************************************************************************

.PlayGame

 LDA #&83               \ Set the palette to the first set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, cyan, yellow)

 JSR ReadKeyboard       \ Enable the keyboard, flush the keyboard buffer and
                        \ read a character from it (so this waits for a key
                        \ press before starting the game, following the "PRESS
                        \ ANY KEY" message on the landscape preview screen)

 LSR gameInProgress     \ Clear bit 7 of gameInProgress to indicate that a game
                        \ now in progress and we are no longer in the title and
                        \ preview screens (so the interrupt handler can now
                        \ update the game)

\ ******************************************************************************
\
\       Name: MainGameLoop
\       Type: Subroutine
\   Category: Main game loop
\    Summary: The main game loop for playing a landscape
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   game10              Jump to MainTitleLoop to restart the game
\
\ ******************************************************************************

.MainGameLoop

 JSR FlushSoundBuffers  \ Flush all four sound channel buffers

 LDA quitGame           \ If bit 7 of quitGame is clear then the player has not
 BPL game1              \ pressed function key f1 to quit the game, so jump to
                        \ game 1 to keep playing the game

 JMP MainTitleLoop      \ The player has pressed function key f1 to quit the
                        \ game, so jump to MainTitleLoop to restart the game

.game1

 LDA sentinelHasWon     \ If bit 7 of sentinelHasWon is set then the player has
 BMI game6              \ run out of energy and has been absorbed by the
                        \ victorious Sentinel, so jump to game6 to restart the
                        \ landscape

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 LDA #0
 STA L0055

 STA lastPanKeyPressed

 STA L0CC9

 STA sightsAreVisible

 JSR sub_C5734

 LDA playerObject       \ Set anotherObject to the object number of the player
 STA anotherObject

 BIT L0CDE              \ If bit 7 of L0CDE is clear, jump to game2
 BPL game2

 BVS game7              \ If bit 6 of L0CDE is set, jump to game7 to ???

 JSR sub_C1090

 JMP game4              \ Jump to game4 to skip the following ???

.game2

 LDA uTurnStatus        \ If bit 7 of uTurnStatus is set then we just performed
 BMI game3              \ a U-turn in the ProcessActionKeys routine, so jump to
                        \ game3 to skip the following ???

 JSR sub_C2463

.game3

 JSR sub_C1090

 JSR sub_C2624

 JSR UpdateIconsScanner \ Update the icons in the top-left corner of the screen
                        \ to show the player's current energy level and redraw
                        \ the scanner box

.game4

 LDA #&19
 STA L0055

 LDA #&02

 JSR sub_C2963

.game5

 JSR sub_C355A

 LDA L0CE7
 BPL game5

 LDA #&83               \ Set the palette to the first set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, cyan, yellow)

 LDA L0CDE

 BPL game11

 STA sentinelHasWon

 LDA #&06
 STA L0C73

 LDA #5                 \ The Sentinel has won, so display the game over screen
 JSR DisplayGameOver    \ with A = 5 ???

.game6

                        \ If we get here then we restart the landscape by
                        \ resetting all the game variables, initialising the
                        \ the seed number generator and jumping into the main
                        \ title loop to preview the landscape and play the game

 JSR ResetVariables     \ Reset all the game's main variables

 LDY landscapeNumberHi  \ Set (Y X) = (landscapeNumberHi landscapeNumberLo)
 LDX landscapeNumberLo

 JSR InitialiseSeeds    \ Initialise the seed number generator to generate the
                        \ sequence of seed numbers for the landscape number in
                        \ (Y X) and set maxNumberOfEnemies and the landscapeZero
                        \ flag accordingly

 JMP main4              \ Jump to main4 in the main title loop to restart the
                        \ landscape without having to enter the landscape's
                        \ secret code again

.game7

                        \ If we get here then we have successfully completed
                        \ the landascape, so ???

 LDA #4                 \ Set all four logical colours to physical colour 4
 JSR SetColourPalette   \ (blue), so this blanks the entire screen to blue

 LDX #3

 LDA #0
 STA L0C73

.game8

 STA seedNumberLFSR+1,X

 DEX

 BPL game8

 JSR ResetVariables2    \ ???

 JSR FinishLandscape    \ Add the player's energy to the landscape number to get
                        \ the number of the next landscape and display that
                        \ landscape's secret code as a title screen

 LDA #&87               \ Set the palette to the second set of colours from the
 JSR SetColourPalette   \ colourPalettes table (blue, black, red, yellow)

 LDA #10                \ Set soundCounter = 10 to count down while the next
 STA soundCounter       \ sound is made

 LDA #&42
 JSR sub_C5FF6

.game9

 JSR sub_C355A
 LDA L0CE7
 BPL game9

 LDX #6                 \ Print text token 6: Print "PRESS ANY KEY" at (64, 100)
 JSR PrintTextToken

 JSR ReadKeyboard       \ Enable the keyboard, flush the keyboard buffer and
                        \ read a character from it (so this waits for a key
                        \ press)

.game10

 JMP MainTitleLoop

.game11

 JSR sub_C1264

 BCC game12

 JMP MainGameLoop

.game12

 LDA panKeyBeingPressed
 STA lastPanKeyPressed

 LDA #0
 STA numberOfScrolls

 STA L0C1E

 BIT sightsAreVisible   \ If bit 7 of sightsAreVisible is set then the sights
 BMI game13             \ are being shown, so jump to game13 to skip the
                        \ following two instructions ???

 SEC                    \ Set bit 7 of L0C1B ???
 ROR L0C1B

.game13

 JSR sub_C10B7

 LSR L0C1B

 JSR UpdateIconsScanner \ Update the icons in the top-left corner of the screen
                        \ to show the player's current energy level and redraw
                        \ the scanner box

 LDA numberOfScrolls    \ Set scrollCounter to the number of scrolls required,
 STA scrollCounter      \ so the interrupt routine will scroll the screen by
                        \ this many steps in the background

.game14

 LDA scrollCounter
 BNE game14

 BEQ game11

\ ******************************************************************************
\
\       Name: ClearIconsScanner
\       Type: Subroutine
\   Category: Graphics
\    Summary: Clear the energy icon and scanner row at the top of the screen
\
\ ******************************************************************************

.ClearIconsScanner

 LDA #0                 \ Set xIconCounter = 0 so we start drawing from the left
 STA xIconCounter       \ edge of the screen

.enec1

 LDA #0                 \ Draw a blank icon into the top part of the screen (via
 JSR DrawIcon           \ the icon screen buffer at iconBuffer) and move along
                        \ to the right, incrementing xIconCounter as we do

 LDA xIconCounter       \ Loop back to keep drawing blank icons until we have
 CMP #40                \ cleared column 39, at which point we have cleared the
 BCC enec1              \ entire row

 JMP DisplayIconBuffer  \ Display the contents of the icon screen buffer by
                        \ copying it into screen memory, which will clear the
                        \ row on-screen, and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: PrintTextToken
\       Type: Subroutine
\   Category: Text
\    Summary: Print a recursive text token
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The number of the text token to print (0 to 17)
\
\ ******************************************************************************

.PrintTextToken

 LDY tokenOffset,X      \ Set Y to the offset for text token X, which we can use
                        \ as a character index to print each character in turn

.text1

 LDA tokenBase,Y        \ Set A to the Y-th character of the text token

 CMP #&FF               \ If A = &FF then we have reached the end of the token,
 BEQ text2              \ so jump to text2 to return from the subroutine

 JSR ProcessCharacter   \ Process the Y-th character of the text token in A, so
                        \ if A is a token number in the format 200 + token, we
                        \ print the text token, otherwise we print A as a simple
                        \ one-byte character

 INY                    \ Increment the character index in Y to point to the
                        \ next character of the text token

 JMP text1              \ Loop back to print the next character

.text2

 RTS                    \ Return from the subroutine

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
\       Name: UpdateIconsScanner
\       Type: Subroutine
\   Category: Graphics
\    Summary: Update the icons in the top-left corner of the screen to show the
\             player's current energy level and redraw the scanner box
\
\ ******************************************************************************

.UpdateIconsScanner

 LDA #0                 \ Set A = 0 to pass to DrawIcon

 STA xIconCounter       \ Set xIconCounter = 0 so we start drawing from the left
                        \ edge of the screen

 JSR DrawIcon           \ Draw a blank icon into the top part of the screen (via
                        \ the icon screen buffer at iconBuffer) and move along
                        \ to the right, incrementing xIconCounter as we do

 LDA playerEnergy       \ Set a loop counter to count down through the player's
 STA loopCounter        \ energy, so we can reduce it by the maximum possible
                        \ amount each time to work out the minimum number of
                        \ icons that represent that energy level
                        \
                        \ In other words, loopCounter contains the amount of
                        \ energy that we have yet to draw

.ener1

 LDA loopCounter        \ If loopCounter < 15 then we can't represent it with a
 CMP #15                \ high-energy robot (as that represents 15 energy
 BCC ener2              \ points), so jump to ener2 to skip to the next level
                        \ down

 SBC #15                \ Subtract 15 from the loop counter as we are about to
 STA loopCounter        \ draw a high-energy robot that represents 15 energy
                        \ points (this subtraction works because we just passed
                        \ through a BCC, so the C flag must be set)

 LDA #6                 \ Draw a high-energy robot into the top part of the
 JSR DrawIcon           \ screen (via the icon screen buffer at iconBuffer) and
                        \ move along to the right, incrementing xIconCounter as
                        \ we do

 LDA #0                 \ Draw a blank icon into the top part of the screen (via
 JSR DrawIcon           \ the icon screen buffer at iconBuffer) and move along
                        \ to the right, incrementing xIconCounter as we do

 JMP ener1              \ Loop back to ener1 to draw another high-energy robot,
                        \ if required

.ener2

 LDA loopCounter        \ If loopCounter < 3 then we can't represent it with a
 CMP #3                 \ blue robot (as that represents three energy points),
 BCC ener3              \ so jump to ener3 to skip to the next level down

 SBC #3                 \ Subtract 3 from the loop counter as we are about to
 STA loopCounter        \ draw a high-energy robot that represents three energy
                        \ points (this subtraction works because we just passed
                        \ through a BCC, so the C flag must be set)

 LDA #1                 \ Draw a blue robot into the top part of the screen (via
 JSR DrawIcon           \ the icon screen buffer at iconBuffer) and move along
                        \ to the right, incrementing xIconCounter as we do

 LDA #0                 \ Draw a blank icon into the top part of the screen (via
 JSR DrawIcon           \ the icon screen buffer at iconBuffer) and move along
                        \ to the right, incrementing xIconCounter as we do

 JMP ener2              \ Loop back to ener2 to draw another blue robot, if
                        \ required

.ener3

                        \ If we get here then the value of loopCounter in A must
                        \ be 0, 1 or 2, as otherwise we would still be drawing
                        \ robots

 CMP #1                 \ If A < 1 then A must be zero, so jump to ener4 to move
 BCC ener4              \ on to the scanner as we have no more energy points to
                        \ draw

 ASL A                  \ If we get here then A is 1 or 2, so double it to get
                        \ the correct icon numbers for the left part of the
                        \ two-part tree or boulder icons:
                        \
                        \   * When A = 1, double it to 2 for the left tree icon
                        \
                        \   * When A = 2, double it to 4 for the left boulder
                        \     icon

 JSR DrawIcon           \ Draw the correct left icon into the top part of the
                        \ screen (via the icon screen buffer at iconBuffer) and
                        \ move along to the right, incrementing xIconCounter as
                        \ we do

 CLC                    \ Increment A to get the correct icon number for the
 ADC #1                 \ right part of the tree or boulder

 JSR DrawIcon           \ Draw the correct right icon into the top part of the
                        \ screen (via the icon screen buffer at iconBuffer) and
                        \ move along to the right, incrementing xIconCounter as
                        \ we do

                        \ We have updated the energy icons, so now we blank the
                        \ rest of the top line of the screen before drawing the
                        \ outline of the scanner

.ener4

 LDA #0                 \ Draw a blank icon into the top part of the screen (via
 JSR DrawIcon           \ the icon screen buffer at iconBuffer) and move along
                        \ to the right, incrementing xIconCounter as we do

 LDA xIconCounter       \ Loop back to keep drawing blank icons until we reach
 CMP #29                \ column 29, which is where we want to draw the scanner
 BCC ener4

 LDA #7                 \ Draw the left edge of the scanner box into the top
 JSR DrawIcon           \ part of the screen (via the icon screen buffer at
                        \ iconBuffer) and move along to the right, incrementing
                        \ xIconCounter as we do

.ener5

 LDA #8                 \ Draw the middle part of the scanner box into the top
 JSR DrawIcon           \ part of the screen (via the icon screen buffer at
                        \ iconBuffer) and move along to the right, incrementing
                        \ xIconCounter as we do

 LDA xIconCounter       \ Loop back to keep drawing the middle part of the
 CMP #38                \ scanner box until we reach column 38
 BCC ener5

 LDA #9                 \ Draw the right edge of the scanner box into the top
 JSR DrawIcon           \ part of the screen (via the icon screen buffer at
                        \ iconBuffer) and move along to the right, incrementing
                        \ xIconCounter as we do

 LDA #0                 \ Draw a blank icon into the top part of the screen (via
 JSR DrawIcon           \ the icon screen buffer at iconBuffer) and move along
                        \ to the right

 JMP DisplayIconBuffer  \ Display the contents of the icon screen buffer by
                        \ copying it into screen memory, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: DrawIcon
\       Type: Subroutine
\   Category: Graphics
\    Summary: Draw a single icon in the top-left corner of the screen (via the
\             icon screen buffer at iconBuffer) and move along to the right
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The type of icon to draw:
\
\                         * 0 = Blank
\
\                         * 1 = Robot
\
\                         * 2 = Tree (left)
\
\                         * 3 = Tree (right)
\
\                         * 4 = Boulder (left)
\
\                         * 5 = Boulder (right)
\
\                         * 6 = High-energy robot
\
\                         * 7 = Scanner box (left)
\
\                         * 8 = Scanner box (middle)
\
\                         * 9 = Scanner box (right)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   A is preserved
\
\ ******************************************************************************

.DrawIcon

 PHA                    \ Store the icon type on the stack so we can preserve it

 ASL A                  \ Set X = (A * 8) + 7
 ASL A                  \
 ASL A                  \ Each icon definition in iconData contains eight bytes,
 ORA #7                 \ so we can use this as an index into iconData, where it
 TAX                    \ points to the last of the eight bytes for icon A (as
                        \ we added 7 to A * 8 with the ORA instruction)

                        \ We now calculate the address of the icon in the screen
                        \ buffer at iconBuffer
                        \
                        \ The icon needs to be drawn in column xIconCounter,
                        \ where each column is eight pixels wide, and because
                        \ the screen is split into 8x8-pixel character blocks of
                        \ eight bytes in each, the icon is in screen memory at
                        \ this address, which we store in (Q P): 
                        \
                        \   (Q P) = iconBuffer + xIconCounter * 8
                        \
                        \ This is calculated by doing half the sum first, and
                        \ then doubling the result, like this:
                        \
                        \   (iconBuffer / 2) + (xIconCounter * 4)
                        \
                        \ The calculation is done this way to cater for values
                        \ of xIconCounter between 32 and 39, as multiplying 32
                        \ by 8 won't fit into one byte, but multiplying by 4
                        \ will fit (and doubling just requires a simple shift)

 LDA xIconCounter       \ Set P = xIconCounter * 4 + LO(iconBuffer / 2)
 ASL A                  \      
 ASL A                  \ so those are the low bytes
 ADC #LO(iconBuffer)/2
 STA P

 LDA #HI(iconBuffer)/2  \ Set A = 0 + HI(iconBuffer / 2)
 ADC #0                 \
                        \ and those are the high bytes, with the result of the
                        \ half sum in (A P)

 ASL P                  \ Set (Q P) = (A P) * 2
 ROL A                  \           = iconBuffer + xIconCounter * 8
 STA Q                  \
                        \ So we now have the address within the icon screen
                        \ buffer for the icon we want to draw

 LDY #7                 \ We now copy eight bytes of icon data into the icon
                        \ screen buffer at iconBuffer

.deni1

 LDA iconData,X         \ Copy the X-th byte of icon data to the Y-th byte of
 STA (P),Y              \ (Q P)

 DEX                    \ Decrement the source byte counter

 DEY                    \ Decrement the destination byte counter

 BPL deni1              \ Loop back until we have copied all eight bytes

 INC xIconCounter       \ Increment the icon counter to move along to the right
                        \ by one column, as we just drew an icon

 PLA                    \ Restore the icon type into A that we stored on the
                        \ stack above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: IRQHandler
\       Type: Subroutine
\   Category: Main game loop
\    Summary: The main interrupt handler, which gets run 50 times a second to
\             update the game state and check for game key presses
\
\ ------------------------------------------------------------------------------
\
\ This routine is called exactly 50 times a second, and it does the following:
\
\   * Count down the sound timer
\
\   * If a game is not in progress (i.e. we are in the title screen rather than
\     playing a landscape), return from the handler
\
\   * If the Sentinel has won, then call sub_C56D9 (if bit 7 of L0C4D is set),
\     and return from the handler
\
\   * If the game is paused, scan for the pause and volume keys and return from
\     the handler
\
\   * If a game is in progress and the Sentinel has not won and the game is not
\     paused, then:
\
\     * If scrollCounter is non-zero then call ScrollPlayerView (which
\       decrements scrollCounter) and DisplayIconBuffer
\
\     * If the Sentinel has been activated, call sub_C12EE and sub_C1623
\
\     * If bit 7 of doNotScanKeyboard is clear then keyboard scans are enabled,
\       so scan for and process all the game keys
\
\ ******************************************************************************

.irqh1

 JMP (irq1Address)      \ Jump to the original address from IRQ1V to pass
                        \ control to the next interrupt handler

.IRQHandler

 SEI                    \ Disable interrupts so the following process isn't
                        \ interrupted by another interrupt

 LDA SHEILA+&6D         \ Set A to the 6522 User VIA interrupt flag register IFR
                        \ (SHEILA &6D)

 AND #%01000000         \ If bit 6 of the IFR is clear then this interrupt has
 BEQ irqh1              \ not been triggered by the 6522 User VIA timer 1
                        \ reaching zero, so jump to irqh1 to pass the interrupt
                        \ on to the next interrupt handler

                        \ If we get here then bit 6 of the IFR is set, so this
                        \ interrupt has been triggered by the 6522 User VIA
                        \ timer 1 reaching zero

 STA SHEILA+&6D         \ The AND instruction above leaves A containing bit 6
                        \ set and all other bits clear, so we can write this to
                        \ the IFR at SHEILA &6D to clear the timer 1 interrupt

 LDA &FC                \ Set A to the interrupt accumulator save register,
                        \ which restores A to the value it had on entering the
                        \ interrupt

 PHA                    \ Store A, X and Y on the stack so we can preserve them
 TXA                    \ across calls to the interrupt handler
 PHA
 TYA
 PHA

 CLD                    \ Clear the D flag to switch arithmetic to normal, in
                        \ case the interrupt was triggered during any BCD
                        \ calculations

 DEC soundCounter       \ Decrement the sound counter so we can detect when the
 BPL irqh2              \ current sound effect has finished, making sure it
 INC soundCounter       \ doesn't go below zero

.irqh2

 LDA gameInProgress     \ If bit 7 of gameInProgress is set then a game is not
 BMI irqh8              \ currently in progress and we are in the title and
                        \ preview screens, so jump to irqh8 to skip the
                        \ following and return from the interrupt handler
                        \ without updating the game state

 LDA sentinelHasWon     \ If bit 7 of sentinelHasWon is set then the Sentinel
 BMI irqh7              \ has won the game, so jump to irqh7 to ??? and return
                        \ from the interrupt handler

 LDA gamePaused         \ If bit 7 of gamePaused is set then the game is paused,
 BMI irqh5              \ so jump to irqh5 to scan for the unpause and volume
                        \ keys and return from the interrupt handler

 LDA scrollCounter      \ If scrollCounter = 0 then we do not need to scroll the
 BEQ irqh3              \ player's landscape view, so jump to irqh3 to skip the
                        \ scrolling process

                        \ If we get here then we still have scrollCounter steps
                        \ to complete in the current scrolling process, so we
                        \ now do one scrolling step (ScrollPlayerView decrements
                        \ the counter in scrollCounter)

 JSR ScrollPlayerView   \ Scroll the screen and copy data from the view screen
                        \ buffer into screen memory to implement the player's
                        \ scrolling landscape view

 JSR DisplayIconBuffer  \ Display the contents of the icon screen buffer by
                        \ copying it into screen memory, as the scrolling
                        \ process will have scrolled this part of the screen, so
                        \ we need to redraw it to prevent the energy icons and
                        \ scanner from moving

.irqh3

 LDA activateSentinel   \ If bit 7 of activateSentinel is set then the Sentinel
 BMI irqh4              \ has not yet been activated at the start of the game,
                        \ so jump to irqh4 to skip the following

 JSR sub_C12EE          \ ???

 JSR sub_C1623          \ ???

.irqh4

 LDA doNotScanKeyboard  \ If bit 7 of doNotScanKeyboard is set then keyboard
 BMI irqh8              \ scans are disabled, so jump to irqh8 to skip the
                        \ following

 JSR CheckForKeyPresses \ Check for various game key presses and update the key
                        \ logger and relevant variables

 JMP irqh8              \ Jump to irqh8 to return from the interrupt handler

.irqh5

                        \ If we get here then the game is paused, so we scan for
                        \ key presses and discard them all except for the
                        \ unpause and volume keys

 LDY #13                \ Scan the keyboard for all game keys in the gameKeys
 JSR ScanForGameKeys    \ table except for the last one ("U" for U-turn)

                        \ We now reset the first three entries in the key
                        \ logger (i.e. entries 0 to 2), leaving the last entry
                        \ populated (i.e. entry 3, which records the volume,
                        \ paue and unpause key presses)

 LDX #2                 \ Set a loop counter in X for resetting three entries

 LDA #%10000000         \ Set A = %10000000 to reset the three entries, as the
                        \ set bit 7 indicates an empty entry in the logger

.irqh6

 STA keyLogger,X        \ Reset the X-th entry in the key logger

 DEX                    \ Decrement the loop counter

 BPL irqh6              \ Loop back until we have reset all four entries

 JMP irqh8              \ Jump to irqh8 to return from the interrupt handler

.irqh7

                        \ If we get here then the Sentinel has won the game

 LDA L0C4D              \ If bit 7 of L0C4D is clear, skip the following to
 BPL irqh8              \ return from the interrupt handler ???

 JSR sub_C56D9          \ ???

.irqh8

 PLA                    \ Restore A, X and Y from the stack
 TAY
 PLA
 TAX
 PLA

 RTI                    \ Return from the interrupt handler

\ ******************************************************************************
\
\       Name: ScrollPlayerView
\       Type: Subroutine
\   Category: Graphics
\    Summary: Scroll the screen and copy data from the view screen buffer into
\             screen memory to implement the player's scrolling landscape view
\
\ ******************************************************************************

.ScrollPlayerView

 LDY lastPanKeyPressed  \ Set Y to the direction of the last pan key that was
                        \ pressed (which may still be being held down)
                        \
                        \ So this contains the direction of any scrolling that
                        \ we still need to apply, as follows:
                        \
                        \   * 0 = pan right
                        \
                        \   * 1 = pan left
                        \
                        \   * 2 = pan up
                        \
                        \   * 3 = pan down
                        \
                        \ We use this as an index into various tables, to look
                        \ up the correct values for the direction in which we
                        \ want to scroll

                        \ We now scroll the screen in the correct direction to
                        \ pan the player's scrolling landscape view
                        \
                        \ Note that we scroll the screen in the opposite
                        \ direction to the pan direction, so if we are panning
                        \ right we move the screen to the left, for example
                        \
                        \ The screen address of the player's scrolling landscape
                        \ view is stored in viewScreenAddr(1 0), so this is the
                        \ address of the screen just below the energy icon and
                        \ scanner row
                        \
                        \ We therefore start the scrolling process by updating
                        \ the screen address in viewScreenAddr(1 0) to point to
                        \ the new address after scrolling
                        \
                        \ Scrolling is done in individual steps, as follows:
                        \
                        \   * When scrolling horizontally, we scroll by one
                        \     column that's one character block wide (i.e. one
                        \     byte, two pixels wide)
                        \
                        \   * When scrolling vertically, we scroll by one row
                        \     that's one character block tall (i.e. eight bytes,
                        \     eight pixels tall)
                        \
                        \ The amount of change that we need to apply to
                        \ viewScreenAddr(1 0) for each of the four directions is
                        \ given in the tables scrollScreenHi and scrollScreenLo,
                        \ as 16-bit signed values, so we just need to look up
                        \ the correct value and apply it to viewScreenAddr(1 0)
                        \
                        \ For example, we advance viewScreenAddr(1 0) by eight
                        \ bytes when panning right, as we need to scroll the
                        \ screen to the left, so the start of the screen in
                        \ memory moves on by eight bytes (one character block)
                        \
                        \ This would scroll the screen to the left by two pixels
                        \ as each character block is two pixels wide
                        \
                        \ Similarly, we reduce viewScreenAddr(1 0) by 320 bytes
                        \ when panning up, as we need to scroll the screen down,
                        \ so the start of the screen in memory moves on by eight
                        \ bytes (one character row of 40 character blocks with
                        \ eight bytes per character block)
                        \
                        \ This would scroll the screen to down by eight pixels
                        \ as each character row is eight pixels wide

 LDA viewScreenAddr     \ Apply the change in (scrollScreenHi scrollScreenLo)
 CLC                    \ for the current pan direction in Y to the screen
 ADC scrollScreenLo,Y   \ address of the player's scrolling landscape, which is
 STA viewScreenAddr     \ stored in viewScreenAddr(1 0)
 LDA viewScreenAddr+1   \
 ADC scrollScreenHi,Y   \ We start by calculating this:
                        \
                        \   (A viewScreenAddr) = viewScreenAddr(1 0)
                        \                  + (scrollScreenHi+Y scrollScreenLo+Y)

 CMP #&80               \ If the high byte in A >= &80 then the new address is
 BCC scro1              \ past the end of screen memory, so subtract &20 from
 SBC #&20               \ the high byte so the address wraps around within the
                        \ range of screen memory between &6000 and &8000
                        \
                        \ If the high byte is in range, jump to scro1 to check
                        \ the high byte against the start of screen memory

 JMP scro2              \ Jump to scro2 to skip the next check, as we know it
                        \ doesn't apply

.scro1

 CMP #&60               \ If the high byte in A < &60 then the new address is
 BCS scro2              \ before the start of screen memory, so add &20 to the
 ADC #&20               \ high byte so the address wraps around within the range
                        \ of screen memory between &6000 and &8000

.scro2

 STA viewScreenAddr+1   \ Store the high byte of the result, so we now have:
                        \
                        \   viewScreenAddr(1 0) = viewScreenAddr(1 0)
                        \                  + (scrollScreenHi+Y scrollScreenLo+Y)
                        \
                        \ with the address wrapped around as required

                        \ We now reprogram the 6845 CRTC chip to scroll the
                        \ screen in hardware (so-called "hardware scrolling")
                        \ by setting 6845 registers R12 and R13 to the new
                        \ address for the start of screen memory
                        \
                        \ The registers actually require the address to be set
                        \ in terms of character rows, so we need to set R12 and
                        \ R12 to the address divided by 8 (see below)

 JSR GetIconRowAddress  \ Set iconRowAddr(1 0) to the address in screen memory
                        \ of the icon and scanner row at the top of the screen
                        \
                        \ This calculates the address from viewScreenAddr(1 0),
                        \ so the value returned will be the new start of screen
                        \ memory, after the scroll is completed
                        \
                        \ It also sets A to the high byte of the address of
                        \ screen memory in iconRowAddr(1 0)

 STA screenAddrHi       \ Set (screenAddrHi A) = iconRowAddr(1 0) / 8
 LDA iconRowAddr        \
 LSR screenAddrHi       \ So (screenAddrHi A) contains the new address of screen
 ROR A                  \ memory, divided by 8, which is suitable for passing to
 LSR screenAddrHi       \ the 6845 CRTC to change the address of screen memory
 ROR A
 LSR screenAddrHi
 ROR A

 LDX #13                \ Set 6845 register R13 = A, for the low byte
 STX SHEILA+&00         \
 STA SHEILA+&01         \ We do this by writing the register number (13) to
                        \ SHEILA &00, and then the value (A) to SHEILA &01

 LDX #12                \ Set 6845 register R12 = &0F, for the high byte
 STX SHEILA+&00         \
 LDA screenAddrHi       \ We do this by writing the register number (12) to
 STA SHEILA+&01         \ SHEILA &00, and then the value (screenAddrHi) to
                        \ SHEILA &01

                        \ This sets 6845 registers (R12 R13) = (screenAddrHi A)
                        \ to point to the start of screen memory in terms of
                        \ character rows. There are 8 pixel lines in each
                        \ character row, so to get the actual address of the
                        \ start of screen memory, we multiply by 8:
                        \
                        \   (screenAddrHi A) * 8
                        \
                        \ which is iconRowAddr(1 0), as set above
                        \
                        \ So this whole thing sets the start of screen memory to
                        \ the address of iconRowAddr(1 0), which scrolls the
                        \ screen by the required amount

 DEC scrollCounter      \ Decrement the scroll counter, as we have just scrolled
                        \ the screen by one more step

                        \ We now set viewScreenAddr(1 0) to the new address of
                        \ the start of the player's landscape view, so that's
                        \ the address of the top-left corner of the view, just
                        \ below the energy icon and scanner bar at the top of
                        \ the screen
                        \
                        \ We now need to set toAddr(1 0) to the address in
                        \ screen memory that we need to update now that the
                        \ screen has been scrolled
                        \
                        \ Scrolling the screen leads to the following update
                        \ requirements:
                        \
                        \   * When scrolling the screen to the left, we need to
                        \     update the column on the right
                        \
                        \   * When scrolling the screen to the right, we need to
                        \     update the column on the left
                        \
                        \   * When scrolling the screen down, we need to update
                        \     the row along the top
                        \
                        \   * When scrolling the screen up, we need to update
                        \     the row along the bottom
                        \
                        \ We want to set toAddr(1 0) to the address of the area
                        \ in screen memory that we need to update, and the
                        \ offset within screen memory of this area for each of
                        \ the four directions is given in the tables at
                        \ updateOffsetHi and updateOffsetLo, as 16-bit signed
                        \ values, so we just need to look up the correct offset
                        \ and apply it to viewScreenAddr(1 0) to get the address
                        \ of the area of screen memory we need to update

 LDA viewScreenAddr     \ Set toAddr(1 0) to the screen address of the player's
 CLC                    \ scrolling landscape, plus the offset for the current
 ADC updateOffsetLo,Y   \ pan direction from (updateOffsetHi updateOffsetLo)
 STA toAddr             \
 LDA viewScreenAddr+1   \ We start by calculating this:
 ADC updateOffsetHi,Y   \
                        \   (A toAddr) = viewScreenAddr(1 0)
                        \                  + (updateOffsetHi+Y updateOffsetLo+Y)

 CMP #&80               \ If the high byte in A >= &80 then the new address is
 BCC scro3              \ past the end of screen memory, so subtract &20 from
 SBC #&20               \ the high byte so the address wraps around within the
                        \ range of screen memory between &6000 and &8000

.scro3

 STA toAddr+1           \ Store the high byte of the result, so we now have:
                        \
                        \   toAddr(1 0) = viewScreenAddr(1 0)
                        \                  + (updateOffsetHi+Y updateOffsetLo+Y)
                        \
                        \ with the address wrapped around as required

                        \ By this point we now done the following to implement
                        \ the required screen scrolling:
                        \
                        \  * Updated viewScreenAddr(1 0) to the new address of
                        \    the player's scrolling landscape
                        \
                        \  * Updated the 6845 to scroll the screen by changing
                        \    the address of screen memory
                        \
                        \  * Decremented the counter in scrollCounter
                        \
                        \  * Set toAddr(1 0) to the address of the area in
                        \    screen memory that we now need to update
                        \
                        \ We can now fall through into DisplayViewBuffer to
                        \ copy the contents of the view screen buffer into the
                        \ area we need to update, so that the scroll reveals the
                        \ correct part of the view

\ ******************************************************************************
\
\       Name: DisplayViewBuffer
\       Type: Subroutine
\   Category: Graphics
\    Summary: Update the player's scrolling landscape view by copying the
\             relevant parts of the view screen buffer into screen memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The direction of scrolling that we just applied:
\
\                         * 0 = pan right
\                        
\                         * 1 = pan left
\                        
\                         * 2 = pan up
\                        
\                         * 3 = pan down
\
\   toAddr(1 0)         The address of the area in screen memory that we need to
\                       update with the contents of the view screen buffer
\
\ ******************************************************************************

.DisplayViewBuffer

                        \ We start by setting both viewBufferAddr(1 0) and
                        \ fromAddr(1 0) to the address in the view screen
                        \ buffer of the content that we need to copy into the
                        \ screen area following the scroll ???
                        \
                        \ We do this by taking the current value of the address
                        \ in viewBufferAddr(1 0) and applying the change in
                        \ (scrollScreenHi scrollScreenLo) for the current pan
                        \ direction in Y, just as we did when we updated the
                        \ screen address in viewScreenAddr(1 0) in the
                        \ ScrollPlayerView routine

 LDA viewBufferAddr     \ Add (scrollScreenHi scrollScreenLo) for this pan
 CLC                    \ direction to the address in viewBufferAddr(1 0),
 ADC scrollScreenLo,Y   \ starting with the low bytes
 STA viewBufferAddr

 STA fromAddr           \ Store the low byte of the result in fromAddr(1 0)

 LDA viewBufferAddr+1   \ And then add the high bytes
 ADC scrollScreenHi,Y
 STA viewBufferAddr+1

 STA fromAddr+1         \ Store the high byte of the result in fromAddr(1 0), so
                        \ fromAddr(1 0) = viewBufferAddr(1 0) ???

 CPY #2                 \ If Y >= 2 then we are panning up or down, and we are
 BCS DisplayBufferRow   \ scrolling down or up, so jump to DisplayBufferRow to
                        \ update the player's scrolling landscape view by
                        \ copying an eight-pixel high character row from the
                        \ view screen buffer into screen memory

                        \ Otherwise we are panning left or right, and we are
                        \ scrolling right or left or up, so fall througn into
                        \ DisplayBufferColumn update the player's scrolling
                        \ landscape view by copying a two-pixel wide column from
                        \ the view screen buffer into screen memory

\ ******************************************************************************
\
\       Name: DisplayBufferColumn
\       Type: Subroutine
\   Category: Graphics
\    Summary: Update the player's scrolling landscape view by copying a 2-pixel
\             wide column from the view screen buffer into screen memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   fromAddr(1 0)       The source address from which we copy the character
\                       column
\
\   toAddr(1 0)         The destination address to which we copy the character
\                       column
\
\ ******************************************************************************

.DisplayBufferColumn

 LDX #24                \ The custom screen mode 5 used by the game contains 25
                        \ character rows, each of which is eight pixels high, so
                        \ set a row counter in X to count the character rows in
                        \ the view screen buffer, which is one row less than the
                        \ screen height, as the top row is the energy icon and
                        \ scanner row 

.dcol1

 JSR DisplayBufferBlock \ Copy an eight-byte 8x2-pixel character block from the
                        \ view screen buffer at fromAddr(1 0) into screen memory
                        \ at toAddr(1 0)

 LDA fromAddr           \ Set (A fromAddr) = fromAddr(1 0) + &140
 CLC                    \                  = fromAddr(1 0) + 320
 ADC #&40               \
 STA fromAddr           \ Each character row in screen mode 5 takes up 320 bytes
 LDA fromAddr+1         \ (40 characters of eight bytes each), so this sets
 ADC #&01               \ fromAddr(1 0) to the address of the next row down in
                        \ the view screen buffer

 CMP #&53               \ If the result of the addition is less than &5300, then
 BNE dcol2              \ we have not reached the end of the view screen buffer,
                        \ so jump to dcol2 to skip the following

                        \ The address in (A fromAddr) is now greater than &5300,
                        \ so it has gone past the end of the view screen buffer,
                        \ so we now set the following:
                        \
                        \   (A fromAddr) = viewBufferAddr(1 0) + 160
                        \
                        \ So this wraps the address around to the start of the
                        \ view screen buffer for when we go past the end of the
                        \ buffer ???

 LDA viewBufferAddr     \ Calculate the following:
 CLC                    \
 ADC #&A0               \   (A fromAddr) = viewBufferAddr(1 0) + &A0
 STA fromAddr           \                = viewBufferAddr(1 0) + 160
 LDA viewBufferAddr+1    
 ADC #&00

.dcol2

 STA fromAddr+1         \ Store the high byte of the result, so we now have:
                        \
                        \   fromAddr(1 0) = fromAddr(1 0) + 320
                        \
                        \ with the address wrapped around as required

 LDA toAddr             \ Set (A toAddr) = toAddr(1 0) + &140
 CLC                    \                = toAddr(1 0) + 320
 ADC #&40
 STA toAddr             
 LDA toAddr+1
 ADC #&01

 CMP #&80               \ If the high byte in A >= &80 then the new address is
 BCC dcol3              \ past the end of screen memory, so subtract &20 from
 SBC #&20               \ the high byte so the address wraps around within the
                        \ range of screen memory between &6000 and &8000

.dcol3

 STA toAddr+1           \ Store the high byte of the result, so we now have:
                        \
                        \   toAddr(1 0) = toAddr(1 0) + 320
                        \
                        \ with the address wrapped around as required

 DEX                    \ Decrement the counter in X to move on to the next
                        \ character row down

 BNE dcol1              \ Loop back until we have copied all 24 character blocks
                        \ in the column from fromAddr(1 0) to toAddr(1 0)

 JMP drow3              \ Jump to drow3 to return from the subroutine, as drow3
                        \ contains an RTS

\ ******************************************************************************
\
\       Name: DisplayBufferRow
\       Type: Subroutine
\   Category: Graphics
\    Summary: Update the player's scrolling landscape view by copying an 8-pixel
\             high character row from the view screen buffer into screen memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   fromAddr(1 0)       The source address from which we copy the character row
\
\   toAddr(1 0)         The destination address to which we copy the character
\                       row
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   drow3               Contains an RTS
\
\ ******************************************************************************

.DisplayBufferRow

 LDX #40                \ Each character row in screen mode 5 contains 40
                        \ character blocks of eight bytes, so set a block
                        \ counter in X to count the character blocks

.drow1

 JSR DisplayBufferBlock \ Copy an eight-byte 8x2-pixel character block from the
                        \ view screen buffer at fromAddr(1 0) into screen memory
                        \ at toAddr(1 0)

 LDA fromAddr           \ Set fromAddr(1 0) = fromAddr(1 0) + 8
 CLC                    \
 ADC #8                 \ So this moves the from address to the next character
 STA fromAddr           \ block in the character row
 LDA fromAddr+1
 ADC #0
 STA fromAddr+1

 LDA toAddr             \ Set (A toAddr) = toAddr(1 0) + 8
 CLC
 ADC #8
 STA toAddr
 LDA toAddr+1
 ADC #0

 CMP #&80               \ If the high byte in A >= &80 then the new address is
 BCC drow2              \ past the end of screen memory, so subtract &20 from
 SBC #&20               \ the high byte so the address wraps around within the
                        \ range of screen memory between &6000 and &8000

.drow2

 STA toAddr+1           \ Store the high byte of the result, so we now have:
                        \
                        \   toAddr(1 0) = toAddr(1 0) + 8
                        \
                        \ with the address wrapped around as required

 DEX                    \ Decrement the counter in X to move on to the next
                        \ character block in the row

 BNE drow1              \ Loop back until we have copied all 40 character blocks
                        \ in the character row from fromAddr(1 0) to toAddr(1 0)

.drow3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DisplayBufferBlock
\       Type: Subroutine
\   Category: Graphics
\    Summary: Update the player's scrolling landscape view by copying an 8-byte
\             character block from the view screen buffer into screen memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   fromAddr(1 0)       The source address from which we copy the eight-byte
\                       character block
\
\   toAddr(1 0)         The destination address to which we copy the eight-byte
\                       character block
\
\ ******************************************************************************

.DisplayBufferBlock

 LDY #0                 \ Copy byte #0 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #1 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #2 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #3 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #4 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #5 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #6 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 INY                    \ Copy byte #7 of fromAddr(1 0) to toAddr(1 0)
 LDA (fromAddr),Y
 STA (toAddr),Y

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: updateOffsetLo
\       Type: Variable
\   Category: Graphics
\    Summary: The offset within screen memory for the player's landscape view
\             of the area to update following a scroll (low byte)
\
\ ******************************************************************************

.updateOffsetLo

 EQUB LO(320 - 8)       \ Direction 0 = 320 - 8 (pan right, scroll left)
 EQUB LO(0)             \ Direction 1 = 0 (pan left, scroll right)
 EQUB LO(0)             \ Direction 2 = 0 (pan up, scroll down)
 EQUB LO(320 * 23)      \ Direction 3 = 320 * 23 (pan down, scroll up)

\ ******************************************************************************
\
\       Name: updateOffsetHi
\       Type: Variable
\   Category: Graphics
\    Summary: The offset within screen memory for the player's landscape view
\             of the area to update following a scroll (high byte)
\
\ ******************************************************************************

.updateOffsetHi

 EQUB HI(320 - 8)       \ Direction 0 = 320 - 8 (pan right, scroll left)
 EQUB HI(0)             \ Direction 1 = 0 (pan left, scroll right)
 EQUB HI(0)             \ Direction 2 = 0 (pan up, scroll down)
 EQUB HI(320 * 23)      \ Direction 3 = 320 * 23 (pan down, scroll up)

\ ******************************************************************************
\
\       Name: scrollScreenLo
\       Type: Variable
\   Category: Graphics
\    Summary: The amount to change the start of screen memory in order to scroll
\             the player's landscape view through each direction (low byte)
\
\ ******************************************************************************

.scrollScreenLo

 EQUB LO(+8)            \ Direction 0 = +8 (pan right, scroll left)
 EQUB LO(-8)            \ Direction 1 = -8 (pan left, scroll right)
 EQUB LO(-320)          \ Direction 2 = -320 (pan up, scroll down)
 EQUB LO(+320)          \ Direction 3 = +320 (pan down, scroll up)

\ ******************************************************************************
\
\       Name: scrollScreenHi
\       Type: Variable
\   Category: Graphics
\    Summary: The amount to change the start of screen memory in order to scroll
\             the player's landscape view through each direction (high byte)
\
\ ******************************************************************************

.scrollScreenHi

 EQUB HI(+8)            \ Direction 0 = +8 (pan right, scroll left)
 EQUB HI(-8)            \ Direction 1 = -8 (pan left, scroll right)
 EQUB HI(-320)          \ Direction 2 = -320 (pan up, scroll down)
 EQUB HI(+320)          \ Direction 3 = +320 (pan down, scroll up)

\ ******************************************************************************
\
\       Name: viewBufferAddrHi
\       Type: Variable
\   Category: Graphics
\    Summary: The value to add to updateOffsetHi for each direction to get the
\             high byte of the view screen buffer address in viewBufferAddr(1 0)
\
\ ******************************************************************************

.viewBufferAddrHi

 EQUB HI(viewBufferRight - (320 - 8))   \ Direction 0 (pan right, scroll left)
 EQUB HI(viewBufferLeft)                \ Direction 1 (pan left, scroll right)
 EQUB HI(viewBufferUp)                  \ Direction 2 (pan up, scroll down)
 EQUB HI(viewBufferDown - (320 * 23))   \ Direction 3 (pan down, scroll up)

\ ******************************************************************************
\
\       Name: viewBufferAddrLo
\       Type: Variable
\   Category: Graphics
\    Summary: The value to add to updateOffsetLo for each direction to get the
\             low byte of the view screen buffer address in viewBufferAddr(1 0)
\
\ ******************************************************************************

.viewBufferAddrLo

 EQUB LO(viewBufferRight - (320 - 8))   \ Direction 0 (pan right, scroll left)
 EQUB LO(viewBufferLeft)                \ Direction 1 (pan left, scroll right)
 EQUB LO(viewBufferUp)                  \ Direction 2 (pan up, scroll down)
 EQUB LO(viewBufferDown - (320 * 23))   \ Direction 3 (pan down, scroll up)

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
\       Name: SetNumberOfScrolls
\       Type: Subroutine
\   Category: Graphics
\    Summary: Start a scroll process by setting the number of scroll steps and
\             the address in viewBufferAddr(1 0) ???
\
\ ******************************************************************************

.SetNumberOfScrolls

 STA numberOfScrolls    \ Store the number of scroll steps required in the
                        \ variable
                        \
                        \ When this variable is non-zero, the interrupt routine
                        \ will scroll the screen by this many steps in the
                        \ background

                        \ Fall through into SetViewBufferAddr to set the address
                        \ in viewBufferAddr(1 0) ???

\ ******************************************************************************
\
\       Name: SetViewBufferAddr
\       Type: Subroutine
\   Category: Graphics
\    Summary: Set the address in viewBufferAddr(1 0) ???
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   Y                   The direction of scrolling that we are applying:
\
\                         * 0 = pan right
\                        
\                         * 1 = pan left
\                        
\                         * 2 = pan up
\                        
\                         * 3 = pan down
\
\ ******************************************************************************

.SetViewBufferAddr

 LDA viewBufferAddrLo,Y \ Set viewBufferAddr(1 0) to the Y-th entry from the
 STA viewBufferAddr     \ viewBufferAddrHi and viewBufferAddrLo lookup tables
 LDA viewBufferAddrHi,Y \ ???
 STA viewBufferAddr+1

 RTS                    \ Return from the subroutine

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
                        \ Y is never zero)

\ ******************************************************************************
\
\       Name: MoveSights
\       Type: Subroutine
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.MoveSights

 JSR MoveSightsSideways

 LDA panKeyBeingPressed
 BPL sigh1

 JSR MoveSightsUpDown

.sigh1

 JMP ShowSights

\ ******************************************************************************
\
\       Name: MoveSightsSideways
\       Type: Subroutine
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.MoveSightsSideways

 LDX keyLogger          \ Set X to the key logger entry for "S" and "D" (pan
                        \ left, pan right), which are used to move the sights

 BMI sisd4
 BNE sisd2

                        \ If we get here then X = 0, so "D" is being pressed,
                        \ which is the key for moving the sights right

 LDA xSights            \ Increment xSights to move the sights right
 CLC
 ADC #1

 CMP #&90
 BCC sisd1
 SBC #&40
 STX panKeyBeingPressed

.sisd1

 STA xSights
 AND #&03
 BEQ siud5
 JMP sisd4

.sisd2

                        \ If we get here then X = 1, so "S" is being pressed,
                        \ which is the key for moving the sights left

 LDA xSights            \ Increment xSights to move the sights left
 SEC
 SBC #1

 CMP #&10
 BCS sisd3
 ADC #&40
 STX panKeyBeingPressed

.sisd3

 STA xSights
 AND #&03
 CMP #&03
 BEQ siud5

.sisd4

 RTS

\ ******************************************************************************
\
\       Name: MoveSightsUpDown
\       Type: Subroutine
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.MoveSightsUpDown

 LDX playerObject       \ Set Y to the current pitch angle of the player
 LDY objectPitchAngle,X

 LDX keyLogger+2        \ Set X to the key logger entry for "L" and "," (pan
                        \ up, pan down), which are used to move the sights

 BMI siud8              \ If there is no key press in the key logger entry, jump
                        \ to siud8 to ???

                        \ If we get here then "L" or "," is being pressed, which
                        \ will put 2 or 3 into the key logger respectively

 CPX #2                 \ If X <> 2 then "," is being pressed (pan down), so
 BNE siud2              \ jump to siud2 to move the sights down

                        \ If we get here then X = 2, so "L" is being pressed,
                        \ which is the key for moving the sights up

 LDA ySights            \ Increment ySights to move the sights up
 CLC
 ADC #1

 CMP #&A0
 BCC siud1
 CPY L1147
 BEQ siud8
 SEC
 SBC #&40
 STX panKeyBeingPressed

.siud1

 STA ySights
 AND #&07
 BNE siud5
 JMP siud4

.siud2

                        \ If we get here then X <> 2, so "," is being pressed,
                        \ which is the key for moving the sights down

 LDA ySights            \ Decrement ySights to move the sights down
 SEC
 SBC #1

 CMP #&20
 BCS siud3
 CPY L1148
 BEQ siud8
 CLC
 ADC #&40
 STX panKeyBeingPressed

.siud3

 STA ySights
 AND #&07
 CMP #&07
 BNE siud5

.siud4

 INX
 INX

.siud5

 LDA L0CC4
 CLC
 ADC L3AC7,X
 STA L0CC4
 LDA L0CC5
 ADC L3ACD,X
 CMP #&80
 BCC siud6
 SBC #&20
 JMP siud7

.siud6

 CMP #&60
 BCS siud7
 ADC #&20

.siud7

 STA L0CC5

.siud8

 RTS

\ ******************************************************************************
\
\       Name: ShowSights
\       Type: Subroutine
\   Category: Sights
\    Summary: Draw the sights on the screen
\
\ ******************************************************************************

.ShowSights

 LDA L0CD7
 BMI C3A05
 JSR HideSights
 LDA xSights
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
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.L3A8A

 EQUB &80, &40, &20, &10

\ ******************************************************************************
\
\       Name: L3A8E
\       Type: Variable
\   Category: Sights
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
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.L3A9A

 EQUB &00, &02, &02, &01, &00, &00, &00, &00
 EQUB &00, &01, &02, &02, &80

\ ******************************************************************************
\
\       Name: HideSights
\       Type: Subroutine
\   Category: Sights
\    Summary: Remove the sights from the screen
\
\ ******************************************************************************

.HideSights

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
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.L3AC7

 EQUB &08, &F8, &FF, &01, &C7, &39

\ ******************************************************************************
\
\       Name: L3ACD
\       Type: Variable
\   Category: Sights
\    Summary: ???
\
\ ******************************************************************************

.L3ACD

 EQUB &00, &FF, &FF, &00, &FE, &01

\ ******************************************************************************
\
\       Name: GetIconRowAddress
\       Type: Subroutine
\   Category: Graphics
\    Summary: Calculate the address in screen memory of the icon and scanner row
\             at the top of the screen
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The high byte of the address in iconRowAddr(1 0)
\
\ ******************************************************************************

.GetIconRowAddress

 LDA viewScreenAddr     \ Set iconRowAddr(1 0) = viewScreenAddr(1 0) - &0140
 SEC                    \                      = viewScreenAddr(1 0) - 320
 SBC #&40               \
 STA iconRowAddr        \ starting with the low bytes

 LDA viewScreenAddr+1   \ And then the high bytes
 SBC #&01

 CMP #&60               \ If the result of the subtraction is less than &6000,
 BCS gicn1              \ add &2000 to wrap it around so the result is within
 ADC #&20               \ screen memory from &6000 and up

.gicn1

 STA iconRowAddr+1      \ Store the high byte of the result in iconRowAddr(1 0),
                        \ so we have the following:
                        \
                        \   iconRowAddr(1 0) = viewScreenAddr(1 0) - 320
                        \
                        \ Each character row in screen mode 5 takes up 320 bytes
                        \ (40 characters of eight bytes each), so this sets
                        \ iconRowAddr(1 0) to the address of the character row
                        \ just above the player's scrolling landscape view,
                        \ which is in screen memory at viewScreenAddr(1 0)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DisplayIconBuffer
\       Type: Subroutine
\   Category: Graphics
\    Summary: Display the redrawn icon and scanner row by copying the contents
\             of the icon screen buffer into screen memory
\
\ ******************************************************************************

.DisplayIconBuffer

 LDA #HI(iconBuffer)    \ Set fromAddr(1 0) = iconBuffer(1 0)
 STA fromAddr+1         \
 LDA #LO(iconBuffer)    \ So the call to DisplayBufferRow copies from the icon
 STA fromAddr           \ screen buffer, which contains the redrawn icon and
                        \ scanner row

 LDA iconRowAddr+1      \ Set toAddr(1 0) = iconRowAddr(1 0)
 STA toAddr+1           \
 LDA iconRowAddr        \ So the call to DisplayBufferRow copies from the icon
 STA toAddr             \ screen buffer into the screen memory for the icon and
                        \ scanner row at the top of the screen

 JMP DisplayBufferRow   \ Jump to DisplayBufferRow to copy the contents of the
                        \ icon screen buffer into screen memory ???

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

  EQUB LO(INT(0.5 + 32 * ATN(I% / 256) * 256 / ATN(1)))

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

  EQUB HI(INT(0.5 + 32 * ATN(I% / 256) * 256 / ATN(1)))

 NEXT

\ ******************************************************************************
\
\       Name: tanHalfAngle
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Table for hypotenuse lengths given the tangent of an angle
\
\ ------------------------------------------------------------------------------
\
\ Given the tangent of an angle, X = tan(theta), this table contains the
\ following at index X:
\
\   tanHalfAngle,X = 2 * tan(theta / 2)
\
\ The table contains lookup values for indexes 0 to 128, which correspond to
\ theta angles of 0 to 45 degrees.
\
\ This allows us to approximate the length of the hypotenuse of a triangle with
\ angle theta, adjacent side a and opposite side b, as follows:
\
\   h =~ a + b * tan(theta / 2)
\
\ ******************************************************************************

.tanHalfAngle

 EQUB 0

 FOR I%, 1, 128

  EQUB INT(0.5 + 2 * 256 * TAN(ATN(I% / 128) / 2))

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
\       Name: secretCodeStash
\       Type: Subroutine
\   Category: Landscape
\    Summary: A stash for calculated values for each iteration in the
\             CheckSecretCode routine
\
\ ******************************************************************************

.secretCodeStash

 SKIP 128               \ This variable overwrites the startup routines as they
                        \ aren't needed again, and it shares memory with the
                        \ view screen buffer

\ ******************************************************************************
\
\       Name: viewBufferLeft
\       Type: Subroutine
\   Category: Graphics
\    Summary: The view screen buffer for buffering the new part of the player's
\             scrolling landscape view when panning right (scrolling left)
\
\ ******************************************************************************

.viewBufferLeft

 SKIP 0                 \ This variable overwrites the startup routines as they
                        \ aren't needed again, and it shares memory with the
                        \ secret code stash

 CLEAR secretCodeStash, P%
 ORG secretCodeStash

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

 SEC                    \ Set bit 7 of gameInProgress to indicate that a game is
 ROR gameInProgress     \ not currently in progress and that we are in the title
                        \ and preview screens (so the interrupt handler doesn't
                        \ progress the game)
                        \
                        \ This code is never actually run in this location
                        \ (identical code can be found at the start of the
                        \ ResetVariables routine)

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
                        \ (otherwise crackers could load the game on MOS 0.10
                        \ and simply press BREAK to access the loaded game code)
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

                        \ We now set timer 1 in the 6522 User VIA to count down
                        \ regularly, triggering the interrupt handler routine at
                        \ IRQHandler every time it counts down
                        \
                        \ The timer is initially set to count down from 14,592
                        \ to zero, and then a value of 19,998 is latched into
                        \ the timer so that it triggers the interrupt every time
                        \ it counts down from 20,000 to zero (the latching
                        \ process takes two ticks, which gives us a total count
                        \ of 20,000)
                        \
                        \ The timer counts down at 1 MHz. or one million times a
                        \ second, so this means the interrupt is triggered every
                        \ 0.02 seconds, or exactly 50 times a second
                        \
                        \ This regular interrupt is used to progress the game
                        \ counters and manage the screen panning effect (see the
                        \ IRQHandler routine for details)

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

 JMP MainTitleLoop      \ Jump to MainTitleLoop to start the main title loop,
                        \  wherewe display the title screen, fetch the landscape
                        \ number and code, preview the landscape and then jump
                        \ to the main game loop

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

 EQUB &20, &65, &74, &73, &36, &0D, &12, &CA    \ These bytes are unused until
 EQUB &19, &20, &20, &20, &20, &20, &20, &4C    \ the game is in progress, at
 EQUB &44, &58, &23, &36, &3A, &4A, &53, &52    \ which point this whole section
 EQUB &20, &43, &46, &4C, &53, &48, &0D, &12    \ of memory is reused
 EQUB &D4, &05, &20, &0D, &12, &DE              \
                                                \ The initial contents is just
                                                \ workspace noise and is ignored
                                                \
                                                \ It actually contains snippets
                                                \ of the original source code

\ ******************************************************************************
\
\       Name: viewBufferRight
\       Type: Subroutine
\   Category: Graphics
\    Summary: The view screen buffer for buffering the new part of the player's
\             scrolling landscape view when panning left (scrolling right)
\
\ ------------------------------------------------------------------------------
\
\ The initial contents of the variable is just workspace noise and is ignored.
\ It actually contains snippets of the original source code.
\
\ ******************************************************************************

.viewBufferRight

 EQUB &0D, &2E, &65, &74, &73, &36, &20, &72
 EQUB &74, &73, &0D, &12, &E8, &05, &20, &0D
 EQUB &12, &F2, &05, &20, &0D, &12, &FC, &05
 EQUB &20, &0D, &13, &06, &05, &20, &0D, &13
 EQUB &10, &05, &20, &0D, &13, &1A, &05, &20
 EQUB &0D, &13, &24, &05, &20, &0D, &13, &2E
 EQUB &2A, &2E, &4D, &49, &4E, &49, &20, &4C
 EQUB &44, &41, &23, &31, &32, &38, &3A, &53
 EQUB &54, &41, &20, &4D, &45, &41, &4E, &59
 EQUB &2C, &58, &3A, &53, &54, &41, &20, &4D
 EQUB &45, &4D, &4F, &52, &59, &2C, &58, &0D
 EQUB &13, &38, &1F, &20, &20, &20, &20, &20
 EQUB &20, &4C, &44, &41, &23, &30, &3A, &53
 EQUB &54, &41, &20, &4D, &45, &41, &4E, &59
 EQUB &53, &43, &41, &4E, &2C, &58, &0D, &13
 EQUB &42, &22, &20, &20, &20, &20, &20, &20
 EQUB &4C, &44, &41, &23, &36, &34, &3A, &53
 EQUB &54, &41, &20, &4D, &54, &52, &59, &43
 EQUB &4E, &54, &2C, &58, &3A, &72, &74, &73
 EQUB &0D, &13, &4C, &05, &20, &0D, &13, &56
 EQUB &1A, &2E, &4D, &45, &41, &4E, &20, &4C
 EQUB &44, &41, &23, &34, &30, &3A, &53, &54
 EQUB &41, &20, &43, &4F, &56, &45, &52, &0D
 EQUB &13, &60, &1B, &20, &20, &20, &20, &20
 EQUB &20, &4C, &44, &58, &20, &45, &54, &45
 EQUB &4D, &3A, &53, &54, &58, &20, &58, &54

 SKIPTO &4900           \ All bytes from &4100 to &48FF are zeroes and appear
                        \ to be unused

\ ******************************************************************************
\
\       Name: viewBufferUp
\       Type: Subroutine
\   Category: Graphics
\    Summary: The view screen buffer for buffering the new part of the player's
\             scrolling landscape view when panning up (scrolling down)
\
\ ******************************************************************************

.viewBufferUp

 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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
\       Name: L49A0
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L49A0

 EQUB &00, &1D, &33, &44, &4C, &5E, &7C
 EQUB &88, &90, &98, &A0

\ ******************************************************************************
\
\       Name: L49AB
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L49AB

 EQUB &00, &1B, &34, &43
 EQUB &4D, &66, &89, &94, &98, &9C, &A0

\ ******************************************************************************
\
\       Name: L49B6
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L49B6

 EQUB &03
 EQUB &03, &00, &00, &02, &03, &00, &00, &00
 EQUB &00, &00

\ ******************************************************************************
\
\       Name: L49C1
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L49C1

 EQUB &00, &00, &00, &00, &00, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF

\ ******************************************************************************
\
\       Name: L49CD
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L49CD

 EQUB &47, &4C
 EQUB &4B, &46, &47, &40, &45, &42, &40, &41
 EQUB &44, &40, &41, &40, &44, &43, &40, &40
 EQUB &43, &45, &40, &42, &45, &44, &41, &42
 EQUB &45, &46, &49, &45, &44, &48, &47, &44
 EQUB &45, &49, &48, &44, &45, &43, &46, &45
 EQUB &43, &44, &47, &43, &44, &43, &47, &46
 EQUB &43, &4B, &4A, &46, &4B, &47, &4D, &4C
 EQUB &47, &4B, &4E, &4A, &4B, &4C, &4D, &4F
 EQUB &4C, &4C, &4F, &4E, &4B, &4C, &46, &4A
 EQUB &49, &46, &47, &48, &4D, &47, &4A, &50
 EQUB &49, &4A, &48, &51, &4D, &48, &4A, &4E
 EQUB &50, &4A, &4D, &51, &4F, &4D, &49, &50
 EQUB &51, &48, &49, &4F, &51, &50, &4E, &4F

\ ******************************************************************************
\
\       Name: objRotationSpeed
\       Type: Variable
\   Category: 3D objects
\    Summary: The angle through which each object rotates on each scheduled
\             rotation
\
\ ******************************************************************************

.objRotationSpeed

 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &FF, &FF, &FF, &FF, &FF, &7F, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF
 EQUB &FF, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00
 EQUB &00, &00, &00, &00, &00, &00, &00, &00

 EQUB &00, &00, &00, &00, &00, &00, &00, &00    \ These bytes appear to be
 EQUB &10, &FE, &FE, &FF, &FF, &FF, &FF, &FF    \ unused
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
 EQUB &FF

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

 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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

 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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

 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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

 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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

 EQUB &FE, &FE, &FF, &FF, &FF, &FF, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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

 EQUB &FF, &FF, &FF, &FF, &FF, &7F, &FF, &FF    \ These bytes appear to be
 EQUB &FF, &FF, &FF, &FF, &FF, &FF, &FF, &FF    \ unused
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
\       Name: sub_C5567
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.C5560

 STA angleTangent
 STA angleLo
 STA angleHi
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
 STA bHi
 LDA L0082
 STA bLo
 LDA L0080
 STA aLo
 LDA L0083
 STA aHi
 JMP C55A5

.C5588

 LDA L0083
 STA bHi
 LDA L0080
 STA bLo
 LDA L0082
 STA aLo
 LDA L0085
 STA aHi
 ORA L0082
 BEQ C5560
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

 JSR GetAngleFromCoords \ Calculate the following angle:
                        \
                        \   (angleHi angleLo) = arctan( (A T) / (V W) )

 LDA L0086
 EOR L0088
 BMI C55D1
 LDA #0
 SEC
 SBC angleLo
 STA angleLo
 LDA #0
 SBC angleHi
 STA angleHi

.C55D1

 LDA #&40
 BIT L0086
 BPL C55D9
 LDA #&C0

.C55D9

 CLC
 ADC angleHi
 STA angleHi
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

 JSR GetAngleFromCoords \ Calculate the following angle:
                        \
                        \   (angleHi angleLo) = arctan( (A T) / (V W) )

 LDA L0086
 EOR L0088
 BPL C560F
 LDA #0
 SEC
 SBC angleLo
 STA angleLo
 LDA #0
 SBC angleHi
 STA angleHi

.C560F

 LDA #0
 BIT L0088
 BPL C5617
 LDA #&80

.C5617

 CLC
 ADC angleHi
 STA angleHi
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
 LDA hypotenuseLo
 STA L0082
 LDA hypotenuseHi
 STA L0085
 LDA #0
 STA L0088
 JSR sub_C5567
 LDA angleLo
 SEC
 SBC #&20
 STA L0050
 LDA angleHi
 SBC objectPitchAngle,X
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
\       Name: GetHypotenuse
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the hypotenuse from an angle and two triangle sides with
\             one lookup and one multiplication (so without a square root)
\
\ ------------------------------------------------------------------------------
\
\ This routine calculates:
\
\   (hypotenuseHi hypotenuseLo) = (aHi aLo) + tan(theta / 2) * (bHi bLo)
\
\ for a triangle with angle theta, adjacent side a and opposite side b.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   angleTangent        The triangle angle theta
\
\   (aHi aLo)           The length of a, the adjacent side of the triangle
\
\   (bHi bLo)           The length of b, the opposite side of the triangle
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.GetHypotenuse

 STY yStoreHypotenuse   \ Store Y in yStoreHypotenuse so it can be preserved
                        \ across calls to the routine

 LDA angleTangent       \ Set Y = angleTangent / 2
 LSR A                  \
 ADC #0                 \ The ADC instruction rounds the result to the nearest
 TAY                    \ integer
                        \
                        \ The value of angleTangent ranges from 0 to 255 to
                        \ represent the tangent of angles 0 to 45 degrees, but
                        \ the tanHalfAngle table ranges from 0 to 128 to
                        \ represent the same range of angles, so we have to
                        \ halve angleTangent so we can use it as an index into
                        \ the tanHalfAngle table to fetch the tangent of the
                        \ half angle

 LDA tanHalfAngle,Y     \ Set U = 2 * tan(theta / 2)
 STA U

 LDA bLo                \ Set (V T) = (bHi bLo)
 STA T
 LDA bHi
 STA V

 JSR Multiply8x16       \ Set (U T) = U * (V T) / 256
                        \           = 2 * tan(theta / 2) * (bHi bLo)

 LSR U                  \ Set (U T) = (U T) / 2
 ROR T                  \           = tan(theta / 2) * (bHi bLo)

 LDA T                  \ Calculate:
 CLC                    \
 ADC aLo                \  (hypotenuseHi hypotenuseLo)
 STA hypotenuseLo       \
 LDA U                  \     = (aHi aLo) + (U T)
 ADC aHi                \
 STA hypotenuseHi       \     = (aHi aLo) + tan(theta / 2) * (bHi bLo)

 LDY yStoreHypotenuse   \ Restore the value of Y from yStoreHypotenuse that we
                        \ stored at the start of the routine, so that it's
                        \ preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: yStoreHypotenuse
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Temporary storage for Y so it can be preserved through calls to
\             GetHypotenuse
\
\ ******************************************************************************

.yStoreHypotenuse

 EQUB 65                \ This value is workspace noise and has no meaning

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
 LDA viewScreenAddr
 CLC
 ADC L0022
 STA L0022
 LDA viewScreenAddr+1
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

 EQUB &FF, &FF          \ These bytes appear to be unused
 EQUB &FF, &FF

\ ******************************************************************************
\
\       Name: PrintCharacter
\       Type: Subroutine
\   Category: Text
\    Summary: Print a single-byte VDU command or character from a text token,
\             optionally printing a drop shadow if the character is alphanumeric
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The one-byte character to be printed
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X is preserved
\
\ ******************************************************************************

.PrintCharacter

 BIT textDropShadow     \ If bit 7 of textDropShadow is set, jump to byte2 to
 BMI byte2              \ print the character in A as-is (i.e. without a drop
                        \ shadow if it is alphanumeric)

 CMP #' '               \ If the character in A is a control character, jump to
 BCC byte2              \ byte2 to print the character as-is

 CMP #127               \ If the character in A is a top-bit-set character, jump
 BCS byte2              \ jump to byte2 to print the character as-is

                        \ If we get here then bit 7 of textDropShadow is clear
                        \ and the character in A is alphanumeric, so now we
                        \ print the character with a drop shadow
                        \
                        \ We do this by printing the sequence of VDU commands at
                        \ vduShadowRear and vduShadowFront, which produce the
                        \ drop shadow effect
                        \
                        \ The drop shadow is printed by first printing the VDU
                        \ commands in vduShadowRear, to print the rear character
                        \ in yellow, and then in vduShadowFront, to print the
                        \ front character in red or cyan
                        \
                        \ The rear character is offset down from the front
                        \ character by four graphics units, which equates to an
                        \ offset of one pixel in mode 5
                        \
                        \ The VDU commands are printed backwards, because that
                        \ makes the loop condition slightly simpler, and it also
                        \ means we can poke the character to print into the
                        \ start of each block of VDU commands, knowing that they
                        \ will then be printed last in each VDU sequence

 STA vduShadowFront     \ Insert the character to be printed into the sequence
 STA vduShadowRear      \ of VDU commands at vduShadowRear and vduShadowFront,
                        \ so that they print the required character with a drop
                        \ shadow

 TXA                    \ Store X on the stack so we can preserve it
 PHA

 LDX #22                \ The vduShadowRear and vduShadowFront variables contain
                        \ a total of 23 VDU command bytes, so set a byte counter
                        \ in X so we can work through them from the end of
                        \ vduShadowRear backwards to the start of vduShadowFront

.byte1

 LDA vduShadowFront,X   \ Print the X-th character from the vduShadowRear and
 JSR OSWRCH             \ vduShadowFront variables

 DEX                    \ Decrement the byte counter

 BPL byte1              \ Loop back until we have printed all 23 command bytes

 PLA                    \ Retrieve X from the stack so it is preserved across
 TAX                    \ calls to the routine

 RTS                    \ Return from the subroutine

.byte2

 JMP OSWRCH             \ We jump here if drop shadows are disabled, or if A is
                        \ not alphanumeric, in which case print the character in
                        \ A and return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PrintVduCharacter
\       Type: Subroutine
\   Category: Text
\    Summary: Print a one-byte character from a text token or a multi-byte
\             VDU 25 command
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to be printed
\
\   Y                   The offset of the current character within the text
\                       token being printed
\
\ ******************************************************************************

.PrintVduCharacter

 CMP #25                \ If the character in A = 25, jump to prin2 to print a
 BEQ prin2              \ six-byte command in the form VDU 25, n, x; y;
                        \
                        \ We print the VDU 25 commands in its own loop because
                        \ the 16-bit arguments to the command (x and y) might
                        \ contain &FF, and we don't want this to be
                        \ misidentified as the end of the text token

 JMP PrintCharacter     \ Otherwise jump to PrintCharacter to print the single-
                        \ byte VDU command or character in A, returning from the
                        \ subroutine using a tail call

.prin1

 INY                    \ Increment the offset of the character being printed to
                        \ move on to the next character in the token

 LDA tokenBase,Y        \ Set A to the next character to print

.prin2

 JSR OSWRCH             \ Print the next character in the VDU 25 command (we
                        \ jump here from above with A = 25, which starts off
                        \ the six-byte VDU sequence)

 DEC vduCounter         \ Decrement the byte counter in vduCounter, which is
                        \ always 6 when we jump into this loop

 BNE prin1

 LDA #6                 \ Reset the byte counter in vduCounter to 6, ready for
 STA vduCounter         \ the next time we perform a VDU 25 command

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: vduCounter
\       Type: Variable
\   Category: Text
\    Summary: The number of bytes in a VDU 25, n, x; y; command
\
\ ******************************************************************************

.vduCounter

 EQUB 6

\ ******************************************************************************
\
\       Name: tokenOffset
\       Type: Variable
\   Category: Text
\    Summary: Address offsets for the text tokens (each offset in the table is
\             the offset of the token from tokenBase)
\
\ ******************************************************************************

.tokenOffset

 EQUB token0 - tokenBase
 EQUB token1 - tokenBase
 EQUB token2 - tokenBase
 EQUB token3 - tokenBase
 EQUB token4 - tokenBase
 EQUB token5 - tokenBase
 EQUB token6 - tokenBase
 EQUB token7 - tokenBase
 EQUB token8 - tokenBase
 EQUB token9 - tokenBase
 EQUB token10 - tokenBase
 EQUB token11 - tokenBase
 EQUB token12 - tokenBase
 EQUB token13 - tokenBase
 EQUB token14 - tokenBase
 EQUB token15 - tokenBase
 EQUB token16 - tokenBase
 EQUB token17 - tokenBase

.tokenBase

\ ******************************************************************************
\
\       Name: vduShadowFront
\       Type: Variable
\   Category: Text
\    Summary: VDU commands for printing the front character of a drop shadow
\
\ ------------------------------------------------------------------------------
\
\ The VDU commands below are printed by working backwards through the table, so
\ the letter to be printed is actually the first entry in the table.
\
\ A drop shadow is printed by first printing the VDU commands in vduShadowRear,
\ to print the rear character in yellow, and then in vduShadowFront, to print
\ the front character in red or cyan. The rear character is offset down from the
\ front character by four graphics units, which equates to an offset of one
\ pixel in mode 5.
\
\ ******************************************************************************

.vduShadowFront

 EQUB "C"               \ 9. Print the character in red or cyan, for the front
                        \ character of the drop shadow
                        \
                        \ The "C" is replaced by the character to be printed

 EQUB 2, 0, 18          \ 8. VDU 18, 0, 2
                        \
                        \ Set the foreground colour to colour 2 (red or cyan,
                        \ depending on the current palette)

 EQUB &00, &04          \ 7. VDU 25, 0, 0; 4;
 EQUW 0                 \
 EQUB 0, 25             \ Move the graphics cursor relative to the last position
                        \ by (0, 4), so we move up the screen by four units, or
                        \ one pixel in mode 5

 EQUB 8                 \ 6. VDU 8
                        \
                        \ Backspace the cursor by one character, so it is on top
                        \ of the yellow character that we just printed in
                        \ vduShadowRear

\ ******************************************************************************
\
\       Name: vduShadowRear
\       Type: Variable
\   Category: Text
\    Summary: VDU commands for printing the rear character of a drop shadow
\
\ ------------------------------------------------------------------------------
\
\ The VDU commands below are printed by working backwards through the table, so
\ the letter to be printed is actually the first entry in the table.
\
\ A drop shadow is printed by first printing the VDU commands in vduShadowRear,
\ to print the rear character in yellow, and then in vduShadowFront, to print
\ the front character in red or cyan. The rear character is offset down from the
\ front character by four graphics units, which equates to an offset of one
\ pixel in mode 5.
\
\ ******************************************************************************

.vduShadowRear

 EQUB "C"               \ 5. Print the character in yellow, for the rear
                        \ character of the drop shadow
                        \
                        \ The "C" is replaced by the character to be printed

 EQUB 3, 0, 18          \ 4. VDU 18, 0, 3
                        \
                        \ Set the foreground colour to colour 3 (yellow)

 EQUB &FF, &FC          \ 3. VDU 25, 0, 0; -4;
 EQUW 0                 \
 EQUB 0, 25             \ Move the graphics cursor relative to the last position
                        \ by (0, -4), so we move down the screen by four units,
                        \ or one pixel in mode 5

 EQUB 127               \ 2. Print a backspace to move the cursor back over the
                        \ top of the space we just printed

 EQUS " "               \ 1. Print a space to clear the screen for the new drop
                        \ shadow character

\ ******************************************************************************
\
\       Name: token0
\       Type: Variable
\   Category: Text
\    Summary: Background colour blue, print "PRESS ANY KEY" at (64, 100), set
\             text background to black
\
\ ******************************************************************************

.token0

 EQUB 200 + 10          \ Text token 10: Configure text to be printed at the
                        \ graphics cursor and set the background colour to
                        \ colour 0 (blue)

 EQUB 200 + 12          \ Text token 12: Move graphics cursor to (64, 100)

 EQUB 200 + 17          \ Text token 17: Print "PRESS ANY KEY"

 EQUB 17, 129           \ VDU 17, 129
                        \
                        \ Set text background to colour 1 (black)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token1
\       Type: Variable
\   Category: Text
\    Summary: Print 13 spaces at (64, 100), print "LANDSCAPE NUMBER?" at
\             (64, 768), switch to text cursor, move text cursor to (5, 27)
\
\ ******************************************************************************

.token1

 EQUB 200 + 12          \ Text token 12: Move graphics cursor to (64, 100)

 EQUB 200 + 15          \ Text token 15: Print five spaces

 EQUB 200 + 15          \ Text token 15: Print five spaces

 EQUB 200 + 16          \ Text token 16: Print three spaces

 EQUB 200 + 7           \ Text token 7: Move the graphics cursor to (64, 768)

 EQUB 200 + 13          \ Text token 13: Print "LANDSCAPE"

 EQUS " NUMBER?"        \ Print " NUMBER?"

 EQUB 4                 \ VDU 4
                        \
                        \ Write text at the text cursor

 EQUB 31, 5, 27         \ VDU 31, 5, 27
                        \
                        \ Move the text cursor to (5, 27)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token2
\       Type: Variable
\   Category: Text
\    Summary: Background colour blue, print "SECRET ENTRY CODE?" at (64, 768),
\             switch to text cursor, move text cursor to (2, 27)
\
\ ******************************************************************************

.token2

 EQUB 200 + 10          \ Text token 10: Configure text to be printed at the
                        \ graphics cursor and set the background colour to
                        \ colour 0 (blue)

 EQUB 200 + 7           \ Text token 7: Move the graphics cursor to (64, 768)

 EQUB 200 + 14          \ Text token 14: Print "SECRET ENTRY CODE"

 EQUS "?"               \ Print "?"

 EQUB 4                 \ VDU 4
                        \
                        \ Write text at the text cursor

 EQUB 31, 3, 27         \ VDU 31, 3, 27
                        \
                        \ Move the text cursor to (2, 27)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token3
\       Type: Variable
\   Category: Text
\    Summary: Background colour blue, print "WRONG SECRET CODE" at (64, 768),
\             print "PRESS ANY KEY" at (64, 100), set text background to black
\
\ ******************************************************************************

.token3

 EQUB 200 + 10          \ Text token 10: Configure text to be printed at the
                        \ graphics cursor and set the background colour to
                        \ colour 0 (blue)

 EQUB 200 + 7           \ Text token 7: Move the graphics cursor to (64, 768)

 EQUS "WRONG SECRET "   \ Print "WRONG SECRET CODE"
 EQUS "CODE"

 EQUB 200 + 0           \ Text token 0: Background colour blue, print "PRESS
                        \ ANY KEY" at (64, 100), set text background to black

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token4
\       Type: Variable
\   Category: Text
\    Summary: Background colour black, print "PRESS ANY KEY" at (192, 64), print
\             "LANDSCAPE" two chars right of (64, 768), move cursor right
\
\ ******************************************************************************

.token4

 EQUB 200 + 11          \ Text token 11: Configure text to be printed at the
                        \ graphics cursor and set the background colour to
                        \ colour 1 (black)

 EQUB 200 + 9           \ Text token 9: Move the graphics cursor to (192, 64)

 EQUB 200 + 17          \ Text token 17: Print "PRESS ANY KEY"

 EQUB 200 + 7           \ Text token 7: Move the graphics cursor to (64, 768)

 EQUB 9, 9              \ VDU 9, 9
                        \
                        \ Move the cursor right by two characters

 EQUB 200 + 13          \ Text token 13: Print "LANDSCAPE"

 EQUB 9                 \ VDU 9
                        \
                        \ Move the cursor right by one character, so it moves on
                        \ to the next character

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token5
\       Type: Variable
\   Category: Text
\    Summary: Text token 5: Print "SECRET ENTRY CODE" at (64, 768), "LANDSCAPE"
\             at (192, 704), move cursor right
\
\ ******************************************************************************

.token5

 EQUB 200 + 7           \ Text token 7: Move the graphics cursor to (64, 768)

 EQUB 200 + 14          \ Text token 14: Print "SECRET ENTRY CODE"

 EQUB 200 + 8           \ Text token 8: Move the graphics cursor to (192, 704)

 EQUB 200 + 13          \ Text token 13: Print "LANDSCAPE"

 EQUB 9                 \ VDU 9
                        \
                        \ Move the cursor right by one character, so it moves on
                        \ to the next character

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token6
\       Type: Variable
\   Category: Text
\    Summary: Text token 6: Print "PRESS ANY KEY" at (64, 100)
\
\ ******************************************************************************

.token6

 EQUB 200 + 12          \ Text token 12: Move graphics cursor to (64, 100)

 EQUB 200 + 17          \ Text token 17: Print "PRESS ANY KEY"

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token7
\       Type: Variable
\   Category: Text
\    Summary: Text token 7: Move the graphics cursor to (64, 768)
\
\ ******************************************************************************

.token7

 EQUB 25, 4             \ VDU 25, 4, 64; 768;
 EQUW 64                \
 EQUW 768               \ Move graphics cursor to absolute position (64, 768)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token8
\       Type: Variable
\   Category: Text
\    Summary: Text token 8: Move the graphics cursor to (192, 704)
\
\ ******************************************************************************

.token8

 EQUB 25, 4             \ VDU 25, 4, 192; 704;
 EQUW 192               \
 EQUW 704               \ Move graphics cursor to absolute position (192, 704)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token9
\       Type: Variable
\   Category: Text
\    Summary: Text token 9: Move the graphics cursor to (192, 64)
\
\ ******************************************************************************

.token9

 EQUB 25, 4             \ VDU 25, 4, 192; 64;
 EQUW 192               \
 EQUW 64                \ Move graphics cursor to absolute position (192, 64)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token10
\       Type: Variable
\   Category: Text
\    Summary: Text token 10: Configure text to be printed at the graphics cursor
\             and set the background colour to colour 0 (blue)
\
\ ******************************************************************************

.token10

 EQUB 5                 \ VDU 5
                        \
                        \ Write text at the graphics cursor rather than the text
                        \ cursor

 EQUB 18, 0, 128        \ VDU 18, 0, 128
                        \
                        \ Set the background colour to colour 0 (blue)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token11
\       Type: Variable
\   Category: Text
\    Summary: Text token 11: Configure text to be printed at the graphics cursor
\             and set the background colour to colour 1 (black)
\
\ ******************************************************************************

.token11

 EQUB 5                 \ VDU 5
                        \
                        \ Write text at the graphics cursor rather than the text
                        \ cursor

 EQUB 18, 0, 129        \ VDU 18, 0, 129
                        \
                        \ Set the background colour to colour 1 (black)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token12
\       Type: Variable
\   Category: Text
\    Summary: Text token 12: Move graphics cursor to (64, 100)
\
\ ******************************************************************************

.token12

 EQUB 25, 4             \ VDU 25, 4, 64; 160;
 EQUW 64                \
 EQUW 160               \ Move graphics cursor to absolute position (64, 100)

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token13
\       Type: Variable
\   Category: Text
\    Summary: Text token 13: Print "LANDSCAPE"
\
\ ******************************************************************************

.token13

 EQUS "LANDSCAPE"

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token14
\       Type: Variable
\   Category: Text
\    Summary: Text token 14: Print "SECRET ENTRY CODE"
\
\ ******************************************************************************

.token14

 EQUS "SECRET ENTRY CODE"

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token15
\       Type: Variable
\   Category: Text
\    Summary: Text token 15: Print five spaces
\
\ ******************************************************************************

.token15

 EQUS "     "

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token16
\       Type: Variable
\   Category: Text
\    Summary: Text token 16: Print three spaces
\
\ ******************************************************************************

.token16

 EQUS "   "

 EQUB &FF               \ End of token

\ ******************************************************************************
\
\       Name: token17
\       Type: Variable
\   Category: Text
\    Summary: Text token 17: Print "PRESS ANY KEY"
\
\ ******************************************************************************

.token17

 EQUS "PRESS ANY KEY"

 EQUB &FF               \ End of token

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
\       Name: iconData
\       Type: Variable
\   Category: Graphics
\    Summary: Screen mode 5 bitmap data for the ten icons that make up the
\             energy icon and scanner row at the top of the screen
\
\ ******************************************************************************

.iconData

 EQUB &0F, &0F, &0F, &0F, &0F, &0F, &0F, &0F    \ Icon #0: Blank

 EQUB &6F, &0F, &00, &06, &09, &09, &0F, &0F    \ Icon #1: Robot

 EQUB &2F, &2F, &7A, &7A, &FA, &2D, &0F, &0F    \ Icon #2: Tree (left)

 EQUB &0F, &0F, &0F, &0F, &8F, &0F, &0F, &0F    \ Icon #3: Tree (right)

 EQUB &0F, &0F, &78, &D2, &87, &87, &0F, &0F    \ Icon #4: Boulder (left)

 EQUB &0F, &0F, &0F, &87, &87, &87, &0F, &0F    \ Icon #5: Boulder (right)

 EQUB &6F, &0F, &FF, &9F, &6F, &6F, &0F, &0F    \ Icon #6: High-energy robot

 EQUB &1E, &1E, &1E, &1E, &1E, &1E, &0F, &0F    \ Icon #7: Scanner box (left)

 EQUB &F0, &0F, &0F, &0F, &0F, &F0, &0F, &0F    \ Icon #8: Scanner box (middle)

 EQUB &87, &87, &87, &87, &87, &87, &0F, &0F    \ Icon #9: Scanner box (right)

\ ******************************************************************************
\
\       Name: soundData
\       Type: Variable
\   Category: Sound
\    Summary: OSWORD blocks for making the various game sounds
\
\ ------------------------------------------------------------------------------
\
\ Sound data. To make a sound, the MakeSound routine passes the bytes in this
\ table to OSWORD 7. These bytes are the OSWORD equivalents of the parameters
\ passed to the SOUND keyword in BASIC. The parameters have these meanings:
\
\   channel/flush, amplitude (or envelope number if 1-4), pitch, duration
\
\ where each value consists of two bytes, with the low byte first and the high
\ byte second.
\
\ For the channel/flush parameter, the top nibble of the low byte is the flush
\ control (where a flush control of 0 queues the sound, and a flush control of
\ 1 makes the sound instantly), while the bottom nibble of the low byte is the
\ channel number. When written in hexadecimal, the first figure gives the flush
\ control, while the second is the channel (so &13 indicates flush control = 1
\ and channel = 3).
\
\ ******************************************************************************

.soundData

 EQUB &10, &00          \ Sound data block #0: SOUND &10, 1, 7, 5
 EQUB &01, &00          \
 EQUB &07, &00          \ Used for the first part of sounds #0 and #1 (???)
 EQUB &05, &00

 EQUB &11, &00          \ Sound data block #1: SOUND &11, 0, 120, 10
 EQUB &00, &00          \
 EQUB &78, &00          \ Used for the second part of sounds #0 and #1 (???)
 EQUB &0A, &00

 EQUB &12, &00          \ Sound data block #2: SOUND &12, 3, 34, 20
 EQUB &03, &00          \
 EQUB &22, &00          \ Used for sounds #3 and #4 (???)
 EQUB &14, &00

 EQUB &13, &00          \ Sound data block #3: SOUND &13, 4, 144, 20
 EQUB &04, &00          \
 EQUB &90, &00          \ Used for sound #5 (ping)
 EQUB &14, &00

 EQUB &10, &00          \ Sound data block #4: SOUND &10, 2, 4, 40
 EQUB &02, &00          \
 EQUB &04, &00          \ Used for sound #2 (???)
 EQUB &28, &00

\ ******************************************************************************
\
\       Name: envelopeData
\       Type: Variable
\   Category: Sound
\    Summary: Data for the six sound envelopes
\
\ ------------------------------------------------------------------------------
\
\ There are six sound envelopes defined in The Sentinel.
\
\   * Envelope 0 is used for sounds #0 and #1 (???).
\
\   * Envelope 1 is used for sound #2 (???).
\
\   * Envelope 2 is used for sound #3 (???).
\
\   * Envelope 3 is used for sound #4 (???).
\
\   * Envelope 4 is used for sound #5 (ping).
\
\   * Envelope 5 is used for sound #6 (???).
\
\ ******************************************************************************

.envelopeData

 EQUB 1, 2, 0, 0, 0, 0, 0, 0, 20, 0, -20, -20, 120, 120

 EQUB 2, 4, 0, 0, 0, 0, 0, 0, 2, -1, 0, 0, 120, 120

 EQUB 4, 2, 1, -1, 0, 1, 1, 8, 120, -1, 0, -1, 120, 8

 EQUB 3, 1, 6, -6, 0, 1, 1, 0, 1, -1, 0, 0, 120, 8

 EQUB 4, &82, 1, -1, 0, 2, 1, 7, 120, -6, -2, -2, 120, 0

 EQUB 1, 1, 0, 0, 0, 0, 0, 0, 120, -120, -1, -1, 120, 0

 EQUB 0, 0, 0, 0        \ These bytes appear to be unused

\ ******************************************************************************
\
\       Name: sin
\       Type: Variable
\   Category: Maths (Geometry)
\    Summary: Table for sine values
\
\ ------------------------------------------------------------------------------
\
\ This table contains sine values for a quarter of a circle, i.e. for the range
\ 0 to 90 degrees, or 0 to PI/2 radians. The table contains values for indexes
\ 0 to 127, which cover the quarter from 0 to PI/2 radians. Entry X in the table
\ is therefore (X / 128) * (PI / 2) radians of the way round the quarter circle,
\ so the table at index X contains the sine of this value.
\
\ The value of sine across the quarter circle ranges from 0 to 1:
\
\   sin(0) = 0
\
\   sin(90) = sin(PI/2) = 1
\
\ It might help to think of sin(X) as an integer ranging from 0 to 256 across
\ the quarter circle, so entry X in this table contains sin(X) * 256, where X
\ ranges from 0 to 128 over the course of a quarter circle.
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
\       Name: iconBuffer
\       Type: Variable
\   Category: Graphics
\    Summary: The icon screen buffer, which is used to buffer the energy icon
\             and scanner row before writing to screen memory
\
\ ******************************************************************************

.iconBuffer

 SKIP 0                 \ The icon screen buffer shares memory with L5A00

\ ******************************************************************************
\
\       Name: L5A00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5A00

 SKIP 128

\ ******************************************************************************
\
\       Name: viewBufferDown
\       Type: Subroutine
\   Category: Graphics
\    Summary: The view screen buffer for buffering the new part of the player's
\             scrolling landscape view when panning down (scrolling up)
\
\ ******************************************************************************

.viewBufferDown

 SKIP 128

\ ******************************************************************************
\
\       Name: L5B00
\       Type: Variable
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.L5B00

 SKIP 256

\ ******************************************************************************
\
\       Name: stripData
\       Type: Variable
\   Category: Landscape
\    Summary: Storage for tile data when smoothing strips of tiles during the
\             landscape generation process
\
\ ------------------------------------------------------------------------------
\
\ The initial contents of the variable is just workspace noise and is ignored.
\ It actually contains snippets of the original source code.
\
\ ******************************************************************************

 CLEAR &5A00, &5C00     \ Memory from &5A00 to &5BFF has two separate uses
 ORG &5A00              \
                        \ During the landscape generation process, it is used
                        \ for storing tile data that can be discarded once the
                        \ landscape is generated
                        \
                        \ During gameplay it is used to store the L5A00,
                        \ viewBufferDown and L5B00 variables
                        \
                        \ These lines rewind BeebAsm's assembly back to L5A00
                        \ (which is at address &5A00), and clear the block
                        \ from that point to stripData (which is at address
                        \ &5C00), so we can assemble the landscape generation
                        \ variables
                        \
                        \ The initial contents of the game binary in this
                        \ address actually contains snippets of the original
                        \ source code, left over from the BBC Micro assembly
                        \ process, so we include this workspace noise to ensure
                        \ that we generate an exact match for the game binary

.stripData

 EQUB &44, &58, &20, &45, &54, &45, &4D, &0D
 EQUB &14, &3C, &05, &20, &0D, &14, &46, &23
 EQUB &20, &20, &20, &20, &20, &20, &54, &59
 EQUB &41, &3A, &4A, &53, &52, &20, &45, &4D
 EQUB &49, &52, &54, &45, &53, &54, &3A, &42
 EQUB &43, &43, &20, &6D, &65, &61, &32, &0D
 EQUB &14, &50, &05, &20, &0D, &14, &5A, &1A
 EQUB &20, &20, &20, &20, &20, &20, &54, &59

\ ******************************************************************************
\
\       Name: tilesAtAltitude
\       Type: Variable
\   Category: Landscape
\    Summary: Storage for tile blocks at specific altitudes for placing enemies
\             on the landscape
\
\ ------------------------------------------------------------------------------
\
\ This table stores the altitude of 4x4 tile blocks at specific altitudes, for
\ use when placing enemies on the landscape. It is only used while the landscape
\ is being generated and the allocated memory is reused during gameplay.
\
\ The initial contents of the variable is just workspace noise and is ignored.
\ It actually contains snippets of the original source code.
\
\ ******************************************************************************

.tilesAtAltitude

 EQUB &41, &3A, &53, &54, &41, &20, &4D, &45
 EQUB &41, &4E, &59, &2C, &58, &20, &0D, &14
 EQUB &64, &05, &20, &0D, &14, &6E, &1C, &20
 EQUB &20, &20, &20, &20, &20, &4C, &44, &41
 EQUB &23, &34, &3A, &53, &54, &41, &20, &4F
 EQUB &42, &54, &59, &50, &45, &2C, &59, &0D
 EQUB &14, &78, &23, &20, &20, &20, &20, &20
 EQUB &20, &4C, &44, &41, &23, &31, &30, &34

 EQUB &3A, &53, &54, &41, &20, &4F, &42, &48    \ These bytes are unused until
 EQUB &41, &4C, &46, &53, &49, &5A, &45, &4D    \ the game is in progress, at
 EQUB &49, &4E, &0D, &14, &82, &11, &20, &20    \ which point this whole section
 EQUB &20, &20, &20, &20, &43, &4C, &43, &3A    \ of memory is reused
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
\       Name: maxAltitude
\       Type: Variable
\   Category: Landscape
\    Summary: The maximum tile altitude for each 4x4 block of tiles
\
\ ------------------------------------------------------------------------------
\
\ This table stores the altitude of the highest tile in each 4x4 block of tiles
\ in the landscape. It is only used while the landscape is being generated and
\ the allocated memory is reused during gameplay.
\
\ The table is laid out with one byte for each 4x4 block, starting in the
\ front-left corner of the landscape at tile coordinate (0, 0), and moving along
\ the front row from left to right, and then moving back by four tiles and
\ moving that row from left to right, until we reach the rear row of 4x4 blocks.
\
\ The rear row and rightmost column of blocks are one tile smaller, so they are
\ 4x3-tile and 3x4-tile blocks, with the far-right block being 3x3 tiles.
\
\ You can picture this as partitioning the 31x31-tile landscape into an 8x8
\ chess board, where each square on the chess board is made up of a 4x4 block of
\ landscape tiles (and with smaller squares along the right and rear edges).
\
\ The blocks of memory either side of maxAltitude are included as they are
\ zeroed when adding enemies to the landscape, and including them means we don't
\ have to worry about the zeroing process leaking into neighbouring variable
\ when placing enemies near the edges of the landscape.
\
\ The initial contents of the variable is just workspace noise and is ignored.
\ It actually contains snippets of the original source code.
\
\ ******************************************************************************

 EQUB &AA, &14, &2E, &54, &41, &4B, &45, &20
 EQUB &4C, &44, &58, &20, &50, &45, &52, &53

.maxAltitude

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

\ ******************************************************************************
\
\       Name: xTileMaxAltitude
\       Type: Variable
\   Category: Landscape
\    Summary: The tile x-coordinate of the highest tile within each 4x4 block of
\             tiles
\
\ ------------------------------------------------------------------------------
\
\ This table stores the tile x-coordinate of the highest tile within each 4x4
\ block of tiles in the landscape. It is only used while the landscape is being
\ generated and the allocated memory is reused during gameplay.
\
\ The table is laid out with one byte for each 4x4 block, starting in the
\ front-left corner of the landscape at tile coordinate (0, 0), and moving along
\ the front row from left to right, and then moving back by four tiles and
\ moving that row from left to right, until we reach the rear row of 4x4 blocks.
\
\ The rear row and rightmost column of blocks are one tile smaller, so they are
\ 4x3-tile and 3x4-tile blocks, with the far-right block being 3x3 tiles.
\
\ You can picture this as partitioning the 31x31-tile landscape into an 8x8
\ chess board, where each square on the chess board is made up of a 4x4 block of
\ landscape tiles (and with smaller squares along the right and rear edges).
\
\ The initial contents of the variable is just workspace noise and is ignored.
\ It actually contains snippets of the original source code.
\
\ ******************************************************************************

.xTileMaxAltitude

 EQUB &42, &43, &23, &31, &3A, &53, &54, &41
 EQUB &20, &45, &4E, &45, &52, &47, &59, &0D
 EQUB &14, &D2, &12, &20, &20, &20, &20, &20
 EQUB &20, &4A, &53, &52, &20, &45, &44, &49
 EQUB &53, &0D, &14, &DC, &18, &20, &20, &20
 EQUB &20, &20, &20, &4C, &44, &41, &23, &35
 EQUB &3A, &4A, &53, &52, &20, &56, &49, &50
 EQUB &4F, &0D, &14, &E6, &16, &20, &20, &20

\ ******************************************************************************
\
\       Name: zTileMaxAltitude
\       Type: Variable
\   Category: Landscape
\    Summary: The tile z-coordinate of the highest tile within each 4x4 block of
\             tiles
\
\ ------------------------------------------------------------------------------
\
\ This table stores the tile z-coordinate of the highest tile within each 4x4
\ block of tiles in the landscape. It is only used while the landscape is being
\ generated and the allocated memory is reused during gameplay.
\
\ The table is laid out with one byte for each 4x4 block, starting in the
\ front-left corner of the landscape at tile coordinate (0, 0), and moving along
\ the front row from left to right, and then moving back by four tiles and
\ moving that row from left to right, until we reach the rear row of 4x4 blocks.
\
\ The rear row and rightmost column of blocks are one tile smaller, so they are
\ 4x3-tile and 3x4-tile blocks, with the far-right block being 3x3 tiles.
\
\ You can picture this as partitioning the 31x31-tile landscape into an 8x8
\ chess board, where each square on the chess board is made up of a 4x4 block of
\ landscape tiles (and with smaller squares along the right and rear edges).
\
\ The initial contents of the variable is just workspace noise and is ignored.
\ It actually contains snippets of the original source code.
\
\ ******************************************************************************

.zTileMaxAltitude

 EQUB &20, &20, &20, &53, &45, &43, &3A, &4A
 EQUB &4D, &50, &20, &74, &61, &6B, &33, &0D
 EQUB &14, &F0, &05, &20, &0D, &14, &FA, &05
 EQUB &20, &0D, &15, &04, &18, &2E, &74, &61
 EQUB &6B, &31, &20, &54, &58, &41, &3A, &4A
 EQUB &53, &52, &20, &45, &4D, &49, &52, &50
 EQUB &54, &0D, &15, &0E, &05, &20, &0D, &15
 EQUB &18, &1F, &20, &20, &20, &20, &20, &20

 EQUB &4C, &44, &41, &20, &4F, &42, &54, &59    \ These bytes are unused until
 EQUB &50, &45, &2C, &58, &3A, &42, &4E, &45    \ the game is in progress, at
 EQUB &20, &74, &61, &6B, &34, &0D, &15, &22    \ which point this whole section
 EQUB &05, &20, &0D, &15, &2C, &1E, &20, &5C    \ of memory is reused

\ ******************************************************************************
\
\       Name: sub_C5C01
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

 RTS                    \ This instruction appears to be unused

.sub_C5C01

 STY L006F
 LDA objectTypes,Y
 STA L004C
 LDX anotherObject
 JSR sub_C5DC4
 JSR sub_C5DF5
 JSR sub_C5567
 LDX anotherObject
 LDA angleLo
 SEC
 SBC L001F
 STA L0C59
 LDA angleHi
 SBC objectYawAngle,X
 CLC
 ADC #&0A
 STA L0C57
 LDY L006F
 LDA #0
 SEC
 SBC angleLo
 STA L0059
 LDA objectYawAngle,Y
 SBC angleHi
 STA L005A
 JSR GetHypotenuse
 LDA L140F
 BNE C5C60
 LDA #&80
 STA L005A
 LDA #0
 STA L0059
 CPY #&3F
 BEQ C5C60
 LSR hypotenuseHi
 ROR hypotenuseLo
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

 LDA hypotenuseLo
 STA L0C5D
 LDA hypotenuseHi
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
 LDA L49A0+1,X
 STA L004F
 LDY L49A0,X
 STY L004E

.C5C85

 LDA L0059
 STA T
 LDA L005A
 CLC
 ADC L4AE0,Y

 JSR GetSineAndCosine   \ Calculate the following:
                        \
                        \   sinA = |sin(A)|
                        \
                        \   cosA = |cos(A)|

 LDY L004E
 LDA L4D60,Y
 STA U
 LDA cosA

 JSR Multiply8x8        \ Set (A T) = A * U

 STA T
 LDA #0
 BIT H
 BVC C5CA9

 JSR Negate16Bit        \ Set (A T) = -(A T)

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
 LDA sinA

 JSR Multiply8x8        \ Set (A T) = A * U

 STA L0080
 LDA #0
 STA L0083
 LDA H
 STA L0086
 JSR sub_C5567
 LDY L0021
 LDA angleLo
 CLC
 ADC L0C59
 STA L0BA0,Y
 LDA angleHi
 ADC L0C57
 STA L5500,Y
 JSR GetHypotenuse
 LDY L004E
 LDA L4C20,Y
 ASL A
 STA T
 LDA #0
 BCC C5D05

 JSR Negate16Bit        \ Set (A T) = -(A T)

.C5D05

 STA U
 LDA T
 CLC
 ADC L0C5B
 STA L0080
 LDA U
 ADC L0C5C
 LDX anotherObject
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
 LDA hypotenuseHi
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
 LDA L49AB+1,X
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
 STA sightsYawAngleLo
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
 STA sightsYawAngleLo
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
 LDA xObject,Y
 SBC xObject,X
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
 LDA zObject,Y
 SBC zObject,X
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

 LDA yObjectLo,Y
 SEC
 SBC yObjectLo,X
 STA L0081
 LDA yObjectHi,Y
 SBC yObjectHi,X
 STA L0084
 RTS

\ ******************************************************************************
\
\       Name: ReadKeyboard
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Enable the keyboard and read a character from it
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The character read from the keyboard
\
\ ******************************************************************************

.ReadKeyboard

 JSR EnableKeyboard     \ Select the keyboard as the input stream and flush the
                        \ keyboard buffer

                        \ Fall through into ReadCharacter to read a character
                        \ from the keyboard and return it in A

\ ******************************************************************************
\
\       Name: ReadCharacter
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Read a character from the currently selected input stream
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   The character read from the input stream, in ASCII
\
\ ******************************************************************************

.ReadCharacter

 JSR OSRDCH             \ Read a character from the currently selected input
                        \ stream into A

 BCC read1              \ If the C flag is clear then the call to OSRDCH read a
                        \ valid character, so jump to read1 to return from the
                        \ subroutine

 CMP #27                \ If the character read is not ESCAPE, jump to read1 to
 BNE read1              \ return from the subroutine

                        \ If we get here then we have an ESCAPE condition, so we
                        \ need to acknowledge it and try again

 TYA                    \ Store Y on the stack to we can preserve it through the
 PHA                    \ call to OSBYTE

 LDA #126               \ Call OSBYTE with A = 126 to acknowledge the ESCAPE
 JSR OSBYTE             \ condition

 PLA                    \ Retrieve Y from the stack
 TAY

 JMP ReadCharacter      \ Loop back to read another character

.read1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: EnableKeyboard
\       Type: Subroutine
\   Category: Keybpard
\    Summary: Select the keyboard as the input stream and flush the keyboard
\             buffer
\
\ ******************************************************************************

.EnableKeyboard

 LDA #2                 \ Call OSBYTE with A = 2 and X = 0 to select the
 LDX #0                 \ keyboard as the input stream and disable the RS423
 JSR OSBYTE

 LDX #0                 \ Set X = 0 to denote the keyboard buffer

 JMP FlushBuffer        \ Call FlushBuffer to flush the keyboard buffer and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SetColourPalette
\       Type: Subroutine
\   Category: Graphics
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
\   Category: Graphics
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
 LDA bitMasks,Y

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
 STA fromAddr
 LDA L0013
 ADC #&00
 STA fromAddr+1
 LDA L2092
 CLC
 ADC fromAddr
 STA toAddr
 LDA L2093
 ADC fromAddr+1
 CMP #&80
 BCC C5ED9
 SBC #&20

.C5ED9

 STA toAddr+1
 LDA fromAddr+1
 CLC
 ADC #&3F
 STA fromAddr+1
 CMP #&53
 BCC C5EF3
 LDA fromAddr
 SEC
 SBC #&60
 STA fromAddr
 LDA fromAddr+1
 SBC #&13
 STA fromAddr+1

.C5EF3

 LDA L0CD0
 ASL A
 ROL A
 ROL A
 AND #&03
 TAX
 LDY #0
 LDA (fromAddr),Y
 AND L227F,X
 STA L0013
 LDA (toAddr),Y
 AND L36BF,X
 ORA L0013
 STA (toAddr),Y
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
\       Name: DisplayGameOver
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.DisplayGameOver

 PHA

 JSR FlushSoundBuffers  \ Flush all four sound channel buffers

 JSR ClearIconsScanner  \ Clear the energy icon and scanner row at the top of
                        \ the screen

 LDA #&06
 STA L0C73
 LDA #&FA
 STA L0C74
 PLA
 JSR sub_C5F68
 LDY #0
 STY L0CC9
 STY sightsAreVisible
 LDA titleObjectToDraw
 JSR sub_C5F80
 LDA #&03
 STA L0C4C
 LDA #&01
 STA currentObject
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
 STA loopCounter

.P5F6E

 JSR sub_C56D9
 JSR sub_C355A
 DEC loopCounter
 BNE P5F6E
 DEC L001E
 BNE P5F6A
 RTS

\ ******************************************************************************
\
\       Name: JumpToPreview
\       Type: Subroutine
\   Category: Main title loop
\    Summary: An intentionally confusing jump point for controlling the main
\             title loop flow when returning from the GenerateLandscape routine
\
\ ******************************************************************************

.JumpToPreview

 EQUB &4C               \ This byte is never executed, as the stack modification
                        \ in the SmoothTileData routine sets the return address
                        \ on the stack to JumpToPreview, and the RTS instruction
                        \ will therefore jump to JumpToPreview+1 (as that's how
                        \ the RTS instruction works)
                        \
                        \ This byte is the opcode for a JMP instruction, so this
                        \ makes it look like there is a JumpToPreview routine
                        \ that contains the following:
                        \
                        \   &4C &30 &3F     JMP &3F30
                        \
                        \ as the BMI instruction below assembles into &30 &3F
                        \
                        \ This would jump to a valid instruction halfway through
                        \ the ConfigureMachine routine, so this byte, although
                        \ unused, is presumably a JMP opcode to confuse any
                        \ crackers who have reached this point in their analysis

 BMI PreviewLandscape   \ We only get here if the stack has been modified by the
                        \ SmoothTileData routine, which makes the RTS at the end
                        \ end of the GenerateLandscape routine jump here
                        \
                        \ The penultimate instruction in GenerateLandscape is a
                        \ call to the ProcessTileData routine, which happens to
                        \ set the N flag, so when the RTS instruction jumps here
                        \ using the modified return address, this BMI branch is
                        \ taken, so this instruction is effectively a JMP to the
                        \ PreviewLandscape routine

\ ******************************************************************************
\
\       Name: sub_C5F80
\       Type: Subroutine
\   Category: ???
\    Summary: ???
\
\ ******************************************************************************

.sub_C5F80

 STA objectTypes+1
 LDA L5FBC,Y
 CLC
 ADC zObject+2
 STA zObject+1
 LDA yObjectHi+2
 CLC
 ADC L5FDC,Y
 STA yObjectHi+1
 LDA xObject+2
 STA xObject+1
 LDA L5FD9,Y
 STA objectPitchAngle+2
 LDA L5FE2,Y
 STA objectYawAngle+2
 LDA #0
 STA yObjectLo+2
 STA yObjectLo+1
 LDA L5FDF,Y
 STA objectYawAngle+1
 LDX #&02
 STX anotherObject
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
\       Name: PreviewLandscape
\       Type: Subroutine
\   Category: Landscape
\    Summary: Draw an aerial preview of the landscape
\
\ ******************************************************************************

.PreviewLandscape

 JSR SpawnEnemies       \ Calculate the number of enemies for this landscape,
                        \ add them to the landscape and set the palette
                        \ accordingly

 LDX #3                 \ Set X = 3 to pass to DrawTitleObject ???

 LDY #0                 \ Set Y = 0 to pass to DrawTitleObject ???

 LDA #&80               \ Set A = &80 so the call to DrawTitleObject draws the
                        \ landscape preview

 JSR DrawTitleObject    \ Draw the landscape preview

 LDX #4                 \ Print text token 4: Background colour black, print
 JSR PrintTextToken     \ "PRESS ANY KEY" at (192, 64), print "LANDSCAPE" two
                        \ characters right of (64, 768), move cursor right

 JSR PrintLandscapeNum  \ Print the four-digit landscape number (0000 to 9999)

 JSR SpawnPlayer        \ Add the player and trees to the landscape
                        \
                        \ If the entered secret entry code in the keyboard input
                        \ buffer does not match the generated secret code for
                        \ this landscape then the call will return here so we
                        \ can display an error
                        \
                        \ If the codes match then the CheckSecretCode will jump
                        \ to the PlayGame routine instead to play the game

 JMP SecretCodeError    \ The entered secret entry in the keyboard input buffer
                        \ does not match the generated secret code for this
                        \ landscape, so jump to SecretCodeError to display the
                        \ "WRONG SECRET CODE" error, wait for a key press and
                        \ rejoin the main title loop

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
 LDA #3
 STA L0C73
 RTS

 EQUB &23

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

                               \ Game addr to file addr
 COPYBLOCK &4900, &4A00, &6000 \ 4900-49FF to 6000-60FF
 COPYBLOCK &5800, &6100, &4100 \ 5800-60FF to 4100-49FF
 COPYBLOCK &0400, &5800, LOAD% \ 0400-57FF to 1900-6CFF

 SAVE "3-assembled-output/TheSentinel.bin", LOAD%, P%
