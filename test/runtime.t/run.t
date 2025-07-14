
  $ . ../testing.sh

  $ run ../programs/comments.md
  <div class="para fadein">
    <span>inline comments</span><span> </span><span><i>don't</i></span
    ><span> </span><span>appear</span>
  </div>

  $ run ../programs/jump-links.md jump
  <div class="para fadein"><a href="#">jump</a></div>
  <div class="para fadein"><span>asd</span></div>

  $ run ../programs/code-links.md code
  <div class="para fadein"><a href="#">code</a></div>
  <div class="para fadein"><span>Hi!</span></div>

  $ run ../programs/frontmatter.md
  <div class="para fadein"><span>hello</span></div>

  $ run ../programs/tweet-style-choices.md a
  <div class="para fadein"><span>this is later cleared</span></div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c</span></a>
    </li>
  </ul>

  $ run ../programs/tweet-style-choices.md a c
  <div class="para fadein"><span>after</span></div>

  $ run ../programs/meta.md
  <div class="para fadein"><span>text from Scene 1</span></div>
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

  $ run ../programs/interpolation.md a c
  <div class="para fadein old">
    <span>Turns:</span><span> </span><span>0</span>
  </div>
  <div class="para fadein old">
    <span>Turns:</span><span> </span><span>1</span>
  </div>
  <div class="para fadein"><span>Turns:</span><span> </span><span>2</span></div>
  <ul class="choice fadein"></ul>

  $ run ../programs/choices-continue.md 'continue'
  <div class="para fadein"><span>here</span></div>

  $ run ../programs/choices-text.md x
  <div class="para fadein"><span>should show.</span></div>
  <div class="para fadein"><span>2</span></div>

  $ run ../programs/choices-nested.md 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  <div class="para fadein old">
    <span>Right before going back to Nested</span>
  </div>
  <div class="para fadein old">
    <span>after</span><span> </span><span>break</span>
  </div>
  <div class="para fadein old">
    <span>Right before going back to Nested</span>
  </div>
  <div class="para fadein old"><span>A paragraph</span></div>
  <div class="para fadein old">
    <span>Right before going back to Nested</span>
  </div>
  <div class="para fadein"><span>Right before going back to Nested</span></div>
  <ul class="choice fadein"></ul>

  $ run ../programs/jump-dynamic.md
  <div class="para fadein"><span>Apple</span></div>

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
  <div class="para fadein"><span>text from Scene 1</span></div>

  $ run ../programs/tunnels.md
  <div class="para fadein"><span>1</span></div>
  <div class="para fadein"><span>2</span></div>

  $ run ../programs/tunnels-followed-by-jumps.md
  <div class="para fadein"><span>before</span></div>
  <div class="para fadein"><span>a</span></div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>b</span></a>
    </li>
  </ul>

  $ run ../programs/spaces.md 'choice text'
  <div class="para fadein"><span>code after</span></div>
  <div class="para fadein">
    <span>"Hi,</span><span> </span><span>A</span><span>," he said.</span>
  </div>
  <div class="para fadein">
    <span>"</span><span>Edge case</span><span>" here</span>
  </div>
  <div class="para fadein"><span>A</span><span>'s thing</span></div>

  $ run ../programs/inline-and-block-meta.md
  <div class="para fadein">
    <span>interpolation</span><span> </span><span>1</span>
  </div>
  <div class="para fadein">
    <span>inline meta</span><span> </span><span><span>1</span></span>
  </div>
  <div class="para fadein"><span>block meta</span></div>

  $ run ../programs/inline-meta-jump.md
  <div class="para fadein">
    <span>hi</span><span> </span><span><span>there</span></span>
  </div>
  <div class="para fadein"><span>b</span></div>

  $ run ../programs/block-meta-jump.md
  <div class="para fadein"><span>1</span></div>
  <div class="para fadein"><span>2</span></div>
  <div class="para fadein"><span>3</span></div>

  $ run ../programs/choice-break-delimiters.md
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c1</span></a>
    </li>
  </ul>

  $ run ../programs/choice-break-delimiters.md c1
  <div class="para fadein"><span>selected</span></div>

  $ run ../programs/nonexistent-section.md Hello
  <div class="para fadein error" style="color: red">Jump a scene not found</div>

  $ run ../programs/consumable-choices.md c1
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>c2</span></a>
    </li>
  </ul>

  $ run ../programs/sticky-choices.md c1
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

  $ run ../programs/local-state.md b a b a b
  <div class="para fadein old">
    <span>ha's state:</span><span> </span><span>0</span>
  </div>
  <div class="para fadein old">
    <span>hb's state:</span><span> </span><span>0</span>
  </div>
  <div class="para fadein old">
    <span>ha's state:</span><span> </span><span>1</span>
  </div>
  <div class="para fadein old">
    <span>hb's state:</span><span> </span><span>1</span>
  </div>
  <div class="para fadein old">
    <span>ha's state:</span><span> </span><span>2</span>
  </div>
  <div class="para fadein">
    <span>hb's state:</span><span> </span><span>2</span>
  </div>
  <ul class="choice fadein">
    <li>
      <a idx="1" href="#" class="choice" draggable="false"><span>a</span></a>
    </li>
  </ul>
