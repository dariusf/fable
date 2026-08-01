
  $ . ../testing.sh

  $ node machine_test.js ../programs/unicode.md
  {"type":"para","content":[{"type":"text","text":"“hello — don’t worry, we’ll be open 9–10…”"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/smartypants.md
  {"type":"para","content":[{"type":"text","text":"\"hello --- don't worry, we'll be open 9--10...\""}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/empty-section.md
  --- status: done, turns: 0

  $ node machine_test.js ../programs/breaks.md
  {"type":"para","content":[{"type":"text","text":"a"},{"type":"verbatim","html":"<br>"},{"type":"space"},{"type":"text","text":"b"},{"type":"verbatim","html":"<br/>"},{"type":"space"},{"type":"text","text":"c"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/paragraph-break.md c
  {"type":"para","content":[{"type":"text","text":"a"}]}
  {"type":"para","content":[{"type":"text","text":"b"}]}
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"c"}]}]}
  --- choose: c
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"haha"}]}
  {"type":"para","content":[{"type":"text","text":"b"},{"type":"space"},{"type":"text","text":"this should not be expanded"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/emphasis.md
  {"type":"para","content":[{"type":"emph","content":[{"type":"text","text":"text"}]},{"type":"space"},{"type":"text","text":"from"},{"type":"space"},{"type":"emph","content":[{"type":"text","text":"Scene"}]},{"type":"space"},{"type":"text","text":"1"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/comments.md
  {"type":"para","content":[{"type":"text","text":"inline comments"},{"type":"space"},{"type":"verbatim","html":"<i>don't</i>"},{"type":"space"},{"type":"text","text":"appear"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/jump-links.md jump
  {"type":"para","content":[{"type":"link","linkId":0,"label":"jump"}]}
  --- activate: jump
  {"type":"para","content":[{"type":"text","text":"asd"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/code-links.md code
  {"type":"para","content":[{"type":"link","linkId":0,"label":"code"}]}
  --- activate: code
  hi
  --- status: done, turns: 1

  $ node machine_test.js ../programs/frontmatter.md
  {"type":"para","content":[{"type":"text","text":"hello"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/choices-precondition-seen.md a
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]},{"choiceId":1,"content":[{"type":"text","text":"b"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"choices","nodeId":4,"items":[{"choiceId":3,"content":[{"type":"text","text":"b"}]}]}
  --- status: awaiting, turns: 1

  $ node machine_test.js ../programs/choices-loose.md First
  {"type":"para","content":[{"type":"text","text":"Before"}]}
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"First"}]},{"choiceId":1,"content":[{"type":"text","text":"Second"}]}]}
  --- choose: First
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"para","content":[{"type":"text","text":"Body"}]}
  {"type":"para","content":[{"type":"text","text":"After"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/choices-tweet-style.md a
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]},{"choiceId":1,"content":[{"type":"text","text":"c"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"para","content":[{"type":"text","text":"this is later cleared"}]}
  {"type":"choices","nodeId":4,"items":[{"choiceId":3,"content":[{"type":"text","text":"c"}]}]}
  --- status: awaiting, turns: 1

  $ node machine_test.js ../programs/choices-tweet-style.md a c
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]},{"choiceId":1,"content":[{"type":"text","text":"c"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"para","content":[{"type":"text","text":"this is later cleared"}]}
  {"type":"choices","nodeId":4,"items":[{"choiceId":3,"content":[{"type":"text","text":"c"}]}]}
  --- choose: c
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":4}
  {"type":"para","content":[{"type":"text","text":"after"}]}
  --- status: done, turns: 2

  $ node machine_test.js ../programs/meta.md
  {"type":"para","content":[{"type":"text","text":"text from Scene 1"}]}
  {"type":"choices","nodeId":3,"items":[{"choiceId":0,"content":[{"type":"text","text":"Apple"}]},{"choiceId":1,"content":[{"type":"text","text":"Banana"}]},{"choiceId":2,"content":[{"type":"text","text":"Carrot"}]}]}
  --- status: awaiting, turns: 0

  $ node machine_test.js ../programs/error-non-string-meta.md
  {"type":"para","content":[{"type":"text","text":"1"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/interpolation.md a c
  {"type":"para","content":[{"type":"text","text":"Turns:"},{"type":"space"},{"type":"text","text":"0"}]}
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"Turns:"},{"type":"space"},{"type":"text","text":"1"}]}
  {"type":"choices","nodeId":3,"items":[{"choiceId":2,"content":[{"type":"text","text":"c"}]}]}
  --- choose: c
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":3}
  {"type":"para","content":[{"type":"text","text":"Turns:"},{"type":"space"},{"type":"text","text":"2"}]}
  --- status: done, turns: 2

  $ node machine_test.js ../programs/choices-continue.md 'continue'
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"continue"}]},{"choiceId":1,"content":[{"type":"text","text":"x"}]}]}
  --- choose: continue
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"para","content":[{"type":"text","text":"here"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/choices-text.md x
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"x"}]},{"choiceId":1,"content":[{"type":"text","text":"y"}]}]}
  --- choose: x
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"para","content":[{"type":"text","text":"should show."}]}
  {"type":"para","content":[{"type":"text","text":"2"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/choices-nested.md 'Choice 1' 'Nested choice. Did you choose choice 1?' 'Choice 2' 'Choice 3' 'Choice 4'
  {"type":"choices","nodeId":4,"items":[{"choiceId":0,"content":[{"type":"text","text":"Choice 1"}]},{"choiceId":1,"content":[{"type":"text","text":"Choice 2"}]},{"choiceId":2,"content":[{"type":"text","text":"Choice 3"}]},{"choiceId":3,"content":[{"type":"text","text":"Choice 4"}]}]}
  --- choose: Choice 1
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":4}
  {"type":"choices","nodeId":7,"items":[{"choiceId":5,"content":[{"type":"text","text":"Nested choice. Did you choose choice 1?"}]},{"choiceId":6,"content":[{"type":"text","text":"Or not?"}]}]}
  --- choose: Nested choice. Did you choose choice 1?
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":7}
  {"type":"para","content":[{"type":"text","text":"Right before going back to Nested"}]}
  {"type":"choices","nodeId":11,"items":[{"choiceId":8,"content":[{"type":"text","text":"Choice 2"}]},{"choiceId":9,"content":[{"type":"text","text":"Choice 3"}]},{"choiceId":10,"content":[{"type":"text","text":"Choice 4"}]}]}
  --- choose: Choice 2
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":11}
  {"type":"para","content":[{"type":"text","text":"after"},{"type":"space"},{"type":"text","text":"break"}]}
  {"type":"para","content":[{"type":"text","text":"Right before going back to Nested"}]}
  {"type":"choices","nodeId":14,"items":[{"choiceId":12,"content":[{"type":"text","text":"Choice 3"}]},{"choiceId":13,"content":[{"type":"text","text":"Choice 4"}]}]}
  --- choose: Choice 3
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":14}
  {"type":"para","content":[{"type":"text","text":"A paragraph"}]}
  {"type":"para","content":[{"type":"text","text":"Right before going back to Nested"}]}
  {"type":"choices","nodeId":16,"items":[{"choiceId":15,"content":[{"type":"text","text":"Choice 4"}]}]}
  --- choose: Choice 4
  you chose choice 4
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":16}
  {"type":"para","content":[{"type":"text","text":"Right before going back to Nested"}]}
  --- status: done, turns: 5

  $ node machine_test.js ../programs/jump-dynamic.md
  {"type":"para","content":[{"type":"text","text":"Apple"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/choices-more.md
  {"type":"choices","nodeId":3,"items":[{"choiceId":0,"content":[{"type":"text","text":"Hi"}]},{"choiceId":1,"content":[{"type":"text","text":"a"}]},{"choiceId":2,"content":[{"type":"text","text":"b"}]}]}
  --- status: awaiting, turns: 0

  $ node machine_test.js ../programs/choices-copy.md
  {"type":"para","content":[{"type":"text","text":"text from Scene 1"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/choices-copy-scenes.md
  {"type":"para","content":[{"type":"text","text":"text from Scene 1"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/meta-undefined.md
  {"type":"para","content":[{"type":"text","text":"a"},{"type":"space"},{"type":"text","text":"b"},{"type":"space"},{"type":"text","text":"c"}]}
  {"type":"para","content":[{"type":"text","text":"after"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/tunnels.md
  {"type":"para","content":[{"type":"text","text":"1"}]}
  {"type":"para","content":[{"type":"text","text":"2"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/tunnels-followed-by-jumps.md
  {"type":"para","content":[{"type":"text","text":"before"}]}
  {"type":"para","content":[{"type":"text","text":"a"}]}
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"b"}]}]}
  --- status: awaiting, turns: 0

  $ node machine_test.js ../programs/spaces.md 'choice text'
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"choice text"}]}]}
  --- choose: choice text
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"code after"}]}
  {"type":"para","content":[{"type":"text","text":"\"Hi,"},{"type":"space"},{"type":"text","text":"A"},{"type":"text","text":",\" he said."}]}
  {"type":"para","content":[{"type":"text","text":"\""},{"type":"text","text":"Edge case"},{"type":"text","text":"\" here"}]}
  {"type":"para","content":[{"type":"text","text":"A"},{"type":"text","text":"'s thing"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/inline-and-block-meta.md
  {"type":"para","content":[{"type":"text","text":"interpolation"},{"type":"space"},{"type":"text","text":"1"}]}
  {"type":"para","content":[{"type":"text","text":"inline meta"},{"type":"space"},{"type":"text","text":"1"}]}
  {"type":"para","content":[{"type":"text","text":"block meta"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/inline-meta-jump.md
  {"type":"para","content":[{"type":"text","text":"hi"},{"type":"space"},{"type":"text","text":"there"}]}
  {"type":"para","content":[{"type":"text","text":"b"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/block-meta-jump.md
  {"type":"para","content":[{"type":"text","text":"1"}]}
  {"type":"para","content":[{"type":"text","text":"2"}]}
  {"type":"para","content":[{"type":"text","text":"3"}]}
  --- status: done, turns: 0

  $ node machine_test.js ../programs/choices-break-delimiters.md
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"c1"}]}]}
  --- status: awaiting, turns: 0

  $ node machine_test.js ../programs/choices-break-delimiters.md c1
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"c1"}]}]}
  --- choose: c1
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"selected"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/error-nonexistent-section.md Hello
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"Hello"}]}]}
  --- choose: Hello
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"error","message":"Jump: section a not found"}
  --- status: stuck, turns: 1

  $ node machine_test.js ../programs/choices-consumable.md c1
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"c1"}]},{"choiceId":1,"content":[{"type":"text","text":"c2"}]}]}
  --- choose: c1
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"choices","nodeId":4,"items":[{"choiceId":3,"content":[{"type":"text","text":"c2"}]}]}
  --- status: awaiting, turns: 1

  $ node machine_test.js ../programs/choices-sticky.md c1
  {"type":"choices","nodeId":2,"items":[{"choiceId":0,"content":[{"type":"text","text":"c1"}]},{"choiceId":1,"content":[{"type":"text","text":"c2"}]}]}
  --- choose: c1
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":2}
  {"type":"choices","nodeId":5,"items":[{"choiceId":3,"content":[{"type":"text","text":"c1"}]},{"choiceId":4,"content":[{"type":"text","text":"c2"}]}]}
  --- status: awaiting, turns: 1

  $ node machine_test.js ../programs/choices-otherwise.md
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- status: awaiting, turns: 0

  $ node machine_test.js ../programs/choices-otherwise.md a
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"choices","nodeId":3,"items":[{"choiceId":2,"content":[{"type":"text","text":"b"}]}]}
  --- status: awaiting, turns: 1

  $ node machine_test.js ../programs/choices-fallthrough.md 'a'
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"here"}]}
  --- status: done, turns: 1

  $ node machine_test.js ../programs/choices-exhausted.md a b
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"choices","nodeId":3,"items":[{"choiceId":2,"content":[{"type":"text","text":"b"}]}]}
  --- choose: b
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":3}
  --- status: done, turns: 2

  $ node machine_test.js ../programs/api-local-state.md b a b a b
  {"type":"para","content":[{"type":"text","text":"ha's state:"},{"type":"space"},{"type":"text","text":"0"}]}
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"b"}]}]}
  --- choose: b
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"hb's state:"},{"type":"space"},{"type":"text","text":"0"}]}
  {"type":"choices","nodeId":3,"items":[{"choiceId":2,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":3}
  {"type":"para","content":[{"type":"text","text":"ha's state:"},{"type":"space"},{"type":"text","text":"1"}]}
  {"type":"choices","nodeId":5,"items":[{"choiceId":4,"content":[{"type":"text","text":"b"}]}]}
  --- choose: b
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":5}
  {"type":"para","content":[{"type":"text","text":"hb's state:"},{"type":"space"},{"type":"text","text":"1"}]}
  {"type":"choices","nodeId":7,"items":[{"choiceId":6,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":7}
  {"type":"para","content":[{"type":"text","text":"ha's state:"},{"type":"space"},{"type":"text","text":"2"}]}
  {"type":"choices","nodeId":9,"items":[{"choiceId":8,"content":[{"type":"text","text":"b"}]}]}
  --- choose: b
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":9}
  {"type":"para","content":[{"type":"text","text":"hb's state:"},{"type":"space"},{"type":"text","text":"2"}]}
  {"type":"choices","nodeId":11,"items":[{"choiceId":10,"content":[{"type":"text","text":"a"}]}]}
  --- status: awaiting, turns: 5

  $ node machine_test.js ../programs/api-seen.md
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- status: awaiting, turns: 0

  $ node machine_test.js ../programs/api-seen.md a
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"choices","nodeId":3,"items":[{"choiceId":2,"content":[{"type":"text","text":"b"}]}]}
  --- status: awaiting, turns: 1

  $ node machine_test.js ../programs/jump-to-current-section.md a
  {"type":"para","content":[{"type":"text","text":"hello"}]}
  {"type":"choices","nodeId":1,"items":[{"choiceId":0,"content":[{"type":"text","text":"a"}]}]}
  --- choose: a
  {"type":"markOld"}
  {"type":"removeChoices","nodeId":1}
  {"type":"para","content":[{"type":"text","text":"hello"}]}
  --- status: done, turns: 1

It is no longer possible to use Meta-more to refer to an existing section.

  $ node machine_test.js ../programs/error-dynamic-more.md
  {"type":"error","message":"MetaBlock: error when executing '- `more x`': nonexistent section x used in more"}
  --- status: stuck, turns: 0

It is no longer possible to define a section using Meta.

  $ node machine_test.js ../programs/error-dynamic-section.md
  {"type":"para","content":[{"type":"text","text":"hello"}]}
  {"type":"error","message":"Jump: section a not found"}
  --- status: stuck, turns: 0
