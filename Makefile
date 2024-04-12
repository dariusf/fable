
.PHONY: all
all:
	dune exec ./main.exe test/examples.t/test.md | tee data.js
	# dune exec ./main.exe test/examples.t/crime.md | tee data.js
	dune build ./web.bc.js
	# dune build --release ./web.bc.js
	dune test