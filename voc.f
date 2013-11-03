.( including voc.f ) cr
marker --voc.f-- 
\ Initialize the jeforth system for vocabulary features. This is a one time word.
char forth constant forth-wordlist // ( -- "forth" ) The vid of forth-wordlist.

code obj>keys	( obj -- keys[] ) \ Get all keys of an object.
				var obj=pop();
				var array = [];
				for(var i in obj) array.push(i);
				push(array);
				end-code

				<selftest>
					marker --voc.f-self-test--
					include selftest.f
					*** obj>keys should return an array with correct elements ... 
					' + obj>keys js> pop().join(",")
					js> tos().indexOf('name')!=-1 \ [...] true
					js> tos(1).indexOf('selftest')!=-1 \ [...] true true
					js> tos(2).indexOf('toString')!=-1 \ [...] true true true
					js> pop(3).indexOf('cfa')==-1 \ true true true true
					and and and ==>judge [if] <js> [] </jsv> all-pass [then]
				</selftest>

code isMember 	( value group -- key|index T|F ) \ Return key or index if value exists.
				var group = pop();
				var result = isMember(pop(), group);
				if (result.flag) {push(result.keyvalue); push(true)}
				else push(false);
				end-code
				/// 'item' can be number, string, or object, anything that can be compared by the == operator.
				/// 'group' is either array or object.

				<selftest>
					*** isMember checks array or object ... 
					char name     ' code isMember [if] char code = [then] \ true
					char selftest ' code isMember [if] char pass = [then] \ true true
					' help js> words.forth isMember [if] js> words.forth[pop()].name=='help' [then] \ true true true
					and and ==>judge [if] <js> [] </jsv> all-pass [then]
				</selftest>

code get-context ( -- "vid" ) \ Get the word list that is searched first. 
				push(order[Math.max(0,order.length-1)]) end-code
				/// context is order[last], order[0] is always "forth".

: set-context	 ( "vid" -- ) \ Set the word list that is searched first.
				 js: order[Math.max(1,order.length-1)]=pop() rescan-word-hash ;
				 /// context is order[last], order[0] is protected to always be "forth".

				<selftest>
					*** set-context get-context manipulate the word-list of first priority ... 
					also forth vocabulary vvv char vvv set-context
					get-context char vvv = \ true
					==>judge [if] <js> ['get-context'] </jsv> all-pass [then]
				</selftest>

code get-current ( -- "vid" ) \ Return vid, new word's destination word list name.
				push(current) end-code

code set-current ( "vid" -- ) \ Set the new word's destination word list name.
				current = pop() end-code

				<selftest>
					*** set-current get-current manipulate the word-list to go to ... 
					also vocabulary vvv000 vvv000 definitions
					also char vvv set-current
					get-current char vvv = \ true
					forth definitions \ change current to forth
					get-current char forth = \ true true
					vvv definitions \ change current to vvv
					get-current char vvv = \ true true true
					: ttt ; js> words.vvv[words.vvv.length-1].name=='ttt' \ true true true true 
					previous \ use the previous word-list as the context
					get-context char vvv000 = \ true true true true true
					and and and and ==>judge [if] <js> ['get-current','forth','(vocabulary)','vocabulary',
					'definitions','previous','forth-wordlist'] </jsv> all-pass [then]
				</selftest>

: (vocabulary) 	( "name" -- ) \ create a new word list.
				>r <js> var name=rtos(),flag=false; for(var vid in words) if(vid==name) {flag=true;break};flag </jsV> 
				if s" Error! redefine vocabulary '" r@ + s" ' is not allowed." + "msg"abort then
				r> (create) colon-word js> last().name dup 
				0 , \ dummy cfa, we need to do this because "(create)" doesn't drop the doVar like "create" does.
				, \ pfa is the "name"
				dup js: words[pop()]=[];words[pop()].push(0) ( empty ) \ words[][0] = 0 是源自 jeforth.WSH 的設計。
				js: last().creater.push('vocabulary') 
				does> r> @ set-context rescan-word-hash ;
				
: vocabulary	( <name> -- ) \ create a new word list.
				BL word (vocabulary) ;
				
: only       	( -- ) \ Clear vocabulary search order[] list, leave order[0] = forth-wordlist only.
				js: order=order.slice(0,1) rescan-word-hash ;

				<selftest>
					*** only leaves 'forth' along ... 
					get-context char forth = \ false
					only
					get-context char forth = \ true
					XOR ==>judge [if] <js> [ ] </jsv> all-pass [then]
				</selftest>

code also       order.push(order[order.length-1]) end-code // ( -- ) vocabulary array's dup

code previous   if(order.length>1){order.pop();fortheval("rescan-word-hash")} end-code // ( -- ) Drop vocabulary order[] array's TOS

: forth 		( -- ) \ Make forth-wordlist be searched first, which is to set context="forth".
				js> order.length>1 if forth-wordlist set-context then ; \ order[0] is always 'forth'.
' get-current alias current // ( -- "vid" ) current is alias of get-current, get the compilation word list's vid name.

\ 如果照 ANS 標準，get-order 應該如下定義。但是 jeforth 有 JavaScript 當靠山，TOS 可以直接操作 array，實在無需如此委屈。
\ code get-order  ( -- vidn ... vid1 n ) \ Get the order[] list with order.length at TOS
\ 				for(var i=0; i<order.length; i++) push(order[i]);
\ 				push(order.length);
\ 				end-code
\ : order 		( -- ) \ list vocabulary array search order.
\ 				get-order ( -- vidn ... vid1 n ) ." search: " for r@ 1- roll . space next cr
\ 				get-current ( -- vid ) ." define: " . cr ;

code get-order  ( -- order-array ) \ Get the vocabulary order array
				push(order);
				end-code

: order 		( -- ) \ list vocabulary array search order.
				." search: " get-order . cr
				." define: " get-current ( -- vid ) . cr ;
				
: definitions 	get-context set-current ; // ( -- ) make current equals to context. current = order[order.length-1].

: get-vocs		js> words obj>keys ; // ( -- vocs[] ) Get all vocabulary names.

: vocs       	." vocs: " get-vocs . cr ; // ( -- ) List all vocabulary names.

				<selftest>
					*** also current order vocs ... 
					js> screenbuffer.length constant start-here // ( -- n ) 
					cr only forth also vvv also vvv000 definitions current char vvv000 = \ true
					order 
					start-here <js> screenbuffer.slice(pop()).indexOf("search: forth,vvv,vvv000")!=-1 </jsv> \ true true
					start-here <js> screenbuffer.slice(pop()).indexOf("define: vvv000")!=-1 </jsv> \ true true true
					vocs
					start-here <js> screenbuffer.slice(pop()).indexOf("vocs: forth,vvv,vvv000")!=-1 </jsv> \ true true true true
					and and and ==>judge [if] <js> ['current','definitions','order','vocs',
					'get-current','get-order','get-vocs','forth'] </jsv> all-pass [then]
				</selftest>

: find-vocs     ( "vid" -- index T|F ) \ Is the given "vid" in the vocs?
				get-vocs isMember ;
				/// this is an example of how to access vocs list.

				<selftest>
					*** find-vocs is a demo of accessing vocs list ... 
					char vvv find-vocs swap 1 = and \ true 
					char vvv000 find-vocs swap 2 = and \ true true
					and ==>judge [if] <js> [ ] </jsV> all-pass [then]
				</selftest>
				
code search-wordlist ( "name" "vid" -- wordObject|F ) \ A.16.6.1.2192 Linear search from the given word-list.
                var vid = pop();
				var name = pop();
				for (var i=words[vid].length-1; i>0; i--) if(words[vid][i].name == name) break;
				push(i?words[vid][i]:false);
				end-code
				/// jeforth.3nw has wordhash which is much more powerful. 
				/// So we don't use search-wordlist at all. 

				<selftest>
					*** search-wordlist linear search a word-list ... 
					char code char forth search-wordlist js> pop().name=='code' \ true
					==>judge [if] <js> [ ] </jsv> all-pass [then]
				</selftest>

\ marker 十分複雜。
\ 引進 vocabulary 之後，marker 要改寫。請想想: 'here' 只有一個，當 here 退回到某處，在此之後的所有 words 都要丟
\ 掉，不管它屬哪個 word list. 執行一個 vocabulary words 切入之前就存在的 marker 會怎樣？會把 forth-wordlist 倒
\ 回去、here 也倒回去，恢復 current = context = "forth"; 這是原始 marker 要補做的動作。 

code (marker)   ( "name" -- ) \ Create a word named <name>. Run <name> to forget itself and all newers. 進一步解決 vocs 的 save-restore 
				// -------------------- the saving part 1/2 ----------------------------------
				// we need to do this before creating the marker new word
                var lengthwas = {}; // each word-list's length was
				for (var vid in words) lengthwas[vid] = words[vid].length; // go through all word lists to save their length
				// ---------------- Create the marker new word --------------------------
				fortheval("(create)");
				// -------------------- the saving part 2/2 ----------------------------------
				var orderwas = []; // FigTaiwan 爽哥提醒
 				for(var i=0; i<order.length; i++) orderwas[i] = order[i]; // FigTaiwan 爽哥提醒. Marker 也得 restore order[] 跟 vocs[].
				last().creater.push(this.name); // this.name is "(marker)"
                last().herewas = here;
                last().lengthwas = lengthwas; // dynamic variable array 的 reference 給了別人之後就不會蒸發掉了。
				last().help =newname + "\t" + packhelp(); // help messages packed
				fortheval("get-vocs"); last().vocswas = pop(); 
				last().orderwas = orderwas;  // FigTaiwan 爽哥提醒 // dynamic variable array 的 reference 給了別人之後就不會蒸發掉了。
				// --------------------- the restore phase ----------------------------------
				// xt's job is to restore the saved context  
                last().xt = function(){ 
                    here = this.herewas;
					order.splice(0,order.length); 
					for(var i=0; i<this.orderwas.length; i++) order[i] = this.orderwas[i]; // FigTaiwan 爽哥提醒; order[order.length-1] 就是 context 不必再 save-restore.
					for(var vid in words) {
						if(!isMember(vid, this.vocswas).flag) {
							delete words[vid]; // if the word-list was not exist then delete it.
						}
					}
					current = this.vid; // FigTaiwan 爽哥提醒。 我不管 current vocabulary 還在不在，一律 restore 到原來的.
                    dictionary = dictionary.slice(0,here);
					for(var vid in words) { // go through all word lists to restore their length
						words[vid] = words[vid].slice(0, this.lengthwas[vid]); 
					}
                    fortheval("rescan-word-hash");
                }
                end-code

: marker     	( <name> -- ) \ Create marker <name>. Run <name> to forget itself and all newers.
				BL word (marker) ;

				<selftest>
					*** marker (marker) are very complicated ... 
					marker ---%%%--- 
					: marker-test-dummy ;
					' marker-test-dummy boolean \ true
					---%%%--- 
					' marker-test-dummy boolean \ false
					XOR ==>judge [if] <js> ['(marker)','marker'] </jsv> all-pass [then]
				</selftest>

code words      ( [<pattern>] -- ) \ List all words or words screened by pattern.
				var pattern = nexttoken();
				for (var j=0; j<order.length; j++) { // 越後面的 priority 越新
					print("\n-------- " + order[j] +" ("+ Math.max(0,words[order[j]].length-1) + " words) --------\n" );
					fortheval("s' " + order[j] + "' (words) " + pattern);
					var word_list = pop();
					for (var i=0; i<word_list.length; i++) print(word_list[i].name+" ");
				}
                end-code interpret-only

				<selftest>
					*** words modified for volcabulary ... 
					js> screenbuffer.length constant start-here // ( -- n ) 
					words \
					start-here <js> screenbuffer.slice(pop()).indexOf("-------- forth (")!=-1 </jsv> \ true
					start-here <js> screenbuffer.slice(pop()).indexOf("words) --------")!=-1 </jsv> \ true true
					and ==>judge [if] <js> [ ] </jsv> all-pass [then]
				</selftest>

code help       ( [<pattern>] -- ) \ Print help messages of words which are screened by pattern.
				var RegEx = nexttoken();
				for (var j=0; j<order.length; j++) { // 越後面的 priority 越新
					print("\n--------- " + order[j] +" ("+ Math.max(0,words[order[j]].length-1) + " words) ---------\n" );
					fortheval("s' " + order[j] + "' (words) " + RegEx);
					var word_list = pop();
					for (var i=0; i<word_list.length; i++) {
						print(word_list[i]+"\n");
						if (typeof(word_list[i].comment) != "undefined") print("\t\t"+word_list[i].comment+"\n");
					}
				}
				end-code

				<selftest>
					*** help modified for volcabulary ... 
					js> screenbuffer.length constant start-here // ( -- n ) 
					help \
					start-here <js> screenbuffer.slice(pop()).indexOf("--------- forth (")!=-1 </jsv> \ true
					start-here <js> screenbuffer.slice(pop()).indexOf("words) ---------")!=-1 </jsv> \ true true
					and ==>judge [if] <js> [ ] </jsv> all-pass [then]
				</selftest>

<selftest> --voc.f-self-test-- </selftest>
js> tick('<selftest>').enabled [if] js> tick('<selftest>').buffer tib.insert [then] 
js: tick('<selftest>').buffer="" \ recycle the memory

