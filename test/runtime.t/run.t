
  $ fable -s ../../examples/test.md -o test

  $ export INPUT=test/index.html

  $ ./test.js 'Go to Scene 1' 'Apple'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div><div class="old"><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'Go to Scene 3'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div><div><span>text from Scene 3</span></div><div><span>Turns:</span><span> </span><span>1</span></div>

  $ ./test.js 'Say something, then go to Scene 1' 'Apple'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div><div class="old"><span>should show.</span></div><div class="old"><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'Continue'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div><div><span>End of first scene</span></div>

  $ ./test.js 'Nested lists' 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div><div class="old"><span>Right before going back to Nested</span></div><div class="old"><span>after</span><span> </span><span>break</span></div><div class="old"><span>Right before going back to Nested</span></div><div class="old"><span>A paragraph</span></div><div class="old"><span>Right before going back to Nested</span></div><div><span>Right before going back to Nested</span></div><ul></ul>

  $ ./test.js 'Copy' 'Apple'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div><div class="old"><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'More' 'a'
  <div class="old"><span>Hello</span><span> </span><span>Apple</span><span>!</span></div><div class="old"><span>inline comments</span><span> </span><span><i>don't</i></span><span> </span><span>appear</span></div><div class="old"><a href="#">jump</a></div><div class="old"><a href="#">code</a></div><div class="old"><span>Make a choice:</span></div>

  $ ./test.js 'Jump dynamic'
  <div><span>Apple scene</span></div>

  $ ./test.js 'Tunnel'
  <div><span>Tunnel</span></div><div><span>End of first scene</span></div>

  $ ./test.js 'Tunnels followed by jumps'
  <div><span>before</span></div><div><span>a</span></div><ul><li><a href="#" class="choice" draggable="false"><span>b</span></a></li></ul>

  $ ./test.js 'Spaces' 'choice text'
  <div><span>code after</span></div><div><span>"Hi,</span><span> </span><span>A</span><span>," he said.</span></div><div><span>"</span><span>Edge case</span><span>" here</span></div><div><span>A</span><span>'s thing</span></div>
