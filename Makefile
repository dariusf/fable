
.PHONY: default
default:
	# dune exec ./main.exe test/examples.t/test.md | tee data.js
	dune exec ./main.exe test/examples.t/crime.md | tee data.js
	dune build ./web.bc.js
	# dune build --release ./web.bc.js
	dune build @examples

.PHONY: all
all: default
	dune test

.PHONY: random
random: default
	test/runtime.t/test.js

.PHONY: watch
watch: default
	git ls | entr -ccr make