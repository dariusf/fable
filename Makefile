
.PHONY: all
all:
	dune exec ./main.exe test.md | tee data.js

.PHONY: test
test:
	dune exec ./main.exe test.md > data.js
	dune build --release ./web.bc.js