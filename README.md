# Sopwith Corona PPC-21

This repository is an experimental native DOS port of Sopwith for the
Corona/Cordata PPC-21 proprietary 640 x 325 monochrome graphics mode.

The working source lives in `dos-corona/`. It is based on the GPL-released
DOS Sopwith source, because that code still has the original CGA-era direct
framebuffer drawing path that can be adapted to the PPC-21.

The repository has been trimmed to only the files needed to build and
document the Corona DOS version. The SDL renderer, desktop packaging,
GitHub Actions, mission-map examples, and other upstream app assets were
removed because they are not used by the `dos-corona/SW.MAK` build.

Current Corona work:

* redirects visible drawing away from CGA `B800:` memory and into Corona
  graphics page 7 at `3800:0000`
* uses the PPC-21's observed `SCREEN 105` framebuffer layout
* maps Sopwith's 320 x 200 logical display into doubled-width 640-pixel
  monochrome output, vertically centered on the 640 x 325 Corona display
* keeps collision/off-screen drawing in the original CGA-style auxiliary
  buffer for now

This is not yet a finished playable build. It is the first hardware-testable
source pass.

Build notes are in [`dos-corona/BUILDING.MD`](dos-corona/BUILDING.MD). The
short version is:

```dos
CD \SOPCOR
BUILD
```

with Microsoft C, MASM, LINK, and NMAKE installed and configured in `PATH`,
`INCLUDE`, and `LIB`.

## Credits and References

Sopwith was originally created by BMB Compuscience Canada. David L. Clark,
the original author, released the Sopwith source under the GNU GPL. This
Corona port work started from Simon Howard's SDL Sopwith repository and the
GPL DOS source lineage referenced there.

Useful references:

* SDL Sopwith upstream: https://github.com/fragglet/sdl-sopwith
* Sopwith history and original-source notes: https://fragglet.github.io/sdl-sopwith
* Sopwith information archive: http://www.sopwith.org/
