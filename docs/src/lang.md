# Writing Scripture

## Concepts

A Scripture story consists of named _sections_, which contain prose interleaved with code.
There is always a _current section_ which the player is reading.

Sections are _shown_ until they end or up until player input is needed (e.g. with choices).

When there is player input (e.g. clicking to make choice), the section _continues_, which will show more prose or execute more code.

The internal state of the game is completely user-defined, and is modified by code execution in a user-defined way.

_Jumps_ connect sections.
Think of jumps essentially as a kind of code, so they may occur anywhere code can:
as part of the flow of a section (in which case the section seamlessly ends and another begins), or in response to player input.

<!-- TODO example -->

## Basics

Scripture is a Markdown dialect.

Like with other narrative scripting languages, unadorned text is prose to be shown to the player.
Narrative-related constructs are represented using Markdown elements.

### Sections

Sections are named using H1s and ended by thematic breaks.

### Inline code

Inline code `` `CODE` `` is run when shown. Its output is hidden.

With a `$` prefix `` `$CODE` ``, the output is _interpolated_ as _text_ into the story at that point.

With a `~` prefix  `` `~CODE` ``, the output is interpolated as _Scripture_ into the story at that point.
This allows _unquoting_: generating some fragment of story dynamically using JavaScript.

A `jump` prefix `` `jump SECTION` `` denotes a jump to SECTION.

### Code blocks

Code block output is not shown, like inline code without a prefix.

<pre><code>```js
CODE
```</code></pre>

Adding the `meta` or `~` info-string after the language type unquotes the code block, like inline code with the `~` prefix.

<pre><code>```js meta
CODE
```</code></pre>

### Choices

Lists denote choices. Each list item is of the format ``TEXT `CODE`  MORE``.

- TEXT is the text of the choice.
- CODE is some fragment of code that will be run on the choice being selected. Its result will not be shown.
- MORE is some unrestricted Scripture fragment that will be shown/run.

Once a choice is selected, the other options will be disabled.
The story continues after a choice, like [weave](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#the-weave-philosophy) in Ink terms. This is the default, unlike in Ink.

### Links

Links allow user input outside the usual flow of choices.

A `[TEXT](#SECTION)` link jumps to SECTION.

A `[TEXT](!FN)` link causes the function FN to be run.

### Runtime

There is a lot of freedom in how the runtime can behave, but it should minimally implement the following:

- the `on_interact` function is called whenever a user interaction takes place

## Semantics

A Scripture story is essentially a procedural program.

A section is essentially a labelled block of JavaScript, where unadorned text can be thought of as print statements (though with provisions for differentiating block and inline elements), and quoted JavaScript is inlined (between statements, for normal code blocks, or into print statements, for interpolation).

Jumps are GOTOs and connect sections, ending control flow when they occur.
