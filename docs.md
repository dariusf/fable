
- [Fable User Guide](#fable-user-guide)
  - [Syntax](#syntax)
    - [Prose](#prose)
    - [Sections](#sections)
    - [Code](#code)
    - [Jumps and Tunnels](#jumps-and-tunnels)
    - [Choices](#choices)
    - [Breaks and Spaces](#breaks-and-spaces)
    - [Links](#links)
  - [Semantics](#semantics)
  - [The Runtime](#the-runtime)
  - [The CLI](#the-cli)
    - [Exporting a standalone story](#exporting-a-standalone-story)
    - [Expect tests](#expect-tests)
    - [Random testing](#random-testing)
- [Development](#development)
  - [Compiler and Runtime](#compiler-and-runtime)
  - [Editor](#editor)
    - [Restarting](#restarting)
    - [Reloading](#reloading)

# Fable User Guide

## Syntax

### Prose

Fable is a Markdown dialect.

Like with other narrative scripting languages, unadorned text is prose to be shown to the player.
Interactivity may be expressed using _instructions_, and are represented using Markdown elements.

### Sections

A Fable _story_ consists of named _sections_, which contain paragraphs of prose and instructions.

Sections are named using headings, and are shown until they end or are interrupted (e.g., by a jump or choice), which may later either continue the section or move to another. A section may thus never be shown in its entirety.

Content before first section goes into an implicit section named "prelude".  The story starts there or at the first section.

### Code

Code can be freely interleaved with prose in Fable.

Inline code `` `CODE` `` is executed when encountered. Its output is hidden. Code blocks (with an optional language declaration) can be used for longer snippets.

    ```js
    CODE
    ```
A _prefix_ can be used to access variations of this.

With a `$` prefix (e.g. `` `$CODE` ``), the output is _interpolated_ as _text_ into the story at that point.

With a `~` prefix, the output is interpolated as _Fable_ into the story at that point.
This allows _unquoting_: generating some fragment of story dynamically using JavaScript.

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

### Breaks and Spaces

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

## The Runtime

The [runtime system](interpret.js) contains code supporting the execution of Fable stories.
User APIs are at the top of the file.
These include things like turn and seen counters, callbacks, and other utilities for automated testing and saving and loading stories, which can be used directly via the console.

## The CLI

### Exporting a standalone story

```sh
# if fable is not on the $PATH
dune exec ./fable.exe -- -s examples/crime.md -o _build
open _build/index.html

# add other files to _build before deploying, e.g. to itch
cd _build
zip -r game.zip *
butler push game.zip $USER/$GAME:html5
```

### Expect tests

```sh
fable -s examples/crime.md -o _build -t
cp tests.t _build # make tests available

# building blocks for your build script
cd _build
npm install selenium-webdriver # or install globally and `npm link`
dune test
dune promote && cp tests.t ..
```

This will produce a minimal dune project in the build directory with cram tests set up.
tests.t should be a cram test file which invokes the test.js script, passing it a sequence of actions to execute against the page.

```
$ node test.js 'Go to Scene 1' 'Apple'
```

test.js will run those actions using a headless browser and output the raw HTML of the resulting page.

Some system dependencies and development tools are required:
dune,
node and npm,
chromedriver/geckodriver on the `$PATH`,
Firefox/Chrome.

### Random testing

Standalone stories can be tested randomly by evaluating `randomly_test()` in the console.

The default oracle looks for unhandled exceptions.
Custom testing oracles can be added by pushing functions which return `true` on error into `internal.bug_detectors`.

To stop, remove the URL hash property or evaluate `stop_testing()` in the console.

# Development

## Compiler and Runtime

Fable Markdown is compiled into a set of named sequences of instructions. Instructions may contain others nested in them.

The runtime is a CPS interpreter whose state is a list of instructions (to be executed), a current element to mutate (e.g. with new prose), and a continuation, which enables the control primitives like jumps and choices.

For efficiency, the interpreter executes instructions in a loop until it reaches one that may change control. That instruction is then given access to the ones after as a continuation.

Note that only `~` and the jump or tunnel instructions can cause control flow changes. In particular, calling runtime functions like `render` within regular inline code will not work (as the jumps have to go through the interpreter).

## Editor

The editor can be used to share Fable stories, so it [sandboxes JS evaluation using an iframe](https://web.dev/articles/sandboxed-iframes#safely_sandboxing_eval).

It simulates[^1] hot reloading on edit by _restarting_ and replaying choices made since the last restart, stopping short if a choice can no longer be taken in a new version.

### Restarting 

How does a restart work, given that stories may have arbitrary, user-defined global state in the `window`?

A restart effectively (and apparently, naively) jumps back to the prelude. This is safe if stories are semantically _closed_, meaning that everything in them is defined before it is used, and definitions are idempotent[^2].

Stories which are not closed will contain undesirable executions which lead to use-before-definition crashes.

For example, this story isn't closed:

```md
- A `->A`
- B `->B`

# A

`var x = 1;` `->B`

# B

`$x`
```

There is the unsafe execution `[B]`, which results in a `ReferenceError: x is not defined`.
Restarting may produce the execution `[A, restart, B]`, which does not crash, even though it should.

<!--
Testing a story with restarting may be thought of testing a modified story where every section has an implicit choice which jumps back to the prelude.
Executions are now of infinite length and there will be some which don't correspond to any that the original story has.
The modified story is an abstraction of the original with strictly more executions.
Since a restart is a transition, the user loses the ability to truly restart in the sense of getting a new execution, so some executions become "hidden".
-->

Having crashes hidden like this may seem nasty, but...

1. The alternative of reloading the iframe on every edit is expensive
2. An easy way to ensure closure is to initialize all user-defined state with `var` in the prelude
3. Random testing (which reloads) can be used to check this closure property

Hence, we assume stories are closed and default to restarting. 

### Reloading

A safe but slow alternative is to reload the iframe on every edit, relying on the browser's cache for efficiency.

1. On page load, nothing happens in the editor, as the iframe loads asynchronously
2. The iframe loads and posts a message to the editor saying it has loaded
3. The editor replies with the contents of the field
4. The iframe receives Markdown text, parses it, then interprets it, which may result in sandboxed JS evaluation
5. On edit, the iframe is reloaded, causing the process to start again from 2

This guarantees that hot reloading will not result in "spooky" executions (`[A, reload, B]` would crash), but transfers quite a bit of data. See the previous section for other reasons why this isn't the default.

[^1]: We can't hot-reload in the traditional sense (by saving and restoring all interpreter state), as some state is maintained by the JS runtime due to the use of CPS.

[^2]: A helpful analogy is the execution model of a REPL. If the same closed block of code is pasted every time, it should always execute the same way, as it only relies on definitions given in the block itself. Idempotency of definitions can be ensured by using `var`.