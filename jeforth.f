﻿code version    ( -- revision ) \ print the greeting message and return the revision code
				// The 'revision' variable is from index.html
				print("j e f o r t h . n w -- r"+revision+'\n');
				print("source code  https://github.com/hcchengithub/jeforth.3nw \n");
				push(revision);
				end-code
				
code <selftest>	( <statements> -- ) \ Collect self-test statements
				push(nexttoken("</selftest>")); 
				end-code

code </selftest> ( "selftest" -- ) \ Save the self-test statements to <selftest>.buffer
				var my = tick("<selftest>");
				my.buffer = my.buffer || ""; // initialize my.buffer
                my.buffer += pop();
                end-code 

				<selftest>
					<text>   
					程式只要稍微大一點點，就得附上一些 self-test 讓它伺機檢查自身。隨便有做，穩定性
					就會亂提升一大步。Forth 的結構全部都是 global words， 改動的時候自由無限， 又難
					以一一去檢討影響到了哪些 words ,  不讓它全面自動測試， 十分令人擔憂。  我當初寫 
					jeforth.WSH  從開始就盡量做了些 self-test, 此舉甚佳， 後來不斷改版的過程中， 被 
					self-test 逮到的問題不計其數。 如果沒有事先埋下 test 機制，這些問題就必定隱身其
					中以待來日了，很恐怖不是嗎? 隨便做，跳著做， 有做就有效。如果程式沒有 self-test 
					不回頭補上而光是努力抓 bug 竊以為不可。
					
					Self-test 的執行時機是程式開始時，或開機時。沒有特定任務就做 self-test.
					
					include 各個 modules 時，循序就做 self-test。藉由 forth 的 marker , (forget) 等 
					self-test 用過即丟， 只花時間，不佔空間。花平時的開發時間不要緊，有特定任務時就
					跳過 self-test，是則完全不佔執行系統任何時間空間，只佔 source code 的篇幅。
					
					我嘗試了種種的 self-test 寫法。有的很醜，混在正常程式裡面相當有礙視線；不醜的很
					累，佔很大 source code 篇幅。總算因著 self-test 的投資報酬很高,都值得。一直希望
					能找出某種天生的 self-test 機制來簡化工作。對 jeforth.nw 而言，這很有希望。因為
					每個 word 都是 object 都有 constructor , prototype 等，答案似乎呼之欲出。
					
					燕南曰: Forth 特色 只有想不到 沒有做不到.... 該做的就做...
					
					以下是發展到目前最好的方法，  若合 燕大俠的先見之明。 jeforth.js kernel  裡只有 
					code end-code 兩個基本 words, 剛進到 jeforth.f  只憑這兩個基本 words 就馬上要為
					每個 word 都做 self-test 原本是很困難的。 然而，一旦想通了 jeforth.f 是整個檔案
					一次讀進來成為大大的一個 TIB 的， 所以其中已經蘊含有 jeforth.f 的全部功能。如果
					self-test 安排在所有的 words 都 load 好以後做，資源充分就不覺有困難，這不用說也
					知道。好玩的是，進一步，利用〈selftest〉〈/selftest〉這對「文字蒐集器」在任意處
					所蒐集「測試程式的本文」，最後再一次把它當成 TIB 執行之。實用上〈selftest〉〈/s
					elftest〉出現在每個 word 定義處，裡頭可以放心自由地使用尚未出生的「未來 words」,
					感覺很奇異，但對流暢臨場撰寫程式時的頭腦有很大的幫助！   </text> drop

					marker ~~selftest~~
					include selftest.f \ self-test tools
						
					.( *** Start self-test ) cr
					s" *** Data stack should be empty ... " . 
						depth not [if] .( pass) cr [else] .( failed!) cr \s [then]
					.( *** Rreturn stack should have less than 2 cells ... )
						js> rstack.length dup . space 2 <= [if] .( pass) cr [else] .( failed!) cr \s [then]
					*** version should return a number . . . 
						version js> typeof(pop())=="number" ==>judge
					[if] <js> [
					',', '.', '."', '.(', '//', ':', ';', '</'+'text>', '<=', '<text>', '@', 
					'[else]', '[if]', '[then]', '\\', '\\s', 'code', 'cr', 'depth', 'drop', 
					'dup', 'else', 'end-code', 'if', 'js:', 'js>', 'marker', 'not', 'space',
					'then', 'variable', '<selftest>', '</self'+'test>', '(marker)', 'variable',
					'word', '<js>', '</'+'jsV>'
					] </jsV> all-pass [then]
				</selftest>

code execute    ( Word|"name"|address|empty -- ... ) \ Execute the given word or the last() if stack is empty.
				execute(pop()); end-code 

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** execute "drop" should drop the TOS ... 
						123 s" drop" execute 
						456 ' drop execute 
						depth 0= ==>judge drop
				</selftest>
	
code interpret-only  ( -- ) \ Make the last new word an interpret-only.
                last().interpretonly=true;
                end-code interpret-only

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** interpret-only makes dummy interpret-only ... 
						: dummy ; interpret-only 
						' dummy js> pop().interpretonly ==>judge drop
						(forget)
				</selftest>


code immediate  ( -- ) \ Make the last new word an immediate.
                last().immediate=true
                end-code interpret-only

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** immediate makes dummy immediate ... 
						: dummy ; immediate 
						' dummy js> pop().immediate ==>judge drop
						(forget)
				</selftest>

code .((		( <str> -- ) \ Print following string down to '))' immediately.
				print(nexttoken('\\)\\)'));ntib+=2; end-code immediate 

code \          ( <comment> -- ) \ Comment down to the next '\n'.
                nexttoken('\n') end-code immediate

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** \ tib line after \ should be ignored ... 
						111 \ 222
						: dummy
							222
							\ 333 444 555
						;
						last execute + depth + 334 = ==>judge drop
						(forget)
				</selftest>

code \s         ( -- ) \ Stop loading forth source files.
                ntib=tib.length;
                end-code

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** \s should ignore the remaining TIB ... 
						<js> fortheval("123 \\s 324 32  ... ignore every thing !!!!"); </jsN>
						depth + 124 = ==>judge drop
				</selftest>

code compile-only  ( -- ) \ Make the last new word a compile-only.
                last().compileonly=true
                end-code interpret-only

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** compile-only makes dummy compile-only ...
						: dummy ; compile-only
						' dummy js> pop().compileonly ==>judge drop
						(forget)
				</selftest>

\ ------------------ Fundamental words ------------------------------------------------------

code (create)	( "name" -- ) \ Create a code word that has a dummy xt
                if(!(newname=pop())) panic("Create what?\n", tib.length-ntib>100);
                if(isReDef(newname)) print("reDef "+newname+"\n"); // 若用 tick(newname) 就錯了
                current_word_list().push(new Word([newname,function(){}]));
				last().vid = current; // vocabulary ID
				last().wid = current_word_list().length-1; // word ID
				last().creater = ["code"];
				last().creater.push(this.name); // this.name is "(create)"
				last().help = newname + "\t" + packhelp(); // help messages packed
                end-code

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** (create) should create a new word ...
						char ~(create)~ (create) 
						js> last().name char ~(create)~ = ==>judge [if]
						<js> ['char', '</j'+'sv>'] </jsv> all-pass 
						[then]
						(forget)
				</selftest>

code //         ( <comment> -- ) \ Give help message to the new word.
                var s = nexttoken('\n');
                last().help = newname + "\t" + s;
                end-code interpret-only

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** // should add help message to the last word ...
						1234 constant x // test!test!
						js> last().help.indexOf("test!test!") -1 != ==>judge drop
						\ see x
						(forget)
				</selftest>


code ///        ( <comment> -- ) \ Add comment to the new word, it appears in 'see'.
                last().comment = typeof(last().comment) == "undefined" ? nexttoken('\n') : last().comment + "\n" + nexttoken('\n');
                end-code interpret-only

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** /// should add comment to the last word ...
						1234 constant x 
						/// comment line 111
						/// comment line 222
						\ see x
						<js> last().comment.indexOf("comment line 111") </jsV> -1 != 
						<js> last().comment.indexOf("comment line 222") </jsV> -1 != 
						and ==>judge drop
						(forget)
				</selftest>

code (space)    push(" ") end-code // ( -- " " ) Put a space on TOS.

				<selftest>
					*** (space) puts a 0x20 on TOS ...
						(space) js> String.fromCharCode(32) = ==>judge drop
				</selftest>
				
code BL         push("\\s") end-code // ( -- "\s" ) RegEx white space.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** BL should return the string '\s' literally ...
						BL char \s = ==>judge drop
				</selftest>

code CR 		push("\n") end-code // ( -- '\n' ) New line character.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** CR should return a new line character, String.fromCharCode(10) or ASCII 10(0x0A) ...
						CR js> String.fromCharCode(10) = ==>judge drop
				</selftest>


code jsEval 	( <string> -- result ) \ Evaluate the given JavaScript statements, return the last statement's value.
                try {
                  push(eval(pop()));
                } catch(err) {
                  panic("JavaScript error : "+err.message+"\n", "error");
                };
				end-code
				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** jsEval should eval(tos) and return the last statement's value ...
						char 123 jsEval 123 ( .s ) = ==>judge drop
				</selftest>

code jsEval2 	( <string> -- ) \ Evaluate the given JavaScript statements, w/o return value.
                try {
                  eval(pop()); 
                } catch(err) {
                  panic("JavaScript error : "+err.message+"\n", "error");
                };
                end-code

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** jsEval2 should eval(tos) but won't return any value ...
						456 char 123 jsEval2 456 ( .s ) = ==>judge drop
				</selftest>

code recentcolonword ( -- recentcolonword ) \ Get the recent colon word obj.
				push(recentcolonword) end-code
				/// It's like a colon word's "this".
				/// Use this command at the very first in a colon definition. 

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** recentcolonword gets the 'self' in a colon word ...
						: dummy recentcolonword ;
						dummy js> pop().name char dummy = ==>judge drop
						(forget)
				</selftest>

code compiling  push(compiling) end-code immediate // ( -- boolean ) Get system state

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** compiling should return the recent forth VM state ...
						: dummy compiling literal ; last execute
						compiling not and ==>judge 
						[if] js> ['literal'] all-pass [then]
						(forget)
				</selftest>

code last 		push(last()) end-code // ( -- word ) Get the word that was last defined.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** last should return the recent forth VM state ...
						: dummy ; last js> pop().name char dummy = ==>judge drop
						(forget)
				</selftest>

code exit       ( -- ) \ Exit this colon word.
				ip = rstack.pop(); endinner=true; 
				end-code compile-only

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** exit should stop a colon word ...
						: dummy 123 exit 456 ; 
						last execute 123 = ==>judge drop
						(forget)
				</selftest>

code ret        ( -- ) \ Mark at the end of a colon word.
				ip = rstack.pop(); endinner=true; 
				end-code compile-only interpret-only
				/// You have no way to use ret. It's used by compilecode('ret') only.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					marker ---
					*** ret and exit are same ...
					: test 111 [ ' ret , ] 222 ; last execute \ No normal way to use 'ret' , this is a trick to compile it.
					111 = depth 1 = and ==>judge drop
					---
				</selftest>

code rescan-word-hash ( -- ) \ Rescan all word-lists in the order[] to rebuild wordhash{}
				wordhash = {};
				for (var j=0; j<order.length; j++) { // 越後面的 priority 越高
					for (var i=1; i<words[order[j]].length; i++){  // 從舊到新，以新蓋舊,重建 wordhash{} hash table.
						wordhash[words[order[j]][i].name] = words[order[j]][i];
					}
				}
				end-code
				/// Used in (forget) and vocabulary words.

code (forget) 	( -- ) \ Forget the last word
				if (last().cfa) here = last().cfa;
				words[current].pop(); // drop the last word
				execute("rescan-word-hash");
				end-code

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** (forget) should forget the last word ...
						: dummy ; (forget)
						last js> pop().name char dummy != 
					==>judge [if]
						<js> tick('rescan-word-hash').selftest='pass' </js> \ test /js
						<js> push(tick('rescan-word-hash').selftest=='pass') </jsN> \ test jsN  true
						<js> push(pop()==true) </jsn> \ test jsn  true 
						[if] <js> ['</'+'js>', '</'+'jsN>', '</'+'jsn>'] </jsV> all-pass [then]
					[then]
				</selftest>

code SetupObjRet ( -- ) \ Setup the essential global variable objRet, fire and forgotten.
                objRet=tick('ret'); end-code
				last execute (forget)

code :          ( <name> -- ) \ Begin a forth colon definition.
                newname = nexttoken();
                newhelp = newname + "\t" + packhelp(); // help messages packed
                newxt=here; // 暫時拿它來放 entry point。
                compiling=true;
				// Keep a copy of the data stack for ';' to check it. Should not be changed.
				stackwas = stack.slice(0); 
				// term.set_prompt("> "); // jQuery-terminal prompt
                end-code

code ;          ( -- ) \ End of the colon definition.
                if (!isSameArray(stackwas,stack)) {
                    panic("Stack changed during colon definition, it must be a mistake!\n", "error");
                } else {
                    compilecode("ret");
					push(newname); execute("(create)");
					// 此時新 word 已經產生，即 last()。以下增補 properties 進此新 word object. JavaScript 這個特性太棒了！
					last().creater[0] = "colon";
                    last().cfa = newxt; // 如上述，':' 拿 newxt 來暫放本 colon word 在 dictionary 裡的 entry point.
                    last().help = newhelp;
                    last().xt = colonxt = function(){
                        rstack.push(ip);
                        recentcolonword = this; // save recentcolonword at the beginning of a colon definition if you want to access its elements.
                        inner(this.cfa);
						endinner = false; // better safe than sorry
                    }
                }
                compiling = false;
				// term.set_prompt(prompt); // jQuery-terminal default prompt
                end-code immediate compile-only

				<selftest>
					js: tick(':').selftest='pass'
					js: tick(';').selftest='pass'
				</selftest>
				
code suspend	( -- ) \ Suspend the forth VM to wait for the I/O.
				if(fortheval.level>0) {
					panic("Suspending Error! fortheval.level is " + fortheval.level + ", < 0 expected.\n");
					reset();
				} else {
					tib = tib.slice(ntib); // time to cut off used tib
					ntib = 0;
					suspendForthVM();
				}
				end-code
				/// 'suspend' and 'resume' better be code words. 
				/// Colon words use return stack that bothers the resuming.
				/// If the caller of the outer loop is terminal, then no problem.
				/// If the caller of the outer loop is another outer loop, e.g. fortheval(),
				/// then only the recent outer loop will be suspend then it skip to the higher
				/// level and go on!

code resume		( -- ) \ Resume the forth VM after a blocking I/O
				resumeForthVM() end-code 
				/// 'suspend' and 'resume' better be code words. Colon words use return 
				/// stack that bothers the resuming. 
				/// 'resume' must be called by terminal all the way through only code words 
				/// because of the return stack must be as-is when suspend.

				<selftest>
					<text>
					Forth VM suspend 之後無事可做，只好結束。以採用 jQuery-terminal 為例，等於是回到
					terminal, 這正是 breakpoint 的效果。可以用 suspend-resume 來實現 forth VM 的 debug
					console 真是意外驚喜！

					suspend 出現在有人登記 blocking I/O 的 callback 之後停下來等 I/O。而 resume 的
					動作只能在 I/O 完成後的 callback function 裡做，否則怎麼會 resume? 因此這種情況下
					the word 'resume' 用不上，而是用 resumeForthVM() 當作 I/O 的 callback function。
					
					以下這段測試程式頗特殊，
					
					（1）它會讓 forth VM 停下來 100mS 之後 resume callback 繼續。
					（2）另，jeforth.f 一開始不在 I/O 上花太多功夫。只用最簡單的辦法，使得 jQuery-terminal 
						 只在印 prompt 之前才會順便把 screenbuffer 都印出去。故 CPU 回到 terminal 之前，所
						 有的 display 都暫時看不見。注意，一開始第一個 prompt 是 terminal 自己送的，故不會
						 印 screenbuffer.
					
					讓 selftest 整個做完之後，發個 $.terminal.active().echo(screenbuffer) 以為可不靠 prompt
					印出 screenbuffer, 
					
						js: fortheval(tick('<selftest>').buffer) 
						js: $.terminal.active().echo(screenbuffer)
					
					其實不然，因為 suspend-resume 只作用在本層 outer loop 裡（上一行）。上一行 Suspend 之後
					還是會「馬上」來執行下一行，此時只印出 suspend 之前的 screenbuffer，然後就沒事做回到
					Terminal。這時也好玩，因為 Terminal 認為它已經 prompt 過了，除非有 keyboard enter 觸發，
					否則仍然不會有 prompt 來印出 screenbuffer。所以上面的第二行有必要，但不是擺這裡。要放到
					被 suspend 的 outer loop 的最後才對，也就是 <sleftest> section 的最後才對。
					</text> drop
					

					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** suspend stop the forth VM. resume gets the VM back on running ...
						marker ---
						code I/O 
							setTimeout(resumeForthVM,10) 
							end-code
						: test 
							I/O \ blocking I/O needs 100mS to accomplish
							<js> new Date().getTime() </jsV> \ cr .s
							suspend \ pause the forth VM so the next line will not run before the resume
							<js> new Date().getTime() </jsV> \ cr .s
							; 
						last execute 
						- 10 <= dup ==>judge drop [if] js: tick('resume').selftest='pass' [then]
						---
				</selftest>

code (')		( "name" -- Word ) \ name>Word like tick but the name is from TOS. 
				push(tick(pop())) end-code
				
code '         	( <name> -- Word ) \ Tick, get word name from TIB, leave the Word object on TOS.
				push(tick(nexttoken())) end-code
				
				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** ' tick should return the word object ...
						: dummy ;
						' dummy js> pop().name char dummy = ==>judge [if] js> ["(')"] all-pass [then]
						(forget)
				</selftest>

\ ------------------ eforth code words ----------------------------------------------------------------------

code branch     ip=dictionary[ip] end-code compile-only // ( -- ) 將當前 ip 內數值當作 ip *** 20111224 sam

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					marker ---
					*** branch should jump to run hello ...
						: sum 0 1 begin 2dup + -rot nip 1+ dup 10 > if drop exit then again ;
						: test sum 55 = ;
						test ==>judge
					[if] <js> ['2dup', '-rot', 'nip', '1+', '>', '0branch', '</'+'jsr>'] </jsr> all-pass [then]
					\ cr see sum cr 
					---
				</selftest>

code 0branch    if(pop())ip++;else ip=dictionary[ip] end-code compile-only // ( n -- ) 若 n!==0 就將當前 ip 內數值當作 ip, 否則將 ip 進位 *** 20111224 sam
code !          dictionary[pop()]=pop() end-code // ( n a -- ) 將 n 存入位址 a
code @          push(dictionary[pop()]) end-code // ( a -- n ) 從位址 a 取出 n
code >r         rstack.push(pop()) end-code  // ( n -- ) Push n into the return stack.
code r>         push(rstack.pop()) end-code  // ( -- n ) Pop the return stack
code r@         push(rstack[rstack.length-1 ]) end-code // ( -- r0 ) Get a copy of the TOS of return stack
code drop       pop(); end-code // ( x -- ) Remove TOS.
code dup        push(tos()); end-code // ( a -- a a ) Duplicate TOS.
code swap       var t=stack.length-1;var b=stack[t];stack[t]=stack[t-1];stack[t-1]=b end-code // ( a b -- b a ) stack operation
code over       push(stack[stack.length-2]); end-code // ( a b -- a b a ) Stack operation.
code 0<         push(pop()<0) end-code // ( a -- f ) 比較 a 是否小於 0

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					marker ---
					*** ! @ >r r> r@ drop dup swap over 0< ...
					variable x 123 x ! x @ 123 = \ true
					111 dup >r r@ r> + swap 2 * = and \ true
					333 444 drop 333 = and \ true
					555 666 swap 555 = \ true 666 true
					rot and swap \ true 666
					0< not and \ true
					-1 0< and \ true
					false over \ true 
					==>judge 
					[if] <js> ['!', '@', '>r', 'r>', 'r@', 'swap', 'drop', 
					'dup', 'over', '0<', '2drop', '</'+'jsR>'] </jsR> all-pass [then]
					2drop
					---
				</selftest>

code here!      here=pop() end-code // ( a -- ) 設定系統 dictionary 編碼位址
code here       push(here) end-code // ( -- a ) 系統 dictionary 編碼位址 a

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					marker ~~~
					*** here! here ...
						marker ---
							10000 here!  \ 
							here 10000 = \ true
							: dummy ; ' dummy js> pop().cfa 10000 >= and \ true
						---
						: dummy ; ' dummy js> pop().cfa 888 < and \ true
						==>judge 
						[if] <js> ['here', 'here!'] </jsV> all-pass [then]
					~~~ 
				</selftest>

\ JavaScript logical operations can be confusing
\ 在處理邏輯 operator 時我決定用 JavaScript 自己的 Boolean() 來 logicalize 所有的
\ operands, 這類共有 and or not 三者。為了保留 JavaScript && || 的功能 (邏輯一旦確
\ 立隨即傳回該 operand 之值) 另外定義 && || 遵照之，結果變成很奇特的功能。Forth 傳
\ 統的 AND OR NOT XOR 是 bitwise operators, 正好用傳統的大寫給它們。

code boolean    push(Boolean(pop())) end-code // ( x -- boolean(x) ) Cast TOS to boolean.
code and        var b=pop(),a=pop();push(Boolean(a)&&Boolean(b)) end-code // ( a b == a and b ) Logical and. See also '&&' and 'AND'.
code or         var b=pop(),a=pop();push(Boolean(a)||Boolean(b)) end-code // ( a b == a or b ) Logical or. See also '||' and 'OR'.
code not        push(!Boolean(pop())) end-code // ( x == !x ) Logical not. Capital NOT is for bitwise.
code &&         push(pop(1)&&pop()) end-code // ( a b == a && b ) if a then b else swap endif
code ||         push(pop(1)||pop()) end-code // ( a b == a || b ) if a then swap else b endif
code AND        push(pop() & pop()) end-code // ( a b -- a & b ) Bitwise AND. See also 'and' and '&&'.
code OR         push(pop() | pop()) end-code // ( a b -- a | b ) Bitwise OR. See also 'or' and '||'.
code NOT        push(~pop()) end-code // ( a -- ~a ) Bitwise NOT. Small 'not' is for logical.
code XOR        push(pop() ^ pop()) end-code // ( a b -- a ^ b ) Bitwise exclusive OR.
code true       push(true) end-code // ( -- true ) boolean true.
code false      push(false) end-code // ( -- false ) boolean false.
code ""         push("") end-code // ( -- "" ) empty string.
code []         push([]) end-code // ( -- [] ) empty array.
code {}         push({}) end-code // ( -- {} ) empty object.
code undefined  push(undefined) end-code // ( -- undefined ) Get an undefined value.
code null		push(null) end-code // ( -- null ) Get a null value. 
				/// 'Null' can be used in functions to check whether an argument is given.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** boolean and or && || not AND OR NOT XOR ... 
					undefined not \ true
					"" boolean \ true false
					and \ false
					false and \ false	
					false or \ false
					true or \ true
					true and \ true
					true or \ true
					false or \ true
					{} [] || \ true [] {} 
					&& \ true []
					|| \ [] true 
					&& \ true
					"" && \ true ""	
					not \ false
					1 2 AND \ true 0
					2 OR NOT  \ true -3
					-3 = \ true true
					1 2 XOR \ true true 3
					0 XOR 3 = \ true true true
					and and \ true 
					<js> function test(x){ return x }; test() </jsV> null = \ true true
					and ==>judge
					[if] <js> ['and', 'or', 'not', '||', '&&', 'AND', 'OR', 'NOT', 'XOR',
						  'true', 'false', '""', '[]', '{}', 'undefined', 'boolean', 'null'
					] </jsV> all-pass [then]
				</selftest>

\ Not eforth code words
\ 以下照理都可以用 eforth 的基本 code words 組合而成 colon words, 我覺得 jeforth 裡適合用 code word 來定義。

code +          push(pop(1)+pop()) end-code // ( a b -- a+b) Add two numbers or concatenate two strings.
code *          push(pop()*pop()) end-code // ( a b -- a*b ) Multiplex.
code -          push(pop(1)-pop()) end-code // ( a b -- a-b ) a-b
code /          push(pop(1)/pop()) end-code // ( a b -- c ) 計算 a 與 b 兩數相除的商 c
code 1+         push(pop()+1) end-code // ( a -- a++ ) a += 1
code 2+         push(pop()+2) end-code // ( a -- a+2 )
code 1-         push(pop()-1) end-code // ( a -- a-1 ) TOS - 1
code 2-         push(pop()-2) end-code // ( a -- a-2 ) TOS - 2

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** + * - / 1+ 2+ 1- 2- ...
					1 1 + 2 * 1 - 3 / 1+ 2+ 1- 2- 1 = ==>judge
					[if] <js> ['+', '*', '-', '/', '1+', '2+', '1-', '2-'] </jsV> all-pass [then]
				</selftest>

code mod        push(pop(1)%pop()) end-code // ( a b -- c ) 計算 a 與 b 兩數相除的餘 c
code div        var b=pop();var a=pop();push((a-(a%b))/b) end-code // ( a b -- c ) 計算 a 與 b 兩數相除的整數商 c

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** mod 7 mod 3 is 1 ...
						7 3 mod 1 = ==>judge drop
					*** div 7 div 3 is 2 ...
						7 3 div 2 = ==>judge drop
				</selftest>
				
code >>         var n=pop();push(pop()>>n) end-code // ( data n -- data>>n ) Singed right shift
code <<         var n=pop();push(pop()<<n) end-code // ( data n -- data<<n ) Singed left shift
code >>>        var n=pop();push(pop()>>>n) end-code // ( data n -- data>>>n ) Unsinged right shift. Note! There's no <<<.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** >> -1 signed right shift n times will be still -1 ...
						-1 9 >> -1 = ==>judge drop
					*** >> -4 signed right shift becomes -2 ...
						-4 1 >> -2 = ==>judge drop
					*** << -1 signed left shift 63 times become the smallest int number ...
						-1 63 << 0x80000000 -1 * = ==>judge drop
					*** >>> -1 >>> 1 become 7fffffff ...
						-1 1 >>> 0x7fffffff = ==>judge drop
				</selftest>
				
code 0=         push(pop()==0) end-code // ( a -- f ) 比較 a 是否等於 0
code 0>         push(pop()>0) end-code // ( a -- f ) 比較 a 是否大於 0
code 0<>        push(pop()!=0) end-code // ( a -- f ) 比較 a 是否不等於 0
code 0<=        push(pop()<=0) end-code // ( a -- f ) 比較 a 是否小於等於 0
code 0>=        push(pop()>=0) end-code // ( a -- f ) 比較 a 是否大於等於 0
code =          push(pop()==pop()) end-code // ( a b -- a=b ) 經轉換後比較 a 是否等於 b, "123" = 123.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** 0= 0> 0<> 0 <= 0>= ...
						"" 0= \ true
						undefined 0= \ true false
						1 0> \ true false true
						0 0> \ true false true false
						XOR -rot XOR + 2 = \ true
						0<> \ false
						0= \ true
						0<> \ true
						0<= \ true
						0>= \ true
						99 && \ 99 
						0= \ false
						99 || 0<> \ true
						-1 0<= \ true true
						1 0>= \ true true true
						s" 123" 123 = \ \ true true true true
						&& && && ==>judge
					[if] <js> ['0=', '0>', '0<>', '0<=', '0>=', '='] </jsV> all-pass [then]
				</selftest>
				
code ==         push(Boolean(pop())==Boolean(pop())) end-code // ( a b -- f ) 比較 a 與 b 的邏輯
code ===        push(pop()===pop()) end-code // ( a b -- a===b ) 比較 a 是否全等於 b
code >          var b=pop();push(pop()>b) end-code // ( a b -- f ) 比較 a 是否大於 b
code <          var b=pop(); push(pop()<b) end-code // ( a b -- f ) 比較 a 是否小於 b
code !=         push(pop()!=pop()) end-code // ( a b -- f ) 比較 a 是否不等於 b
code !==        push(pop()!==pop()) end-code // ( a b -- f ) 比較 a 是否不全等於 b
code >=         var b=pop();push(pop()>=b) end-code // ( a b -- f ) 比較 a 是否大於等於 b
code <=         var b=pop();push(pop()<=b) end-code // ( a b -- f ) 比較 a 是否小於等於 b


				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** == compares after booleanized ...
						{} [] == \ true 
						"" null == \ true
						"" undefined == \ true
						s" 123" 123 == \ true
						&& && && ==>judge drop
					*** === compares the type also ...
						"" 0 = \ true
						"" 0 == \ true
						"" 0 === \ false
						s" 123" 123 = \ true
						s" 123" 123 == \ true
						s" 123" 123 === \ false
						XOR and XOR and and ==>judge drop
					*** > < >= <= != !== <> ...
						1 2 > \ false
						1 1 > \ false
						2 1 > \ true
						1 2 < \ true
						1 1 < \ false
						2 1 < \ fasle
						1 2 >= \ false
						1 1 >= \ true
						2 1 >= \ true
						1 2 <= \ true
						1 1 <= \ true
						2 1 <= \ fasle
						1 1 <> \ false
						0 1 <> \ true
						XOR AND XOR and and and XOR XOR XOR and and XOR XOR ==>judge
						[if] <js> ['<', '>=', '<=', '!=', '!==', '<>'] </jsV> all-pass [then]
				</selftest>

code abs        push(Math.abs(pop())) end-code // ( n -- |n| ) Absolute value of n.
code max        push(Math.max(pop(),pop())) end-code // ( a b -- max(a,b) ) The maximum.
code min        push(Math.min(pop(),pop())) end-code // ( a b -- min(a,b) ) The minimum.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** abs makes negative positive ...
						1 63 << abs 0x80000000 = ==>judge drop 
					*** max min ...
						1 -2 3 max max 3 = \ true
						1 -2 3 min min -2 = \ true
						and ==>judge
						[if] <js> ['min'] </jsV> all-pass [then]
				</selftest>
				
code doVar      push(ip); ip=rstack.pop(); endinner=true; end-code compile-only // ( -- a ) 取隨後位址 a , runtime of created words
code doNext     var i=rstack.pop()-1;if(i>0){ip=dictionary[ip]; rstack.push(i);}else ip++ end-code compile-only // ( ?? ) next's runtime.
code ,          dictcompile(pop()) end-code // ( n -- ) Compile TOS to dictionary.

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					marker ---
					*** doVar doNext ...
						variable x
						: tt for x @ . x @ 1+ x ! next ;
						10 tt space x @ 10 = ==>judge [if] 
						<js> ['doNext','space', ',', 'colon-word', 'create', '(create)',
						'for', 'next'] </jsV> all-pass 
						[then]
					---
				</selftest>

\ 目前 Base 切換只影響 .r .0r 的輸出結果。
\ JavaScript 輸入用外顯的 0xFFFF 形式，用不著 hex decimal 切換。

code hex        base=16 end-code // ( -- ) 設定數值以十六進制印出 *** 20111224 sam
code decimal    base=10 end-code // ( -- ) 設定數值以十進制印出 *** 20111224 sam
code base@      push(base) end-code // ( -- n ) 取得 base 值 n *** 20111224 sam
code base!      base=pop() end-code // ( n -- ) 設定 n 為 base 值 *** 20111224 sam
10 base!        // 沒有經過宣告的 variable base 就是 global.base

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** hex decimal base@ base! ... 
						decimal base@ 0x0A = \ true
						10 0x10 = \ false
						hex base@ 0x10 = \ true
						10 0x10 = \ false !!!! JavaScript 輸入用外顯的表達 10 就是十不會變，這好！
						0x0A base! 
						base@ 10 = \ true
						XOR and XOR and ==>judge [if]
						<js> ['decimal','base@', 'base!'] </jsV> all-pass 
						[then]
				</selftest>
				
code depth      ( -- depth ) \ Data stack depth
				push(stack.length) end-code
code pick       ( nj ... n1 n0 j -- nj ... n1 n0 nj ) \ Get a copy of a cell in stack. 
				push(tos(pop())) end-code
code roll       ( ... n3 n2 n1 n0 3 -- ... n2 n1 n0 n3 )
				push(pop(pop())) end-code
				
				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					*** pick 2 from 1 2 3 gets 1 2 3 1 ...
					1 2 3 0 pick 3 = depth 4 = and >r 3 drops \ true
					1 2 3 1 pick 2 = depth 4 = and >r 3 drops \ true
					1 2 3 2 pick 1 = depth 4 = and >r 3 drops \ true
					r> r> r> and and ==>judge drop
					*** roll 2 from 1 2 3 gets 2 3 1 ...
					1 2 3 0 roll 3 = depth 3 = and >r 2 drops \ true
					1 2 3 1 roll 2 = depth 3 = and >r 2 drops \ true
					1 2 3 2 roll 1 = depth 3 = and >r 2 drops \ true
					r> r> r> and and ==>judge drop
				</selftest>
				
code .          print(pop()+""); end-code // ( n -- ) Print number or string on TOS.
: space      	(space) . ; // ( -- ) Print a space.

code word       ( "delimiter" -- "token" <delimiter> ) \ Get next "token" from TIB.
				push(nexttoken(pop())) end-code
				/// If delimiter is RegEx '\s' then white spaces before the "token" 
				/// will be removed. Otherwise, return TIB[ntib] up to but not include the delimiter.
				/// If delimiter not found then return the entire remaining TIB (can be multiple lines!).

				<selftest>
					marker ---
					*** word reads "string" from TIB ...
					char \s word    111    222 222 === >r s" 111" === r> and \ true , whitespace 會切掉
					char  2 word    111    222 222 === >r s"    111    " === r> and \ true , whitespace 照收
					: </div> ;
					char </div> word    此後到 </ div> 之
								前都被收進，可
								以跨行！ come-find-me-!!
					</div> js> pop().indexOf("come-find-me-!!")!=-1 \ true
					and and ==>judge drop	
					---
				</selftest>
				
: [compile]     ' , ; immediate // ( <string> -- ) Compile the next immediate word. 
				/// 把下個 word 當成「非立即詞」進行正常 compile, 等於是把它變成正常 word 使用。
				/// 常見 [compile] compiling 出現在 colon definition 裡，查看當時的 state。
				
: compile       ( -- ) r> dup @ , 1+ >r ; compile-only // ( -- ) Compile the next word in the dictionary over to dictionary[here].

				<selftest>
					marker ---
					*** [compile] compile [ ] ...
					: iii ; immediate
					: jjj ;
					: test [compile] iii compile jjj ; \ 正常執行 iii，把 jjj 放進 dictionary 
					: use [ test ] ; \ 如果 jjj 是 immediate 就可以不要 [ ... ] 
					' use js> pop().cfa @ ' jjj = ==>judge [if]
						<js> ['compile', '[', ']'] </jsV> all-pass 
					[then]
					---
				</selftest>

code colon-word	( -- ) \ Decorate the last() as a colon word.
				last().creater[0] = "colon";
				last().cfa = here;
				last().xt = colonxt;
				end-code
: create		( <name> -- ) \ Create a new word. The new word is a variable by default.
				BL word (create) colon-word compile doVar ;
code (marker)   ( "name" -- ) \ Create marker "name". Run "name" to forget itself and all newers.
                var lengthwas = current_word_list().length; // save current word list length before create the new marker word
				execute("(create)");
				// last().vid = current; done by (create) already
				// last().wid = current_word_list().length-1;   done by (create) already
				last().creater[0] = "code";
				last().creater.push(this.name); // this.name is "(marker)"
                last().herewas = here;
                last().lengthwas = lengthwas; // [x] 引進 vocabulary 之後，此 marker 在只有 forth-wordlist 時使用。有了多個 word-list 之後要改寫。
				last().help = newname + "\t" + packhelp(); // help messages packed
                last().xt = function(){ // marker's xt restores the saved context
                    here = this.herewas;
					order = [current = context = "forth"]; // 萬一此 marker 在引入 vocabulary 之後被 call 到。
					for(var vid in words) if(vid != current) delete words[vid]; // "forth" is the only one, clean up other word-lists.
                    words[current] = current_word_list().slice(0, this.lengthwas);
                    dictionary = dictionary.slice(0,here);
					wordhash = {};
                    for (var i=1; i<current_word_list().length; i++){  // 從舊到新，以新蓋舊,重建 wordhash{} hash table.
                        wordhash[current_word_list()[i].name] = current_word_list()[i];
                    }
                }
                end-code
: marker     	( <name> -- ) \ Create marker <name>. Run <name> to forget itself and all newers.
				BL word (marker) ;
code next       compilecode("doNext");dictionary[here++]=pop(); end-code immediate compile-only // ( -- ) for ... next (FigTaiwan SamSuanChen)

code [          compiling=false end-code immediate // ( -- ) 進入直譯狀態, 輸入指令將會直接執行 *** 20111224 sam
code ]          compiling=true end-code // ( -- ) 進入編譯狀態, 輸入指令將會編碼到系統 dictionary *** 20111224 sam
code cr         print("\n") end-code // ( -- ) 到下一列繼續輸出 *** 20111224 sam
code cls		screenbuffer="" end-code // ( -- ) Clear screen of the jQuery-terminal.
code abort      reset() end-code // ( -- ) Reset the forth system.

code literal    dictcompile(new Constant(pop())) end-code immediate compile-only // ( x -- ) Compile the TOS.
code alias      ( Word <alias> -- ) \ Create a new name for an existing word
				var w = pop();
				// To use the correct TIB, must use execute("word") instead of fortheval("word").
				execute("BL"); execute("word"); execute("(create)"); 
                // mergeObj(last(), w); // copy everything by value from the predecessor includes arrays and objects.
				for(var i in w) last()[i] = w[i]; // copy from predecessor but arrays and objects are by reference
				last().predecessor = last().name;
                last().name = newname;
				last().creater = w.creater.slice(0); // this is the way JavaScript copy array by value
				last().creater.push("alias");
                end-code

				<selftest>
					depth [if] .( Data stack should be empty! ) cr \s [then]
					marker ---
					*** alias should create a new word that acts same ...
						1234 constant x ' x alias y
						y 1234 = ==>judge drop
						\ see x cr see y
					---
				</selftest>

\ ------------------ eforth colon words ---------------------------

' != alias <>	// ( a b -- f ) 比較 a 是否不等於 b, alias of !=.
: nip           ( a b -- b ) swap drop ;
: rot           ( w1 w2 w3 -- w2 w3 w1 ) >r swap r> swap ;
: -rot          ( w1 w2 w3 -- w3 w1 w2 ) swap >r swap r> ;
: 2drop         ( a b -- ) drop drop ;
: 2dup          ( w1 w2 -- w1 w2 w1 w2 ) over over ;
' NOT alias invert // ( w -- ~w )
: negate        -1 * ; // ( n -- -n ) Negated TOS.
: within         ( n low high -- within? ) -rot over max -rot min = ;

				<selftest>
					*** nip rot -rot 2drop 2dup invert negate within ...
					1 2 3 4 nip \ 1 2 4
					-rot \ 4 1 2
					2drop \ 4
					3 2dup \ 4 3 4 3
					invert negate \ 4 3 4 4
					= rot rot \ true 4 3 
					5 within \ true true
					1 2 3 within \ true true false
					4 2 3 within \ true true false false
					-2 -4 -1 within \ true true false false true
					0 -4 -1 within \ true true false false true false
					-5 -4 -1 within \ true true false false true false false
					XOR XOR XOR XOR XOR XOR
					==>judge [if]
						<js> ['rot', '-rot', '2drop', '2dup', 'negate', 'invert', 'within'] </jsV> all-pass 
					[then]
				</selftest>

: [']			( <name> -- Word ) \ In colon definitions, compile next word object as a literal.
				' [compile] literal ; immediate compile-only 
				
				<selftest>
					marker ---
					*** ['] tick next word immediately ...
					: x ;
					: test ['] x ; 
					test ' x = ==>judge drop
					---
				</selftest>
				
: allot         here + here! ; // ( n -- ) 增加 n cells 擴充 memory 區塊

				<selftest>
					marker ---
					*** allot should consume some dictionary cells ...
					: a ; : b ; ' b js> pop().cfa ' a js> pop().cfa - \ normal distance
					: aa ; 
					10 allot 
					: bb ; ' bb js> pop().cfa ' aa js> pop().cfa - \ 10 more expected
					- abs 10 = ==>judge drop
					---
				</selftest>

: for           ( count -- ) \ for..next loop.
				compile >r here ; immediate compile-only
				/// index=(count ... 2,1) but when count <= 0 still do once!! for aft..then next , index=(count-1 ... 2,1) but if count <= 1 do nothing.
: begin         ( -- a ) \ begin..again, begin..until, begin..while..until..then, begin..while..repeat
				here ; immediate compile-only
: until         ( a -- ) \ begin..unitl
				compile 0branch , ; immediate compile-only
: again         ( a -- ) \ begin..again,
				compile  branch , ; immediate compile-only
				
				<selftest>
					marker ---
					*** begin again , begin until ... 
					: tt 
						1 0 \ index sum
						begin \ index sum
							over \ index sum index
							+ \ index sum'
							swap 1+ \ sum' index'
							dup 10 > if \ sum' index' 
								drop
								exit
							then  \ sum' index'
							swap  \ index' sum'
						again 
					; last execute 55 = \ true
					: ttt 
						1 0 \ index sum
						begin \ index sum
							over \ index sum index
							+ \ index sum'
							swap 1+ \ sum' index'
							swap \ index' sum' 
						over 10 > until \ index' sum' 
						nip
					; last execute 55 = \ true
					and ==>judge [if]
					<js> ['again', 'until', 'over', 'swap', 'dup', 'exit', 'nip'] </jsV> all-pass 
					[then]
					---
				</selftest>
				
: if            ( -- a ) \ if..then..else
				compile 0branch here 0 , ; immediate compile-only
: ahead         ( -- a ) \ aft internal use
				compile branch here 0 , ; immediate compile-only
: repeat        ( a a -- ) \ begin..while..repeat
				[compile] again here swap ! ; immediate compile-only
: then          ( a -- ) \ if..then..else
				here swap ! ; immediate compile-only
: aft           ( a -- a a ) \ for aft ... then next
				drop [compile] ahead [compile] begin swap ; immediate compile-only
: else          ( a -- a ) \ if..then..else
				[compile] ahead swap [compile] then ; immediate compile-only
: while         ( a -- a a ) \ begin..while..repeat
				[compile] if swap ; immediate compile-only

				<selftest>
					marker ---
					*** aft for then next ahead begin while repeat ... 
					: tt 5 for r@ next ; last execute + + + + 15 = \ true
					: ttt 5 for aft r@ then next ; last execute + + + 10 = \ true true
					depth 2 = \ T T T
					: tttt
						0 0 \ index sum
						begin \ idx sum
							over 10 <= 
						while \ idx sum
							over + 
							swap 1+ swap
						repeat \ idx sum
						nip
					; last execute 55 = \ T T T T
					and and and ==>judge [if]
					<js> ['for', 'then', 'next', 'ahead', 'begin', 'while', 'repeat'] </jsV> all-pass 
					[then]
					---
				</selftest>

: ?dup          dup if dup then ; // ( w -- w w | 0 ) Dup TOS if it is not 0|""|false.

				<selftest>
					*** ?dup dup only when it's true ...
					1 0 ?dup \ 1 0
					drop ?dup \ 1 1
					+ 2 = ==>judge drop
				</selftest>

: variable      ( <string> -- ) \ create a variable.
				create 0 , ;
: +!            ( n addr -- ) \ Add n into addr, addr is a variable.
				swap over @ swap + swap ! ;
: ?             @ . ; // ( a -- ) print value of the variable.
				
				<selftest>
					marker ---
					*** +! ? variable ...
					variable x 10 x !
					5 x +! x @ 15 = \ true 
					x ? space <js> screenbuffer.slice(-3)=='15 '</jsR> \ true true  
					and ==>judge [if]
					<js> ['variable', 'marker', '?', 'space'] </jsR> all-pass 
					[then] 
					---
				</selftest>
				
: chars         ( n str -- ) \ Print str n times.
				swap 0 max dup 0= if exit then for dup . next drop ;
				
: spaces        ( n -- ) \ print n spaces.
				(space) chars ;

				<selftest>
					marker ---
					*** spaces chars cls ...
					js> screenbuffer constant screenwas
					: test 10 spaces ;
					cls test js> screenbuffer s"           " = ==>judge [if]
					<js> ['chars', 'cls'] </jsR> all-pass 
					[then] 
					screenwas js: screenbuffer=pop()+screenbuffer 
					---
				</selftest>
				
: char          ( <str> -- str ) \ Get character(s).
				BL word [compile] compiling if [compile] literal then ; immediate
				/// "char abc" gets "abc", Note! ANS forth "char abc" gets only 'a'.
: .(            [ char \) ] literal word . BL word drop ; immediate // ( <str> -- ) Print following string down to ')' immediately.
: (             [ char \) ] literal word drop BL word drop ; immediate // ( <str> -- ) Ignore the comment down to ')'.
: ."            [ char " ] literal word [compile] literal BL word drop compile . ; immediate compile-only // ( <str> -- ) Print following string down to '"'.
: .'            [ char ' ] literal word [compile] literal BL word drop compile . ; immediate compile-only // ( <str> -- ) Print following string down to "'".

: s"  			( <str> -- str ) \ Get string down to the next delimiter.
				[ char " ] literal word [compile] compiling if [compile] literal then BL word drop ; immediate
: s'  			( <str> -- str ) \ Get string down to the next delimiter.
				[ char ' ] literal word [compile] compiling if [compile] literal then BL word drop ; immediate
: s`  			( <str> -- str ) \ Get string down to the next delimiter.
				[ char ` ] literal word [compile] compiling if [compile] literal then BL word drop ; immediate
: does>         r> s" last().cfa" jsEval ! ; // ( -- ) redirect the last new colon word.xt to after does>
: constant      create , does> r> @ ; // ( n <name> -- ) Create a constant.
				
				<selftest>
					marker ---
					*** .( ( ." .' s" s' s` ... 
					js> screenbuffer constant screenwas
					cls .( aa) ( now screenbuffer should be 'aa' ) 
					js> screenbuffer=="aa" \ true
					: test ." aa" .' bb' s' cc' . s` dd` . s" ee" . ; 
					cls test 
					js> screenbuffer=="aabbccddee" \ true
					and 
					screenwas js: screenbuffer=pop()
					==>judge [if]
					<js> ['(', '."', ".'", "s'", "s`", 's"', 'does>', 'constant'] </jsR> all-pass 
					[then] 
					---
				</selftest>

: count 		( string -- string length ) \ Get length of the given string
				s" tos().length" jsEval ;

				<selftest>
					*** count ... 
						s" abc" count 3 = swap \ true "abc"
						depth 2 = \ true "abc" true
						and and ==>judge drop
				</selftest>

code accept		push(false) end-code // ( -- str T|F ) Read a line from terminal. A fake before I/O ready.
: refill        ( -- flag ) \ Reload TIB from stdin. return 0 means no input or EOF
				accept if s" tib=pop();ntib=0" jsEval drop 1 else 0 then ;
: [else] ( -- ) \ 考慮中間的 nested 結構，把下一個 [then] 之前的東西都丟掉。
				1
				begin \ level
					begin \ level
						BL word count \ (level $word len ) 吃掉下一個 word
					while \ (level $word) 查看這個被吃掉的 word
						dup s" [if]" = if \ level $word
							drop 1+ \ level' 如果這個 word 是 [if] 就要多出現一個 [then] 之後才結束
						else \ level $word
							dup s" [else]" = if \ (level)
								drop 1- dup if 1+ then \ (level') 這個看不太懂，似乎是如果最外層多出一個 [else] 就把它當 [then] 用。
							else \ level $word
								s" [then]" = if \ (level)
									1- \ level' \ (level') 如果這個 word 是 [then] 就剝掉一層
								then \ (level') 其他 word 吃掉就算了
							then \ level'
						then \ level'
						?dup if else exit then \ (level') 這個 [then] 是最外層就整個結束，否則繼續吃掉下一個 word.
					repeat \ (level) or (level $word)
					drop   \ (level)
				refill not until \ level
				drop
				; immediate
: [if] 			( flag -- ) \ Conditional compilation [if] [else] [then]
				if else [compile] [else] then \ skip everything down to [else] or [then] when flag is not true.
				; immediate
: [then] 		( -- ) \ Conditional compilation [if] [else] [then]
				; immediate
: js>  			( <expression> -- value ) \ Evaluate JavaScript <expression> which has no white space within.
				BL word [compile] compiling if [compile] literal compile jsEval else jsEval then  ; immediate
				/// Same thing as "s' blablabla' jsEval" but simpler. Return the last statement's value.
: js:  			( <expression> -- ) \ Evaluate JavaScript <expression> which has no white space within
				BL word [compile] compiling if [compile] literal compile jsEval2 else jsEval2 then  ; immediate
				/// Same thing as "s' blablabla' jsEval2" but simpler. No return value.

: sleep 		( mS -- ) \ Suspend the forth VM for mS time
				js: setTimeout(resumeForthVM,pop())
				suspend ;

: "msg"abort	( "errormsg" -- ) \ Panic with error message and abort the forth VM
				cr js: panic(pop()+'\n') abort ;
				
: abort"		( <msg>	-- ) \ Through an error message and abort the forth VM
				char " word [compile] literal BL word drop compile "msg"abort ; 
				immediate compile-only
				
: "msg"?abort	( flag "errormsg" -- ) \ Conditional panic with error message and abort the forth VM
                swap if "msg"abort else drop then ;
				
: ?abort"       ( f <errormsg> -- ) \ Conditional abort with an error message.
                char " word [compile] literal BL word drop compile "msg"?abort ; 
				immediate compile-only

\ 其實所有用 word 取 TIB input string 的 words， 用 file 或 clipboard 輸入時， 都是可
\ 以跨行的！只差用 keyboard 輸入時受限於 console input 一般都是以「行」為單位的，造成
\ TIB 只能到行尾為止後面沒了，所以才會跨不了行。將來要讓 keyboard 輸入也能跨行時，就
\ 用 text。

: <text>		( <text> -- "text" ) \ Get multiple-line string
				char </text> word ; immediate

: </text> 		( "text" -- ... ) \ Delimiter of <text>
				[compile] compiling if [compile] literal then ; immediate
				/// Usage: <text> word of multiple lines </text>

: <js> 			( <js statements> -- "statements" ) \ Evaluate JavaScript statements
				char </js>|</jsV>|</jsN>|</jsv>|</jsn>|</jsR>|</jsr> word 
				[compile] compiling if [compile] literal then ; immediate

: </jsN> 		( "statements" -- ) \ No return value
				[compile] compiling if compile jsEval2 else jsEval2 then ; immediate
				last alias </js>  immediate
				last alias </jsn> immediate
				
: </jsV> 		( "statements" -- ) \ Retrun the value of last statement
				[compile] compiling if compile jsEval else jsEval then ; immediate
				last alias </jsv> immediate
				last alias </jsR> immediate
				last alias </jsr> immediate

\ ------------------ Tools  ----------------------------------------------------------------------
: drops 		( ... n -- ... ) \ Drop n cells from data stack.
				1+ js> stack.splice(stack.length-tos(),pop()) drop ;
				/// We need 'drops' <js> sections in a colon definition are easily to have 
				/// many input arguments that need to be dropped.

				<selftest>
					*** drops n data stack cells ... 
						1 2 3 4 5 2 drops depth 3 = ==>judge 4 drops
				</selftest>

\ JavaScript's hex is a little strange.
\ Example 1: -2 >> 1 is -1 correct, -2 >> 31 is also -1 correct, but -2 >> 32 become -2 !!
\ Example 2: -1 & 0x7fffffff is 0x7fffffff, but -1 & 0xffffffff will be -1 !! 
\ That means hex is 32 bits and bit 31 is the sign bit. But not exactly, because 0xfff...(over 32 bits)
\ are still valid numbers. However, my job is just to print hex correctly by using .r and 
\ .0r. So I simply use a workaround that prints higher 16 bits and then lower 16 bits respectively.
\ So JavaScript's opinion about hex won't bother me anymore.
			
code .r         ( num|str n -- ) \ Right adjusted print num|str in n characters (FigTaiwan SamSuanChen)
                var n=pop(); var i=pop();
				if(typeof i == 'number') {
					if(base == 10){
						i=i.toString(base);
					}else{
						i = (i >> 16 & 0xffff || "").toString(base) + (i & 0xffff).toString(base);
					}
				}
                n=n-i.length;
                if(n>0) do {
					i=" "+i;
					n--;
				} while(n>0);
                print(i);
                end-code
				
code .0r        ( num|str n -- ) \ Right adjusted print num|str in n characters (FigTaiwan SamSuanChen)
                var n=pop(); var i=pop();
				var minus = "";
				if(typeof i == 'number') {
					if(base == 10){
						if (i<0) minus = '-';
						i=Math.abs(i).toString(base);
					}else{
						i = (i >> 16 & 0xffff || "").toString(base) + (i & 0xffff).toString(base);
					}
				}
                n=n-i.length - (minus?1:0);
                if(n>0) do {
					i="0"+i;
					n--;
				} while (n>0);
                print(minus+i);
                end-code
				/// Limitation: Negative numbers are printed in a strange way. e.g. "0000-123".
				/// We need to take care of that separately.

				<selftest>
					<text> .r 是 FigTaiwan 爽哥那兒抄來的。 JavaScript 本身就有 number.toString(base) 可以任何 base
					印出數值。base@ base! hex decimal 等只對 .r .0r 有用。輸入時照 JavaScript 的慣例，數字就是十進位，
					0x1234 是十六進位，已經足夠。 .r .0r 很有用, .s 的定義就是靠他們。
					</text> drop 
					
					marker ---
					
					*** .r .0r can print hex-decimal ...
					decimal  -1 10  .r <js> screenbuffer.slice(-10)=='        -1'</jsR> \ true
					hex      -1 10  .r <js> screenbuffer.slice(-10)=='  ffffffff'</jsR> \ true
					decimal  56 10 .0r <js> screenbuffer.slice(-10)=='0000000056'</jsR> \ true
					hex      56 10 .0r <js> screenbuffer.slice(-10)=='0000000038'</jsR> \ true
					decimal -78 10 .0r <js> screenbuffer.slice(-10)=='-000000078'</jsR> \ true 
					hex     -78 10 .0r <js> screenbuffer.slice(-10)=='00ffffffb2'</jsR> \ true
					XOR XOR XOR XOR and space
					==>judge [if] <js> ['decimal', 'hex', '.0r'] </jsR> all-pass [then] 
					---
				</selftest>
				
code dropall    stack=[] end-code // ( ... -- ) Clear the data stack.

				<selftest> 
					*** dropall clean the data stack ...
					1 2 3 4 5 dropall depth 0= ==>judge drop 
				</selftest>
				
code (ASCII)    push(pop().charCodeAt(0)) end-code // ( str -- ASCII ) Get a character's ASCII code.
code ASCII>char ( ASCII -- 'c' ) \ number to character
				push(String.fromCharCode(pop())) end-code 
				/// 65 ASCII>char tib. \ ==> A (string)
: ASCII			( <str> -- ASCII ) \ Get a character's ASCII code.
				BL word (ASCII) [compile] compiling if [compile] literal then 
				; immediate 

				<selftest>
					marker ---
					*** ASCII (ASCII) ASCII>char  ...
					char abc (ASCII) 97 = \ true
					98 ASCII>char char b = \ true
					: test ASCII c ; test 99 = \ true
					and and ==>judge [if] <js> ['(ASCII)', 'ASCII>char'] </jsV> all-pass [then]
					---
				</selftest>
				
code .s         ( ... -- ... ) \ Dump the data stack.
				var count=stack.length, basewas=base;
                if(count>0) for(var i=0;i<count;i++){
					if (typeof(stack[i])=="number") {
						push(stack[i]); push(i); fortheval("decimal 7 .r char : . space dup decimal 11 .r space hex 11 .r char h .");
					} else {
						push(stack[i]); push(i); fortheval("decimal 7 .r char : . space .");
					}
					print(" ("+mytypeof(stack[i])+")\n");
                } else print("empty\n");
				base = basewas;
                end-code

				<selftest>
					marker ---
					*** .s is almost the most used word ...
					js> screenbuffer constant screenwas
					cls 32424 -24324 .s 
					<js> screenbuffer.indexOf('32424')    !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('7ea8h')    !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('-24324')   !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('ffffa0fch')!=-1 </jsV> \ true
					<js> screenbuffer.indexOf('2:')       ==-1 </jsV> \ true
					screenwas js: screenbuffer=pop()
					and and and and ==>judge 3 drops
					---
				</selftest>

				
code (see)      ( thing -- ) \ See into the given word, object, array, ... anything.
                var w=pop(); 
				var basewas = base; base = 10;
                if (!(w instanceof Word)) {
                    see(w);  // none forth word objects. 意外的好處是不必有 "unkown word" 這種無聊的錯誤訊息。
                }else{
                    for(var i in w){
                        if (typeof(w[i])=="function") continue;
                        if (i=="comment") continue;
                        push(i); fortheval("16 .r s'  : ' .");
                        print(w[i]+" ("+mytypeof(w[i])+")\n");
                    }
                    if (w.creater[0] == "colon"){
                        var i = w.cfa;
                        print("\n-------- Definition in dictionary --------\n");
                        do {
							push(i); fortheval("5 .0r");
                            print(": "+dictionary[i]+" ("+mytypeof(dictionary[i])+")\n");
                        } while (dictionary[i++] != objRet);
                        print("---------- End of the definition -----------\n");
                    } else {
                        for(var i in w){
                            if (typeof(w[i])!="function") continue;
                            // if (i=="selfTest") continue;
                            push(i); fortheval("16 .r s'  :\n' .");
                            print(w[i]+"\n");
                        }
                    }
                    if (w.comment != undefined) print("\ncomment:\n"+w.comment+"\n");
                }
				base = basewas;
                end-code
: see           ' (see) ; // ( <name> -- ) See definition of the word

				<selftest>
					marker ---
					*** see (see) ...
					js> screenbuffer constant screenwas
					: test ; // test.test.test
					cls see test
					<js> screenbuffer.indexOf('test.test.test') !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('cfa') !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('colon') !=-1 </jsV> \ true
					screenwas js: screenbuffer=pop()
					and and ==>judge [if] <js> ['(see)'] </jsv> all-pass [then]
					---
				</selftest>
				
code words      ( [<pattern>] -- ) \ List words of name/help/comments screened by pattern.
                fortheval("s' forth' (words) " + nexttoken('\\n'));
				var word_list = pop();
				var w = "";
                for (var i=0; i<word_list.length; i++) w += word_list[i].name + " ";
				print(w);
				end-code
				/// Search the pattern in help and comments also.
				
code (words)    ( "word-list" [<pattern>] -- word[] ) \ Get an array of words, name/help/comments screened by pattern.
                // var RegEx = new RegExp(nexttoken(),"i");
				var pattern = nexttoken('\\n|\\r'); // if use only '\\n' then we get an unexpected ending '\r'. 
				var word_list = words[pop()];
				var result = [];
                for(var i=1;i<word_list.length;i++) {
					// if (RegEx){
					if (pattern){
						var flag = 	// (word_list[i].name.search(RegEx) != -1 ) ||
									// (word_list[i].help.search(RegEx) != -1 ) ||
									// (typeof(word_list[i].comment)!="undefined" && (word_list[i].comment.search(RegEx) != -1)));
									(word_list[i].name.indexOf(pattern) != -1 ) ||
									(word_list[i].help.indexOf(pattern) != -1 ) ||
									(typeof(word_list[i].comment)!="undefined" && (word_list[i].comment.indexOf(pattern) != -1));
						if (flag) { 
							result.push(word_list[i]); 
						}
					} else {
						result.push(word_list[i]);
					}
				}
				push(result);
                end-code

code help       ( [<pattern>] -- ) \ Print help of words which's name/help/comments are screened by pattern.
                fortheval("s' forth' (words) " + nexttoken('\\n'));
				var word_list = pop();
                for (var i=0; i<word_list.length; i++) {
					print(word_list[i]+"\n");
					if (typeof(word_list[i].comment) != "undefined") print("\t\t"+word_list[i].comment+"\n");
				}
				end-code

				<selftest>

					<text> 
					本來 words help 都接受 RegEx 的，可是不好用。現已改回普通 non RegEx pattern. 只動 
					(words) 就可以來回修改成 RegEx/non-RegEx. 
					</text> drop

					marker ---
					*** help words (words) ...
					js> screenbuffer constant screenwas
					: test ; // testing help words and (words) 32974974
					/// 9247329474 comment
					cls help
					<js> screenbuffer.indexOf('32974974') !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('9247329474') !=-1 </jsV> \ true
					cls words 9247329474
					<js> screenbuffer.indexOf('test') !=-1 </jsV> \ true
					cls words test
					<js> screenbuffer.indexOf('<selftest>') !=-1 </jsV> \ true
					<js> screenbuffer.indexOf('***') !=-1 </jsV> \ true
					screenwas js: screenbuffer=pop()
					and and and and ==>judge [if] <js> ['(words)', 'words'] </jsv> all-pass [then]
					---
				</selftest>
				
code bye        ( ERRORLEVEL -- ) \ Exit to shell with TOS as the ERRORLEVEL.
                var errorlevel = pop();
				window.errorlevel = typeof(errorlevel)=='number' ? errorlevel : 0;
                close();
                end-code

code readFile 	( "pathname" -- string ) \ Read utf8 text file to a string. Panic if failed.
				push(fs.readFileSync(pop(),'utf8'));
				end-code
				
code writeFile ( string "pathname" -- ) \ Write string to utf8 text file. Panic if failed.
				fs.writeFileSync(pop(),pop(),'utf8')
				end-code

code tib.append	( "string" -- ) \ Append the "string" to TIB
				tib += " " + pop(); end-code

				<selftest> <text>
					靠！ tib.append 沒辦法測呀！到了 terminal prompt 手動這樣測，
					OK 111 s" 12345" tib.append 222
					OK .s
						0:         111          6fh (number)
						1:         222          deh (number)
						2:       12345        3039h (number) <=== appended to the ending
				</text> drop </selftest>

code tib.insert	( "string" -- ) \ Insert the "string" into TIB
				var before = tib.slice(0,ntib), after = tib.slice(ntib);
				tib = before + " " + pop() + " " + after; end-code

code sinclude.js ( "pathname" -- ) \ Include JavaScript source file
				fortheval("readFile"); eval(pop());
				end-code
: include.js	( <pathname> -- ) \ Include JavaScript source file
				BL word sinclude.js ;

: sinclude		( "pathname" -- ... ) \ Lodad the given forth source file.
				readFile tib.insert ;

: include       ( <filename> -- ... ) \ Load the source file if it's not included yet.
				BL word sinclude ; interpret-only

: dump          ( addr -- addr' ) \ dump dictionary
                20 for \ (addr)
                    dup @ js> pop()==undefined if \ Dictionary 裡往下沒東西了 (addr)
                        r> drop 0 >r \ terminate the for...next after this cycle
                    then
                    dup 5 .0r s" : " . dup ? s"  (" . dup @ js> typeof(pop()) . s" )" . cr
                1+ next \ (addr')
                ;

: d        		( <addr> -- ) \ dump dictionary
                recentcolonword \ save the recentcolonword to local stack immediatly, it will be changed soon.
                BL word  					\ (recentcolonword str)
                count 0= 					\ (recentcolonword str undef?) No start address?
                if       					\ (recentcolonword str)
                    drop 					\ drop the undefined  (recentcolonword)
					js> tos().lastaddress
                else  						\ (recentcolonword str)
                    js> parseInt(pop())		\ (recentcolonword addr)
                then
				dump 						\ (recentcolonword addr')
				js: pop(1).lastaddress=pop()
                ;

code notpass	( -- ) \ List words their sleftest flag are not 'pass'.
				for (var j in words) { // all word-lists
					for (var i in words[j]) {  // all words in a word-list
						if(i!=0 && words[j][i].selftest != 'pass') print(words[j][i].name+" ");
					}
				}
				end-code 
 
				<selftest>
					marker ---
					*** d dump notpass readFile writeFile ...
					js> screenbuffer constant screenwas
					cls d 0
					<js> screenbuffer.indexOf('00000: 0 (number)') !=-1 </jsV> \ true
					cls notpass cr 
					js> screenbuffer char selftest.log writeFile
					char selftest.log readFile constant verify // read back the selftest.log for verification
					verify <js> pop().indexOf('bye') !=-1 </jsV> \ true
					verify <js> pop().indexOf('***') !=-1 </jsV> \ true
					verify <js> pop().indexOf('pass') !=-1 </jsV> \ true
					verify <js> pop().indexOf('fail') ==-1 </jsV> \ true
					verify <js> pop().indexOf('Fail') ==-1 </jsV> \ true
					verify <js> pop().indexOf('error') ==-1 </jsV> \ true
					verify <js> pop().indexOf('Error') ==-1 </jsV> \ true
					screenwas js: screenbuffer=pop()
					and and and and and and and ==>judge [if] 
					<js> ['dump', 'notpass', 'readFile', 'writeFile'] </jsv> all-pass 
					[then]
					---
				</selftest>

\ -------------- Forth Debug Console -------------------------------------------------

: (*debug*)		( "prompt" -- ) \ Forth debug console. 'q' to exit.
				s" *debug* " swap + s"  " + js: prompt=pop();indebug=true; suspend ;

: *debug*		( <prompt> -- ) \ Forth debug console. 'q' to exit.
				BL word [compile] compiling 
				if [compile] literal compile (*debug*) else (*debug*) then 
				; immediate

code q			( -- ) \ Exit from forth debug console.
				prompt="OK ";
				indebug=false;
				resumeForthVM();
				end-code
				
\ ----------------- Self Test -------------------------------------

<selftest> 
	<js> ['accept', 'refill', 'wut', '==>judge', 'all-pass', '***', 
		  '~~selftest~~', '.((', 'sleep'
	] </jsv> all-pass 
	cr .( The following words are not tested yet : ) cr
	notpass cr cr
	.(( Saving selftest information to log file 'selftest.log'. )) cr
	js> screenbuffer char selftest.log writeFile
	~~selftest~~ 								\ forget self-test temporary words
	js: $.terminal.active().echo(screenbuffer) 	\ print the self-test results to terminal 
	js: tick('<selftest>').buffer="" 			\ clear the self-test section, recycle the memory
</selftest>

\ Do the jeforth.f self-test only when there's no command line 
js> require('nw.gui') constant nw.gui // Note-webkit GUI module
nw.gui js> pop().App.argv.length [if] \ We have jobs from command line to do. Disable self-test.
	js: tick('<selftest>').enabled=false
[else] \ We don't have jobs from command line to do. So we do the self-test.
	js> tick('<selftest>').enabled=true;tick('<selftest>').buffer tib.insert
[then] js: tick('<selftest>').buffer="" \ recycle the memory

\ ----------------- include .f modules -------------------------------------
include platform.f 	\ Let platform.f be the first one if we want to use jQuery-terminal.
include voc.f		\ voc.f is very basic too if we like to use vocabulary.
include mytools.f

\ ----------------- run the command line -------------------------------------
nw.gui <js> pop().App.argv.join(" ") </jsV> tib.insert

\ ------------ End of jeforth.f, the kernel of jeforth.3nw -------------------



