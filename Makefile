BEEBASM?=beebasm
PYTHON?=python

# A make command with no arguments will build the Play It Again Sam
# variant with crc32 verification of the game binaries
#
# Optional arguments for the make command are:
#
#   variant=<release>   Build the specified variant:
#
#                         pias (default)
#
#   verify=no           Disable crc32 verification of the game binaries
#
# So, for example:
#
#   make variant=pias verify=no
#
# will build the Play It Again Sam variant with no crc32 verification

variant-number=1
folder=pias
suffix=-pias

.PHONY:all
all:
	echo _VARIANT=$(variant-number) > 1-source-files/main-sources/the-sentinel-build-options.asm
	$(BEEBASM) -i 1-source-files/main-sources/the-sentinel-source.asm -v > 3-assembled-output/compile.txt
	$(BEEBASM) -i 1-source-files/main-sources/the-sentinel-disc.asm -do 5-compiled-game-discs/the-sentinel$(suffix).ssd -opt 3 -title "The Sentinel"
ifneq ($(verify), no)
	@$(PYTHON) 2-build-files/crc32.py 4-reference-binaries/$(folder) 3-assembled-output
endif

.PHONY:b2
b2:
	curl -G "http://localhost:48075/reset/b2"
	curl -H "Content-Type:application/binary" --upload-file "5-compiled-game-discs/the-sentinel$(suffix).ssd" "http://localhost:48075/run/b2?name=sentinel$(suffix).ssd"
