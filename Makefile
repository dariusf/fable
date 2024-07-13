
export OCAMLRUNPARAM=b

.PHONY: default
default:
	dune build @compiler # fast cram tests
	dune build @editor

.PHONY: example
example: default
	dune exec ./fable.exe -- -s examples/crime.md -o _build/dev
	python -m http.server 8005 --directory  _build/dev

.PHONY: test
test: default
	dune test

.PHONY: release
release:
	dune build --release ./fable.exe

.PHONY: random
random: default
	test/runtime.t/test.js

.PHONY: watch
watch: default
	git ls | entr -ccr make

.PHONY: editor
editor:
	dune build @editor --display=short
	python -m http.server 8005 --directory _build/default/deploy

.PHONY: clean
clean:
	dune clean