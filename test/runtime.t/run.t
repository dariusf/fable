
  $ export INPUT=../../../../../../index.html

  $ ./test.py 'Go to Scene 1' 'Apple'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.py 'Go to Scene 3'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>text from Scene 3</span></div><div><span>Turns: </span><span>1</span></div>

  $ ./test.py 'Say something, then go to Scene 1' 'Apple'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span> should show. </span></div><div><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.py 'Continue'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>End of first scene</span></div>

  $ ./test.py 'Nested lists' 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>Right before going back to Nested</span></div><div><span> after</span><br><span>break</span></div><div><span>Right before going back to Nested</span></div><div><span>A paragraph</span></div><div><span>Right before going back to Nested</span></div><div><span>Right before going back to Nested</span></div><ul></ul>

  $ ./test.py 'Copy' 'Apple'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div><div><span>text from Scene 1</span></div><div><details>
    <summary>Click me</summary>
    This was hidden
  </details></div>

  $ ./test.py 'More' 'a'
  <div><span>Hello </span><span>Apple</span><span>!</span></div><div><a href="#">jump</a></div><div><a href="#">code</a></div><div><span>Make a choice:</span></div>
