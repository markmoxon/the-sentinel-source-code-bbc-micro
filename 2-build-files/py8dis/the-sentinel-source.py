from commands import *
import acorn


load(0x1900, "../../4-reference-binaries/pias/TheSentinel.bin")

set_output_filename("TheSentinel.bin")

acorn.bbc()

entry(0x6D00, "Entry")

go()
