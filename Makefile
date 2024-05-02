
.PHONY: default
default:
#	dune exec ./main.exe examples/test.md > story.js
	dune exec ./main.exe examples/crime.md > story.js
	grep 'story ' story.js | sed -e 's/var story =//g' -e 's/;$$//g' | jq | pbcopy
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
