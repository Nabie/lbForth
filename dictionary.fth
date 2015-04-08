\ Definitions that are common to both the kernel and the metacompiler.
\ Dictionary: DP HERE ALLOT ALIGN CURRENT.
\ Word fields: >NAME >LFA >CODE >BODY.
\ Compiling words: , COMPILE, HEADER,.

variable dp
: here      dp @ ;
: allot     dp +! ;
: aligned   cell + 1 - cell negate nand invert ;
: align     dp @ aligned dp ! ;

: ,       here !  cell allot ;
: c,      here c!  1 allot ;
: move,   here swap dup allot cmove ;
: ",      move, align ;

include jump.fth

: >name    count cabs ;
: >lfa     TO_NEXT + ;
: >code    TO_CODE + ;
: >body    TO_BODY + ;
: >nextxt   >lfa @ ;

include threading.fth

variable current

\ Compile the contents of a, then store x in a.
: chain, ( x a -- )   dup @ , ! ; 

: link, ( nt -- )      to latestxt  current @ >body @ , ;
: reveal               latestxt  current @ >body ! ;
: #name ( -- u )       NAME_LENGTH 1 - ;
: name, ( a u -- )     #name min c,  #name ", ;
: header, ( a u -- )   align here >r name, r> link, 0 , ;

: cells   [ cell 1 > ] [if] dup + [then]
   [ cell 2 > ] [if] dup + [then]
   [ cell 4 > ] [if] dup + [then] ;
