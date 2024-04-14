# Writing Scripture

## Concepts

### Sections

A Scripture story consists of named _sections_, which contain prose interleaved with _instructions_.

Sections are shown until they end or up until player input is required (e.g. choices), which may either continue the section or move to another. A section may thus never be shown in its entirety.

### Control

_Jumps_ connect sections.
They may occur anywhere in prose:
as part of the flow of a section (in which case the section seamlessly ends and another begins), or in response to player input (via choices).

<!-- TODO examples -->

### State

The internal state of the game can be completely user-defined, and is modified by code execution in a user-defined way. Some state is maintained by the runtime.

### Syntax

Scripture is a Markdown dialect.

Like with other narrative scripting languages, unadorned text is prose to be shown to the player.
Narrative-related constructs are represented using Markdown elements.

## Elements

### Sections

Sections are named using headings.

### Inline code

Inline code `` `CODE` `` is run when shown. Its output is hidden.

With a `$` prefix (`` `$CODE` ``), the output is _interpolated_ as _text_ into the story at that point.

With a `~` prefix  (`` `~CODE` ``), the output is interpolated as _Scripture_ into the story at that point.
This allows _unquoting_: generating some fragment of story dynamically using JavaScript.

A `jump` or `->` prefix (`` `jump SECTION` `` or `` `-> SECTION` ``) denotes a _jump_ to SECTION.

A _dynamic jump_ `->$` prefix (`` `->$ E` ``) jumps to the name of the section that E evaluates to.

A `tunnel` or `>->` prefix (`` `tunnel SECTION` `` or `` `>-> SECTION` ``) denotes a _tunnel_ to SECTION, which returns to the origin of the jump after the jumped-to section completes.

### Code blocks

A plain code block (with optional language declaration) is just like inline code without a prefix: its output is not shown.

<pre><code>```js
CODE
```</code></pre>

Adding the `meta` or `~` info-string after the language type unquotes the code block, like inline code with the `~` prefix.

<pre><code>```js meta
CODE
```</code></pre>

### Choices

Lists denote choices. Each list item is of the format ``TEXT `CODE`  BODY``.

- TEXT is the text of the choice.
- CODE is some fragment of code that will be run on the choice being selected. Its result will not be shown.
- BODY is some unrestricted Scripture fragment that will be shown.

guard ?
more
sticky
fallback
guarded mores

Once a choice is selected, the other options will be disabled.
The story continues after a choice, like [weave](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#the-weave-philosophy) in Ink terms. This is the default, unlike in Ink.

### Links

Links allow user input outside the usual flow of choices.

A `[TEXT](#SECTION)` link jumps to SECTION.

A `[TEXT](!FN)` link causes the function FN to be run.

## Semantics

A Scripture story can be given a (denotational) semantics by (rough) analogy to procedural programs.

| Scripture           | Program          |
| ------------------- | ---------------- |
| section             | labelled block   |
| prose               | print statements |
| inline code, blocks | statements       |
| meta                | unquote          |
| jump                | goto             |
| tunnel              | procedure call   |
| choices             | conditional      |

The abstraction provided by a Scripture story is intentionally very leaky.
This has several benefits.
The story can be reasoned about like a program.
It's clear when a particular bit of prose "executes", allowing things like widgets appearing in the flow of a story using raw HTML.
The browser console is fully available, and the state of the story can be queried at any point without doing anything special.
Necessary data structures and libraries and language features can simply be used.

# TODO

nested lists

finish ink feature by feature comparison

Built-in seen and turns

content before first heading

guard
interpolated choices + guards
meta can jump, run cannot

browser tests
save and load
standalone
space behavior

readme
