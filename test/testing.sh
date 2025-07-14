#!/bin/bash


compile() {
  fable $1 | sed -e 's/var story = //g' -e 's/;$//g' #| jq .
}

run() {
  md="$1"
  shift
  out=$(mktemp -d)
  fable -s $md -o $out/test
  node test.js $out/test/index.html "$@" | npx prettier --parser html
}

graph() {
  md="$1"
  out=$(mktemp -d)
  fable -s $md -o $out/test
  # nop <
  cat $out/test/graph.dot
}