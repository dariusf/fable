
- [Fable User Guide](#fable-user-guide)
  - [Syntax](#syntax)
    - [Prose](#prose)
    - [Sections](#sections)
    - [Code](#code)
    - [Jumps and Tunnels](#jumps-and-tunnels)
    - [Choices](#choices)
    - [Breaks and spaces](#breaks-and-spaces)
    - [Links](#links)
  - [Semantics](#semantics)
  - [The runtime](#the-runtime)
  - [The CLI tools](#the-cli-tools)
- [Development](#development)
  - [Implementation](#implementation)
  - [Tasks](#tasks)

# Fable User Guide

## Syntax

### Prose

Fable is a Markdown dialect.

Like with other narrative scripting languages, unadorned text is prose to be shown to the player.
Narrative-related constructs are represented using Markdown elements.

### Sections

A Fable story consists of named _sections_, which contain prose interleaved with _instructions_.

Sections are named using headings, and are shown until they end or are interrupted (e.g., by a jump or choice), which may later either continue the section or move to another. A section may thus never be shown in its entirety.

Content before first section goes into an implicit section named `default`.  The story starts there or at the first section.

### Code

Code can be freely interleaved with prose in Fable.

Inline code `` `CODE` `` is executed when encountered[^2]. Its output is hidden. Code blocks (with an optional language declaration) can be used for longer snippets.

    ```js
    CODE
    ```
A _prefix_ can be used to access variations of this.

With a `$` prefix (e.g. `` `$CODE` ``), the output is _interpolated_ as _text_ into the story at that point.

With a `~` prefix, the output is interpolated as _Fable_ into the story at that point.
This allows _unquoting_: generating some fragment of story dynamically using JavaScript[^2].

The block form of this uses the `meta` or `~` info-string after the language type.

    ```js ~
    CODE
    ```


### Jumps and Tunnels

_Jumps_ connect sections.
They may occur anywhere in prose:
as part of the flow of a section (in which case the section seamlessly ends and another begins), or in response to player input (via choices).

Jumps are represented as inline code with a different family of prefixes.

A `jump` or `->` (e.g. `` `->SECTION` ``) prefix denotes a jump to SECTION.

A _dynamic jump_ `->$` prefix jumps to the name of the section that its content evaluates to.

A `tunnel` or `>->` prefix denotes a _tunnel_ to a named section, which returns to the origin of the jump after the destination section completes.

### Choices

Lists denote choices. Each choice item is minimally of the form ``TEXT `CODE` BODY``.

- TEXT will be shown to the player, as the text of that item.
- CODE is some fragment of code that will be run when the choice is selected. Its result is not shown.
- BODY is some unrestricted Fable fragment that will be shown. Indenting the body with 4 spaces Markdown-style allows it to contain other elements, allowing nested choices.

The section continues after a choice, like Ink's [weave](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#the-weave-philosophy). This is the default, unlike in Ink.

**Preconditions.** choice item may have a _precondition_ `` `guard CODE` `` or `` `?CODE` ``. It will then only be shown if CODE evaluates to a truthy value.

**Persistence.** By default, each item in the choice can only be selected once: after selecting an item, if control later returns to the section the choice was in, the item cannot be selected again.
This can be overriden by including `` `sticky` `` somewhere in the body, making the choice _persistent_.
Whether a choice is persistent is orthogonal to whether it has a precondition.

<!-- interpolated/inlined choices -->

**Interpolated choices.** A choice may have items consisting only of `` `more SECTION` ``, where SECTION is expected to have a single choice in it; the options of that choice will then be inlined transparently into the current choice.
This may happen recursively.
Such items may have preconditions, in which case they apply to every item inlined.

<!-- TODO fallback -->

### Breaks and spaces

Like in Markdown, double linebreaks delimit paragraphs, and single linebreaks are turned into spaces.

Spaces between prose and other instructions are stripped, so they have to be readded if interpolation is used.

### Links

Links allow user input outside the usual flow of choices.

A `[TEXT](#SECTION)` link jumps to SECTION.

<!-- TODO disable other choices -->

A `[TEXT](!FN)` link causes the function FN to be executed.

## Semantics

A Fable story can be given a (denotational) semantics by (rough) analogy to procedural programs.

| Fable   | Program         |
| ------- | --------------- |
| section | labelled block  |
| prose   | print statement |
| code    | statements      |
| choices | conditional     |
| tunnel  | procedure call  |
| jump    | goto            |
| meta    | unquote         |

The abstraction provided by Fable is intentionally leaky.
This has several benefits.
The story can be reasoned about and tested like a program.
It's clear when a particular bit of prose "executes", allowing things like raw HTML widgets appearing within the flow of a story.
The browser console is fully available, and the state of the story can be queried at any point without doing anything special.
Necessary data structures, libraries, and language features can be used without any fanfare.

## The runtime

The [runtime system](interpret.js) contains code supporting the execution of Fable stories.
User APIs are at the top of the file.
These include things like turn and seen counters, callbacks, and other utilities for automated testing and saving and loading stories, which can be used directly via the console.

## The CLI tools

Export a standalone story

```sh
dune exec ./main.exe --display=short -- -s test/examples.t/crime.md -o detective
open detective/index.html
```

# Development

## Implementation

Fable Markdown is compiled into a set of named sequences of instructions. Instructions may contain others nested in them.

The runtime is a CPS interpreter whose state is a list of instructions (to be executed), a current element to mutate (e.g. with new prose), and a continuation, which enables the control primitives like jumps and choices.

To execute efficiently, the interpreter executes instructions in a loop until it reaches one that may change control. That instruction is then given access to the ones after as a continuation.

## Tasks

Build a simple story (see Makefile for which) and run fast tests, which is useful for development:

```sh
make
```

Run all tests, including [Selenium](test/runtime.t/test.js):

```sh
npm install selenium-webdriver
make test
```

Build CLI:

```sh
dune build --release ./main.exe --display=short
```

[^2]: Note that only `~` and the jump or tunnel instructions can cause control flow changes. In particular, calling runtime functions like `render` within regular inline code will not work (as the jumps have to go through the interpreter).