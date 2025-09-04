python the-sentinel-source.py > the-sentinel-source.asm

beebasm -i the-sentinel-source.asm -v > compile.txt
rm null.bin

crc32 TheSentinel.bin
crc32 ../../4-reference-binaries/pias/TheSentinel.bin
