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

* redirects visible drawing away from CGA `B800:` memory and into a Corona
  graphics page
* uses the PPC-21's observed `SCREEN 105` framebuffer layout
* maps Sopwith's 320 x 200 logical display into doubled-width 640-pixel
  monochrome output on the 640 x 325 Corona display
* keeps collision/off-screen drawing in the original CGA-style auxiliary
  buffer for now
* installs a Corona-safe IBM keyboard interrupt path, including
  Ctrl-Alt-Del handling
* drives PC speaker sound through direct PIT/speaker ports that work on the
  PPC-21
* uses polled BIOS-tick timing for Corona gameplay and title/menu sound
* includes an experimental Corona sprite mask cache for common fully visible
  sprites

## Current Hardware Status

As of the current checkpoint, the build has been tested on a Corona/Cordata
PPC-21. The title screen works, title sprites render correctly, and the title
music plays. The game starts and runs without the earlier hard freezes.

Known remaining issues:

* gameplay is much too slow on the 4.77 MHz 8088, especially while scrolling
  terrain or drawing explosions
* sound can still lag behind gameplay events during heavy redraws
* the Corona renderer is monochrome-only; CGA color dithering is still not
  implemented
* the game simulation is still 320 x 200 internally, not native 640 x 325
* the sprite cache is intentionally conservative and only covers common
  fully visible sprite cases

Build notes are in [`dos-corona/BUILDING.MD`](dos-corona/BUILDING.MD). The
short version is:

```dos
CD \SOPCOR
BUILD
```

with Microsoft C, MASM, LINK, and NMAKE installed and configured in `PATH`,
`INCLUDE`, and `LIB`.

On the Linux Mint development machine used for this port, an external build
environment lives outside this repository at:

```sh
/home/robbert/Documents/GitHub/sopwith-corona-build-env/build-openwatcom.sh
```

That external build pipeline is intentionally not part of this repository.
It produces `sopwith.exe` under the external build workspace, and the tested
hardware drop is copied to:

```sh
/mnt/xt/corona/sopwith.exe
```

## Credits and References

Sopwith was originally created by BMB Compuscience Canada. David L. Clark,
the original author, released the Sopwith source under the GNU GPL. This
Corona port work started from Simon Howard's SDL Sopwith repository and the
GPL DOS source lineage referenced there.

Useful references:

* SDL Sopwith upstream: https://github.com/fragglet/sdl-sopwith
* Sopwith history and original-source notes: https://fragglet.github.io/sdl-sopwith
* Sopwith information archive: http://www.sopwith.org/
