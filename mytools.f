s" mytools.f"	.( Including ) dup . cr also forth definitions 
				char -- over over + + (marker) (vocabulary) 
				last execute definitions

code int 		( float -- integer ) 
				push(parseInt(pop())) end-code

code random 	( -- 0~1 ) 
				push(Math.random()) end-code

code isSameArray ( a1 a2 -- T|F ) \ Compare two arrays.
				push(isSameArray(pop(), pop()));
				end-code
				/// isSameArray() defined in jeforth.js, make it a forth command
				/// for wider usage.

code member-count ( obj|hash|array -- count ) \ Get member count of an obj or hash table
				push(memberCount.call(pop())) end-code
				/// Get hash table's length
				/// An array's length is array.length but there's no such thing of hash.length for hash{}.
				/// memberCount.call(object) gets the given object's member count which is also a hash table's length.

code freeze 	( mS -- ) \ Freeze the entire system for mS time. Nobody can do anything.
				var ms=pop();
				var startTime = new Date().getTime();
				while(new Date().getTime() < (startTime + ms));
				end-code

: nop 			; // ( -- ) No operation.
				
code .longwords ( length -- ) \ print long words. I designed this word for fun to see what are they.
				var limit = pop();
				for (var j=0; j<order.length; j++) { // 越後面的 priority 越新
					print("\n-------- " + order[j] +" "+ (words[order[j]].length-1) + " words --------\n" );
					for (var i=1; i<words[order[j]].length; i++){  // 從舊到新
						if(words[order[j]][i].name.length > limit) print(words[order[j]][i].name+" ");
					}
				}
                end-code
