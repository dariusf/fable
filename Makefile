
export OCAMLRUNPARAM=b

.PHONY: default
default:
	dune build @compiler # fast cram tests
	dune build @editor

.PHONY: example
example: default
	@rm -rf _build/story
	./fable -s examples/test.md -o _build/story
	python -m http.server 8005 --directory  _build/story

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