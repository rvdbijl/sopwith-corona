//
// Copyright(C) 1984-2000 David L. Clark
// Copyright(C) 2001-2005 Simon Howard
//
// You can redistribute and/or modify this program under the terms of the
// GNU General Public License version 2 as published by the Free Software
// Foundation, or any later version. This program is distributed WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.
//
//
//        swtitle  -      SW perform animation on the title screen
//

#include <ctype.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#include "emscripten.h"
#endif

#include "video.h"

#include "hiscore.h"
#include "sw.h"
#include "swasynio.h"
#include "swconf.h"
#include "swend.h"
#include "swgames.h"
#include "swgrpha.h"
#include "swinit.h"
#include "swmain.h"
#include "swmenu.h"
#include "swtext.h"
#include "swsound.h"
#include "swsymbol.h"
#include "swtitle.h"
#include "timer.h"

// How many milliseconds from when the title screen appears to when the high
// score table gets shown?
#define HIGH_SCORE_PERIOD 10000

#define X_OFFSET ((SCR_WDTH/2)-160)

// If a text element has this magic string value, it is (1) drawn centered and
// (2) replaced by a string that shows the program version.
#define MAGIC_VERSION  "__VERSION__"

struct title_element {
	enum { TITLE_GROUND, TITLE_TEXT, TITLE_SYMBOL } type;
	union {
		struct {
			int color;
			int x, y;
			char *text;
		} text;
		struct {
			int color;
			int x, y;
			sopsym_t *sym;
		} sym;
		struct {
			GRNDTYPE *ground;
			unsigned int ground_len;
		} ground;
	} v;
};

static struct title_element default_elements[] = {
	{TITLE_GROUND, {.ground={original_ground + 367, 600}}},
	{TITLE_TEXT, {.text={2, 18, 2, "SDL"}}},
	{TITLE_TEXT, {.text={3, 13, 4, "S O P W I T H"}}},
	{TITLE_TEXT, {.text={3, 20, 6, MAGIC_VERSION}}},
	{TITLE_TEXT, {.text={3, 0, 9, "(c) 1984, 1985, 1987"}}},
	{TITLE_TEXT, {.text={1, 21, 9, "BMB"}}},
	{TITLE_TEXT, {.text={3, 25, 9, "Compuscience"}}},
	{TITLE_TEXT, {.text={3, 0, 10, "(c) 1984-2000 David L. Clark"}}},
	{TITLE_TEXT,
	 {.text={3, 0, 11, "(c) 2001-2024 Simon Howard, Jesse Smith"}}},
	{TITLE_TEXT, {.text={3, 4, 12, "Distributed under the"}}},
	{TITLE_TEXT, {.text={1, 26, 12, "GNU"}}},
	{TITLE_TEXT, {.text={3, 30, 12, "GPL"}}},
	{TITLE_SYMBOL, {.sym={1, 40, 180, &symbol_plane[0].sym[0]}}},
	{TITLE_SYMBOL, {.sym={2, 130, 80, &symbol_plane[1].sym[6]}}},
	{TITLE_SYMBOL, {.sym={2, 23, 91, &symbol_targets[3].sym[0]}}},
	{TITLE_SYMBOL, {.sym={1, 213, 91, &symbol_ox[0].sym[0]}}},
	{TITLE_SYMBOL, {.sym={2, 280, 165, &symbol_pixel}}},
	{TITLE_SYMBOL, {.sym={2, 280, 170, &symbol_pixel}}},
	{TITLE_SYMBOL, {.sym={2, 280, 175, &symbol_pixel}}},
	{TITLE_SYMBOL, {.sym={2, 280, 180, &symbol_pixel}}},
	{TITLE_SYMBOL, {.sym={2, 280, 185, &symbol_pixel}}},
	{TITLE_SYMBOL, {.sym={2, 280, 190, &symbol_pixel}}},
	{TITLE_SYMBOL, {.sym={2, 270, 160, &symbol_plane_hit[0].sym[0]}}},
};

static struct title_element *title_elements = default_elements;
static int title_elements_len = arrlen(default_elements);
static int title_screen_start;

static void FreeTitleElement(struct title_element *el)
{
	switch (el->type) {
	case TITLE_TEXT:
		free(el->v.text.text);
		break;
	case TITLE_GROUND:
		free(el->v.ground.ground);
		break;
	default:
		break;
	}
}

// Clear all title screen elements. Starts the process of defining a new
// title screen in a mod file.
void ClearTitleScreen(void)
{
	static bool first_clear = true;
	int i;

	if (!first_clear) {
		for (i = 0; i < title_elements_len; ++i) {
			FreeTitleElement(&title_elements[i]);
		}
		free(title_elements);
	}

	title_elements = NULL;
	title_elements_len = 0;
	first_clear = false;
}

static struct title_element *AddTitleElement(void)
{
	++title_elements_len;
	title_elements = realloc(
		title_elements,
		title_elements_len * sizeof(struct title_element));
	if (title_elements == NULL) {
		abort();
	}
	return title_elements + title_elements_len - 1;
}

void AddTitleText(char *text, int x, int y, int color)
{
	struct title_element *el = AddTitleElement();
	el->type = TITLE_TEXT;
	el->v.text.x = x;
	el->v.text.y = y;
	el->v.text.color = color;
	el->v.text.text = text;
}

void AddTitleGround(GRNDTYPE *ground, unsigned int len)
{
	struct title_element *el = AddTitleElement();
	el->type = TITLE_GROUND;
	el->v.ground.ground = ground;
	el->v.ground.ground_len = len;
}

static void DrawTitleScreenText(void)
{
	struct title_element *el;
	int i, x;

	for (i = 0; i < title_elements_len; ++i) {
		el = &title_elements[i];
		if (el->type != TITLE_TEXT) {
			continue;
		}
		swcolor(el->v.text.color);

		x = el->v.text.x + X_OFFSET/8;
		if (!strcmp(el->v.text.text, MAGIC_VERSION)) {
			const char *s = "Version " PACKAGE_VERSION;
			x -= (strlen(s) + 1) / 2;
			swposcur(x, el->v.text.y);
			swputs(s);
		} else {
			swposcur(x, el->v.text.y);
			swputs(el->v.text.text);
		}
	}
}

static void DrawTitleScreenElements(void)
{
	struct title_element *el;
	int i, xoff;

	for (i = 0; i < title_elements_len; ++i) {
		el = &title_elements[i];
		switch (el->type) {
		case TITLE_SYMBOL:
			Vid_DispSymbol(el->v.sym.x + X_OFFSET, el->v.sym.y,
			               el->v.sym.sym, el->v.sym.color);
			break;
		case TITLE_GROUND:
			// The logic here ensures that the ground is correctly
			// aligned even if the screen width is changed.
			xoff = (SCR_WDTH - (int) el->v.ground.ground_len) / 2;
			swground(el->v.ground.ground - imin(xoff, 0),
			         imax(xoff, 0),
			         imin(el->v.ground.ground_len, SCR_WDTH));
			break;
		default:
			break;
		}
	}
}

void swtitln(void)
{
	int i;

	sound(S_TITLE, 0, NULL);

	// clear the screen
	Vid_ClearBuf();

	DrawTitleScreenElements();

	// We show the title screen, but after five seconds it switches to the
	// high score table instead.
	i = Timer_GetMS() - title_screen_start;
	if ((i / HIGH_SCORE_PERIOD) % 2 == 0) {
		DrawTitleScreenText();
	} else {
		DrawHighScoreTable();
	}
}

void swtitlf(void)
{
	if (titleflg) {
		return;
	}

	sound(0, 0, NULL);
	swsound();
}

bool ctlbreak(void)
{
	return Vid_GetCtrlBreak();
}

// clear bottom of screen
void clrprmpt(void)
{
	int x, y;

	for (y = 0; y <= 43; ++y)
		for (x = 0; x < SCR_WDTH; ++x) {
			Vid_PlotPixel(x, y, 0);
		}

	swposcur(0, 20);
}

static void TitleScreenBackground(void *unused)
{
	swtitln();
	clrprmpt();
}

static bool gethost(void)
{
	static char addrbuf[50];

	clrprmpt();

	swputs("Enter Remote Hostname/IP:\n");
	swgets(addrbuf, sizeof(addrbuf) - 3);
	asynhost = addrbuf;

	return strcmp(addrbuf, "") != 0;
}

#ifdef TCPIP
static enum menu_action StartNetgameListen(const struct menuitem *item)
{
	playmode = PLAYMODE_ASYNCH;
	asynmode = ASYN_LISTEN;
	return MENU_ACTION_RETURN;
}

static enum menu_action StartNetgameConnect(const struct menuitem *item)
{
	if (gethost()) {
		playmode = PLAYMODE_ASYNCH;
		asynmode = ASYN_CONNECT;
		return MENU_ACTION_RETURN;
	} else {
		return MENU_ACTION_NONE;
	}
}

static const struct menuitem netgame_menu_items[] = {
	{'L', "listen for connection",  StartNetgameListen},
	{'C', "connect to remote host", StartNetgameConnect},
	{0, NULL},
};

static const struct menu netgame_menu = {
	TitleScreenBackground, NULL,
	netgame_menu_items,
};
#endif

static enum menu_action StartNovice(const struct menuitem *item)
{
	playmode = PLAYMODE_NOVICE;
	return MENU_ACTION_RETURN;
}

static enum menu_action StartExpert(const struct menuitem *item)
{
	playmode = PLAYMODE_SINGLE;
	return MENU_ACTION_RETURN;
}

static const struct menuitem single_player_menu_items[] = {
	{'N', "novice player", StartNovice},
	{'E', "expert player", StartExpert},
	{0, NULL},
};

static const struct menu single_player_menu = {
	TitleScreenBackground, NULL,
	single_player_menu_items,
};

static enum menu_action StartVsComputer(const struct menuitem *item)
{
	playmode = PLAYMODE_COMPUTER;
	return MENU_ACTION_RETURN;
}

#ifdef __EMSCRIPTEN__
static enum menu_action OpenManual(const struct menuitem *item)
{
	emscripten_run_script("openManual()");
	return MENU_ACTION_NONE;
}

static enum menu_action InstallApp(const struct menuitem *item)
{
	emscripten_run_script("promptForInstall()");
	return MENU_ACTION_NONE;
}
#endif

#ifndef NO_EXIT
static enum menu_action QuitGame(const struct menuitem *item)
{
	exit(0);
	return MENU_ACTION_NONE;
}
#endif

static const struct menuitem main_menu_items[] = {
	{'S', "single player", SubMenu, &single_player_menu},
	{'C', "single player versus computer", StartVsComputer},
#ifdef TCPIP
	{'N', "network game", SubMenu, &netgame_menu},
#endif
	{'O', "game options", SubMenu, &options_menu},
#ifdef __EMSCRIPTEN__
	{'M', "open manual", OpenManual},
	{'I', "install as app", InstallApp},
#endif
#ifndef NO_EXIT
	{'Q', "quit game", QuitGame},
#endif
	{0, NULL},
};

static const struct menu main_menu = {
	TitleScreenBackground, NULL,
	main_menu_items,
};

void getgamemode(void)
{
	title_screen_start = Timer_GetMS();
	playmode = PLAYMODE_UNSET;
	while (playmode == PLAYMODE_UNSET) {
		RunMenu(&main_menu);
	}
}

//
// 2003-02-14: Code was checked into version control; no further entries
// will be added to this log.
//
// sdh 14/2/2003: change license header to GPL
// sdh 27/06/2002: move to new sopsym_t for symbols,
//                 remove references to symwdt, symhgt
// sdh 28/04/2002: Centering of title screen on non-320 pixel wide screens
// sdh 26/03/2002: change CGA_ to Vid_
// sdh 16/11/2001: TCPIP #define to disable TCP/IP support
// sdh 29/10/2001: moved options menu into swconf.c
// sdh 29/10/2001: harrykeys
// sdh 28/10/2001: rearranged title/menu stuff a bit
//                 added options menu
// sdh 21/10/2001: rearranged headers, added cvs tags
// sdh 19/10/2001: moved all the menus here
// sdh 19/10/2001: removed extern definitions, these are now in headers
// sdh 18/10/2001: converted all functions to ANSI-style arguments
// sdh ??/10/2001: added #define to control whether we use the classic
//                 title screen or the "network edition" one
//
// 2000-10-29      Copyright update.
// 99-01-24        1999 copyright.
// 96-12-27        New network version.
// 87-04-01        Version 7.F15
// 87-03-11        Title reformatting.
// 87-03-10        Microsoft compiler.
// 84-02-02        Development
//
