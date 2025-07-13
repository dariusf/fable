
  $ . ../testing.sh

  $ fable -s ../programs/test.md -o test

  $ node test.js test/index.html 'Go to Scene 1' 'Apple'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>text from Scene 1</span></div><div class="para fadein"><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ node test.js test/index.html 'Go to Scene 3'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein"><span>text from Scene 3</span></div><div class="para fadein"><span>Turns:</span><span> </span><span>1</span></div>

  $ node test.js test/index.html 'Say something, then to Scene 1' 'Apple'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>should show.</span></div><div class="para fadein old"><span>text from Scene 1</span></div><div class="para fadein"><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ node test.js test/index.html 'Continue'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein"><span>End of first scene</span></div>

  $ node test.js test/index.html 'Nested lists' 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>Right before going back to Nested</span></div><div class="para fadein old"><span>after</span><span> </span><span>break</span></div><div class="para fadein old"><span>Right before going back to Nested</span></div><div class="para fadein old"><span>A paragraph</span></div><div class="para fadein old"><span>Right before going back to Nested</span></div><div class="para fadein"><span>Right before going back to Nested</span></div><ul class="choice fadein"></ul>

  $ node test.js test/index.html 'Copy' 'Apple'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div><div class="para fadein old"><span>text from Scene 1</span></div><div class="para fadein"><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ node test.js test/index.html 'More' 'a'
  <div class="para fadein old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="para fadein old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="para fadein old"><a href="#">jump</a></div><div class="para fadein old"><a href="#">code</a></div><div class="para fadein old"><span>Make a choice:</span></div>

  $ node test.js test/index.html 'Jump dynamic'
  <div class="para fadein"><span>Apple scene</span></div>

  $ node test.js test/index.html 'Tunnel!'
  <div class="para fadein"><span>Tunnel</span></div><div class="para fadein"><span>End of first scene</span></div>

  $ node test.js test/index.html 'Tunnels followed by jumps'
  <div class="para fadein"><span>before</span></div><div class="para fadein"><span>a</span></div><ul class="choice fadein"><li><a idx="1" href="#" class="choice" draggable="false"><span>b</span></a></li></ul>

  $ node test.js test/index.html 'Spaces' 'choice text'
  <div class="para fadein"><span>code after</span></div><div class="para fadein"><span>"Hi,</span><span> </span><span>A</span><span>," he said.</span></div><div class="para fadein"><span>"</span><span>Edge case</span><span>" here</span></div><div class="para fadein"><span>A</span><span>'s thing</span></div>

  $ node test.js test/index.html 'Inline and block meta'
  <div class="para fadein"><span>interpolation</span><span> </span><span>1</span></div><div class="para fadein"><span>inline meta</span><span> </span><span><span>1</span></span></div><div class="para fadein"><span>block meta</span></div>

  $ node test.js test/index.html 'Inline meta jump'
  <div class="para fadein"><span>hi</span><span> </span><span><span>there</span></span></div><ul class="choice fadein"><li><a idx="1" href="#" class="choice" draggable="false"><span>a</span></a></li><li><a idx="2" href="#" class="choice" draggable="false"><span>b</span></a></li></ul>

  $ node test.js test/index.html 'Block meta jump'
  <div class="para fadein"><span>1</span></div><div class="para fadein"><span>2</span></div><div class="para fadein"><span>3</span></div>

  $ node test.js test/index.html 'Choice break delimiters'
  <ul class="choice fadein"><li><a idx="1" href="#" class="choice" draggable="false"><span>asd</span></a></li></ul>

  $ node test.js test/index.html 'Choice break delimiters' 'asd'
  <div class="para fadein"><span>selected</span></div>

  $ simple ../programs/nonexistent-section.md Hello
  <div class="para fadein error" style="color: red;">Jump a scene not found</div>

  $ simple ../programs/consumable-choices.md c1
  <ul class="choice fadein"><li><a idx="1" href="#" class="choice" draggable="false"><span>c2</span></a></li></ul>

  $ simple ../programs/sticky-choices.md c1
  <ul class="choice fadein"><li><a idx="1" href="#" class="choice" draggable="false"><span>c1</span></a></li><li><a idx="2" href="#" class="choice" draggable="false"><span>c2</span></a></li></ul>
