# Annotated source code for the BBC Micro version of The Sentinel

This folder contains the annotated source code for the BBC Micro version of The Sentinel.

* Main source files:

  * [sentinel-source.asm](sentinel-source.asm) contains the main source for the game

* Other source files:

  * [sentinel-disc.asm](sentinel-disc.asm) builds the SSD disc image from the assembled binaries and other source files

  * [sentinel-readme.asm](sentinel-readme.asm) generates a README file for inclusion on the SSD disc image

* Files that are generated during the build process:

  * [sentinel-build-options.asm](sentinel-build-options.asm) stores the make options in BeebAsm format so they can be included in the assembly process

---

_Mark Moxon_