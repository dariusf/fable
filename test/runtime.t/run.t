
  $ fable -s ../../examples/test.md -o test

  $ export INPUT=test/index.html

  $ ./test.js 'Go to Scene 1' 'Apple'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'Go to Scene 3'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>text from Scene 3</span></div><div><span>Turns:</span><span>1</span></div>

  $ ./test.js 'Say something, then go to Scene 1' 'Apple'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>should show.</span></div><div><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'Continue'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>End of first scene</span></div>

  $ ./test.js 'Nested lists' 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>Right before going back to Nested</span></div><div><span>after</span><span> </span><span>break</span></div><div><span>Right before going back to Nested</span></div><div><span>A paragraph</span></div><div><span>Right before going back to Nested</span></div><div><span>Right before going back to Nested</span></div><ul></ul>

  $ ./test.js 'Copy' 'Apple'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.js 'More' 'a'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div>

  $ ./test.js 'Jump dynamic'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>Apple scene</span></div>

  $ ./test.js 'Tunnel'
  <div><span>Hello</span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>Tunnel</span></div><div><span>End of first scene</span></div>
