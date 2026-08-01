#!/usr/bin/env node
// Load the Fable jsoo runtime in node, input some choices, print the raw event stream.
// usage: machine_smoke.js <fablejs.bc.js> <story.md> [choice labels...]

const fs = require("fs");
const path = require("path");

require(path.resolve("../../fablejs.bc.js")); // defines globalThis.Fable, Machine

(0, eval)(fs.readFileSync(path.resolve("../../stdlib.js"), "utf8"));

const md = fs.readFileSync(process.argv[2], "utf8");
const choices = process.argv.slice(3);
const story = Fable.parse(md);

// minimal version of render.js: global eval with scene-local state
const section_state = {};

globalThis.scenes = {};
for (const scene of story.scenes) {
  scenes[scene.name] = scene.cmds;
}

// TODO get rid of this once internal is retired
globalThis.internal = { scenes, section_state };

const handle = Machine.create(story, { eval: execute, seed: 1 });

function execute(code) {
  const scene = handle?.currentScene();
  if (scene !== null && scene !== undefined) {
    section_state[scene] ||= {};
    globalThis.local = section_state[scene];
  }
  return eval?.(code);
}

// TODO remove
Object.defineProperty(internal, "turns", { get: () => handle.turns() });

globalThis.seen = new Proxy(
  {},
  {
    get: (_target, scene) => handle.seen(String(scene)),
  },
);

function show(res) {
  for (const e of res.events) {
    console.log(JSON.stringify(e));
  }
}

show(handle.start());
for (const label of choices) {
  const isChoice =
    handle.status() === "awaiting" &&
    handle.choices().some((c) => c.label.trim() === label.trim());
  if (isChoice) {
    console.log(`--- choose: ${label}`);
    show(handle.chooseByLabel(label));
  } else {
    console.log(`--- activate: ${label}`);
    show(handle.activateByLabel(label));
  }
}
console.log(`--- status: ${handle.status()}, turns: ${handle.turns()}`);
