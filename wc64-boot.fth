: hi 'h' emit 'i' emit cr ; hi
: cya 'b' emit 'y' emit 'e' emit cr ;
: s 's' emit ; : e 'e' emit ;
: mil 1000 dup * * ; mil
: xx s 1000 mil for next e cr ;
xx cya bye

33 32 + emit cr
33 dup + emit cr
hi
