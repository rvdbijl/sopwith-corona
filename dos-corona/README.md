# Sopwith for Corona PPC-21

This directory contains the GPL-released DOS Sopwith source as a starting
point for a native Corona/Cordata PPC-21 graphics port.

The original DOS code draws directly into CGA memory at `B800:` using the
standard 320 x 200 CGA layout. The Corona PPC-21 does not have that CGA
framebuffer, but it does have a proprietary 640 x 325 monochrome graphics
mode exposed by Corona GW-BASIC as `SCREEN 105`.

The initial Corona patch is intentionally simple:

- visible video output is redirected to Corona graphics page 7 at
  `3800:0000`;
- mode setup uses BIOS mode 7, port `3B8h = A9h`, and CRTC start address
  `3800h`;
- Sopwith's 320 x 200 logical pixels are drawn as doubled-width monochrome
  pixels centered vertically in the 640 x 325 Corona display;
- collision/off-screen drawing remains in the original CGA-style auxiliary
  buffer for now.

This is a proof-oriented first pass. It favors clarity over speed and still
needs real hardware testing.

The original archive referenced `mixed.inc` and `sw.lnk` but did not include
them in the copy inspected for this port. Minimal replacements are included
here so the historical `SW.MAK` has a complete file set to start from.
