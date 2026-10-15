// JS API for running the machine. Lifecycle, story API, persistence logic.
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

/** A reference to the machine
 * @type {FableMachine | null} */
var handle_ = null;

/** The current story, after a load or edit
 * @type {Story} */
var currentStory_;

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

/** Widget values recorded in the history, applied by the machine
 * @type {Record<string, string>} */
var widgets = {};

/** @param {Story} s */
function initStoryState(s) {
  currentStory_ = s;
  caps().configure?.(s.frontmatter);
  for (const k of Object.keys(scenes)) {
    delete scenes[k];
  }
  for (const scene of s.scenes) {
    scenes[scene.name] = scene.cmds;
  }
  for (const k of Object.keys(widgets)) {
    delete widgets[k];
  }
  resetLocalSectionState();
}

/** User-facing object which is mutated to save things,
 * persisted transparently.
 * @type {Record<string, any>} */
var saveData = {};

/** Build the storage key for a story.
 * Enables bumping the version to start over with fresh saved data.
 * @param {Story} s @param {string=} version */
function storageKey(s, version) {
  const title = s.frontmatter.title ?? "untitled";
  return `fable:${title}:${version ?? s.frontmatter.version ?? "0"}`;
}

/** Read the saved data and sync it to the global saveData
 * @param {Story} s @returns {SaveData} */
function restoreSaveData(s) {
  const save = caps().storage.get(storageKey(s)) ?? { choices: [] };
  for (const k of Object.keys(saveData)) {
    delete saveData[k];
  }
  Object.assign(saveData, save.data ?? {});
  return save;
}

/** For accessing previous versions of the saved data to migrate it.
 * @param {string | number} version @returns {SaveData | null} */
function previousSave(version) {
  return caps().storage.get(storageKey(currentStory_, String(version)));
}

/** @param {Story} s @returns {number | undefined} */
function frontmatterSeed(s) {
  const n = parseInt(s.frontmatter.seed);
  return Number.isNaN(n) ? undefined : n;
}

// Fresh machine over a story, resuming a save if one applies
/** @param {Story} s @param {SaveData} save @returns {string | undefined} */
function loadStory(s, save) {
  initStoryState(s);
  caps().clear();

  const seed = save.seed ?? frontmatterSeed(s) ?? caps().defaultSeed();
  handle_ = Machine.create(s, {
    eval: evalCapability,
    setWidget: (key, value) => {
      widgets[key] = value;
    },
    seed,
  });

  if (save.choices.length > 0) {
    // headless replay, then one render of the buffered log
    const res = machine().loadSaved(save.choices);
    if (res.diverged) {
      // it's possible to diverge on load if a new version of the game was released
      console.log("diverged at", res.divergedAt);
    }
    render(res.events, "instant");
    return res.divergedAt;
  } else {
    render(machine().start().events, "instant");
    return undefined;
  }
}

/**
 * called on hot reload with a new story
 * @param {Story} s
 * @returns {string | undefined} */
function applyEdit(s) {
  initStoryState(s);
  const divergedAt = rerender(machine().hotReload(s));

  // when reloading, we want to see the updated, diverged state
  saveGame();

  return divergedAt;
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
  render(res.events, "instant");
  return res.divergedAt;
}

// rewind: truncate-history + headless replay + one rebuild
function handleBack() {
  resetLocalSectionState();
  const divergedAt = rerender(machine().rewind(1));
  saveGame();
  return divergedAt;
}

function recordWidgets() {
  const current = caps().readWidgets?.() ?? {};
  for (const [key, value] of Object.entries(current)) {
    if (widgets[key] !== value) {
      machine().widgetInput(key, value);
    }
  }
}

/** Response to a user interaction (choose/activate)
 * @param {() => Result} act */
function interacted(act) {
  recordWidgets();
  // the widget inputs have to be recorded in history before the user interaction records the choice
  const res = act();
  saveGame();
  caps().afterInteract?.();
  render(res.events);
}

/**
 * @param {FableEvent[]} events
 * @param {ScrollBehavior=} scrollBehaviour
 */
function render(events, scrollBehaviour) {
  caps().render(events, scrollBehaviour);
  globalThis.afterRender?.();
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

// compatibility shims for story code that uses `internal`
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
    return machine().choiceHistory();
  },
};

// user API shims (machine-owned state, read through the handle).
// Randomness is handle-owned; the handle reseeds its own RNG before any
// replay/rewind, so draws re-roll identically. Math.random in story
// code would not.

/** @type {() => number} */
var random = () => machine().random();
/** @type {(l: number, h: number) => number} */
var randomIncl = (l, h) => machine().randomIncl(l, h);
/** @type {(l: number, h: number) => number} */
var randomExcl = (l, h) => machine().randomExcl(l, h);
var coin = () => machine().coin();

/** @template T * @param {T[]} arr * @returns {T[]} */
function shuffle(arr) {
  return arr
    .map((value) => ({ value, sort: random() }))
    .sort((a, b) => a.sort - b.sort)
    .map(({ value }) => value);
}

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
  const h = machine().choiceHistory();
  return h[h.length - 1];
}

// PERSISTENCE (the machine's history is the save)

function saveGame() {
  globalThis.beforeSave?.();
  caps().storage.set(storageKey(currentStory_), {
    choices: machine().history(),
    seed: machine().seed(), // save the seed to improve determinism
    data: saveData,
  });
}

function clearSaveData() {
  caps().storage.clear(storageKey(currentStory_));
}

// TESTING

function randomly_test() {
  while (machine().status() === "awaiting") {
    const cs = machine().choices();
    const c = randomFrom(cs);
    console.log("choice taken:", c.label);
    render(machine().choose(c.choiceId).events);
  }
  console.log(
    machine().status() === "stuck" ? "bug found" : "no links left",
    machine().history(),
  );
}

/** Parse a history entry encoded as a string for e.g. query params
 * @param {string} s @returns {HistoryEntry} */
function parseHistoryEntry(s) {
  const m = /^select:([^:]*):(.*)$/s.exec(s);
  return m ? { widget: m[1], value: m[2] } : { choice: s };
}

/** @param {string[]} entries */
function play(...entries) {
  render(
    machine().applyInputs(entries.map(parseHistoryEntry)).events,
    "instant",
  );
}

/** @param {string} id @param {string} value @returns {string} */
function select(id, value) {
  return `select:${id}:${value}`;
}

/** @param {string} text */
function skipUntil(text) {
  render(machine().skipUntil(text).events, "instant");
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
