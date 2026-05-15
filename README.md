
## Corona PPC-21 Port Work

This fork is starting an experimental native DOS port for the
Corona/Cordata PPC-21 proprietary 640 x 325 monochrome graphics mode.
The early hardware work lives in `dos-corona/`, based on the GPL-released
DOS Sopwith source rather than the SDL renderer.

The first pass redirects visible drawing away from CGA `B800:` memory and
into Corona graphics page 7 at `3800:0000`, using the PPC-21's observed
`SCREEN 105` framebuffer layout. It is not yet a finished playable build.

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
