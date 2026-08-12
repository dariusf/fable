// The DOM-free layer over the machine: lifecycle, story API, persistence logic.
// Anything requiring a browser is injected via initRuntime.

/** @type {RuntimeCapabilities | null} */
var caps_ = null;

/** @returns {RuntimeCapabilities} */
function caps() {
  if (caps_ == null) {
    throw new Error("runtime used before initRuntime()");
  }
  return caps_;
}

/** @param {RuntimeCapabilities} c */
function initRuntime(c) {
  caps_ = c;
}

/** @type {FableMachine | null} */
var handle_ = null;

/** @returns {FableMachine} */
function machine() {
  if (handle_ == null) {
    throw new Error("machine used before loadStory()");
  }
  return handle_;
}

// runtime-owned state, opaque to the machine
/** @type {Record<string, Record<string, unknown>>} */
var local_section_state = {};

function resetLocalSectionState() {
  for (const k of Object.keys(local_section_state)) {
    delete local_section_state[k];
  }
}

/**
 * State backing story API
 * @type {Record<string, unknown[]>} */
var scenes = {};

/** @param {Story} s */
function initStoryState(s) {
  caps().configure?.(s.frontmatter);
  for (const k of Object.keys(scenes)) {
    delete scenes[k];
  }
  for (const scene of s.scenes) {
    scenes[scene.name] = scene.cmds;
  }
  resetLocalSectionState();
}

// fresh machine over a story, resuming a save if one applies
/** @param {Story} s @returns {string | undefined} */
function loadStory(s) {
  initStoryState(s);
  caps().clear();

  const save = caps().storage.get() ?? { choices: [] };
  const seed = save.seed ?? caps().defaultSeed();
  handle_ = Machine.create(s, { eval: evalCapability, seed });

  if (save.choices.length > 0) {
    // headless replay, then one render of the buffered log
    const res = machine().loadSaved(save.choices);
    if (res.diverged) {
      // it's possible to diverge on load if a new version of the game was released
      console.log("diverged at", res.divergedAt);
    }
    caps().render(res.events, "instant");
    return res.divergedAt;
  } else {
    caps().render(machine().start().events, "instant");
    return undefined;
  }
}

/**
 * called on hot reload with a new story
 * @param {Story} s
 * @returns {string | undefined} */
function applyEdit(s) {
  initStoryState(s);
  return rerender(machine().hotReload(s));
}

/**
 * clear the page and re-render a sequence of events
 * @param {Result} res
 * @returns {string | undefined} */
function rerender(res) {
  if (res.diverged) {
    console.log("diverged at", res.divergedAt);
  }
  caps().clear();
  caps().render(res.events, "instant");
  return res.divergedAt;
}

// rewind: truncate-history + headless replay + one rebuild
function handleBack() {
  resetLocalSectionState();
  return rerender(machine().rewind(1));
}

/** Response to a user interaction (choose/activate)
 * @param {Result} res */
function interacted(res) {
  saveGameOnInteract();
  caps().afterInteract?.();
  caps().render(res.events);
}

/** * @param {string} code */
function evalCapability(code) {
  const scene = machine().currentScene();
  if (scene != null) {
    local_section_state[scene] ||= {};
    /** @type {any} */ (globalThis).local = local_section_state[scene];
  }
  // indirect (global-scope) eval
  return eval?.(code);
}

// compatibility shims for story code that reaches into `internal`
// TODO remove this after all stories are ported
var internal = {
  scenes,
  section_state: local_section_state,
  get turns() {
    return machine().turns();
  },
  get current_scene() {
    return machine().currentScene();
  },
  get choice_history() {
    return machine().history();
  },
};

// user API shims (machine-owned state, read through the handle).
// Randomness is handle-owned; the handle reseeds its own RNG before any
// replay/rewind, so draws re-roll identically. Math.random in story
// code would not.
var random = () => machine().random();
/** @type {(l: number, h: number) => number} */
var randomIncl = (l, h) => machine().randomIncl(l, h);
/** @type {(l: number, h: number) => number} */
var randomExcl = (l, h) => machine().randomExcl(l, h);
var coin = () => machine().coin();

/** @param {string} scene */
function turns_since(scene) {
  return machine().turnsSince(scene);
}
/** @type {Record<string, number>} */
var seen = new Proxy(
  {},
  {
    get: (_target, scene) => machine().seen(String(scene)),
  },
);
function last_choice() {
  const h = machine().history();
  return h[h.length - 1];
}

// PERSISTENCE (the machine's history is the save)

function saveGameOnInteract() {
  caps().storage.set({
    choices: machine().history(),
    seed: machine().seed(), // save the seed to improve determinism
  });
}

// TESTING

function randomly_test() {
  while (machine().status() === "awaiting") {
    const cs = machine().choices();
    const c = randomFrom(cs);
    console.log("choice taken:", c.label);
    caps().render(machine().choose(c.choiceId).events);
  }
  console.log(
    machine().status() === "stuck" ? "bug found" : "no links left",
    machine().history(),
  );
}

/** @param {string[]} labels */
function clickAll(...labels) {
  for (const l of labels) {
    caps().render(machine().chooseByLabel(l).events);
  }
}

// STORY HELPERS

/** @param {string} string */
function capitalize(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

/** @param {string} label */
function jump(label) {
  return `\`->${label}\``;
}

/** @param {string} label */
function tunnel(label) {
  return `\`>->${label}\``;
}

/** @template T @param {T[]} xs @returns {T} */
function randomFrom(xs) {
  return xs[randomExcl(0, xs.length)];
}
