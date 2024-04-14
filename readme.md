
# Scripture

## Usage

Export a standalone story

```sh
dune exec ./main.exe --display=short -- -s test/examples.t/crime.md -o detective
open detective/index.html
```

## Development

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