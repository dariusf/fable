// A DOM renderer for the machine's events, plus the browser implementation of the runtime's capabilities.

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

function clearContent() {
  content.textContent = "";
  resetRenderer();
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

// PERSISTENCE (localStorage)

const local_storage_key = "fable";
const local_storage_version = 2;

/** @type {RuntimeCapabilities["storage"]} */
const localStorageBacked = {
  get() {
    const params = new URLSearchParams(window.location.search);
    if (params.get("reset") === "1") {
      localStorage.removeItem(local_storage_key);
      return null;
    }
    const choices = params.get("choices");
    if (choices) {
      return { choices: choices.split("|") };
    }
    if (!isStandalone()) return null;
    try {
      const raw = localStorage.getItem(local_storage_key);
      if (!raw) {
        return null;
      }
      const save = JSON.parse(raw);
      return save ? { choices: save.choices, seed: save.seed } : null;
    } catch (e) {
      console.error("error loading game", e);
      return null;
    }
  },
  set(save) {
    if (!isStandalone()) return;
    localStorage.setItem(
      local_storage_key,
      JSON.stringify({ version: local_storage_version, ...save }),
    );
    if (isInDev()) window.history.pushState({}, ""); // enable back button
  },
};

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

function main() {
  initRuntime({
    render: interpretEvents,
    clear: clearContent,
    defaultSeed: () =>
      isDeterministic() ? 1 : Math.floor(Math.random() * 2 ** 31),
    storage: localStorageBacked,
    configure: (frontmatter) => {
      tweet_style_choices = frontmatter.twine_mode === "true";
    },
    afterInteract: () => postStatus(),
  });
  loadStory(story);
}

// ENVIRONMENT PREDICATES

// true if we are running in a html page or on itch
// false if we are running in the editor
function isStandalone() {
  return !inIFrame() || location.host.indexOf("itch") > -1;
}

function isInDev() {
  return (
    location.host.indexOf("localhost") > -1 ||
    location.host.indexOf("127.0.0.1") > -1 ||
    location.protocol === "file:"
  );
}

function inIFrame() {
  try {
    return window.self !== window.top;
  } catch (e) {
    return true;
  }
}

function isDeterministic() {
  const p = new URLSearchParams(window.location.search);
  return navigator.webdriver || p.get("det") === "1";
}

// TEXT

/** @param {string} s */
function smartypants(s) {
  // the order matters
  return s
    .replace(/---/g, "—")
    .replace(/--/g, "–")
    .replace(/\.\.\./g, "…")
    .replace(/'([st])/g, "’$1")
    .replace(/(^|[ \t\n(])'/g, "$1‘")
    .replace(/'/g, "’")
    .replace(/(^|[ \t\n(])"/g, "$1“")
    .replace(/"/g, "”");
}

/**
 * smartypants for raw HTML, so only the text between tags is transformed
 * @param {string} html */
function smartypantsHtml(html) {
  return html
    .split(/(<[^>]*>)/)
    .map((part) => (part.startsWith("<") ? part : smartypants(part)))
    .join("");
}

// BROWSER STORY HELPERS

/**
 * @param {string} id
 * @param {string} val */
function putValueInSelect(id, val) {
  const selectElt = /** @type {HTMLSelectElement | null} */ (
    document.getElementById(id)
  );
  if (selectElt) {
    selectElt.value = val;
  }
}

// tap an element 5 times in 2 seconds to offer a game reset
/** @param {HTMLElement} element @param {() => void} reset */
function enableResetDetector(element, reset) {
  const REQUIRED_TAPS = 5;
  const TIME_WINDOW_MS = 2000;

  /** @type {number[]} */
  let taps = [];

  element.addEventListener("click", () => {
    const now = performance.now();
    taps.push(now);
    taps = taps.filter((t) => now - t < TIME_WINDOW_MS);
    if (taps.length >= REQUIRED_TAPS) {
      taps = [];
      if (confirm("Start over?")) {
        reset();
      }
    }
  });
}
