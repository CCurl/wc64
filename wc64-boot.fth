: hi 'h' emit 'i' emit cr ; hi
: cya 'b' emit 'y' emit 'e' emit cr bye ;
: s 's' emit ; : e 'e' emit ;
: mil 1000 dup * * ; mil
: xx s 1000 mil for next e cr ;
xx

33 32 + emit cr
33 dup + emit cr

: cells cell * ;
: kb 1024 dup * ;
: const add-word lit, (exit) , ;
mem 64 kb cells + const vars
vars const (vh)
vars cell + (vh) !
: vhere (vh) @ ;
: allot vhere + (vh) ! ;
: variable vhere const cell allot ;

variable ttt   : ttt@ ttt @ ; : ttt! ttt ! ;
variable xxx   : xxx@ xxx @ ; : xxx! xxx ! ;
55 ttt! ttt@ emit
56 xxx! xxx@ emit
55 ttt! ttt@ emit '-' emit cell '0' + emit cr

cya
