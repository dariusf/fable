
- [Fable User Guide](#fable-user-guide)
  - [Workflows](#workflows)
  - [Language Reference](#language-reference)
    - [Prose](#prose)
    - [Sections](#sections)
    - [Code](#code)
    - [Jumps and Tunnels](#jumps-and-tunnels)
    - [Choices](#choices)
    - [Breaks and Spaces](#breaks-and-spaces)
    - [Links](#links)
    - [Semantics](#semantics)
  - [Runtime](#runtime)
    - [Programming](#programming)
  - [CLI](#cli)
    - [Exporting a standalone HTML page](#exporting-a-standalone-html-page)
    - [Writing](#writing)
    - [Visualising a story](#visualising-a-story)
    - [Expect tests](#expect-tests)
    - [Random testing](#random-testing)
  - [Related work](#related-work)
- [Development](#development)
  - [Getting started](#getting-started)
  - [Compiler and Runtime](#compiler-and-runtime)
  - [Editor](#editor)
    - [Restarting](#restarting)
    - [Reloading](#reloading)

# Fable User Guide

## Workflows

Fable consists of a browser-based [editor](https://dariusf.github.io/fable/), a CLI tool, and a library (Fabula).

- The editor is the most accessible way to get started. However, as it runs completely client-side, the only durable way to save your story is by encoding it in a URL. While works in theory[^url], you'll want to save longer stories manually. The editor also does not provide a way to package a story as a HTML file for deployment to e.g. itch.
- To do that, you'll want at some point to write your story in a text editor, and use a build script to invoke the CLI tool.
- The library, Fabula, is mostly intended for internal use in the above two frontends. Let me know your use cases for it.

[^url]: The maximum length of a URL [varies a lot across browsers](https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers), but modern browsers either do not limit it or have absurdly high limits. For comparison, The Lord of the Rings is 3MB of text, so you could in theory write that entirely on an iPhone in Safari.

## Language Reference

Fable is a Markdown dialect. Its design is guided by a number of desiderata:

- Web-first. The web is the only open mainstream platform, and also the most accessible one for casual players.
- First-class support for programming. Substantial stories will need a substantial amount of code. Rather than reinventing the programming language, we start with the most popular language, JavaScript.
- Future-proof. Stories are just Markdown text files. The Fable compiler is open source. The output is vanilla HTML/JS/CSS which can be immediately uploaded to e.g. itch.
- Interoperability with the existing ecosystem. The use of Markdown confers many advantages: editor extensions, e.g., folding, jumping to headings, syntax highlighting, will just work (even if they can be specialised a little). Typesetting, formatting, escaping into HTML, etc. are all solved. Diagrams can be rendered with Graphviz or Mermaid.
- Lightweight. The pipeline is simple and minimal: a markdown file is compiled into high-level instructions for a small runtime. The mental model is also simple: choice-based interface fiction where code blocks imperatively modify the page as they become visible. While a framework or game engine might be useful for larger projects or teams, for small, indie ones, this is the right balance.

### Prose

Like other narrative scripting languages, unadorned text is prose to be shown to the player.

_Meta_ things (e.g. code, choices) are quoted using backticks, or represented using typographic elements which wouldn't normally appear in prose (e.g. lists).
Meta elements which have imperative effects are called _instructions_.

<!-- Interactivity may be expressed using _instructions_, where are represented using Markdown elements. -->

### Sections

A Fable _story_ consists of named _sections_, which contain paragraphs of prose and instructions.
<!-- why not call them scenes? a scene is a reader-level concept that may span multiple sections (an author-level concept). jumping between sections is completely transparent and does not necessarily map to a change of scene -->

Sections are named using headings, and are shown until they end or are interrupted (e.g., by a jump or choice), which may later either continue the section or move to another. A section may thus never be shown in its entirety.

Content before first section goes into an implicit section named "prelude".  The story starts there or at the first section.

### Code

Code can be freely interleaved with prose in Fable.

Inline code `` `CODE` `` is executed when encountered (see the [programming guide](#programming) for how). Its output is hidden. Code blocks (with an optional language declaration) can be used for longer snippets.

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

See [the docs on the runtime](#runtime) for more on its API.

### Jumps and Tunnels

_Jumps_ connect sections.
They may occur anywhere in prose:
as part of the flow of a section (in which case the section seamlessly ends and another begins), or in response to player input (via choices).

Jumps are represented as inline code with a different family of prefixes.

A `jump` or `->` (e.g. `` `->SECTION` ``) prefix denotes a jump to SECTION.
An empty SECTION is shorthand for the current section.

A _dynamic jump_ `->$` prefix jumps to the name of the section that its content evaluates to.

A `tunnel` or `>->` prefix denotes a _tunnel_ to a named section, which returns to the origin of the jump after the destination section completes.

### Choices

Lists denote choices. Each choice item is typically of the form ``TEXT `CODE` BODY``.

- TEXT will be shown to the player, as the clickable text of that item.
- CODE is some fragment of code that will be run when the choice is selected. Its result is not shown.
- BODY is some Fable fragment that will be executed only if the item is chosen.

The section *continues* after a choice, like Ink's [weave](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#the-weave-philosophy). This is the default, unlike in Ink.

**Loose lists.** Like in Markdown, lists can be loose, with blank lines between items. This is useful if items have a significant body.

**No code.** CODE can be left empty `` ` ` ``, in which case it functions as a divider between what is shown before and on selection. It can also be replaced with a single line break.

**Nested choices.** Indenting the body so that it lines up with the text of the bullet (Markdown-style) allows it to contain other elements, allowing nested choices.

<!-- https://spec.commonmark.org/0.31.2/#list-items -->

**Preconditions.** Each choice item may have a _precondition_ `` `guard CODE` `` or `` `?CODE` ``, preceding the item text. The item will then be shown only if CODE evaluates to a truthy value.

**Persistence.** By default, each item in the choice can only be selected once: after selecting an item, if control later returns to the section the choice was in, the item cannot be selected again.
This can be changed by starting the choice text with `` `sticky` ``, making the choice _persistent_.
Whether a choice is persistent is independent of whether it has a precondition.

**Inlined choices.** A choice may have items consisting only of `` `more SECTION` ``, where SECTION is expected to have a single choice in it; the options of that choice will then be inlined transparently into the current choice.
This may happen recursively.
Such items may have preconditions, in which case they apply to every inlined item.

**Fallback.** A fallback choice can be given by starting the choice text with `` `otherwise` ``. It will then be shown only if no other choices are available.
Persistent choices are incompatible with fallback choices, as then the fallback choices will never be taken.

**Empty choices and fallthrough.**
Empty choices may arise due to incomplete preconditions, or choices being exhausted without an `otherwise` clause.
<!-- By default, they are an error: since the reader has not selected anything, the natural thing to do would be to get stuck. -->
They _get stuck_, rather than continuing with whatever is after.
To instead continue with whatever is after the choice, add `` `fallthrough` `` in an item (which will otherwise be ignored).
This is also incompatible with `` `otherwise` ``.

### Breaks and Spaces

Like in Markdown, double linebreaks delimit paragraphs, and single linebreaks are turned into spaces.

For control, spaces between prose and other instructions are stripped, so they have to be readded if interpolation is used.

<!-- A minor extension is the quoted semicolon `` `;` ``.
This acts as a paragraph break wherever it appears, i.e. the equivalent of two newlines, followed by matching the indentation of the context.
This is especially useful in places where paragraph breaks are frequent but cumbersome, e.g. dialogue inside a choice item, where paragraphs are used to signal new speakers.
For block-level things like nested choices, indentation is preferable.

The quoted semicolon is used for putting paragraph breaks between things like dialogue. For blocks, nested choices indent is better -->

### Links

Links allow input outside the usual flow of choices.

A `[TEXT](#SECTION)` link jumps to SECTION.

<!-- TODO disable other choices -->

A `[TEXT](!FN)` link causes the function FN to be executed.

### Semantics

A Fable story can be given a (denotational) semantics as a procedural program.

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

## Runtime

The [runtime system](interpret.js) supports the execution of Fable stories.
Direct console access to its APIs is supported.

- `seen[SECTION]`: the number of times SECTION has been seen; can be used in a truthy manner
- `internal`: internal state of the runtime system
    - `internal.bug_detectors`: push oracles in here
    - `internal.history_interpretations`: push functions of type `(string) => boolean`. They should return true (and perform side effects) to indicate that an ad hoc history item is handled upon hot reload
    - Hooks: these are lists of callbacks, typically of type `() => void`; exceptions are noted
      - `internal.on_scene_visit`
      - `internal.on_interact`: called at some point when a choice is made
      - `pre_push_history`: called before a choice history item is pushed; may be used to add ad hoc history items, whose meaning can then be defined using `history_interpretations`. Return `true` to make the callback one-shot.
- `local`: section-local state, may be mutated; initialise its variables at the top of a section using
    ````markdown
    # My Section

    ```js
    local.x ||= 0
    ```
    ````
- `clear()`: clears the page
- `jump(label)`, `tunnel(label)`: builders for Fable fragments which may help reduce the amount of quoting required
- `randomly_test()`, `stop_testing()`: start and stop random testing

All other parts of the runtime are considered unstable and not part of the API.

<!-- TODO save and load -->

### Programming

Code is evaluated using [indirect `eval`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/eval#direct_and_indirect_eval), which means:

- It runs in the global scope and cannot access local variables.
- Local variables (from `let` and `const`) are effectively scoped to each code block or backticked span.
- Any programming which involves story-wide state should be done with global variables, either by assigning to `window`, using `var`, or assigning to a variable without a prior declaration.
    - This enables the use of the browser devtools to inspect or modify story state.
    - By convention, user state is in `window.state`.

## CLI

### Exporting a standalone HTML page

```sh
fable -s examples/crime.md -o _build
open _build/index.html

# add other files to _build before deploying, e.g. to itch
cd _build
zip -r game.zip *
butler push game.zip $USER/$GAME:html5
```
<!--
### Compiling a Fable story

```sh
fable examples/crime.md > story.js
```
-->

### Writing

A script (call it `write.sh`) for a nice offline writing setup with live reloading.

```sh
#!/usr/bin/env bash

build() {
  fable -s story.md -o _build
}

if [ -z $1 ]; then
  vite _build &

  # kill child processes on interrupt
  procs="$(jobs -p | tr '\n' ' ')"
  trap "kill $procs" 2

  git ls | entr -ccr ./write.sh build
else
  "$1"
fi
```

### Visualising a story

When building in standalone mode, `graph.dot` and `graph.mmd` are written to the build directory. They can be rendered using Graphviz and Mermaid.

```sh
# Most package managers have Graphviz
dot -Tsvg -o _build/graph.svg _build/graph.dot

# npm install -g @mermaid-js/mermaid-cli
mmdc -i _build/graph.mmd -o _build/graph-mm.svg
```

Because of Fable's expressiveness and dynamic nature, it is not possible to show a perfectly accurate graph, so the output is a best-effort overapproximation. Dotted edges indicate dynamic edges, indicating that it *may be possible* to jump between the connected sections. Following these rules of thumb will help produce a more accurate graph:

- If you only use `` `->SCENE` `` to jump, the output will be completely accurate.
- If you jump dynamically, avoid dynamically constructing section names. Instead, invoke `jump` directly on constant section names, and put those in branches. That will produce accurate dotted edges.

### Expect tests

When writing an extensive story, it's very useful to guard against regressions by recording the result of a playthrough and comparing it against what you get in subsequent versions.

First, generate your story with tests.

```sh
fable -s examples/crime.md -o _build -t
```

This will produce a minimal dune project in the build directory with [cram](https://dune.readthedocs.io/en/stable/reference/dune/cram.html) tests set up.

Next, add your tests.

```sh
code tests.t # first time
cp tests.t _build # subsequent times
```

`tests.t` should be a cram test file which invokes the `test.js` script, passing it a sequence of choices to execute against the story. Example:

```cram
  $ node test.js /abs/path/to/index.html 'Go to Scene 1' 'Apple'
```

Finally, invoke `dune test` in the build directory.

```sh
# npm i -g playwright
# npm i -g @playwright/browser-chromium
cd _build
npm link playwright
dune test

# if anything changes
dune promote && cp tests.t ..
```

This will play through your story headlessly using Playwright and output the raw HTML of the resulting page to the test file.

You can then `promote` the output out of the build directory, so you have a record of how the choices played out to compare against in future.

The simplest way to make Playwright available is to install it globally and link it into the build directory right before running the tests.

### Random testing

Standalone stories can be tested randomly in the browser by evaluating `randomly_test()` in the console.

The default oracle looks for unhandled exceptions.
Custom testing oracles can be added by pushing functions which return `true` on error into `internal.bug_detectors`.

To stop, remove the URL hash property or evaluate `stop_testing()` in the console.

## Related work

Fable's closest relative is Ink.

Ink is a scripting language: it is interpreted at runtime by a separate game engine. In contrast, the Markdown file in which you write a Fable story is compiled into the actual game. Fable also only targets the web. These differences underlie many of the design decisions Fable makes:

- Ink defines its own scripting language, as it is engine-independent, whereas Fable just uses JavaScript.
- In Ink, you attach tags to bits of text and rely on the engine interpreting them the way you want, whereas in Fable you can directly evaluate code as part of the flow of the story to make something happen/appear in the game.
- Fable's authoring language is simpler and smaller. It is a Markdown dialect, so e.g. inline HTML can be used to tag things, there is already syntax for images, etc. It relies _unquoting_ to JavaScript to dynamically generate bits of Fable, compared to having special syntax for e.g. conditionals.

# Development

## Getting started

```sh
opam install --deps-only .
npm i -g playwright @playwright/browser-chromium prettier
```

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
