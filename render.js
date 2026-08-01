/// <reference path="./fable.d.ts" />

// A DOM renderer over the machine's event stream, plus glue needed to play a story.

// CONFIG

var choices_disappear = true;
var tweet_style_choices = false;

// RENDERER

const content = /** @type {HTMLElement} */ (document.querySelector("#content"));
const container = /** @type {HTMLElement} */ (
  document.querySelector("#scroll-container")
);

/**
 * @type {{
 *   blocks: HTMLElement[],
 *   firstNotOld: number,
 *   choiceLists: Map<NodeId, {ul: HTMLElement, anchors: HTMLAnchorElement[]}>,
 * }}
 */
const renderer = {
  // Every top-level element created, in order.
  // Enables the DOM to be write-only, and all writes to it to be batched.
  // Contains intermediate state visible between batches (elements still in unattached fragments).
  // Events like markOld use this.
  blocks: [],
  // blocks[0..firstNotOld) already have .old; markOld starts from here
  firstNotOld: 0,
  // nodeId -> { ul, anchors } for removeChoices
  choiceLists: new Map(),
};

/** @param {HTMLElement} elt */
function deleteBlock(elt) {
  const idx = renderer.blocks.indexOf(elt);
  if (idx !== -1) {
    renderer.blocks.splice(idx, 1);
    if (idx < renderer.firstNotOld) {
      renderer.firstNotOld--;
    }
  }
}

function deleteAllBlocks() {
  renderer.blocks = [];
  renderer.firstNotOld = 0;
}

/** @param {(elt: HTMLElement) => void} f */
function markOldBlocks(f) {
  for (let i = renderer.firstNotOld; i < renderer.blocks.length; i++) {
    f(renderer.blocks[i]);
  }
  renderer.firstNotOld = renderer.blocks.length;
}

function resetRenderer() {
  renderer.blocks = [];
  renderer.firstNotOld = 0;
  renderer.choiceLists.clear();
}

/**
 * @param {Inline} i
 * @returns {HTMLElement} */
function renderInline(i) {
  switch (i.type) {
    case "text": {
      const s = document.createElement("span");
      s.textContent = smartypants(i.text);
      return s;
    }
    case "space": {
      const s = document.createElement("span");
      s.textContent = " ";
      return s;
    }
    case "verbatim": {
      const s = document.createElement("span");
      s.innerHTML = smartypantsHtml(i.html);
      return s;
    }
    case "link": {
      const a = document.createElement("a");
      a.href = "#";
      a.textContent = smartypants(i.label);
      a.onclick = (ev) => {
        ev.preventDefault();
        interacted(machine().activate(i.linkId));
      };
      return a;
    }
    case "emph": {
      const el = document.createElement("i");
      for (const c of i.content) {
        el.appendChild(renderInline(c));
      }
      return el;
    }
    default:
      throw new Error(`unknown inline ${i}`);
    // console.error("unknown inline", i);
    // return document.createElement("span");
  }
}

/**
 * Interprets one batch of events, resulting in a fragment being appended to the DOM and scrolled to.
 * scrollBehavior should be either "smooth" or "instant".
 * @param {FableEvent[]} events
 * @param {ScrollBehavior} [scrollBehavior] */
function interpretEvents(events, scrollBehavior = "smooth") {
  const fragment = document.createDocumentFragment();

  /** @param {HTMLElement} elt */
  const addBlock = (elt) => {
    fragment.appendChild(elt);
    renderer.blocks.push(elt);
  };

  for (const e of events) {
    switch (e.type) {
      case "para": {
        const d = document.createElement("div");
        d.classList.add("para");
        for (const i of e.content) {
          d.appendChild(renderInline(i));
        }
        addBlock(d);
        break;
      }
      case "verbatimBlock": {
        const d = document.createElement("div");
        d.classList.add("para");
        d.innerHTML = e.html;
        addBlock(d);
        break;
      }
      case "choices": {
        const ul = document.createElement("ul");
        ul.classList.add("choice");
        if (isStandalone()) {
          ul.classList.add("fadein");
        }
        /** @type {HTMLAnchorElement[]} */
        const anchors = [];
        e.items.forEach((item, i) => {
          const li = document.createElement("li");
          const a = document.createElement("a");
          a.setAttribute("idx", String(i + 1));
          a.href = "#";
          a.classList.add("choice");
          a.draggable = false;
          for (const c of item.content) {
            a.appendChild(renderInline(c));
          }
          a.onclick = (ev) => {
            ev.preventDefault();
            interacted(machine().choose(item.choiceId));
          };
          li.appendChild(a);
          ul.appendChild(li);
          anchors.push(a);
        });
        addBlock(ul);
        renderer.choiceLists.set(e.nodeId, { ul, anchors });
        break;
      }
      case "removeChoices": {
        const c = renderer.choiceLists.get(e.nodeId);
        if (!c) {
          // should not happen
          throw new Error(`duplicate choice removal ${c}`);
        }
        renderer.choiceLists.delete(e.nodeId);
        if (choices_disappear) {
          c.ul.remove();
          deleteBlock(c.ul);
        } else {
          // de-link instead of deleting
          for (const a of c.anchors) {
            a.removeAttribute("href");
            a.onclick = (ev) => ev.preventDefault();
          }
        }
        if (tweet_style_choices) {
          for (const b of renderer.blocks) {
            b.remove();
          }
          deleteAllBlocks();
        }
        break;
      }
      case "markOld":
        markOldBlocks((b) => b.classList.add("old"));
        break;
      case "error": {
        const d = document.createElement("div");
        d.classList.add("para", "error");
        d.style.color = "red";
        d.textContent = e.message;
        addBlock(d);
        console.error(e.message);
        break;
      }
      default:
        console.error("unknown event", e);
    }
  }

  content.appendChild(fragment);
  scrollToLastOld(scrollBehavior);
}

// scroll the last .old block to the top of the screen
/** @param {ScrollBehavior} [behavior] */
function scrollToLastOld(behavior = "smooth") {
  const old = /** @type {NodeListOf<HTMLElement>} */ (
    document.querySelectorAll(".old")
  );
  if (old.length > 0) {
    container.scrollTo({ top: old[old.length - 1].offsetTop, behavior });
  } else {
    container.scrollTo(0, 0);
  }
}

/** Response to a user interaction (choose/activate)
 * @param {Result} res */
function interacted(res) {
  saveGameOnInteract();
  postStatus();
  interpretEvents(res.events);
}

/**
 * clear the DOM and re-render a sequence of events
 * @param {Result} res
 * @returns {string | undefined} */
function rerender(res) {
  if (res.diverged) {
    console.log("diverged at", res.divergedAt);
  }
  content.textContent = "";
  resetRenderer();
  interpretEvents(res.events, "instant");
  return res.divergedAt;
}

// rewind: truncate-history + headless replay + one rebuild
function handleBack() {
  resetLocalSectionState();
  return rerender(machine().rewind(1));
}

// HOST

/** @type {FableMachine | null} */
let handle_ = null;

/** @returns {FableMachine} */
function machine() {
  if (handle_ == null) {
    throw new Error("machine used before main()");
  }
  return handle_;
}

// host-owned state, opaque to the machine
/** @type {Record<string, Record<string, unknown>>} */
const local_section_state = {};

function resetLocalSectionState() {
  for (const k of Object.keys(local_section_state)) {
    delete local_section_state[k];
  }
}

/**
 * State backing story API
 * @type {Record<string, unknown[]>} */
const scenes = {};

/** @param {Story} s */
function initStoryState(s) {
  tweet_style_choices = s.frontmatter.twine_mode === "true";
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
  content.textContent = "";
  resetRenderer();

  const save = loadSave();
  const seed =
    save.seed ?? (isDeterministic() ? 1 : Math.floor(Math.random() * 2 ** 31));
  handle_ = Machine.create(s, { eval: evalCapability, seed });

  if (save.choices.length > 0) {
    // headless replay, then one render of the buffered log
    const res = machine().loadSaved(save.choices);
    if (res.diverged) {
      // it's possible to diverge on load if a new version of the game was released
      console.log("diverged at", res.divergedAt);
    }
    interpretEvents(res.events, "instant");
    return res.divergedAt;
  } else {
    interpretEvents(machine().start().events, "instant");
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

function main() {
  loadStory(story);
}

/** * @param {string} code */
function evalCapability(code) {
  const scene = machine().currentScene();
  if (scene != null) {
    local_section_state[scene] ||= {};
    /** @type {any} */ (window).local = local_section_state[scene];
  }
  // indirect (global-scope) eval
  return eval?.(code);
}

// compatibility shims for story code that reaches into `internal`
// TODO remove this after all stories are ported
const internal = {
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
const random = () => machine().random();
/** @type {(l: number, h: number) => number} */
const randomIncl = (l, h) => machine().randomIncl(l, h);
/** @type {(l: number, h: number) => number} */
const randomExcl = (l, h) => machine().randomExcl(l, h);
const coin = () => machine().coin();

/** @param {string} scene */
function turns_since(scene) {
  return machine().turnsSince(scene);
}
/** @type {Record<string, number>} */
const seen = new Proxy(
  {},
  {
    get: (_target, scene) => machine().seen(String(scene)),
  },
);
function last_choice() {
  const h = machine().history();
  return h[h.length - 1];
}

// PERSISTENCE (localStorage; the machine's history is the save)

const local_storage_key = "fable";
const local_storage_version = 2;

function saveGameOnInteract() {
  if (!isStandalone()) return;
  const save = {
    version: local_storage_version,
    choices: machine().history(),
    seed: machine().seed(), // save the seed to improve determinism
  };
  localStorage.setItem(local_storage_key, JSON.stringify(save));
  if (isInDev()) window.history.pushState({}, ""); // enable back button
}

/** @returns {{choices: string[], seed?: number}} */
function loadSave() {
  const params = new URLSearchParams(window.location.search);
  if (params.get("reset") === "1") {
    localStorage.removeItem(local_storage_key);
    return { choices: [] };
  }
  const choices = params.get("choices");
  if (choices) {
    return { choices: choices.split("|") };
  }
  if (!isStandalone()) return { choices: [] };
  try {
    const raw = localStorage.getItem(local_storage_key);
    if (!raw) {
      return { choices: [] };
    }
    const save = JSON.parse(raw);
    return save ? { choices: save.choices, seed: save.seed } : { choices: [] };
  } catch (e) {
    console.error("error loading game", e);
    return { choices: [] };
  }
}

// back button
window.onpopstate = function () {
  if (!isInDev() || !isStandalone() || !handle_) return;
  handleBack();
};

// EDITOR PROTOCOL

/**
 * pick the nth offered choice, as the digit keys do
 * @param {number} n */
function chooseNth(n) {
  /** @type {HTMLElement | null} */ (
    document.querySelector(`a[idx="${n}"]`)
  )?.click();
}

/** @type {{[T in EditorMsg["type"]]: (msg: Extract<EditorMsg, {type: T}>) => string | undefined | void}} */
const editorCommands = {
  LOAD: (msg) => loadStory(Fable.parse(msg.md)),
  EDIT: (msg) => applyEdit(Fable.parse(msg.md)),
  BACK: () => handleBack(),
  CHOOSE: (msg) => chooseNth(msg.index),
};

window.addEventListener("message", (e) => {
  const command =
    editorCommands[/** @type {EditorMsg["type"]} */ (e.data?.type)];
  if (!command) {
    console.warn("unknown message", e.data);
    return;
  }
  try {
    const divergedAt = command(e.data) ?? undefined;
    postStatus(divergedAt);
  } catch (err) {
    // e.g. a parse error while the story is being typed
    console.error(e.data.type, err);
  }
});

/** @param {string} [divergedAt] */
function postStatus(divergedAt) {
  if (!inIFrame()) return;
  /** @type {StoryMsg} */
  const msg = {
    type: "STATUS",
    historyLength: machine().history().length,
    divergedAt,
  };
  window.parent.postMessage(msg, "*");
}

window.onload = function () {
  if (inIFrame()) {
    /** @type {StoryMsg} */
    const msg = { type: "READY" };
    window.parent.postMessage(msg, "*");
  }
};

// keyboard shortcuts: 1-9 pick the nth offered choice
window.addEventListener("keydown", (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key >= "1" && e.key <= "9") {
    e.preventDefault();
  }
  if (e.key >= "1" && e.key <= "9") {
    chooseNth(+e.key);
  }
});

// TESTING

function randomly_test() {
  while (machine().status() === "awaiting") {
    const cs = machine().choices();
    const c = randomFrom(cs);
    console.log("choice taken:", c.label);
    interpretEvents(machine().choose(c.choiceId).events);
  }
  console.log(
    machine().status() === "halted" ? "bug found" : "no links left",
    machine().history(),
  );
}

/** @param {string[]} labels */
function clickAll(...labels) {
  for (const l of labels) {
    interpretEvents(machine().chooseByLabel(l).events);
  }
}
