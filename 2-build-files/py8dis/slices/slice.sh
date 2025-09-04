# Slice the main binary into the different blocks that are moved about
# in memory when the game is run

dd if=../../../4-reference-binaries/pias/TheSentinel.bin of=1900-55ff.bin bs=1 skip=0 count=15616
dd if=../../../4-reference-binaries/pias/TheSentinel.bin of=5600-5eff.bin bs=1 skip=15616 count=2304
dd if=../../../4-reference-binaries/pias/TheSentinel.bin of=5f00-6cff.bin bs=1 skip=17920 count=3584
dd if=../../../4-reference-binaries/pias/TheSentinel.bin of=6d00-6d23.bin bs=1 skip=21504 count=36

# Confirm that the slices match the original binary when reassembled

cat 1900-55ff.bin 5600-5eff.bin 5f00-6cff.bin 6d00-6d23.bin | diff ../../../4-reference-binaries/pias/TheSentinel.bin -
