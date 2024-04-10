
.PHONY: default
default:
	dune exec ./main.exe test/examples.t/test.md | tee data.js
	# dune exec ./main.exe test/examples.t/crime.md | tee data.js

.PHONY: all
all: default
	dune build --release ./web.bc.js
	dune test