\ -------------- Tools for self-test --------------------

variable wut // Word under test

: ==>judge		( boolean -- ) \ print 'pass'(if true) or 'failed!' and stop testing.
				if ." pass" cr wut @ js: pop().selftest='pass' true
				else ." failed!" cr wut @ js: pop().selftest='failed!' \s false then ;

: ***			( <word> <description down to '\n'> -- ) \ Start to test a word
				BL word dup (') wut ! char \n|\r word \ name desc
				." *** " swap . space 1 sleep \ desc
				wut @ if . else drop ." unknown?" cr abort then 
				depth ?abort" *** Error! Data stack is not empty!" ;
				
code all-pass 	( ["name",...] -- ) \ Pass-mark all these word's selftest flag
				var a=pop();
				for (var i in a) {
					var w = tick(a[i]);
					if(!w) panic("Error! " + a[i] + "?\n");
					else w.selftest='pass';
				}
				end-code
\ -------------------------------------------------------
