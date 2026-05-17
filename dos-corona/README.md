# Sopwith for Corona PPC-21

This directory contains the GPL-released DOS Sopwith source as a starting
point for a native Corona/Cordata PPC-21 graphics port.

The original DOS code draws directly into CGA memory at `B800:` using the
standard 320 x 200 CGA layout. The Corona PPC-21 does not have that CGA
framebuffer, but it does have a proprietary 640 x 325 monochrome graphics
mode exposed by Corona GW-BASIC as `SCREEN 105`.

The Corona patch currently includes:

- visible video output redirected to a Corona graphics page;
- mode setup using BIOS mode 7, port `3B8h = A9h`, and a Corona CRTC display
  start;
- Sopwith's 320 x 200 logical pixels drawn as doubled-width monochrome pixels
  on the 640 x 325 Corona display;
- precomputed Corona Y-offset and CGA-byte-to-Corona-mask tables;
- an experimental sprite cache for common fully visible sprites;
- Corona-specific keyboard handling using the IBM keyboard interrupt path;
- direct PC speaker PIT/speaker-port output;
- polled BIOS-tick based timing for gameplay and title/menu sound.

This is now a hardware-tested checkpoint rather than only a first-pass proof.
The game starts and runs on a Corona/Cordata PPC-21, but gameplay is still far
too slow on the 4.77 MHz 8088. Heavy scrolling and explosions are the main
performance problems. Sound works, but it can lag behind during expensive
draws.

Build instructions are in [BUILDING.MD](BUILDING.MD). A DOS batch wrapper is
provided as `BUILD.BAT`; it calls the historical `SW.MAK` file.

For the current Linux development setup, the practical build path is an
external OpenWatcom/DOS build workspace outside this repository:

```sh
/home/robbert/Documents/GitHub/sopwith-corona-build-env/build-openwatcom.sh
```

After each build, copy the executable to the PPC-21 transfer mount:

```sh
cp /home/robbert/Documents/GitHub/sopwith-corona-build-env/work/dos-corona/sopwith.exe /mnt/xt/corona/sopwith.exe
```

The external build environment and transfer mount should remain outside the
repository.

## Current Debugging Notes

Recent fixes worth knowing about in a follow-up session:

- the old hard gameplay freeze was avoided by using a polled Corona frame tick
  path instead of relying on the original timer hook during gameplay;
- a stack imbalance in `swcoronasoundtick` caused title/menu lockups and has
  been fixed;
- an early sprite-cache bug used the saved `ES` value as the sprite source
  pointer and corrupted cached title sprites; the cache now uses the live
  source pointer;
- Ctrl-Alt-Del works through the Corona keyboard interrupt path;
- an `INT 1Ch` test program reported ticks on the real PPC-21, so lack of a
  realtime clock is not itself the blocker.

Open problems:

- optimize terrain/world scrolling and explosion drawing;
- reduce sound latency when rendering is slow;
- improve or replace vertical stretching and eventually add CGA color
  dithering;
- consider more byte-oriented blitters and cached object shapes instead of
  pixel-by-pixel drawing;
- decide whether native-height gameplay is worth the larger simulation changes.

The original archive referenced `mixed.inc` and `sw.lnk` but did not include
them in the copy inspected for this port. Minimal replacements are included
here so the historical `SW.MAK` has a complete file set to start from.

Credit: Sopwith was originally created by BMB Compuscience Canada. David L.
Clark released the source under the GNU GPL. This port work uses that DOS
source and references Simon Howard's SDL Sopwith project:
https://github.com/fragglet/sdl-sopwith
