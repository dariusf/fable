#!/usr/bin/env node
// A node harness for the runtime. Runs choices and prints the raw event stream.
// usage: main_test.js <story.md> [choice labels...]

const fs = require("fs");
const path = require("path");

require(path.resolve("../../fablejs.bc.js")); // defines globalThis.Fable, Machine

(0, eval)(fs.readFileSync(path.resolve("../../runtime.js"), "utf8"));

const md = fs.readFileSync(process.argv[2], "utf8");
const choices = process.argv.slice(3);

initRuntime({
  render: (events) => {
    for (const e of events) {
      console.log(JSON.stringify(e));
    }
  },
  clear: () => {},
  defaultSeed: () => 1,
  storage: {
    get: () => null,
    set: () => {},
  },
});

loadStory(Fable.parse(md));

for (const label of choices) {
  const isChoice =
    machine().status() === "awaiting" &&
    machine()
      .choices()
      .some((c) => c.label.trim() === label.trim());
  if (isChoice) {
    console.log(`--- choose: ${label}`);
    interacted(machine().chooseByLabel(label));
  } else {
    console.log(`--- activate: ${label}`);
    interacted(machine().activateByLabel(label));
  }
}
console.log(`--- status: ${machine().status()}, turns: ${machine().turns()}`);
