.( Including platform.f )

<text>
	Should io.f or platform.f be loaded before jeforth.f kernel code or after it? jeforth.f 
	kernel doesn't need any actual I/O. Words like dot . , accept , etc can use either print 
	to log string or fakes. On the other hand, io.f probably needs basic words. So I prefer 
	loading platform.f after jeforth.f.
</text> drop

js> $.terminal.active()  constant  term         // ( -- object ) jQuery-terminal
100                      constant  rightMargin  // ( -- n ) Right margin of the terminal display. Dynamic adjustable.

code redefine	( Word <name> -- ) \ Redefine the <name> by the new Word.
				var newword = pop(), oldname = nexttoken(), oldword = tick(oldname);
				if(!oldword) { 
					panic("Error! "+oldname+"?\n"); 
					reset(); 
				} else {
					oldword.predecessor = newword.name;
					oldword.creater = newword.creater.slice(0); // this is the way JavaScript copy array by value
					oldword.creater.push("redefine");
					oldword.help = newword.help;
					oldword.comment = newword.comment;
					oldword.vid = newword.vid;
					if(newword.cfa){ // colon word
						oldword.xt = newword.xt;
						oldword.cfa = newword.cfa;
					} else {
						if(oldword.cfa) delete oldword.cfa;
						oldword.xt = newword.xt;
					}
				}
                end-code
				/// The problem of using 'redefine' is that you can't forget them then.
				/// So redefine is used in very restricted cases only. In platform.f for
				/// example because platform.f is very basic like a part of kernel.

\ everything in the <js> section are not accessable outside unless exported by an assignment statement.
<js>
	// Before redefine the print() function, flush the remaining line in the screen buffer.
	execute("term"); var term = pop();
	term.echo(screenbuffer.slice(screenbuffer.lastIndexOf('\n')+1));

	// redefine print(). The original defined in index.html is very rough.
	// Redefine print() has to be an assignment statement so as to replace the 'print' global variable.
	// Input: s is the string to print. prompt==true called from prompt(), otherwise from other callers.
	function newprint(s, prompt){
		var me = arguments.callee;
		var ss = (me.lastline || "") + s; // 
		var a = ss.split('\n');  // Note: "\n".split('\n')==["",""]; "111".split('\n')==["111"]; "".split('\n')==[""]
		execute("rightMargin"); var rightMargin=pop();
		for (var i=0; i < a.length-1; i++) { 
			term.echo(a[i]=="" ? ' ' : a[i]); // translation needed or echo("") will do nothing
			screenbuffer += a[i] + '\n';
		}
		// a[i] is the last line. Wrap around is important to see the program running. Or
		// it will be a long long last line, invisible!
		while( a[i].length > rightMargin ) { // if the last line is long enough
			term.echo(ss = a[i].slice(0,rightMargin));
			screenbuffer += ss + '\n';
			a[i] = a[i].slice(rightMargin);
		}
		if(me.lastline=a[i]){
			if (prompt && (!suspendForthVM.activated || indebug)){
				term.echo(me.lastline); // Don't translate here, if is "" then do nothing is correct. 
				screenbuffer += me.lastline + '\n';
				me.lastline = "";
			}else{
				// The last line is not easy to print when suspend-resume or sleep is involved. 
				// Use the setTimeout() to retry later is my solution. -- r13 
				setTimeout(function(){me("",true)},10);
			}
		}
	}
	print = newprint; // redefine print() 
	print.lastline = "";
	
	function newPrompt(pprint,t){ 
		pprint(prompt); // pprint is callback function from jQuery-terminal that prints prompt
	}
	term.set_prompt(newPrompt);
</js>

: new-cls		( -- ) \ Clear screen of the jQuery-terminal.
				term js: pop().clear();screenbuffer="" ;
				last redefine cls 

				<selftest>
					marker ~~platform.f-selftest~~	
					include selftest.f
					marker ---
					cr .(( *** Display output's foundation print() has redefined ... )) cr
					screen-buffer constant screen-buffer-was
					cls code ttt print(1111);print('\n');print(2222) end-code last execute
					screen-buffer js> pop().indexOf("1111\n")!=-1 \ true
					screen-buffer js> pop().indexOf("2222")==-1 \ true true
					cr cr cls screen-buffer-was .
					and [if] 
						.( pass ) cr
						<js> ['tib.insert','nw.gui','new-cls','new-code',
						'screen-buffer','term'] </jsv> all-pass 
					[else] 
						.( failed ) \s 
					[then]
					---
				</selftest>
				
\ jQuery-terminal supports push-pop of sub-terminals. But sub-terminal is not blocking.
\ That means the mother terminal is still running when sub-terminal is prompting (or pushed).
\ Whereas, accept is a blocking word. We have to use the suspend-resume technique here.

code (accept)	( "prompt" -- ) \ Book a call back function to receive a line from jQuery-terminal.
				execute("term"); var term = pop();
				var promptwas = prompt;
				prompt = pop();
				keyboard.readline(function(line){
					prompt = promptwas; // restore original jQuery-terminal prompt
					push(line);
					push(true);
					resumeForthVM();
				});
				end-code 
: new-accept	( -- str T|F ) \ Read a line from terminal.
				"" (accept) suspend ;
				last redefine accept 
				
: prompt-accept	( "prompt" -- str T|F ) \ Read a line from terminal.
				(accept) suspend ;

: new-refill	( -- flag ) \ Reload TIB from terminal. return false means no input or EOF
				accept if js: tib=pop();ntib=0 true else false then ;
				last redefine refill

: text			( "delimiter" -- "text" <delimiter> ) \ Similar to 'word' but accept keyboard inputs.
				"" js: ++ntib 		\ ( deli txt -- ) skip the whitespace after 'text' command
				begin 				\ ( deli txt -- ) 
					js> nextstring(tos(1)) \ ( deli txt result -- )
					js> tos().str 	\ ( deli txt result result.str -- )
					js> pop(1).flag \ ( deli txt result.str result.flag -- )
					if 				\ ( deli txt result.str -- )
						+ nip exit 	\  ( -- txt <delimiter> )
					then  			\  ( deli txt result.str -- )
					js> pop(1)+'\n'+pop() \  ( deli txt  -- )
					refill 
				not until nip ;

: new-<text>	( <"text"> -- "text" ) \ Get multiple-line string from TIB and terminal
				char </text> text ; immediate
				last redefine <text> 

: new-code		( <JavaScript satements> -- ) \ Start to compose a code word.
				<js> compiling = true;
				newname = nexttoken();
				if(isReDef(newname)) print("reDef "+newname+"\n");
				newhelp = newname + "\t" + packhelp();
				push('newxt=function(){ /* '+newname+' */\n'); </js> ( body -- )
				char end-code text + CR + char } + js: eval(pop()) ;
				/// New definition of the 'code' command. Can accept keyboard input now.
				last redefine code

: new-<js>		( <js statements> -- "statements" ) \ Evaluate JavaScript statements
				char </js>|</jsV>|</jsN>|</jsv>|</jsn>|</jsR>|</jsr> text
				[compile] compiling if [compile] literal then ; immediate
				last redefine <js> 

code rescan-tabcompletion ( -- ) \ Rescan words for jQuery-termianl TAB autocompletion.
				tabcompletion = [];
				for(var i in wordhash) tabcompletion.push(i);
				end-code

code screen-buffer ( -- "screen" ) \ Entire screen buffer
				push(screenbuffer) end-code
				/// term.get_output() is similar but it doesn't contain the inputs.
				/// screen-buffer contains both inputs and outputs ever on the screen.

				<selftest>
				*** screen-buffer rightMargin ... 
				js> screenbuffer.length constant start-here // ( -- n ) 
				.( aaaabbbbccccdddd ) 
				start-here screen-buffer <js> pop().slice(pop()).indexOf("\n")==-1 </jsv> \ true
				: t 90 for ." abcde" next ; last execute
				start-here screen-buffer <js> pop().slice(pop()).indexOf("\n")!=-1 </jsv> \ true
				and ==>judge [if] <js> ['redefine','rightMargin'] </jsv> all-pass [then]
				~~platform.f-selftest~~	
				</selftest>
				
js> tick('<selftest>').enabled [if] 
	js> tick('<selftest>').buffer tib.insert
[then] js: tick('<selftest>').buffer="" \ recycle the memory




