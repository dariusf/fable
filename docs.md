
# Writing Fable

## Elements

### Prose

Fable is a Markdown dialect.

Like with other narrative scripting languages, unadorned text is prose to be shown to the player.
Narrative-related constructs are represented using Markdown elements.

### Sections

Sections are named using headings.

Content before first heading goes into an implicit heading named `default`.  The story starts there or at the first heading.

A section is just a named sequence of instructions and does not have to execute to completion, though it will if no control flow changes occur before it ends.

A Fable story consists of named _sections_, which contain prose interleaved with _instructions_.

Sections are shown until they end or up until player input is required (e.g. choices), which may either continue the section or move to another. A section may thus never be shown in its entirety.

### Inline code

The internal state of the game can be completely user-defined, and is modified by code execution in a user-defined way. Some state is maintained by the runtime.

Inline code `` `CODE` `` is run when shown[^2]. Its output is hidden.

A _prefix_ can be used to access variations of this.

With a `$` prefix (e.g. `` `$CODE` ``), the output is _interpolated_ as _text_ into the story at that point[^2].

With a `~` prefix, the output is interpolated as _Fable_ into the story at that point.
This allows _unquoting_: generating some fragment of story dynamically using JavaScript.

_Jumps_ connect sections.
They may occur anywhere in prose:
as part of the flow of a section (in which case the section seamlessly ends and another begins), or in response to player input (via choices).

A `jump` or `->` prefix denotes a _jump_ to a named section.

A _dynamic jump_ `->$` prefix jumps to the name of the section that content evaluates to.

A `tunnel` or `>->` prefix denotes a _tunnel_ to a named section, which returns to the origin of the jump after the jumped-to section completes.

### Code blocks

A plain code block (with optional language declaration) is just like inline code without a prefix: its output is not shown.

<pre><code>```js
CODE
```</code></pre>

Adding the `meta` or `~` info-string after the language type unquotes the code block, like inline code with the `~` prefix.

<pre><code>```js ~
CODE
```</code></pre>

### Choices

Lists denote choices. Each choice item is of the form ``TEXT `CODE`  BODY``.

- TEXT will be shown to the player, for them to choose.
- CODE is some fragment of code that will be run when the choice is selected. Its result is not shown.
- BODY is some unrestricted Fable fragment that will be shown. Indenting the body with 4 spaces Markdown-style allows it to contain other elements, allowing nested choices.

The story continues after a choice, like [weave](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#the-weave-philosophy) in Ink terms. This is the default, unlike in Ink.

A choice may have a _precondition_ `` `guard CODE` `` or `` `?CODE` ``. It will only be shown if CODE evaluates to a truthy value.

By default, each item in the choice can only be selected once: after selecting an item, if control later returns to the section the choice was in, the item cannot be selected again.
This can be overriden by including `` `sticky` `` somewhere in the body, making the choice _persistent_.
Whether a choice is persistent is orthogonal to whether it has a precondition.

<!-- interpolated/inlined choices -->

A choice may have items consisting only of `` `more SECTION` ``, where SECTION is expected to have a single choice in it; the options of that choice will then be inlined transparently into the current choice.
This may happen recursively.
Such items may have preconditions, in which case they apply to every item inlined.

TODO fallback

### Breaks and spaces

Linebreaks are turned into spaces.

Spaces between prose and other instructions are stripped, so they have to be readded if interpolation is used.

### Links

Links allow user input outside the usual flow of choices.

A `[TEXT](#SECTION)` link jumps to SECTION.

A `[TEXT](!FN)` link causes the function FN to be run.

## Semantics

A Fable story can be given a (denotational) semantics by (rough) analogy to procedural programs.

| Fable               | Program          |
| ------------------- | ---------------- |
| section             | labelled block   |
| prose               | print statements |
| inline code, blocks | statements       |
| meta                | unquote          |
| jump                | goto             |
| tunnel              | procedure call   |
| choices             | conditional      |

The abstraction provided by Fable is intentionally very leaky.
This has several benefits.
The story can be reasoned about and tested like a program.
It's clear when a particular bit of prose "executes", allowing things like raw HTML widgets appearing in the flow of a story.
The browser console is fully available, and the state of the story can be queried at any point without doing anything special.
Necessary data structures and libraries and language features can be used without any fanfare.

# The runtime

The runtime system contains code for supporting the execution of Fable stories.
User APIs are at the top of the file.
These include things like turn and seen counters, callbacks, and other utilities for automated testing and saving and loading stories, which can be used directly via the console.

# The CLI tools

Export a standalone story

```sh
dune exec ./main.exe --display=short -- -s test/examples.t/crime.md -o detective
open detective/index.html
```

# Development

## Implementation

Fable Markdown is compiled into a set of named sequences of instructions. Instructions may contain others nested in them.

The runtime is a CPS interpreter. Its state is a list of instructions (to be executed), a current element to mutate (e.g. with new prose), and a continuation. The last one is how the control primitives like jumps and choices are implemented.

To execute efficiently, the interpreter executes instructions in a loop until it reaches one that may change control. The remaining instructions are acted on via a continuation.

## Tasks

Build a simple story (see Makefile for which) and run fast tests, which is useful for development

```sh
make
```

Run all tests

```sh
make all
```

Random testing of the story built via `make` randomly

```sh
make test
```

Check test/runtime.t/test.js to see how the last two work.

Deploy (`--release` ensures that the runtime, which is embedded in main, is small)

```sh
dune build --release ./main.exe --display=short
```

# Comparison to [Ink](https://github.com/inkle/ink)

<!-- Just a very short intro. -->

Fable generalizes and extends Ink. Embeds everything in markdown. Allows use of js. This allows for a much smaller implementation[^1] and proper data structures, a sane programming language. Conceptual model is very similar. First class and transparent interop with browsers. Automated testing built in.



The goal is to clean up onk concetually, extend its capabilities. The target kind of game is one with a primarily text based ui with some kind of. The story is the game, rather than driving a larger engine. The latter is more general but for people without the time or resources to maintain

The tradeoff is that it is less appropriate for use in a game engine. It can be made to work by reimplementing the runtime and using an alternative scripting language. This is a non-goal.

Evaluate and compile code at runtime so probably not usable in a game engine


Ink is designed for writing interactive fiction scripts which are embedded into a larger game engine and drive its UI.
Fable is designed for deep interactive stories with a primarily text-based UI.
There is some overlap between these goals, but they favour different design tradeoffs.

- Ink contains an [ad hoc programming language](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#part-5-advanced-state-tracking). This is generally fine as it is meant to FFI into the host game engine, where a more complete world model might be found. Fable has access to full JavaScript and expects that the modeling of the game world is done alongside the story.
- Fable's language is much simpler. It is a Markdown dialect (benefitting from all the [effort](https://spec.commonmark.org/current/) that has been put into writing intuitive yet extremely expressive markup) and supports scripting using quoted JavaScript. Effort was put into boiling down language features into a small number of fundamental concepts.
- Fable's compiler and runtime are much smaller (< 800 LoC of OCaml and JS, with the heavy lifting being done by [Cmarkit](https://erratique.ch/software/cmarkit)). [Ink's compiler](https://github.com/inkle/ink) is 17K LoC of C#, and [InkJS](https://github.com/y-lohse/inkjs) is 18K LoC of TypeScript.
- Ink is mature, has [a significant ecosystem](https://github.com/inkle/ink-library), and is appropriate for production games. Fable is appropriate for small games, experiments, and prototypes.

## Feature-by-feature comparison

| Fable         | Ink              |
| ------------- | ---------------- |
| section       | knot             |
| -             | stitch           |
| -             | labels           |
| jump          | divert           |
| tunnel        | tunnel           |
| -             | tags             |
| -             | glue             |
| - (default)   | weave/gather     |
| - (implicit)  | END              |
| interpolation | conditional text |
| script tags   | include          |
| seen TODO     | read counts      |
| TODO          | tunnels          |

Many features are subsumed by simply using JS.

- alternatives, cycles, shuffles
- functions, conditionals, constants
- builtins like SINCE

### Things removed or not (yet) needed

- Glue
- Weave/gather (default)
- Tags
- END (implicit)

### Sections

Ink knots correspond to Fable sections.
There is no scoping.
Stitches are simply.

### Choices

Largely similar, but simplified.

- Fable choices cannot be labelled and jumped to, and do not support mixing choice and output text. Both of these may be added in future, but they do not seem worth the extra implementation complexity. Also, labelling choice items and jumping into them seems odd, as only the body of the item is being used, not the choice-making aspect; factoring it out into a new section seems more appropriate.
- Fable choices are weaved by default. If Ink choices are thought of as auxiliary sections which are jumped to by selecting choices, Fable choices are tunneled to.
- Markdown provides a well-defined way to nest blocks, which doesn't require repeating bullets
- Threads in lists are supported directly, and via a distinct mechanism from threads in sections

### Threads

Threads in Ink are like story mixins. They can have parameters to say, e.g. where to divert back to. They can mix prose and choices, are "collected" and merged into the source section/choice.

In Fable, threads are separated into interpolated choices and direct `render` calls to include bits of scenes in sections, so they have a well-defined meaning: it is clear what is being included from where they appear.

Fable `more` annotations in choices do not have parametes. This may be changed in future, but is not often used and may be supported using global variables.

### Lists

Ink has a single data structure, the _list_, aka an ordered enum set.

`LIST` declares an enumerated type, as well as a set containing those elements marked with parentheses.

`VAR` declares a set of any type.

Lists can be used to model a variety of things.

- Enums, by ensuring that the set contains only one element.
- Knowledge lattices, by ensuring that the set grows monotonically, and predecessors of a particular fact are added automatically
- Sequences, by making use of the ordering

While this is creative, it's awkward for simple things.

<!--
# [YarnSpinner](https://github.com/YarnSpinnerTool)
https://www.gamedeveloper.com/programming/deep-dive-yarn-spinner
-->

[^1]: Fable's compiler and runtime weigh in at < 800 LoC of OCaml and JS, with the heavy lifting being done by [Cmarkit](https://erratique.ch/software/cmarkit). [Ink's compiler](https://github.com/inkle/ink) is 17K LoC of C#, and [InkJS](https://github.com/y-lohse/inkjs) is 18K LoC of TypeScript.

[^2]: Note that only `~` and the jump or tunnel instructions can cause control flow changes. In particular, calling runtime functions like `render` within regular inline code will not work (as the jumps have to go through the CPS interpreter).