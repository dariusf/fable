
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

The abstraction provided by Scripture is intentionally very leaky.
This has several benefits.
The story can be reasoned about and tested like a program.
It's clear when a particular bit of prose "executes", allowing things like raw HTML widgets appearing in the flow of a story.
The browser console is fully available, and the state of the story can be queried at any point without doing anything special.
Necessary data structures and libraries and language features can be used without any fanfare.

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

# Development

## Implementation

Scripture Markdown is compiled into a set of named sequences of instructions. Instructions may contain others nested in them.

The runtime is a CPS interpreter. Its state is a list of instructions (to be executed), a current element to mutate (e.g. with new prose), and a continuation. The last one is how the control primitives like jumps and choices are implemented.

To execute efficiently, the interpreter executes instructions in a loop until it reaches one that may change control. The remaining instructions would have to be acted on via a continuation.

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

# The CLI tools

Export a standalone story

```sh
dune exec ./main.exe --display=short -- -s test/examples.t/crime.md -o detective
open detective/index.html
```


<!-- # Other systems -->

<!-- Interactive fiction languages.

- Both have a compiler that translates the source language into data which is interpreted at runtime.
- Both have a similar conceptual model, of labelled sections which are primarily connected using GOTOs. -->

# Comparison to [Ink](https://github.com/inkle/ink)

Ink is designed for writing interactive fiction scripts which are embedded into a larger game engine and drive its UI.
Scripture is designed for deep interactive stories with a primarily text-based UI.
There is some overlap between these goals, but they favour different design tradeoffs.

- Ink contains an [ad hoc programming language](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#part-5-advanced-state-tracking). This is generally fine as it is meant to FFI into the host game engine, where a more complete world model might be found. Scripture has access to full JavaScript and expects that the modeling of the game world is done alongside the story.
- Scripture's language is much simpler. It is a Markdown dialect (benefitting from all the [effort](https://spec.commonmark.org/current/) that has been put into writing intuitive yet extremely expressive markup) and supports scripting using quoted JavaScript. Effort was put into boiling down language features into a small number of fundamental concepts.
- Scripture's compiler is smaller (250 LoC of OCaml; the heavy lifting is done by [Cmarkit](https://erratique.ch/software/cmarkit)). [Ink's compiler](https://github.com/inkle/ink) is 17K LoC of C#.
- Scripture's runtime is smaller (150 LoC of JS). [InkJS](https://github.com/y-lohse/inkjs) is 18K LoC of TypeScript.
- Ink is mature, has [a significant ecosystem](https://github.com/inkle/ink-library), and is appropriate for production games. Scripture is appropriate for small games, experiments, and prototypes.

## Feature-by-feature comparison

| Scripture     | Ink              |
| ------------- | ---------------- |
| section       | knot             |
| -             | stitch           |
| -             | labels           |
| jump          | divert           |
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

### Choices

Largely similar, but simplified.

| Scripture | Ink         |
| --------- | ----------- |
| guarded   | conditional |

- Ink choices support mixing choice and output text, can be jumped to, fallback choices
- Scripture choices allow interpolated options, and are weaved by default

### Threads

Threads in Ink are like story mixins. They can have parameters to say, e.g. where to divert back to.

Templates and interpolated options

### Lists

Ink list is an enum map

<!--
# [YarnSpinner](https://github.com/YarnSpinnerTool)
https://www.gamedeveloper.com/programming/deep-dive-yarn-spinner
-->
