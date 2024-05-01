
.PHONY: default
default:
	# dune exec ./main.exe test/examples.t/test.md > data.js
	dune exec ./main.exe test/examples.t/crime.md > data.js
	grep 'data ' data.js | sed -e 's/const data =//g' -e 's/;$$//g' | jq | pbcopy
	dune build ./web.bc.js
	# dune build --release ./web.bc.js
	dune build @examples

.PHONY: test
test: default
	dune test

.PHONY: random
random: default
	test/runtime.t/test.js

.PHONY: watch
watch: default
	git ls | entr -ccr make
