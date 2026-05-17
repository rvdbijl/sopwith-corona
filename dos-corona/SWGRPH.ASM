;
;	swgrph	 -	SW screen graphics
;
;	Copyright (C) 1984-2003 David L. Clark.
;	This program is free software; you can redistribute it and/or modify it under
;	the terms of the GNU General Public License as published by the Free Software
;	Foundation; either version 2 of the License, or (at your option) any later
;	version. This program is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;	or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
;	more details. You should have received a copy of the GNU General Public
;	License along with this program; if not, write to the Free Software Foundation,
;	Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
;
;	Modification History:
;			84-02-21	Development
;			84-06-13	PCjr Speed-up
;			85-11-05	Atari
;			87-03-10	Microsoft compiler
;			87-03-13	Splatted ox display
;			94-12-18	C6 Compiler
;			2003-01-27	GNU General Public License
;
;


%	.MODEL	model,lang
	INCLUDE mixed.inc

	.CODE

	include segments.h
	include sw.ha

CORONA_SEG_DEFAULT equ	03800H
CORONA_MODE	equ	0A9H
CORONA_YMAX	equ	324
CORONA_YOFF	equ	62
CORONA_PAGE_STEP equ	0800H
CORONA_ALLOC_PARAS equ	1000H
CORONA_PAGE_MASK equ	0F800H
CORCACHE_ENTRIES equ	12
CORCACHE_WORDS	equ	64
CORCACHE_BYTES	equ	(CORCACHE_WORDS*2)

	public	swdisp
	public	swground
	public	swputsym
	public	swputcol
	public	swclrcol
	public	swpntsym
	public	swpntcol
	public	get_type
	public	set_type
	public	setvdisp
	public	setadisp
	public	swcoronaclear
	public	swcoronamark
	public	swcoronatick
	public	swcoronasoundtick

	extrn	dispoxsplat:near
	extrn	soundadj:near



;----------------------------------------------------------------------------


swdisp:
	push	BP			; save registers
	push	DI
	push	SI
	push	ES

;
;	setup display in video ram
;
	call	setvdisp

;
;	for each object, delete the object from the screen if it currently
;	displayed, and re-draw the object if still on the screen
;

	mov	BX,objtop		; address of first object

disploop:
	or	BX,BX			; last object?
	jnz	disp00			;    NO  - continue
	jmp	dispdel 		;    YES - leave

disp00: mov	AX,OB_DELFLG[BX]	; is the object being deleted and
	and	AX,OB_DRWFLG[BX]	; redrawn?
	jz	disp0			;   NO - continue
	cmp	word ptr OB_SYMHGT[BX],1; is the object trivial?
	je	disp0			;   YES- continue
	mov	AX,OB_OLDSYM[BX]	; are the old object display and the
	cmp	AX,OB_NEWSYM[BX]	; new object display the same
	jne	disp0			;   NO - continue
	mov	AX,OB_Y[BX]		; is the object moving
	cmp	AX,OB_OLDY[BX]		; vertically?
	jne	disp0			;   YES - continue
	mov	AX,OB_OLDX[BX]		; is the object moving
	add	AX,displx		; with the player in
	cmp	AX,OB_X[BX]		; the x direction?
	jnz	disp0			;   NO - continue
	jmp	disp11			; test display function

disp0:
	cmp	word ptr OB_DELFLG[BX],0; is this object to be deleted?
	jz	disp1			;    NO  - skip
	mov	DI,OB_OLDY[BX]		;    YES - save old object y coord
	mov	SI,OB_OLDX[BX]		;		old object x coord
	mov	BP,OB_OLDSYM[BX]	;	   old symbol
	mov	AX,OB_CLR[BX]		;	   color of object
	call	drawsym 		;	   remove by xor draw

disp1:	cmp	word ptr OB_DRWFLG[BX],0; is the object to be drawn
	jz	disp3			;    NO  - skip
	mov	SI,OB_X[BX]		;    YES - load object x coord
	cmp	SI,displx		;	   object past left margin?
	jl	disp2			;	      YES - skip
	cmp	SI,disprx		;	   object past right margin?
	jg	disp2			;	      YES - skip
	sub	SI,displx		;	   get object x coord
	call	testox			;	   hidden due to splatted ox?
	je	disp2			;	      YES - skip

	mov	OB_OLDX[BX],SI		;	   save object x coord
	mov	DI,OB_Y[BX]		;	   save object y coord
	mov	OB_OLDY[BX],DI
	mov	BP,OB_NEWSYM[BX]	;		new symbol
	mov	AX,OB_CLR[BX]		;		color of object
	call	drawsym 		;	   draw the object

disp11: cmp	word ptr OB_DRAWF[BX],0 ;	   is there a display function?
	jz	disp3			;	      NO - skip
	push	BX			;	      YES- save object pointer
	call	word ptr OB_DRAWF[BX]	;		   call function
	pop	BX			;		   restore BX
	jmp	disp3

disp2:	mov	word ptr OB_DRWFLG[BX],0; indicate object not drawn
disp3:	mov	BX,OB_NEXT[BX]		; get next object in list
	jmp	disploop		; loop back

;
;	for each object in the newly deleted object list, delete
;	any images on screen
;

dispdel:

	mov	BX,deltop		; start of deleted object list

dispdlop:
	or	BX,BX			; last object on list?
	jz	dispret 		;   YES - leave

	cmp	word ptr OB_DELFLG[BX],0; is this object to be deleted?
	jz	dispd1			;    NO  - skip
	mov	DI,OB_OLDY[BX]		;    YES - save old object y coord
	mov	SI,OB_OLDX[BX]		;		old object x coord
	mov	BP,OB_OLDSYM[BX]	;	   old symbol
	mov	AX,OB_CLR[BX]		;	   color of object
	call	drawsym 		;	   remove by xor draw

dispd1: mov	BX,OB_NEXT[BX]		; get next object in list
	jmp	dispdlop		; loop back

dispret:
	cmp	word ptr oxsplatted,1	; ox splatted on screen?
	je	dispdone		;    YES - leave
	call	dispgrnd		; update ground display
	cmp	word ptr splatox,0	; hit the ox?
	jz	dispdone		;    NO - skip
	call	dispoxsplat		;    YES- splat the ox

dispdone:
	mov	word ptr dispinit,0	; reset initialized display flag
	mov	word ptr forcdisp,0	; reset force display flag
	pop	ES			; restore registers
	pop	SI
	pop	DI
	pop	BP
	ret


;-----------------------------------------------------------------------------

testox:
	cmp	word ptr oxsplatted,1	; OX splatted?
	jne	testr			;    NO - leave

	push	AX			; save registers
	push	DX			;
	mov	AX,SI			; X coordinate in AX
	mov	DL,106			; divide by 320/3
	div	DL			;
	test	AL,1			; test if to display
	pop	DX			; restore registers
	pop	AX			;

testr:	ret				; return

;-----------------------------------------------------------------------------

dispgrnd:
	cld				; clear direction flag
	cmp	word ptr dispinit,1	; first display after initialization?
	je	dg1			;   YES - skip erase of old ground
	cmp	dispdx,0		;	  is screen moving?
	jnz	dg0			;	  YES - continue
	cmp	forcdisp,0		;	  NO  - is display to be forced
	jnz	dg0			;		YES - continue
	ret				;		NO  - return

dg0:	lea	SI,grndsave		;   NO	- erase old ground by xor
	call	dispg			;	  redraw of ground

dg1:	mov	AX,DS			; set ES to DS for ground save
	mov	ES,AX
	lea	SI,ground		; start of ground address
	add	SI,displx		; start address of displayed ground
	mov	BX,SI			; save it
	lea	DI,grndsave		; address of ground save area
	mov	CX,(SCR_WDTH/2) 	; screen width in words
	rep	movsw			; save ground being displayed

	mov	SI,BX			; start address of displayed ground
	call	dispg			; display it
	ret

dispg:	mov	DX,disproff		; down raster line offset in DX
	cmp	byte ptr coronadisp,1
	jne	dg_cga
	call	corona_dispg
	ret

dg_cga:
	mov	BX,DX
	sub	BX,SCR_LINW		; up raster line offset in BX

	mov	AL,[SI] 		; initial ground height in AL
	mov	CL,AL			;			in CL
	sub	AL,(SCR_HGHT-1) 	; inverted ground height
	neg	AL			;
	shr	AL,1			; adjust for even/odd scan lines
	mov	CH,SCR_LINW		; line width
	mul	CH			; byte offset of first dot in AX

	test	CL,1			; is first dot on an odd scanline
	jnz	dg2			;    NO - skip
	add	AX,DX			;    YES- move to next segment
	neg	BX			;	  reverse up/down offsets
	neg	DX
	xchg	BX,DX

dg2:	add	AX,dispoff		; add display offset
	mov	DI,AX			; set final register

	mov	BP,SI			; start of ground to display
	add	BP,SCR_WDTH		; end of ground to display
	mov	CH,0C0H 		; initial ground dot mask
	mov	AH,[SI] 		; initial 'last ground height'
	mov	ES,dispseg		; screen segment

dgloop:
	lodsb				; get next ground height
	cmp	AL,AH			; compare new height to old
	ja	dga			;   ABOVE
	jb	dgb			;   BELOW

	xor	ES:[DI],CH		;   EQUAL - plot dot
	jmp	dgn			;	    get next pixel

dga:	add	DI,BX			;   ABOVE - move up a scan line
	neg	BX			;	    reverse up/down offsets
	neg	DX
	xchg	BX,DX
	xor	ES:[DI],CH		;	    plot dot
	inc	AH			;	    move up a height
	cmp	AL,AH			;	    where we want to be?
	jne	dga			;	       NO - up again
	jmp	dgn			;	       YES- get next pixel

dgb:	add	DI,DX			;   BELOW - move down a scan line
	neg	BX			;	    reverse up/down offsets
	neg	DX
	xchg	BX,DX
	xor	ES:[DI],CH		;	    plot dot
	dec	AH			;	    move down a height
	cmp	AL,AH			;	    where we want to be?
	jne	dgb			;	       NO - up again

dgn:	shr	CH,1			; shift plot mask right 2 bits
	shr	CH,1			;
	or	CH,CH			; end of byte?
	jnz	dgloop			;   NO - get next ground height
	inc	DI			;   YES- increment a byte
	mov	CH,0C0H 		;	 reset plot mask
	cmp	SI,BP			;	 end of ground display?
	jb	dgloop			;	    NO - get next ground height
	ret				;	    YES- bye



;-----------------------------------------------------------------------------

swground:
	push	BP			; save registers
	push	DI
	push	SI
	push	ES
	call	dispgrnd		; display ground for title screen
	pop	ES			; restore registers
	pop	SI
	pop	DI
	pop	BP
	ret




;-----------------------------------------------------------------------------

swclrcol:
	push	DI			; save registers
	push	SI
	push	ES

	cld				; clear direction flag
	mov	ES,dispseg		; get current display segment
	mov	SI,dispoff		; get current display offset
	add	SI,(((SCR_HGHT/2)-1)*SCR_LINW) ; offset of last line
	call	clearhalf		; clear even lines
	add	SI,disproff
	call	clearhalf		; clear odd lines

	pop	ES			; restore registers
	pop	SI
	pop	DI
	ret


clearhalf proc near
	mov	DI,SI			; starting address
	mov	CX,8			; clear 8 lines
	xor	AX,AX			; zero pattern in AX

cloop:	stosw				; clear 48 pixels
	stosw
	stosw
	stosw
	stosw
	stosw
	sub	DI,(SCR_LINW+12)	; reset to previous line
	loop	cloop			; do 8 times
	ret
clearhalf endp


;-----------------------------------------------------------------------------

swputsym:
	mov	BX,SP			; new frame pointer
	push	BP			; save other registers
	push	SI
	push	DI
	push	ES

	mov	SI,2[BX]		; load symbol x ccord
	mov	DI,4[BX]		;      symbol y coord
	mov	BX,6[BX]		;      object address
	mov	BP,OB_NEWSYM[BX]	;      current symbol
	mov	AX,OB_CLR[BX]		;      color of object
	call	drawsym 		; draw symbol

	pop	ES			; restore registers
	pop	DI
	pop	SI
	pop	BP
	ret


;-----------------------------------------------------------------------------

swpntsym:
	push	BP			; save SI
	mov	BP,SP			; new frame pointer
	push	SI			; save other registers
	push	DI
	push	ES

	mov	SI,4[BP]		; load point x ccord
	mov	DI,6[BP]		;      point y coord
	mov	BP,8[BP]		;      point color
	cmp	byte ptr coronadisp,1
	jne	pnt_cga
	call	corona_drawpnt
	jmp	pntret

pnt_cga:
	call	drawpnt 		; display point

pntret:
	pop	ES			; restore registers
	pop	DI
	pop	SI
	pop	BP
	ret


;-----------------------------------------------------------------------------

swputcol:
	mov	BX,SP			; new frame pointer
	push	BP			; save other registers
	push	SI
	push	DI
	push	ES

	mov	SI,2[BX]		; load symbol x ccord
	mov	DI,4[BX]		;      symbol y coord
	mov	BX,6[BX]		;      object address
	mov	BP,OB_NEWSYM[BX]	;      current symbol

	call	setup			; setup display parameters
	jnz	putc0			; symbol is a point?
	call	drawpntc		;    YES - draw point
	jmp	putcret 		;	   return

;	plot a rastor line of a symbol to the video ram.  Register
;	values at this time are
;		AL - byte count of segment display
;		AH - byte count of horizontal wraparound
;		BX - offset from end of symbol line to beginning of next
;		CL - number of bits to shift each byte
;		BP - number of lines to display
;		SI - pointer to first symbol byte to display
;		DI - pointer to first video ram byte to use

putc0:
	mov	retcode,0		; zero return code
putc1:
	push	AX			; save segment lengths AL
	push	DI			; save current video ram location
	xor	CH,CH			; reset byte rotation hold areas
	push	BX			; save line to line adjustment
	lea	BX,CS:trans		; address of byte translation table
	call	dispputc		; display segment

	cmp	AH,0			; wrap around segment ?
	jl	putc2			;  NO-	 goto normal carry processing
	mov	AL,AH			;  YES-  add wrap segment length
	xor	AH,AH			;	 to symbol address SI
	add	SI,AX
	jmp	putc3			;	 jump carry

putc2:
	cmp	CH,0			; shift carry present
	jz	putc3			;  NO -goto loop increment
	mov	DH,CH			; byte to plot
	call	collide 		; collision detection
	xor	ES:[DI],CH		; plot carry to ram
putc3:
	pop	BX			; restore line to line adjustment
	pop	DI			; restore old start location
	add	DI,BX			; destination to start of new line
	xchg	BX,adjrast		; exchange line to line offsets
	pop	AX			; restore segment lengths
	dec	BP			; decrement line counter
	jnz	putc1			; loop until line counter is 0

	mov	AL,retcode		; return code
	xor	AH,AH

putcret:
	pop	ES			; restore registers
	pop	DI
	pop	SI
	pop	BP
	ret

;	plot a rastor line segment to the video ram.  Register
;	values at this time are
;		AL - byte count of segment
;		AH - ---don't care---
;		BX - translate table address
;		CL - number of bits to shift each byte
;		CH - carry from previous shift
;		DX - screen line length in bytes
;		SI - pointer to first symbol byte to display
;		DI - pointer to first video ram byte to use

dispputc:
	xor	DL,DL			; clear shift carry area
	mov	DH,[SI] 		; symbol character
	shr	DX,CL			; shift right CL bits
	or	DH,CH			; or carry from previous shift
	call	collide 		; collision detection
	xor	ES:[DI],DH		; plot to video ram
	mov	CH,DL			; save carry
	inc	SI			; increment symbol pointer
	inc	DI			; video ram pointer
	dec	AL			; decrement byte counter
	jnz	dispputc		; loop until segment done

	ret



;-----------------------------------------------------------------------------

swpntcol:
	push	BP			; save BP
	mov	BP,SP			; new frame pointer
	push	SI			; save other registers
	push	DI
	push	ES

	mov	SI,4[BP]		; load point x ccord
	mov	DI,6[BP]		;      point y coord
	mov	BP,8[BP]		;      point color
	cmp	byte ptr coronadisp,1
	jne	pcol_cga
	call	corona_drawpntc
	jmp	pcolret

pcol_cga:
	call	drawpntc		; display point

pcolret:
	pop	ES			; restore registers
	pop	DI
	pop	SI
	pop	BP
	ret


;-----------------------------------------------------------------------------

drawsym:
	cmp	byte ptr coronadisp,1
	jne	ds_cga
	call	corona_drawsym
	ret

ds_cga:
	push	BX			; save object pointer

	push	BX			; set up mask for xor color adj.
	mov	BX,AX			;
	and	BX,3			;
	mov	AL,CS:cmsktab[BX]	;
	mov	colmask,AL		;
	pop	BX			;

	call	setup			; setup display parameters
	jnz	ds1			; symbol is a point?
	call	drawpnt 		;    YES - draw point
	jmp	dsret			;	   return

;	plot a rastor line of a symbol to the video ram.  Register
;	values at this time are
;		AL - byte count of segment display
;		AH - byte count of horizontal wraparound
;		BX - offset from end of symbol line to beginning of next
;		CL - number of bits to shift each byte
;		BP - number of lines to display
;		SI - pointer to first symbol byte to display
;		DI - pointer to first video ram byte to use

ds1:
	push	AX			; save segment lengths AL
	push	DI			; save current video ram location
	xor	CH,CH			; reset byte rotation hold areas
	push	BX			; save line to line adjustment
	lea	BX,CS:trans		; address of byte translation table
	call	dispds			; display segment

	cmp	AH,0			; wrap around segment ?
	jl	ds2			;  NO-	 goto normal carry processing
	mov	AL,AH			;  YES-  add wrap segment length
	xor	AH,AH			;	 to symbol address SI
	add	SI,AX
	jmp	ds3			;	 jump carry

ds2:
	cmp	CH,0			; shift carry present
	jz	ds3			;  NO -goto loop increment
	mov	DH,CH			; plot carry into ram using
	call	adjcolor		; color adjustment
	xor	ES:[DI],DH		;
ds3:
	pop	BX			; restore line to line adjustment
	pop	DI			; restore old start location
	add	DI,BX			; destination to start of new line
	xchg	BX,adjrast		; exchange line to line offsets
	pop	AX			; restore segment lengths
	dec	BP			; decrement line counter
	jnz	ds1			; loop until line counter is 0

dsret:
	pop	BX			; restore registers
	ret



;	plot a rastor line segment to the video ram.  Register
;	values at this time are
;		AL - byte count of segment
;		AH - ---don't care---
;		BX - rastor line offset
;		CL - number of bits to shift each byte
;		CH - carry from previous shift
;		DX - screen line length in bytes
;		SI - pointer to first symbol byte to display
;		DI - pointer to first video ram byte to use

dispds:
	xor	DL,DL			; clear shift carry area
	mov	DH,[SI] 		; symbol character
	shr	DX,CL			; shift right CL bits
	or	DH,CH			; or carry from previous shift

	call	adjcolor		; adjust symbol for color of object

	xor	ES:[DI],DH		; plot to video ram
	mov	CH,DL			; save carry
	inc	SI			; increment symbol pointer
	inc	DI			; video ram pointer
	dec	AL			; decrement byte counter
	jnz	dispds			; loop until segment done

	ret



;-----------------------------------------------------------------------------

drawpnt:
	cmp	byte ptr coronadisp,1
	jne	dp_cga
	call	corona_drawpnt
	ret

dp_cga:
;	invert row requested

	sub	DI,(SCR_HGHT - 1 )
	neg	DI

;	calculate the number of bits to rotate the colour
;	the column position is not byte aligned.  (CL)

	mov	CX,SI			; pixel column requested
	and	CL,03H			; pixel offset in CL
	sub	CL,3			; inverted
	neg	CL
	shl	CL,1			; bits to rotate in CL

;	determine first video ram byte to use and store in AX

	mov	AX,DI			; starting row in AX.
	shr	AX,1			; divide by 2 for even/odd rastor lines
	mov	DX,SCR_WDTH
	mul	DX			; end of previous row in DX:AX
	add	AX,SI			; pixel offset in DX:AX
	adc	DX,0			; handle carry into DX
	shr	DX,1			; shift DX:AX by 2
	rcr	AX,1
	shr	DX,1
	rcr	AX,1			; byte offset in AX
	mov	SI,AX			;	      in SI

;	adjust byte offset if line odd

	test	DI,01H			; Row odd?
	jz	dp1			;   NO - skip
	add	SI,disproff		; first video ram byte
dp1:
	mov	AX,dispseg		; save video ram segment
	mov	ES,AX
	add	SI,dispoff

;	plot the current colour, or exclusive or the current colour based
;	on the first bit of the colour.

	mov	AX,BP
	and	AL,83H
	test	AL,80H
	jnz	dp2

	mov	CH,03H
	shl	CH,CL
	mov	DH,ES:[SI]
	and	CH,DH
	xor	DH,CH
	rol	AL,CL
	or	DH,AL
	mov	ES:[SI],DH
	ret

dp2:	and	AL,7FH
	shl	AL,CL
	xor	ES:[SI],AL
	ret



;-----------------------------------------------------------------------------

drawpntc:

;	invert row requested

	sub	DI,(SCR_HGHT - 1 )
	neg	DI

;	calculate the number of bits to rotate the colour
;	the column position is not byte aligned.  (CL)

	mov	CX,SI			; pixel column requested
	and	CL,03H			; pixel offset in CL
	sub	CL,3			; inverted
	neg	CL
	shl	CL,1			; bits to rotate in CL

;	determine first video ram byte to use and store in AX

	mov	AX,DI			; starting row in AX.
	shr	AX,1			; divide by 2 for even/odd rastor lines
	mov	DX,SCR_WDTH
	mul	DX			; end of previous row in DX:AX
	add	AX,SI			; pixel offset in DX:AX
	adc	DX,0			; handle carry into DX
	shr	DX,1			; shift DX:AX by 2
	rcr	AX,1
	shr	DX,1
	rcr	AX,1			; byte offset in AX
	mov	SI,AX			;	      in BX

;	adjust byte offset if line odd

	test	DI,01H			; Row odd?
	jz	dpc1			;   NO - skip
	add	SI,disproff		; first video ram byte
dpc1:
	mov	AX,dispseg		; save video ram segment
	mov	ES,AX
	add	SI,dispoff

;	create	mask to return colour of point previous to plot

	mov	CH,03H
	shl	CH,CL
	and	CH,ES:[SI]

;	plot the current colour, or exclusive or the current colour based
;	on the first bit of the colour.

	mov	AX,BP
	and	AL,83H
	test	AL,80H
	jnz	dpc2

	xor	ES:[SI],CH
	rol	AL,CL
	or	ES:[SI],AL
	jmp	dpc3

dpc2:	and	AL,7FH
	shl	AL,CL
	xor	ES:[SI],AL

;
;	return the color code found
;

dpc3:
	shr	CH,CL
	mov	AL,CH
	xor	AH,AH
	ret


;----------------------------------------------------------------------------

;
;	if symbol height and width are 1, signal point code
;

setup:
	cmp	word ptr OB_SYMHGT[BX],1
	jne	stp1
	cmp	word ptr OB_SYMWDT[BX],1
	jne	stp1
	ret

;	invert row requested

stp1:
	sub	DI,(SCR_HGHT - 1 )
	neg	DI

;	calculate the number of bits to rotate a symbol byte if
;	the column position is not byte aligned.  (CL)

	mov	CX,SI			; pixel column requested
	and	CL,03H			; bit offset in CL
	shl	CL,1			; bits to rotate in CL

;	calculate byte count for on scan line taking into account vertical
;	screen boundaries.  Place in AL.    Place any overwrap in AH.

	mov	AX,OB_SYMWDT[BX]	; symbol width in pixels
	shr	AX,1			;	  then in bytes in AL
	shr	AX,1

	mov	DX,SI			; pixel column requested
	shr	DX,1			; pixel byte offset in DL
	shr	DX,1
	sub	DL,SCR_LINW		; screen width in bytes
	neg	DL			; available bytes for symbol in DL

	mov	AH,AL
	sub	AH,DL			; symbol width less than available?
	jle	stp2			; YES - skip
	mov	AL,DL			; NO -	available bytes in AL
stp2:

;	calculate line count for the symbol taking into account horizontal
;	boundaries, and push in stack

	push	AX			; save AX, segment length count
	mov	AX,OB_SYMHGT[BX]	; symbol height in AX
	mov	DX,SCR_HGHT		; screen height
	sub	DX,DI			; available lines for symbol in DX
	cmp	AX,DX			; symbol height less than available?
	jbe	stp3			; YES - skip
	mov	AX,DX			; NO -	available lines in DI
stp3:
	push	AX

;	determine first video ram byte to use and store in AX

	mov	AX,DI			; starting row in AX.
	shr	AX,1			; divide by 2 for even/odd rastor lines
	mov	DX,SCR_WDTH
	mul	DX			; end of previous row in DX:AX
	add	AX,SI			; pixel offset in DX:AX
	adc	DX,0			; handle carry into DX
	shr	DX,1			; shift DX:AX by 2
	rcr	AX,1
	shr	DX,1
	rcr	AX,1			; byte offset in AX

;	store rastor line width in DX, and calculate line to line offsets
;	as 'rastor line offset' and DX - 'rastor line offset'

	mov	DX,SCR_LINW		; line width in bytes in DX
	mov	BX,disproff		; even to odd line offset in BX
	mov	adjrast,DX
	sub	adjrast,BX		; odd to even line offset

;	adjust first video ram byte to use, and reverse rastor line
;	offsets if starting on an odd line

	test	DI,01H			; Row odd?
	jz	stp4			;   NO - skip
	add	AX,BX			; first video ram byte
	xchg	BX,adjrast		; exchange offsets
stp4:

;	setup final registers for display

	mov	SI,dispseg		; save video ram segment
	mov	ES,SI
	mov	SI,BP			; access pointer to symbol
	mov	DI,AX			; set video ram destination
	add	DI,dispoff
	pop	BP			; line count for display
	pop	AX			; restore segment length

	or	AX,AX			; return not zero
	ret


;-----------------------------------------------------------------------------
;
;	routine to perform collision detection between DH and ES:[DI]
;

collide:
	push	AX			; save AX
	mov	AL,DH			; byte to plot in AL
	xlat	CS:trans		; translate
	and	AL,ES:[DI]		; non-zero if collision
	or	retcode,AL
	pop	AX
	ret


;------------------------------------------------------------------------------
;
;	routine to adjust the color of an object
;

adjcolor:
	push	AX			; save AX
	mov	AL,DH			; byte to plot in AL
	xlat	CS:trans		; translate to ones for xor
	and	AL,colmask		; mask off if color 1
	xor	DH,AL			; convert 01-10 if color 2
	pop	AX			; restore AX
	ret

;
;	translation table corresponding to any 2-bit non zero portion
;	of a byte set to 11.
;
trans	db	00H,03H,03H,03H,0CH,0FH,0FH,0FH,0CH,0FH,0FH,0FH,0CH,0FH,0FH,0FH
	db	30H,33H,33H,33H,3CH,3FH,3FH,3FH,3CH,3FH,3FH,3FH,3CH,3FH,3FH,3FH
	db	30H,33H,33H,33H,3CH,3FH,3FH,3FH,3CH,3FH,3FH,3FH,3CH,3FH,3FH,3FH
	db	30H,33H,33H,33H,3CH,3FH,3FH,3FH,3CH,3FH,3FH,3FH,3CH,3FH,3FH,3FH
	db	0C0H,0C3H,0C3H,0C3H,0CCH,0CFH,0CFH,0CFH,0CCH,0CFH,0CFH,0CFH,0CCH,0CFH,0CFH,0CFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0C0H,0C3H,0C3H,0C3H,0CCH,0CFH,0CFH,0CFH,0CCH,0CFH,0CFH,0CFH,0CCH,0CFH,0CFH,0CFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0C0H,0C3H,0C3H,0C3H,0CCH,0CFH,0CFH,0CFH,0CCH,0CFH,0CFH,0CFH,0CCH,0CFH,0CFH,0CFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH
	db	0F0H,0F3H,0F3H,0F3H,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH,0FCH,0FFH,0FFH,0FFH

;
;	mask for xor color adjustments
;

cmsktab db	0,0,0FFH,0



;------------------------------------------------------------------------------
;
;	get_type();
;	set_type( type );
;
;	get/set screen types
;


get_type:
	mov	AH,15			; get state function
	int	10H			; get video state in AL
	xor	AH,AH			;		  in AX
	ret				; return


set_type:
	push	BP			; save frame pointer
	mov	BP,SP			; new frame pointer
	mov	AL,@AB[BP]		; get mode in AL
	cmp	AL,4			; Corona substitutes for CGA modes
	jb	st_bios
	cmp	AL,6
	ja	st_bios
	call	corona_enter
	jmp	st_ret
st_bios:
	push	AX
	call	corona_release
	pop	AX
	mov	word ptr coronatxt,0
	xor	AH,AH			; set video mode function
	int	10H			; do it
st_ret:
	pop	BP			; restore frame pointer
	ret				; return



;------------------------------------------------------------------------------
;
;	setvdisp();
;	setadisp();
;
;	set current display to video/alternate buffer
;


setvdisp:
	mov	AX,coronaseg
	mov	dispseg,AX
	mov	word ptr dispoff,0
	mov	word ptr disproff,0
	mov	byte ptr coronadisp,1
	ret


setadisp:
	mov	word ptr dispseg,DS
	mov	word ptr dispoff,( offset DGROUP:auxdisp - 1000H )
	mov	word ptr disproff,1000H
	mov	byte ptr coronadisp,0
	ret				; return


;------------------------------------------------------------------------------
;
;	Corona/Cordata PPC-21 native graphics support.
;
;	The PPC-21 graphics page layout is:
;
;	offset = ((y mod 13) << 11) + ((y / 13) * 80) + (x >> 3)
;	mask   = 01h << (x & 7)
;
;	Sopwith's game coordinates are 320 x 200.  The first-pass Corona
;	renderer doubles X pixels and centers the 200-line game image inside
;	the 325-line PPC-21 graphics display.
;

corona_enter:
	push	AX
	push	BX
	push	CX
	push	DX
	push	DI
	push	ES

	call	corona_alloc_page
	call	corona_init_ytab
	call	corona_init_masktab
	call	corona_init_symcache
	mov	word ptr coronatxt,1

	mov	AX,0007H		; start from MDA-compatible text mode
	int	10H

	mov	DX,03B8H		; enable Corona graphics mode
	mov	AL,CORONA_MODE
	out	DX,AL

	mov	DX,03B4H		; CRTC start address high
	mov	AL,0CH
	out	DX,AL
	inc	DX
	mov	AL,coronacrtc
	out	DX,AL
	dec	DX
	mov	AL,0DH			; CRTC start address low = 00h
	out	DX,AL
	inc	DX
	xor	AL,AL
	out	DX,AL

	call	swcoronaclear

	pop	ES
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret


swcoronaclear:
	push	AX
	push	CX
	push	DI
	push	ES

	mov	AX,coronaseg		; clear the whole 32 KiB page
	mov	ES,AX
	xor	DI,DI
	xor	AX,AX
	mov	CX,4000H
	rep	stosw

	pop	ES
	pop	DI
	pop	CX
	pop	AX
	ret


swcoronamark:
	push	BP
	mov	BP,SP
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI
	push	DI
	push	ES

	mov	BX,4[BP]		; marker count, 1..40
	cmp	BX,40
	jbe	scm_count_ok
	mov	BX,40
scm_count_ok:

	mov	AX,coronaseg		; draw in the physical top margin
	mov	ES,AX			; y = 26..33, x = 32..351
	xor	DX,DX
scm_row_loop:
	mov	DI,160+4		; y / 13 = 2, x / 8 = 4
	mov	AX,DX
	mov	CL,11
	shl	AX,CL			; (y % 13) * 2048
	add	DI,AX

	xor	AL,AL			; clear the full marker strip
	mov	CX,80
	push	DI
	rep	stosb
	pop	DI

	mov	CX,BX			; draw one byte-wide bar per mark
	or	CX,CX
	jz	scm_next_row
	mov	AL,0FFH
scm_bar_loop:
	stosb
	inc	DI			; one-byte gap between bars
	loop	scm_bar_loop

scm_next_row:
	inc	DX
	cmp	DX,8
	jb	scm_row_loop

scm_ret:
	pop	ES
	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	pop	BP
	ret


swcoronatick:
	push	AX
	push	BX
	push	CX
	push	DX
	push	ES

	mov	AX,0040H		; BIOS data area timer tick
	mov	ES,AX
	mov	AX,ES:[006CH]
	mov	BX,corlasttick
	mov	corlasttick,AX
	cmp	BX,0FFFFH
	je	sct_first
	sub	AX,BX
	je	sct_spin
	cmp	AX,4			; avoid huge catch-up bursts
	jbe	sct_count
	mov	AX,4
	jmp	sct_count

sct_first:
	mov	AX,1

sct_count:
	mov	word ptr cortickspin,0
	mov	CX,AX
	mov	BX,AX
	shl	BX,1			; BX = elapsed * 2
	shl	AX,1
	shl	AX,1
	shl	AX,1			; AX = elapsed * 8
	add	AX,BX			; AX = elapsed * 10
	add	word ptr movetick,AX

sct_sound:
	push	CX
	call	soundadj
	pop	CX
	loop	sct_sound

sct_ret:
	pop	ES
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret

sct_spin:
	inc	word ptr cortickspin	; do not let the frame wait wedge if
	cmp	word ptr cortickspin,2048 ; the BIOS tick path stalls unexpectedly
	jb	sct_ret
	mov	word ptr cortickspin,0
	mov	AX,1
	jmp	sct_count


swcoronasoundtick:
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI
	push	DI
	push	BP
	push	ES
	push	DS

	cmp	word ptr coronatxt,0
	je	scst_ret

	inc	word ptr corsndspin	; fallback for machines where the
	cmp	word ptr corsndspin,96	; BIOS tick path does not advance sound
	jb	scst_bios
	mov	word ptr corsndspin,0
	call	soundadj

scst_bios:
	mov	AX,0040H		; BIOS data area timer tick
	mov	ES,AX
	mov	AX,ES:[006CH]
	mov	BX,corsndtick
	mov	corsndtick,AX
	cmp	BX,0FFFFH
	je	scst_ret
	sub	AX,BX
	jz	scst_ret
	cmp	AX,4			; bound catch-up after long redraws
	jbe	scst_count
	mov	AX,4
scst_count:
	mov	CX,AX
scst_loop:
	push	CX
	call	soundadj
	pop	CX
	loop	scst_loop

scst_ret:
	pop	DS
	pop	ES
	pop	BP
	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret


corona_calc:
;	Input:	SI = Sopwith X coordinate, 0..319
;		DI = Sopwith Y coordinate, 0..199
;	Output:	ES:BX = Corona byte address
;		DH = two-pixel mask for doubled X
;		CF set if the point is outside the logical game area.

	cmp	SI,SCR_WDTH
	jae	cc_bad
	cmp	DI,SCR_HGHT
	jae	cc_bad

	mov	BX,DI
	shl	BX,1
	mov	BX,corytab[BX]

	mov	AX,SI
	shr	AX,1			; doubled X byte offset = X / 4
	shr	AX,1
	add	BX,AX

	mov	DH,03H			; doubled X bit pair
	mov	CX,SI
	and	CL,03H
	shl	CL,1
	shl	DH,CL

	mov	AX,coronaseg
	mov	ES,AX
	clc
	ret

cc_bad:
	stc
	ret


corona_dup_addr:
;	Input:	SI = Sopwith X coordinate, DI = Sopwith Y coordinate
;	Output:	ES:BX = duplicate Corona row address, CF set if no duplicate row.

	mov	BX,DI
	cmp	byte ptr cordup[BX],0
	je	cda_bad
	shl	BX,1
	mov	BX,corytab2[BX]

	mov	AX,SI
	shr	AX,1
	shr	AX,1
	add	BX,AX

	clc
	ret

cda_bad:
	stc
	ret


corona_alloc_page:
;	Reserve a DOS memory block for the Corona framebuffer.  The display
;	start must be 32 KiB aligned, so allocate 64 KiB and use the next
;	aligned 32 KiB page inside the block.

	push	AX
	push	BX
	push	CX
	push	DX

	mov	AX,coronablock
	or	AX,AX
	jnz	cap_have_block

	mov	AH,48H			; DOS allocate memory
	mov	BX,CORONA_ALLOC_PARAS
	int	21H
	jc	cap_fallback
	mov	coronablock,AX

cap_have_block:
	mov	AX,coronablock
	add	AX,( CORONA_PAGE_STEP - 1 )
	and	AX,CORONA_PAGE_MASK
	jmp	cap_use

cap_fallback:
	mov	AX,CORONA_SEG_DEFAULT

cap_use:
	mov	coronaseg,AX
	mov	coronacrtc,AH		; page segment 3800h -> CRTC high 38h

	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret


corona_release:
	push	AX
	push	ES

	mov	AX,coronablock
	or	AX,AX
	jz	cr_done

	mov	ES,AX
	mov	AH,49H			; DOS free memory
	int	21H
	mov	word ptr coronablock,0

cr_done:
	pop	ES
	pop	AX
	ret


corona_init_ytab:
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI
	push	DI

	xor	DI,DI			; logical Sopwith Y

ciy_loop:
	mov	AX,(SCR_HGHT-1)
	sub	AX,DI
	add	AX,CORONA_YOFF

	mov	corphys,AX
	call	corona_yoffset

	mov	SI,DI
	shl	SI,1
	mov	corytab[SI],BX
	mov	corytab2[SI],BX
	mov	byte ptr cordup[DI],0

	inc	DI
	cmp	DI,SCR_HGHT
	jb	ciy_loop

	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret


corona_yoffset:
;	Input:	AX = physical Corona Y, 0..324
;	Output:	BX = byte offset for X byte column zero on that Y.

	mov	BL,13
	div	BL			; AL = y / 13, AH = y mod 13

	mov	DL,AH
	xor	AH,AH
	mov	BX,AX
	shl	AX,1			; quotient * 16
	shl	AX,1
	shl	AX,1
	shl	AX,1
	mov	CL,6
	shl	BX,CL			; quotient * 64
	add	BX,AX			; quotient * 80

	mov	AL,DL
	xor	AH,AH
	mov	CL,11
	shl	AX,CL			; remainder * 2048
	add	BX,AX
	ret


corona_init_masktab:
;	Build source-byte/x-phase -> Corona word-mask table.  Each CGA symbol
;	byte contains four two-bit pixels; Corona draws any nonzero CGA color as
;	a doubled monochrome pixel.  Precomputing this removes branchy mask
;	assembly from the runtime symbol loop.

	push	AX
	push	BX
	push	CX
	push	DX
	push	SI
	push	DI
	push	ES

	mov	AX,DS
	mov	ES,AX
	lea	DI,cormtab
	xor	SI,SI
	cld

cim_src_loop:
	mov	AX,SI
	xor	BX,BX
	test	AL,0C0H
	jz	cim_mask1
	or	BL,03H
cim_mask1:
	test	AL,030H
	jz	cim_mask2
	or	BL,0CH
cim_mask2:
	test	AL,00CH
	jz	cim_mask3
	or	BL,30H
cim_mask3:
	test	AL,003H
	jz	cim_mask_done
	or	BL,0C0H
cim_mask_done:
	mov	DX,BX
	xor	CX,CX

cim_phase_loop:
	mov	AX,DX
	push	CX
	shl	CL,1
	shl	AX,CL
	pop	CX
	stosw
	inc	CX
	cmp	CX,4
	jb	cim_phase_loop

	inc	SI
	cmp	SI,256
	jb	cim_src_loop

	pop	ES
	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret


corona_init_symcache:
	push	AX
	push	CX
	push	DI
	push	ES

	mov	AX,DS
	mov	ES,AX
	xor	AX,AX
	mov	CX,CORCACHE_ENTRIES
	lea	DI,corcache_sym
	cld
	rep	stosw
	mov	word ptr corcache_next,0

	pop	ES
	pop	DI
	pop	CX
	pop	AX
	ret


corona_getcache:
;	Input:	BP = source symbol, corphase = x phase, corcachecnt = source byte count.
;	Output:	AX = cache data offset containing word masks for this symbol/phase.

	push	BX
	push	CX
	push	DX
	push	SI
	push	DI
	push	BP
	push	ES

	xor	SI,SI
	mov	CX,CORCACHE_ENTRIES

cgc_find:
	cmp	corcache_sym[SI],BP
	jne	cgc_next
	mov	AX,corphase
	cmp	corcache_phase[SI],AX
	je	cgc_found

cgc_next:
	add	SI,2
	loop	cgc_find

	mov	SI,corcache_next
	inc	word ptr corcache_next
	cmp	word ptr corcache_next,CORCACHE_ENTRIES
	jb	cgc_slot_ok
	mov	word ptr corcache_next,0
cgc_slot_ok:
	mov	DI,SI
	shl	DI,1
	mov	corcache_sym[DI],BP
	mov	AX,corphase
	mov	corcache_phase[DI],AX
	jmp	cgc_build

cgc_build:
	mov	AX,SI
	mov	CL,7
	shl	AX,CL
	mov	BX,AX
	lea	DI,corcache_data[BX]
	mov	DX,DI			; return cache base
	mov	AX,DS
	mov	ES,AX
	mov	SI,BP
	mov	CX,corcachecnt
	cld

cgc_build_loop:
	lodsb
	mov	BL,AL
	xor	BH,BH
	shl	BX,1
	shl	BX,1
	shl	BX,1
	add	BX,corphase
	mov	AX,cormtab[BX]
	stosw
	loop	cgc_build_loop

	mov	AX,DX
	jmp	cgc_ret

cgc_found:
	mov	AX,SI
	shr	AX,1
	mov	CL,7
	shl	AX,CL
	mov	BX,AX
	lea	AX,corcache_data[BX]

cgc_ret:
	pop	ES
	pop	BP
	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	ret


corona_xor_point:
	push	AX
	push	BX
	push	CX
	push	DX
	push	ES

	call	corona_calc
	jc	cxp_ret
	xor	ES:[BX],DH
	mov	AL,DH
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cxp_ret
	xor	ES:[BX],AL
cxp_ret:
	pop	ES
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret


corona_drawpnt:
	call	corona_calc
	jc	cdp_ret

	mov	AL,DH
	mov	CX,BP
	test	CL,80H
	jnz	cdp_xor
	and	CL,03H
	jz	cdp_clear
	or	ES:[BX],AL
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cdp_ret
	or	ES:[BX],AL
	ret

cdp_clear:
	not	AL
	and	ES:[BX],AL
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cdp_ret
	and	ES:[BX],AL
	ret

cdp_xor:
	xor	ES:[BX],AL
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cdp_ret
	xor	ES:[BX],AL
cdp_ret:
	ret


corona_drawpntc:
	call	corona_calc
	jc	cdpc_bad

	mov	DL,DH			; save Corona bit pair mask
	mov	AL,ES:[BX]		; old monochrome pixel -> CGA-ish color
	and	AL,DL
	jz	cdpc_old_zero
	mov	AH,03H
	jmp	cdpc_have_old

cdpc_old_zero:
	xor	AH,AH

cdpc_have_old:
	mov	CX,BP
	test	CL,80H
	jnz	cdpc_xor
	and	CL,03H
	jz	cdpc_clear
	or	ES:[BX],DL
	mov	AL,DL
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cdpc_ret
	or	ES:[BX],AL
	jmp	cdpc_ret

cdpc_clear:
	mov	AL,DL
	not	AL
	and	ES:[BX],AL
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cdpc_ret
	and	ES:[BX],AL
	jmp	cdpc_ret

cdpc_xor:
	xor	ES:[BX],DL
	mov	AL,DL
	push	AX
	call	corona_dup_addr
	pop	AX
	jc	cdpc_ret
	xor	ES:[BX],AL

cdpc_ret:
	mov	AL,AH
	xor	AH,AH
	ret

cdpc_bad:
	xor	AX,AX
	ret


corona_drawsym:
	push	BX
	push	CX
	push	DX
	push	SI
	push	DI
	push	BP
	push	ES

	mov	corclr,AX

	cmp	word ptr OB_SYMHGT[BX],1
	jne	cds_symbol
	cmp	word ptr OB_SYMWDT[BX],1
	jne	cds_symbol
	call	corona_drawpnt
	jmp	cds_done

cds_symbol:
	mov	corx,SI
	mov	cory,DI
	mov	corsym,BP

	mov	AX,OB_SYMHGT[BX]
	mov	CX,DI
	inc	CX
	cmp	AX,CX
	jbe	cds_rows_ok
	mov	AX,CX
cds_rows_ok:
	mov	corrows,AX

	mov	AX,OB_SYMWDT[BX]
	shr	AX,1
	shr	AX,1
	mov	corbytes,AX
	mov	byte ptr corcacheuse,0

	mov	AX,corx
	and	AX,3
	shl	AX,1
	mov	corphase,AX

	mov	AX,corx			; use cached expanded masks only for
	cmp	AX,SCR_WDTH		; fully visible common-size sprites
	jae	cds_no_cache
	add	AX,OB_SYMWDT[BX]
	cmp	AX,SCR_WDTH
	ja	cds_no_cache
	mov	AX,corbytes
	mul	word ptr OB_SYMHGT[BX]
	cmp	AX,CORCACHE_WORDS
	ja	cds_no_cache
	mov	corcachecnt,AX
	call	corona_getcache
	mov	corcachebase,AX
	mov	byte ptr corcacheuse,1

cds_no_cache:

	mov	AX,coronaseg
	mov	ES,AX

	cmp	byte ptr corcacheuse,0
	jz	cds_src_ptr
	mov	BP,corcachebase
	jmp	cds_have_ptr
cds_src_ptr:
	mov	BP,corsym
cds_have_ptr:
	xor	DX,DX			; row index
cds_row_loop:
	cmp	DX,corrows
	jae	cds_done

	mov	AX,cory
	sub	AX,DX
	mov	cury,AX
	mov	BX,AX
	mov	AL,cordup[BX]
	mov	corduprow,AL
	shl	BX,1
	mov	AX,corytab[BX]
	mov	corrow1,AX
	mov	AX,corytab2[BX]
	mov	corrow2,AX

	mov	AX,corx
	mov	curx,AX
	shr	AX,1
	shr	AX,1
	mov	corxbyte,AX
	xor	CX,CX			; byte index
cds_byte_loop:
	cmp	CX,corbytes
	jae	cds_next_row
	cmp	byte ptr corcacheuse,0
	jne	cds_cached_byte

	mov	AL,[BP]
	mov	corbyte,AL

	mov	AX,curx
	cmp	AX,SCR_WDTH
	jae	cds_advance
	cmp	AX,(SCR_WDTH-4)
	ja	cds_clip_byte

	mov	DI,corrow1
	add	DI,corxbyte

	mov	BL,corbyte
	xor	BH,BH
	shl	BX,1
	shl	BX,1
	shl	BX,1
	add	BX,corphase
	mov	AX,cormtab[BX]
	or	AX,AX
	jz	cds_advance

	push	CX
	mov	cormask,AX
	xor	ES:[DI],AL
	or	AH,AH
	jz	cds_emit_done
	xor	ES:1[DI],AH
cds_emit_done:
	cmp	byte ptr corduprow,0
	jz	cds_emit_pop
	mov	DI,corrow2
	add	DI,corxbyte
	mov	AX,cormask
	xor	ES:[DI],AL
	or	AH,AH
	jz	cds_emit_pop
	xor	ES:1[DI],AH
cds_emit_pop:
	pop	CX
	jmp	cds_advance

cds_cached_byte:
	mov	DI,corrow1
	add	DI,corxbyte

	mov	AX,[BP]
	or	AX,AX
	jz	cds_advance_cached

	mov	cormask,AX
	xor	ES:[DI],AL
	or	AH,AH
	jz	cds_cached_done
	xor	ES:1[DI],AH
cds_cached_done:
	cmp	byte ptr corduprow,0
	jz	cds_advance_cached
	mov	DI,corrow2
	add	DI,corxbyte
	mov	AX,cormask
	xor	ES:[DI],AL
	or	AH,AH
	jz	cds_advance_cached
	xor	ES:1[DI],AH
	jmp	cds_advance_cached

cds_clip_byte:

	mov	AL,corbyte
	and	AL,0C0H
	jz	cds_pix1
	mov	SI,curx
	mov	DI,cury
	call	corona_xor_point

cds_pix1:
	mov	AL,corbyte
	and	AL,030H
	jz	cds_pix2
	mov	SI,curx
	inc	SI
	mov	DI,cury
	call	corona_xor_point

cds_pix2:
	mov	AL,corbyte
	and	AL,00CH
	jz	cds_pix3
	mov	SI,curx
	add	SI,2
	mov	DI,cury
	call	corona_xor_point

cds_pix3:
	mov	AL,corbyte
	and	AL,003H
	jz	cds_advance
	mov	SI,curx
	add	SI,3
	mov	DI,cury
	call	corona_xor_point

cds_advance:
	inc	BP
	inc	CX
	add	word ptr curx,4
	inc	word ptr corxbyte
	jmp	cds_byte_loop

cds_advance_cached:
	add	BP,2
	inc	CX
	add	word ptr curx,4
	inc	word ptr corxbyte
	jmp	cds_byte_loop

cds_next_row:
	inc	DX
	jmp	cds_row_loop

cds_done:
	pop	ES
	pop	BP
	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	ret


corona_dispg:
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI
	push	DI
	push	BP
	push	ES

	mov	BP,SI
	mov	AX,coronaseg
	mov	ES,AX
	xor	SI,SI			; Corona byte column, four game pixels
cdg_loop:
	cmp	SI,(SCR_WDTH/4)
	jae	cdg_done

	mov	AL,[BP]
	xor	AH,AH
	mov	BX,AX
	mov	DI,BX
	shl	DI,1
	mov	DI,corytab[DI]
	add	DI,SI
	xor	byte ptr ES:[DI],03H
	cmp	byte ptr cordup[BX],0
	je	cdg_pix2
	shl	BX,1
	mov	DI,corytab2[BX]
	add	DI,SI
	xor	byte ptr ES:[DI],03H
cdg_pix2:
	inc	BP

	mov	AL,[BP]
	xor	AH,AH
	mov	BX,AX
	mov	DI,BX
	shl	DI,1
	mov	DI,corytab[DI]
	add	DI,SI
	xor	byte ptr ES:[DI],0CH
	cmp	byte ptr cordup[BX],0
	je	cdg_pix3
	shl	BX,1
	mov	DI,corytab2[BX]
	add	DI,SI
	xor	byte ptr ES:[DI],0CH
cdg_pix3:
	inc	BP

	mov	AL,[BP]
	xor	AH,AH
	mov	BX,AX
	mov	DI,BX
	shl	DI,1
	mov	DI,corytab[DI]
	add	DI,SI
	xor	byte ptr ES:[DI],30H
	cmp	byte ptr cordup[BX],0
	je	cdg_pix4
	shl	BX,1
	mov	DI,corytab2[BX]
	add	DI,SI
	xor	byte ptr ES:[DI],30H
cdg_pix4:
	inc	BP

	mov	AL,[BP]
	xor	AH,AH
	mov	BX,AX
	mov	DI,BX
	shl	DI,1
	mov	DI,corytab[DI]
	add	DI,SI
	xor	byte ptr ES:[DI],0C0H
	cmp	byte ptr cordup[BX],0
	je	cdg_next
	shl	BX,1
	mov	DI,corytab2[BX]
	add	DI,SI
	xor	byte ptr ES:[DI],0C0H
cdg_next:
	inc	BP

	inc	SI
	jmp	cdg_loop

cdg_done:
	pop	ES
	pop	BP
	pop	DI
	pop	SI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret




	.DATA

adjrast  dw	?			; rastor line offset save area
colmask  db	?			;
retcode  db	?			; return code
grndsave db	SCR_WDTH dup (?)	; ground save area
dispseg  dw	?			; Display segment
dispoff  dw	?			;	  offset
disproff dw	?			;	  inter bank offset
coronadisp db	0			; drawing visible Corona page?
coronaseg dw	CORONA_SEG_DEFAULT	; selected Corona graphics page
coronacrtc db	38H			; selected CRTC start high byte
coronablock dw	0			; DOS block containing graphics page
corlasttick dw	0FFFFH			; last BIOS tick used for polling
cortickspin dw	0			; fallback frame poll divider
corsndtick dw	0FFFFH			; last BIOS tick used for sound poll
corsndspin dw	0			; fallback sound poll divider
corytab   dw	SCR_HGHT dup (?)	; logical Y to Corona byte offset
corytab2  dw	SCR_HGHT dup (?)	; optional duplicate physical row
cordup	  db	SCR_HGHT dup (?)	; nonzero if corytab2 is active
cormtab   dw	1024 dup (?)		; CGA byte/phase to Corona mask
corcache_sym dw CORCACHE_ENTRIES dup (?) ; cached source symbol offsets
corcache_phase dw CORCACHE_ENTRIES dup (?) ; cached x phases
corcache_data dw (CORCACHE_ENTRIES*CORCACHE_WORDS) dup (?)
corcache_next dw 0			; next FIFO cache slot
corcachecnt dw	?			; source bytes to cache
corcachebase dw ?			; active expanded symbol data
corcacheuse db	?			; nonzero if current symbol is cached
corclr	  dw	3			; current CGA color for dithering
corphys   dw	?			; current physical Y during setup
corprevphys dw	?			; previous physical Y during setup
corphase  dw	?			; current symbol x phase table offset
corx	  dw	?
cory	  dw	?
curx	  dw	?
cury	  dw	?
corsym	  dw	?
corrows   dw	?
corbytes  dw	?
corbyte   db	?
corduprow db	?
corxbyte  dw	?
corrow1   dw	?
corrow2   dw	?
cormask   dw	?

	extrn	displx:word		; Display left and right bounds
	extrn	disprx:word
	extrn	dispdx:word		; Display shift
	extrn	movetick:word		; Move synchronization counter
	extrn	auxdisp:byte		; auxiliary display buffer
	extrn	ground:byte		; Ground height by pixel
	extrn	dispinit:word		; Initialized display flag
	extrn	forcdisp:word		; Force display flag
	extrn	coronatxt:word		; Corona text overlay is 80 columns
	extrn	objtop:word		; First object in object list
	extrn	deltop:word		; First object in deleted object list
	extrn	splatox:word		; display splatted ox
	extrn	oxsplatted:word 	; an ox has bben splatted

	end
