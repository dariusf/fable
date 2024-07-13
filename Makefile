
export OCAMLRUNPARAM=b

.PHONY: default
default:
#	dune exec ./fable.exe examples/test.md > story.js
	dune exec ./fable.exe examples/crime.md > story.js
#	dune exec ./fable.exe examples/wash.md > story.js
	grep 'story ' story.js | sed -e 's/var story =//g' -e 's/;$$//g' | jq | pbcopy
	dune build ./fablejs.bc.js
	dune build @compiler # fast cram tests

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
