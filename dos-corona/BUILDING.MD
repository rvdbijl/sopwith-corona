# Building The DOS/Corona Version

This directory is an experimental native DOS build of Sopwith for the
Corona/Cordata PPC-21 graphics mode. It is based on the GPL-released DOS
Sopwith source and still uses the historical Microsoft C + MASM build style.

The build has not yet been confirmed on real hardware. Expect one or two
toolchain fixes before the first successful `SOPWITH.EXE`.

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

The first Corona patch assumes:

* Corona graphics page 7 starts at `3800:0000`
* the display page must stay below physical `40000h`
* mode setup is BIOS mode 7, then port `3B8h = A9h`
* CRTC start address high/low is `38h:00h`
* pixel layout is:

```text
offset = ((y mod 13) << 11) + ((y / 13) * 80) + (x >> 3)
mask   = 01h << (x & 7)
```

Sopwith remains a 320 x 200 game internally. Visible output is currently
drawn as doubled-width monochrome pixels centered vertically on the 640 x 325
Corona display.

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
