
  $ . ../testing.sh

  $ run ../programs/unicode.md
  <div class="para"><span>“hello — don’t worry, we’ll be open 9–10…”</span></div>

  $ run ../programs/smartypants.md
  <div class="para"><span>“hello — don’t worry, we’ll be open 9–10…”</span></div>

  $ run ../programs/empty-section.md

  $ run ../programs/breaks.md
  <div class="para">
    <span>a</span><span><br /></span><span> </span><span>b</span
    ><span><br /></span><span> </span><span>c</span>
  </div>

  $ run ../programs/paragraph-break.md c
  <div class="para old"><span>a</span></div>
  <div class="para old"><span>b</span></div>
  <div class="para"><span>haha</span></div>
  <div class="para">
    <span>b</span><span> </span><span>this should not be expanded</span>
  </div>

  $ run ../programs/emphasis.md
  <div class="para">
    <i><span>text</span></i
    ><span> </span><span>from</span><span> </span><i><span>Scene</span></i
    ><span> </span><span>1</span>
  </div>

  $ run ../programs/comments.md
  <div class="para">
    <span>inline comments</span><span> </span><span><i>don’t</i></span
    ><span> </span><span>appear</span>
  </div>

  $ run ../programs/jump-links.md jump
  <div class="para"><a href="#">jump</a></div>
  <div class="para"><span>asd</span></div>

  $ run ../programs/code-links.md code
  <div class="para"><a href="#">code</a></div>
  <div class="para"><span>Hi!</span></div>

  $ run ../programs/frontmatter.md
  <div class="para"><span>hello</span></div>

  $ run ../programs/choices-precondition-seen.md a
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>b</span></a>
    </li>
  </ul>

  $ run ../programs/choices-loose.md First
  <div class="para old"><span>Before</span></div>
  <div class="para"><span>Body</span></div>
  <div class="para"><span>After</span></div>

  $ run ../programs/choices-tweet-style.md a
  <div class="para"><span>this is later cleared</span></div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c</span></a>
    </li>
  </ul>

  $ run ../programs/choices-tweet-style.md a c
  <div class="para"><span>after</span></div>

  $ run ../programs/meta.md
  <div class="para"><span>text from Scene 1</span></div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>Apple</span></a>
    </li>
    <li>
      <a idx="2" href="#" class="choice" draggable="false"><span>Banana</span></a>
    </li>
    <li>
      <a idx="3" href="#" class="choice" draggable="false"><span>Carrot</span></a>
    </li>
  </ul>

  $ run ../programs/error-non-string-meta.md
  <div class="para">
    <span><span>1</span></span>
  </div>

  $ run ../programs/interpolation.md a c
  <div class="para old"><span>Turns:</span><span> </span><span>0</span></div>
  <div class="para old"><span>Turns:</span><span> </span><span>1</span></div>
  <div class="para"><span>Turns:</span><span> </span><span>2</span></div>

  $ run ../programs/choices-continue.md 'continue'
  <div class="para"><span>here</span></div>

  $ run ../programs/choices-text.md x
  <div class="para"><span>should show.</span></div>
  <div class="para"><span>2</span></div>

  $ run ../programs/choices-nested.md 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div class="para old"><span>Right before going back to Nested</span></div>
  <div class="para old"><span>after</span><span> </span><span>break</span></div>
  <div class="para old"><span>Right before going back to Nested</span></div>
  <div class="para old"><span>A paragraph</span></div>
  <div class="para old"><span>Right before going back to Nested</span></div>
  <div class="para"><span>Right before going back to Nested</span></div>

  $ run ../programs/jump-dynamic.md
  <div class="para"><span>Apple</span></div>

  $ run ../programs/choices-more.md
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>Hi</span></a>
    </li>
    <li>
      <a idx="2" href="#" class="choice" draggable="false"><span>a</span></a>
    </li>
    <li>
      <a idx="3" href="#" class="choice" draggable="false"><span>b</span></a>
    </li>
  </ul>

  $ run ../programs/choices-copy.md
  <div class="para"><span>text from Scene 1</span></div>

  $ run ../programs/tunnels.md
  <div class="para"><span>1</span></div>
  <div class="para"><span>2</span></div>

  $ run ../programs/tunnels-followed-by-jumps.md
  <div class="para"><span>before</span></div>
  <div class="para"><span>a</span></div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>b</span></a>
    </li>
  </ul>

  $ run ../programs/spaces.md 'choice text'
  <div class="para"><span>code after</span></div>
  <div class="para">
    <span>“Hi,</span><span> </span><span>A</span><span>,” he said.</span>
  </div>
  <div class="para">
    <span>“</span><span> </span><span>Edge case</span><span> </span
    ><span>“ here</span>
  </div>
  <div class="para"><span>A</span><span> </span><span>’s thing</span></div>

  $ run ../programs/inline-and-block-meta.md
  <div class="para"><span>interpolation</span><span> </span><span>1</span></div>
  <div class="para">
    <span>inline meta</span><span> </span><span><span>1</span></span>
  </div>
  <div class="para"><span>block meta</span></div>

  $ run ../programs/inline-meta-jump.md
  <div class="para">
    <span>hi</span><span> </span><span><span>there</span></span>
  </div>
  <div class="para"><span>b</span></div>

  $ run ../programs/block-meta-jump.md
  <div class="para"><span>1</span></div>
  <div class="para"><span>2</span></div>
  <div class="para"><span>3</span></div>

  $ run ../programs/choices-break-delimiters.md
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c1</span></a>
    </li>
  </ul>

  $ run ../programs/choices-break-delimiters.md c1
  <div class="para"><span>selected</span></div>

This has to be checked dynamically because jumps may be produced by meta blocks. Currently we only check it dynamically.

  $ run ../programs/error-nonexistent-section.md Hello
  <div class="para error" style="color: red">Jump: scene a not found</div>

  $ run ../programs/choices-consumable.md c1
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c2</span></a>
    </li>
  </ul>

  $ run ../programs/choices-sticky.md c1
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c1</span></a>
    </li>
    <li>
      <a idx="2" href="#" class="choice" draggable="false"><span>c2</span></a>
    </li>
  </ul>

  $ run ../programs/choices-otherwise.md
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>a</span></a>
    </li>
  </ul>

  $ run ../programs/choices-otherwise.md a
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>b</span></a>
    </li>
  </ul>

  $ run ../programs/choices-fallthrough.md 'a'
  <div class="para"><span>here</span></div>

  $ run ../programs/choices-exhausted.md a b

  $ run ../programs/api-local-state.md b a b a b
  <div class="para old"><span>ha’s state:</span><span> </span><span>0</span></div>
  <div class="para old"><span>hb’s state:</span><span> </span><span>0</span></div>
  <div class="para old"><span>ha’s state:</span><span> </span><span>1</span></div>
  <div class="para old"><span>hb’s state:</span><span> </span><span>1</span></div>
  <div class="para old"><span>ha’s state:</span><span> </span><span>2</span></div>
  <div class="para"><span>hb’s state:</span><span> </span><span>2</span></div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>a</span></a>
    </li>
  </ul>

  $ run ../programs/api-seen.md
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>a</span></a>
    </li>
  </ul>

  $ run ../programs/api-seen.md a
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>b</span></a>
    </li>
  </ul>

  $ run ../programs/jump-to-current-section.md a
  <div class="para old"><span>hello</span></div>
  <div class="para"><span>hello</span></div>

more cannot reference other sections when used in a meta block, so essentially only static use is supported.

  $ run ../programs/dynamic-more.md
  <div class="para error" style="color: red">
    MetaBlock: error when executing '- `more x`': Error: parse: nonexistent
    section x used in more
  </div>

Sections created in meta blocks do not make it out.

  $ run ../programs/dynamic-section.md
  <div class="para"><span>hello</span></div>
  <div class="para error" style="color: red">Jump: scene a not found</div>
  <div class="para error" style="color: red">
    MetaBlock: error when executing `# a hello`: Error: Jump: scene a not found
  </div>
