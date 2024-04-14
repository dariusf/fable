
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
