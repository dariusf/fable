
.PHONY: default
default:
	# dune exec ./main.exe test/examples.t/test.md | tee data.js
	dune exec ./main.exe test/examples.t/crime.md | tee data.js
	dune build ./web.bc.js
	# dune build --release ./web.bc.js
	dune test test/examples.t

.PHONY: all
all:
	dune test

.PHONY: watch
watch:
	git ls | entr -ccr make