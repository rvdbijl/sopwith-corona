
# Sopwith Corona PPC-21

This fork is starting an experimental native DOS port of Sopwith for the
Corona/Cordata PPC-21 proprietary 640 x 325 monochrome graphics mode.

The early hardware work lives in `dos-corona/`. It is based on the
GPL-released DOS Sopwith source, because that code still has the original
CGA-era direct framebuffer drawing path that can be adapted to the PPC-21.

Current Corona work:

* redirects visible drawing away from CGA `B800:` memory and into Corona
  graphics page 7 at `3800:0000`
* uses the PPC-21's observed `SCREEN 105` framebuffer layout
* maps Sopwith's 320 x 200 logical display into doubled-width 640-pixel
  monochrome output, vertically centered on the 640 x 325 Corona display
* keeps collision/off-screen drawing in the original CGA-style auxiliary
  buffer for now

This branch is not yet a finished playable build. It is the first
hardware-testable source pass.

Build notes for the DOS/Corona version are in
[`dos-corona/BUILDING.MD`](dos-corona/BUILDING.MD).

## Credits and References

Sopwith was originally created by BMB Compuscience Canada. David L. Clark,
the original author, released the Sopwith source under the GNU GPL. This
repository is forked from Simon Howard's SDL Sopwith project and preserves
that GPL lineage.

Useful references:

* SDL Sopwith upstream: https://github.com/fragglet/sdl-sopwith
* Sopwith history and original-source notes: https://fragglet.github.io/sdl-sopwith
* Sopwith information archive: http://www.sopwith.org/

## Upstream SDL Sopwith

SDL Sopwith is a port of the game "Sopwith", which was originally
by BMB Compuscience Canada. The original author David L. Clark
has kindly released the source code under the GNU GPL.

Features:

* Uses LibSDL, so will run on most modern operating systems, and also
  the web (via emscripten)
* Support for loading custom mission files (new levels)
* TCP/IP multiplayer
* PC speaker emulation
* Multiple palettes that emulate a selection of old monitors
* Medals and high score table

## More Info

More information about SDL Sopwith is available in some of the files
included here:

* AUTHORS - People responsible for this
* COPYING - License information (GNU GPL)
* FAQ - Frequently asked questions about SDL Sopwith
* NEWS - What's new, ChangeLog

You can find lots more information about the original Sopwith here:

* http://www.sopwith.org/
* https://fragglet.github.io/sdl-sopwith
* https://en.wikipedia.org/wiki/Sopwith_(video_game)

## Feedback

If you like SDL Sopwith, [join the Discord community](https://discord.gg/S2P5wUUzNU)
where you can chat with other fans of the game!
