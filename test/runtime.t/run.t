
  $ fable -s ../../examples/test.md -o test

  $ export INPUT=test/index.html

  $ ./test.js 'Go to Scene 1' 'Apple'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>text from Scene 1</span></div><div class="para fadein"><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'Go to Scene 3'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein"><span>text from Scene 3</span></div><div class="para fadein"><span>Turns:</span><span> </span><span>1</span></div>

  $ ./test.js 'Say something, then go to Scene 1' 'Apple'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>should show.</span></div><div class="para fadein old"><span>text from Scene 1</span></div><div class="para fadein"><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'Continue'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein"><span>End of first scene</span></div>

  $ ./test.js 'Nested lists' 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>Right before going back to Nested</span></div><div class="para fadein old"><span>after</span><span> </span><span>break</span></div><div class="para fadein old"><span>Right before going back to Nested</span></div><div class="para fadein old"><span>A paragraph</span></div><div class="para fadein old"><span>Right before going back to Nested</span></div><div class="para fadein"><span>Right before going back to Nested</span></div><ul class="choice fadein"></ul>

  $ ./test.js 'Copy' 'Apple'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>text from Scene 1</span></div><div class="para fadein"><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'More' 'a'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div>

  $ ./test.js 'Jump dynamic'
  <div class="para fadein"><span>Apple scene</span></div>

  $ ./test.js 'Tunnel'
  <div class="para fadein"><span>Tunnel</span></div><div class="para fadein"><span>End of first scene</span></div>

  $ ./test.js 'Tunnels followed by jumps'
  <div class="para fadein"><span>before</span></div><div class="para fadein"><span>a</span></div><ul class="choice fadein"><li><a href="#" class="choice" draggable="false"><span>b</span></a></li></ul>

  $ ./test.js 'Spaces' 'choice text'
  <div class="para fadein"><span>code after</span></div><div class="para fadein"><span>"Hi,</span><span> </span><span>A</span><span>," he said.</span></div><div class="para fadein"><span>"</span><span>Edge case</span><span>" here</span></div><div class="para fadein"><span>A</span><span>'s thing</span></div>

  $ ./test.js 'Inline and block meta'
  <div class="para fadein"><span>interpolation</span><span> </span><span>1</span></div><div class="para fadein"><span>inline meta</span><span> </span><span><span>1</span></span></div><div class="para fadein"><span>block meta</span></div>

  $ ./test.js 'Inline jump'
  <div class="para fadein"><span>hi</span><span> </span><span><span>there</span></span></div><ul class="choice fadein"><li><a href="#" class="choice" draggable="false"><span>a</span></a></li><li><a href="#" class="choice" draggable="false"><span>b</span></a></li></ul>
