# Other systems

<!-- Interactive fiction languages.

- Both have a compiler that translates the source language into data which is interpreted at runtime.
- Both have a similar conceptual model, of labelled sections which are primarily connected using GOTOs. -->

# [Ink](https://github.com/inkle/ink)

Ink is designed for writing interactive fiction scripts which are embedded into a larger game engine and drive its UI.
Scripture is designed for deep interactive stories with a primarily text-based UI.
There is some overlap between these goals, but they favour different design tradeoffs.

- Ink contains an [ad hoc programming language](https://github.com/inkle/ink/blob/master/Documentation/WritingWithInk.md#part-5-advanced-state-tracking). This is generally fine as it is meant to FFI into the host game engine, where a more complete world model might be found. Scripture has access to full JavaScript and expects that the modeling of the game world is done alongside the story.
- Scripture's language is much simpler. It is a Markdown dialect (benefitting all the [effort](https://spec.commonmark.org/current/) that has been put into writing intuitive yet extremely expressive markup) and supports scripting using quoted JavaScript. Effort was put into boiling down language features into a small number of fundamental concepts.
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

Templates and interpolated options

### Lists

Ink list is an enum map

<!--
# [YarnSpinner](https://github.com/YarnSpinnerTool)
https://www.gamedeveloper.com/programming/deep-dive-yarn-spinner
-->
