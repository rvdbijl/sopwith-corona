# Building The DOS/Corona Version

This directory is an experimental native DOS build of Sopwith for the
Corona/Cordata PPC-21 graphics mode. It is based on the GPL-released DOS
Sopwith source and still uses the historical Microsoft C + MASM build style.

The build has been confirmed on real Corona/Cordata PPC-21 hardware. The
current executable starts, shows the title screen, plays sound, enters
gameplay, and does not show the earlier hard-freeze behavior. It is not yet
performance-complete: gameplay is still too slow on a 4.77 MHz 8088 and sound
can lag during heavy redraws.

## Required Toolchain

Use a real 16-bit DOS toolchain. Modern Visual Studio/MSVC cannot build this
program because it does not emit 16-bit DOS executables.

Recommended tools:

* Microsoft C 5.1 or Microsoft C 6.0
* Microsoft MASM 5.1 or MASM 6.x
* Microsoft LINK from the same era
* NMAKE

The checked-in `SW.MAK` expects these commands:

```dos
MASM /Dmodel=small /Dlang=c /Mx file.asm;
CL -c -Gs -Zl -FPc -AS -Osa file.c
LINK @SW.LNK
```

## Where To Install

On the target DOS machine or inside DOSBox-X, install the compiler and
assembler into short DOS paths. For example:

```dos
C:\C600       Microsoft C 6.0
C:\MASM       MASM
C:\SOPCOR     this dos-corona source directory
```

For Microsoft C 6.0:

```dos
SET PATH=C:\C600\BINB;C:\C600\BIN;C:\MASM;%PATH%
SET INCLUDE=C:\C600\INCLUDE
SET LIB=C:\C600\LIB
```

For Microsoft C 5.1:

```dos
SET PATH=C:\MSC\BIN;C:\MASM;%PATH%
SET INCLUDE=C:\MSC\INCLUDE
SET LIB=C:\MSC\LIB
```

If MASM is installed somewhere else, add that directory to `PATH` as well.

## Build

From this directory:

```dos
BUILD
```

or directly:

```dos
NMAKE /F SW.MAK
```

The expected output is:

```dos
SOPWITH.EXE
SOPWITH.MAP
```

## Current Linux Build Environment

For the current development machine, the working build pipeline is outside
this repository:

```sh
/home/robbert/Documents/GitHub/sopwith-corona-build-env/build-openwatcom.sh
```

The script builds a copy of `dos-corona` in the external workspace and writes:

```text
/home/robbert/Documents/GitHub/sopwith-corona-build-env/work/dos-corona/sopwith.exe
/home/robbert/Documents/GitHub/sopwith-corona-build-env/work/dos-corona/sopwith.map
```

Copy test builds to the mounted transfer directory used by the PPC-21:

```sh
cp /home/robbert/Documents/GitHub/sopwith-corona-build-env/work/dos-corona/sopwith.exe /mnt/xt/corona/sopwith.exe
```

Do not add the external build environment or generated binaries to this repo.

## Clean

To remove build products:

```dos
BUILD CLEAN
```

This removes `.OBJ`, `.EXE`, `.MAP`, `.LST`, and `.ERR` files in the current
directory.

## Linker Library Prompts

The historical makefile compiles C files with `-Zl`, which suppresses default
library records. If `LINK @SW.LNK` prompts for runtime libraries, try the
small-model Microsoft C runtime for your compiler version.

Common answers are:

```dos
SLIBCE
```

or:

```dos
SLIBC
```

If your linker asks for a full path, use the matching file under your
compiler's `LIB` directory.

## Current Corona Graphics Assumptions

The current Corona renderer assumes:

* the graphics page is 32 KiB aligned and must stay below physical `40000h`
* mode setup is BIOS mode 7, then port `3B8h = A9h`
* pixel layout is:

```text
offset = ((y mod 13) << 11) + ((y / 13) * 80) + (x >> 3)
mask   = 01h << (x & 7)
```

Sopwith remains a 320 x 200 game internally. Visible output is currently
drawn as doubled-width monochrome pixels on the 640 x 325 Corona display.

The renderer now precomputes Y offsets and CGA-byte-to-Corona masks. It also
has an experimental small FIFO sprite cache for common fully visible sprites.
Partially clipped sprites and larger shapes still fall back to the safer
uncached path.

## Current Runtime Status

Hardware-tested behavior at this checkpoint:

* title screen renders correctly
* title sound plays normally
* menus work
* gameplay starts and runs
* Ctrl-Alt-Del works

Known problems:

* gameplay is much too slow during terrain scrolling
* explosions cause large frame drops
* sound can be delayed relative to gameplay events
* CGA color dithering is not implemented
* native 325-line gameplay would require deeper game-coordinate changes

Useful context for future debugging:

* `swcoronatick` is the Corona gameplay tick path; it polls the BIOS tick and
  has a fallback so the frame wait cannot wedge forever
* `swcoronasoundtick` keeps title/menu sound advancing while polling for keys
* `swkeyint` contains the Corona keyboard path and Ctrl-Alt-Del handling
* `corona_getcache` builds cached expanded sprite masks keyed by source symbol
  pointer and x phase

## Source Credit

Sopwith was originally created by BMB Compuscience Canada. David L. Clark
released the Sopwith source under the GNU GPL. This Corona experiment is
based on that DOS source and on the public SDL Sopwith repository maintained
by Simon Howard:

```text
https://github.com/fragglet/sdl-sopwith
https://fragglet.github.io/sdl-sopwith
http://www.sopwith.org/
```
