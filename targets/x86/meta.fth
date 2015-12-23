\ Metacompiler for x86.  Copyright Lars Brinkhoff 2015.

require search.fth

hex
400000 constant load-address
decimal

vocabulary compiler

vocabulary t-words
defer t,
: t-word ( a u xt -- ) -rot "create , does> @ t, ;
: fatal   cr source type cr bye ;
: ?undef   0= if ." Undefined!" fatal then ;
: t-search   ['] t-words search-wordlist ;
: defined?   t-search if drop -1 else 0 then ;
: "' ( u a -- xt ) t-search ?undef >body @ ;
: t'   parse-name "' ;
: t-compile   parse-name postpone sliteral postpone "' postpone t, ; immediate
: t-[compile]   also compiler ' previous compile, ; immediate

: already-defined?   >in @ >r parse-name defined? r> >in ! ;
: trailing-semicolon?   source 1- + c@ [char] ; = ;
: ignore-definition   begin trailing-semicolon? postpone \ until ;

variable leaves
: 0leaves   0 leaves ! ;
: leaves@   leaves @ ;

vocabulary meta
only forth also meta definitions
include lib/image.fth

0 value latest

' , is t,

include targets/x86/params.fth
: >link   next-offset + ;
: >does   does-offset + ;
: >code   code-offset + ;
: >body   body-offset + ;

: link, ( nt -- ) latest ,  to latest ;
: reveal ;
: name, ( a u -- ) #name min c,  #name ", ;
: header, ( a u -- ) align here 3dup t-word >r name, r> link, 0 , ;
: ?code, ( -- ) here cell+ , ;

: host   only forth definitions host-image ;

include targets/x86/asm.fth
include lib/pe.fth
include lib/xforward.fth

only forth definitions also meta
: target   only forth also meta also t-words definitions previous target-image ;

target
load-address org
pe-header,

include targets/x86/nucleus.fth

host also meta definitions

: >mark   here 0 , ;
: <mark   here ;
: >resolve   here swap ! ;
: <resolve   , ;
: t-literal   t-compile (literal) , ;

: h-number   [ action-of number ] literal is number ;
: ?number,   if 2drop undef fatal else drop t-literal 2drop then ;
: number, ( a u -- ) 0 0 2over >number nip ?number, ;
: t-number   ['] number, is number ;

t' docol >body constant 'docol
t' dovar >body constant 'dovar
t' docon >body constant 'docon
t' dodef >body constant 'dodef
t' dodoes >body constant 'dodoes

: h: : ;

h: '   t' ;
h: ]   only forward-refs also t-words also compiler  t-number ;
h: :   parse-name header, 'docol , ] ;
h: create   parse-name header, 'dovar , ;
h: variable   create cell allot ;
h: defer   parse-name header, 'dodef , t-compile abort ;
h: constant   parse-name header, 'docon , , ;
h: value   constant ;
h: immediate   latest dup c@ negate swap c! ;
h: to   ' >body ! ;
h: is   ' >body ! ;
h: [defined]   parse-name defined? ;
h: [undefined]   [defined] 0= ;

h: ?:   already-defined? if ignore-definition else : then ;

only forth also meta also compiler definitions previous

h: \   postpone \ ;
h: (   postpone ( ;
h: [if]   postpone [if] ;
h: [else]   postpone [else] ;
h: [then]   postpone [then] ;

h: [   target h-number ;
h: ;   t-compile exit t-[compile] [ ;

h: [']   ' t-literal ;
h: [char]   char t-literal ;
h: literal   t-literal ;
h: compile   ' t-literal t-compile , ;
h: [compile]   ' , ;
h: does>   t-compile (does>) ;

h: cell   cell t-literal ;
h: TO_NEXT   next-offset t-literal ;
h: TO_DOES   does-offset t-literal ;
h: TO_CODE   code-offset t-literal ;
h: TO_BODY   body-offset t-literal ;
h: NAME_LENGTH   name-size t-literal ;
h: 'dodoes   'dodoes t-literal ;

h: s"   t-compile (sliteral) parse" dup , ", ;
h: ."   t-[compile] s" t-compile type ;

h: if   t-compile 0branch >mark ;
h: ahead   t-compile branch >mark ;
h: then   >resolve ;

h: begin   <mark ;
h: again   t-compile branch <resolve ;
h: until   t-compile 0branch <resolve ;

h: else   t-[compile] ahead swap t-[compile] then ;
h: while    t-[compile] if swap ;
h: repeat   t-[compile] again t-[compile]  then ;

h: to   ' >body t-literal t-compile ! ;
h: is   t-[compile] to ;

h: do   0leaves  t-compile 2>r  t-[compile] begin ;
h: loop   t-compile (loop) t-[compile] until  here leaves@ chains!  t-compile 2rdrop ;
h: leave   t-compile branch  leaves chain, ;

h: abort"   t-[compile] if t-[compile] s" t-compile cr t-compile type
   t-compile cr t-compile abort t-[compile] then ;

\ only forth :noname 2dup type space (parsed) ; is parsed
target

include kernel.fth

code cold
   here pe-entry

   ' sp0 >body S mov,
   ' rp0 >body R mov,

   ' turnkey # W mov,
   execute,
end-code

latest ' latest0 >body !

\ Start of image.
load-address ' image0 >body !

\ Start of free dictionary.
here ' dp0 >body !

\ Allocate space for dictionary and stacks.
here
   17000 cells allot  here ' limit >body !
   100 cells allot  here ' sp0 >body !
   256 cells allot  here ' rp0 >body !
here - ( dup ) allot \ negate elf-extra-bytes

only forth also meta also t-words resolve-all-forward-refs

only forth also meta
pe-end

target-region type bye

host also meta

cr .( Target size: ) t-size .
cr .( Target used: ) target here host also meta >host t-image host - .
cr .( Host unused: ) unused .
cr .( Target words: ) also t-words words only forth
cr .( Forward refs: ) also meta also forward-refs words
cr

target-region hex dump bye
