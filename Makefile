
export OCAMLRUNPARAM=b

.PHONY: default
default:
	@echo 'note: this only runs unit tests; make test to run integration tests'
	dune build ./fable.exe # compile
	dune test fabula       # expect unit tests
	dune build @compiler   # cram integration tests
	dune build @editor     # compile only
	npx -y -p typescript tsc -p jsconfig.json
	npx -y -p typescript tsc -p editor/jsconfig.json

.PHONY: example
example: default
	@rm -rf _build/story
	./fable -s examples/wash.md -o _build/story
	python -m http.server 8005 --directory  _build/story

.PHONY: test
test: default
# dune test will run unit, compiler, machine, runtime; we're just more explicit here
	dune build @machine # machine integration tests; node-only/headless
	dune build @runtime # integration tests on standalone story.html; playwright
	npx playwright test # editor tests
#	npx playwright test -g filter --ui
#	--headed
# npx playwright codegen localhost:8005

.PHONY: release
release:
	dune build --release ./fable.exe

.PHONY: watch
watch: default
	git ls | entr -ccr make

.PHONY: editor
editor:
	dune build @editor --display=short
	serve _build/default/deploy

.PHONY: clean
clean:
	dune clean
