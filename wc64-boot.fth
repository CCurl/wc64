: cr 10 emit ;

: cells cell * ;
: kb 1024 dup * ;
: const add-word lit, (exit) , ;
mem 64 kb cells + const vars
vars const (vh)
vars cell + (vh) !
: here (h) @ ;
: vhere (vh) @ ;
: allot vhere + (vh) ! ;
: variable vhere const cell allot ;

: if   (jmpz)   , here 0 , ; immediate
: -if  (njmpz)  , here 0 , ; immediate
: if0  (jmpnz)  , here 0 , ; immediate
: -if0 (njmpnz) , here 0 , ; immediate
: then here swap ! ; immediate

: begin here ; immediate
: while  (jmpnz)  , ; immediate
: -while (njmpnz) , ; immediate
: until  (jmpz)   , ; immediate
: again  (jmp)    , ; immediate

: 2drop drop drop ;
: ztype dup c@ -if0 2drop exit then emit 1+ ztype ;
: abs dup 0 < if negate then ;

variable #buf  64 allot
variable bp

: space 32 emit ;
: hold bp @ 1- dup bp ! c! ;
: #n dup 9 > if 7 + then '0' + hold ;
: # base @ /mod swap #n ;
: #s # -if #s exit then drop ;
: <# dup 0 < #buf c! bp bp ! 0 hold abs ;
: #> #buf c@ if '-' hold then bp @ ;
: (.) <# #s #> ztype ;
: . (.) space ;

: mil 1000 dup * * ; mil

variable tm-struct 8 allot
: lap tm-struct y! 1 y@ 228 syscall2 drop
    y@ @ 1000 mil * y@ 8 + @ + ;
: .lap lap swap - . ;

: hi 'h' emit 'i' emit cr ;
: cya 'b' emit 'y' emit 'e' emit cr bye ;
: s 's' emit ; : e 'e' emit ;
: bb s lap 1000 mil for next e space .lap cr ;
: #. '.' hold ;
: .ver 'v' emit version <# # # #. # # #. #s #> ztype cr ;
.ver hi bb cya
