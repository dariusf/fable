#!/bin/bash


simple() {
  md="$1"
  shift
  out=$(mktemp -d)
  fable -s $md -o $out/test
  node test.js $out/test/index.html "$@"
}