/// <reference path="../fable.d.ts" />

/** @type {AceEditor} */
let editor;
const iframe = /** @type {HTMLIFrameElement} */ (
  document.querySelector("iframe")
);

// the last status we received from the story.
// only tracks history length, so we don't send backs that fail
let lastStatus = { historyLength: 0 };

// one-shot flag that controls whether we send a load or an edit event
let freshLoad = false;

// protocol
const storyFrame = {
  /** @param {EditorMsg} msg */
  post(msg) {
    if (iframe.contentWindow) {
      iframe.contentWindow.postMessage(msg, "*");
    }
  },
  /** @param {string} md */
  load(md) {
    this.post({ type: "LOAD", md });
  },
  /** @param {string} md */
  edit(md) {
    this.post({ type: "EDIT", md });
  },
  back() {
    this.post({ type: "BACK" });
  },
  /** @param {number} n */
  choose(n) {
    this.post({ type: "CHOOSE", index: n });
  },
  /** @type {(() => void)[]} */
  readyCallbacks: [],
  /** @type {((s: StatusMsg) => void)[]} */
  statusCallbacks: [],
  /** @param {() => void} cb */
  onReady(cb) {
    this.readyCallbacks.push(cb);
  },
  /** @param {(s: StatusMsg) => void} cb */
  onStatus(cb) {
    this.statusCallbacks.push(cb);
  },
};

window.addEventListener("message", (e) => {
  const data = /** @type {StoryMsg} */ (e.data);
  if (data.type === "READY") {
    storyFrame.readyCallbacks.forEach((cb) => cb());
  } else if (data.type === "STATUS") {
    storyFrame.statusCallbacks.forEach((cb) => cb(data));
  } else {
    console.warn(`unknown message ${/** @type {any} */ (data).type}`);
  }
});

/** @typedef {Extract<StoryMsg, {type: "STATUS"}>} StatusMsg */

const compiler = {
  /** @param {string} md */
  graph(md) {
    return Fable.graph(md);
  },
  /** @param {string} md */
  storyData(md) {
    const json = Fable.parse(md);
    return {
      json,
      styleOverride: Fable.produceStyleOverride(json.frontmatter),
    };
  },
};

const Completion = (function () {
  /** @type {AceCompletion[]} */
  let headingCache = [];

  /** @param {AceEditSession} session */
  function collectHeadings(session) {
    /** @type {AceCompletion[]} */
    const headings = [];
    const seen = new Set();

    for (const line of session.getDocument().getAllLines()) {
      const match = line.match(/^\s*#\s+(.+?)\s*$/);
      if (!match) continue;

      const heading = match[1].trim();
      if (!heading || seen.has(heading)) continue;

      seen.add(heading);
      headings.push({
        caption: heading,
        value: heading,
        meta: "heading",
        score: 1000,
      });
    }

    return headings;
  }

  const refreshHeadingCache = debounce(() => {
    headingCache = collectHeadings(editor.session);
  }, 100);

  /** @param {string} text @param {RegExp} boundaryRegex */
  function findBoundaryStart(text, boundaryRegex) {
    for (let i = text.length - 1; i >= 0; i--) {
      if (boundaryRegex.test(text[i])) {
        return i + 1;
      }
    }

    return 0;
  }

  /** @param {string} text @param {RegExp} boundaryRegex */
  function findBoundaryEnd(text, boundaryRegex) {
    for (let i = 0; i < text.length; i++) {
      if (boundaryRegex.test(text[i])) {
        return i;
      }
    }

    return text.length;
  }

  /**
   * @param {AceEditSession} session
   * @param {AcePoint} pos
   * @param {RegExp} [boundaryRegex] */
  function getCursorBoundedText(session, pos, boundaryRegex = /[\s()[\]]/) {
    const line = session.getLine(pos.row);
    const beforeCursor = line.slice(0, pos.column);
    const afterCursor = line.slice(pos.column);
    const startOfChunk = findBoundaryStart(beforeCursor, boundaryRegex);
    const endOfChunk = pos.column + findBoundaryEnd(afterCursor, boundaryRegex);

    return {
      line,
      beforeCursor,
      afterCursor,
      startOfChunk,
      endOfChunk,
      chunk: line.slice(startOfChunk, endOfChunk),
      chunkBeforeCursor: line.slice(startOfChunk, pos.column),
      chunkAfterCursor: line.slice(pos.column, endOfChunk),
    };
  }

  /**
   * @param {AceEditSession} session
   * @param {AcePoint} pos */
  function isHeadingAnchorContext(session, pos) {
    const { chunkBeforeCursor } = getCursorBoundedText(session, pos);

    return chunkBeforeCursor.startsWith("`->"); //&& chunkAfterCursor === "`";
  }

  /** @type {AceCompleter} */
  const headingCompleter = {
    getCompletions(_editor, session, pos, _prefix, callback) {
      if (!isHeadingAnchorContext(session, pos)) {
        callback(null, []);
        return;
      }

      callback(null, headingCache);
    },
  };

  /** @param {AceEditor} editor */
  function setupTriggerOnIntentToJump(editor) {
    editor.commands.on("afterExec", (/** @type {any} */ e) => {
      if (e.command.name !== "insertstring" || e.args !== ">") {
        return;
      }
      const pos = editor.getCursorPosition();
      if (isHeadingAnchorContext(editor.session, pos)) {
        editor.execCommand("startAutocomplete");
      }
    });
  }

  return {
    headingCompleter,
    refreshHeadingCache,
    setupTriggerOnIntentToJump,
  };
})();

// https://www.joshwcomeau.com/snippets/javascript/debounce/
/** @param {(...args: any[]) => void} callback @param {number} wait */
function debounce(callback, wait) {
  /** @type {number | undefined} */
  let timeoutId;
  return (/** @type {any[]} */ ...args) => {
    window.clearTimeout(timeoutId);
    timeoutId = window.setTimeout(() => {
      callback(...args);
    }, wait);
  };
}

function updateTheme() {
  const isDarkMode =
    window.matchMedia &&
    window.matchMedia("(prefers-color-scheme: dark)").matches;

  // Ace extension UIs change their styling based on whether an ancestor with .ace_dark is present
  document.body.classList.toggle("ace_dark", isDarkMode);

  if (isDarkMode) {
    editor.setTheme("ace/theme/one_dark");
  } else {
    editor.setTheme("ace/theme/chrome");
  }
  editor.renderer.once("themeLoaded", () => {
    const div = /** @type {HTMLElement} */ (document.getElementById("editor"));
    div.style.visibility = "visible";
  });
}

function setupEditor() {
  // https://ace.c9.io/tool/mode_creator.html

  editor = ace.edit("editor");
  // see https://ace.c9.io/build/kitchen-sink.html for theme list,
  // https://cdnjs.com/libraries/ace for theme name
  // editor.setTheme("ace/theme/xcode");
  updateTheme();

  // React to system theme changes dynamically
  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", updateTheme);

  editor.renderer.setPadding(10);
  editor.renderer.setScrollMargin(10, 10, 0, 0);
  editor.setShowPrintMargin(false);
  editor.renderer.setShowGutter(false);
  editor.setHighlightActiveLine(false);
  editor.setOption("displayIndentGuides", false);
  editor.setOption("cursorStyle", "wide"); // disable blinking
  editor.commands.bindKey("Cmd-L", /** @type {any} */ (null));
  editor.session.setUseWorker(false);
  editor.session.setUseWrapMode(true);
  editor.setOptions({
    mode: "ace/mode/markdown",
    tabSize: 2,
    useSoftTabs: true,
    scrollPastEnd: 0.8,
    enableBasicAutocompletion: true, // both have to be enabled
    enableLiveAutocompletion: true,
  });

  // completion
  editor.session.on("change", Completion.refreshHeadingCache);
  // remove basic completers for words and such
  // editor.completers = [...(editor.completers || []), headingCompleter];
  editor.completers = [Completion.headingCompleter];
  Completion.setupTriggerOnIntentToJump(editor);

  editor.setFontSize(14);
  registerHotkeys();
  editor.on("change", onEdit);

  // vim mode has to be enabled to configure some things,
  // so enable it temporarily to do that.
  // we also want to support configuration via cmd+,
  vim();
  // https://github.com/ajaxorg/ace/blob/master/src/keyboard/vim.js
  ace.config.loadModule("ace/keyboard/vim", function (module) {
    module.Vim.noremap("j", "gj", "normal");
    module.Vim.noremap("k", "gk", "normal");
    module.Vim.noremap("j", "gj", "visual");
    module.Vim.noremap("k", "gk", "visual");
  });
  disableVim();

  editor.focus();
}

function registerHotkeys() {
  window.addEventListener(
    "keydown",
    (event) => {
      if (!(event.metaKey || event.ctrlKey) || event.altKey) return;

      const key = event.key.toLowerCase();

      if (key === "o") {
        event.preventDefault();
        event.stopPropagation();
        openFile();
      } else if (key === "s") {
        event.preventDefault();
        event.stopPropagation();
        save();
      } else if (key === "b") {
        event.preventDefault();
        event.stopPropagation();
        back();
      } else if (key === "r" && !event.shiftKey) {
        event.preventDefault();
        event.stopPropagation();
        restart();
      } else if (key === "g") {
        // keep this on the raw key event to minimise popup blocking
        event.preventDefault();
        event.stopPropagation();
        graph();
      } else if (/^Digit[0-9]$/.test(event.code)) {
        event.preventDefault();
        event.stopPropagation();
        const digitKey = event.code.replace("Digit", "");
        storyFrame.choose(parseInt(digitKey));
      }
    },
    true, // run first, during capture (top-down) phase
  );
}

function setupDragAndDrop() {
  const editorDiv = /** @type {HTMLElement} */ (
    document.getElementById("editor")
  );
  editorDiv.addEventListener("dragover", (e) => {
    e.preventDefault();
  });
  editorDiv.addEventListener("drop", async (e) => {
    e.preventDefault();
    const file = e.dataTransfer?.files[0];
    if (!file) return;

    if (file.name.endsWith(".md")) {
      const text = await file.text();
      editorSetFresh(text);
    } else if (file.name.endsWith(".html")) {
      alert(
        "This is a published story file. Open the original .md file to edit.",
      );
    }
  });
}

/** @param {string} s */
function editorSet(s) {
  // inp.value = s;
  editor.setValue(s, -1);
}

/** @param {string} s */
function editorSetFresh(s) {
  freshLoad = true;
  editorSet(s);
}

function editorGet() {
  // return inp.value;
  return editor.getValue();
}

function disableVim() {
  editor.setKeyboardHandler("");
}

function vim() {
  editor.setKeyboardHandler("ace/keyboard/vim");
}

function fullReload() {
  iframe.src += ""; // reload
}

let onEdit = debounce(() => {
  const currentText = editorGet();
  const examplesSelect = /** @type {HTMLSelectElement} */ (
    document.querySelector("#examples")
  );
  const selectedOption = examplesSelect.options[examplesSelect.selectedIndex];

  if (
    selectedOption.value !== "custom" &&
    selectedOption.dataset.text?.trim() !== currentText.trim()
  ) {
    examplesSelect.value = "custom";
    isDirty = true;
  }

  if (freshLoad) {
    freshLoad = false;
    storyFrame.load(currentText);
  } else {
    storyFrame.edit(currentText);
  }
}, 250);

/** @param {Window} win @param {string} mermaidSource */
function populateGraphWindow(win, mermaidSource) {
  const isDarkMode =
    window.matchMedia &&
    window.matchMedia("(prefers-color-scheme: dark)").matches;
  const themeCSS = getThemeCSS();

  win.document.open();
  win.document.write(`
<!doctype html>
<html>
<head>
  <title>Fable Graph</title>
  <style>
    ${themeCSS}
    body {
      margin: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background: var(--main-bg-color);
      color: var(--main-fg-color);
      font-family: sans-serif;
    }
    #graph-container {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <div id="graph-container"></div>
  <script type="module">
    import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
    import elkLayouts from 'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk/dist/mermaid-layout-elk.esm.min.mjs';

    (async () => {
      const source = ${JSON.stringify(mermaidSource)};
      const container = document.getElementById('graph-container');
      const isDarkMode = ${isDarkMode};

      try {
        mermaid.registerLayoutLoaders(elkLayouts);
        mermaid.initialize({
          startOnLoad: false,
          theme: isDarkMode ? 'dark' : 'default',
        });

        const { svg } = await mermaid.render('fable-graph', source);
        container.innerHTML = svg;
      } catch (e) {
        container.innerHTML = '<pre style="color: red; padding: 20px;">' + e + '</pre>';
        console.error(e);
      }
    })();
  </script>
</body>
</html>
`);
  win.document.close();
}

function graph() {
  let source;
  try {
    source = compiler.graph(editorGet());
  } catch (err) {
    alert("Error generating graph: " + String(err));
    return;
  }
  const win = window.open();
  if (!win) {
    alert("Unable to open a popup to view the graph");
    return;
  }
  populateGraphWindow(win, source);
}

// makes onReady idempotent
let isInitialized = false;
function onReady() {
  if (!isInitialized) {
    isInitialized = true;
    const queryParams = new URLSearchParams(window.location.search);
    const story = queryParams.get("story");
    if (story !== null) {
      editorSetFresh(base64ToString(story));
    } else {
      editorSetFresh(current_example_text());
    }
    // The editorSet above triggers onEdit, which will send after its
    // 250ms debounce. We don't send here to avoid a double-send.
    return;
  }
  storyFrame.load(editorGet());
}

const examples = /** @type {HTMLSelectElement} */ (
  document.querySelector("#examples")
);
function current_example_name() {
  return examples.options[examples.selectedIndex].value;
}
function current_example_text() {
  const text = /** @type {string} */ (
    examples.options[examples.selectedIndex].dataset.text
  );
  return text.trim();
}

function load_selected_example() {
  fileHandle = null;
  isDirty = false;
  editorSetFresh(current_example_text());
}

function back() {
  if (lastStatus.historyLength > 0) {
    storyFrame.back();
  }
}

function restart() {
  storyFrame.load(editorGet());
}

function reload() {
  fullReload();
}

// whether or not to block leaving in case there are unsaved changes
let isDirty = false;
window.onbeforeunload = function () {
  if (isDirty) {
    return "You have unsaved changes. Are you sure you want to leave?";
  }
};

/** @type {FileSystemFileHandle | null} */
let fileHandle = null;

async function openFile() {
  if ("showOpenFilePicker" in window) {
    try {
      const [handle] = await window.showOpenFilePicker({
        types: [
          {
            description: "Fable story",
            accept: { "text/markdown": [".md"] },
          },
        ],
      });
      fileHandle = handle;
      const file = await handle.getFile();
      const text = await file.text();
      isDirty = true;
      editorSetFresh(text);
    } catch (e) {
      console.error(e);
    }
  } else {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".md";
    input.onchange = async (e) => {
      const file = /** @type {HTMLInputElement} */ (e.target).files?.[0];
      if (file) {
        const text = await file.text();
        isDirty = true;
        editorSetFresh(text);
      }
    };
    input.click();
  }
}

/** @param {string} markdown */
async function saveFileNative(markdown) {
  try {
    if (!fileHandle) {
      fileHandle = await window.showSaveFilePicker({
        suggestedName: "story.md",
        types: [
          {
            description: "Fable story",
            accept: { "text/markdown": [".md"] },
          },
        ],
      });
    }
    const writable = await fileHandle.createWritable();
    await writable.write(markdown);
    await writable.close();
    isDirty = false;
  } catch (e) {
    console.error(e);
  }
}

/** @param {Blob} blob @param {string} filename */
function downloadBlob(blob, filename) {
  const link = document.createElement("a");
  link.style.display = "none";
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  setTimeout(() => {
    URL.revokeObjectURL(link.href);
    link.remove();
  }, 0);
}

/** @param {string} markdown */
function saveFileFallback(markdown) {
  const file = new File([markdown], "story.md", { type: "text/markdown" });
  downloadBlob(file, file.name);
  isDirty = false;
}

async function save() {
  const markdown = editorGet();
  if ("showSaveFilePicker" in window) {
    await saveFileNative(markdown);
  } else {
    saveFileFallback(markdown);
  }
}

// Prefetch assets for standalone HTML assembly
const assetPromises = {
  runtime: fetch("fablejs.bc.js").then((r) => r.text()),
  stdlib: fetch("stdlib.js").then((r) => r.text()),
  render: fetch("render.js").then((r) => r.text()),
  css: fetch("default.css").then((r) => r.text()),
};

async function publish() {
  const [runtime, stdlib, render, css] = await Promise.all([
    assetPromises.runtime,
    assetPromises.stdlib,
    assetPromises.render,
    assetPromises.css,
  ]);

  const { json: storyJson, styleOverride } = compiler.storyData(editorGet());

  const storyJs = "var story = " + JSON.stringify(storyJson) + ";";
  const title = storyJson.frontmatter.title ?? "Untitled Fable Story";
  const extra = styleOverride + (storyJson.frontmatter.extra ?? "");

  const html = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <style>${css}</style>
    ${extra}
  </head>
  <body>
    <div id="centred-container">
      <div id="scroll-container">
        <div id="content-container">
          <div id="content"></div>
        </div>
        <div id="scroll-placeholder"></div>
      </div>
    </div>
    <script>${runtime}</script>
    <script>${storyJs}</script>
    <script>${stdlib}</script>
    <script>${render}</script>
    <script>main();</script>
  </body>
</html>`;

  const file = new File([html], "index.html", { type: "text/html" });
  downloadBlob(file, file.name);
}

function share() {
  const url = new URL(window.location.href);
  url.search = new URLSearchParams({
    story: stringToBase64(editorGet()),
  }).toString();
  // this navigates away
  // window.location = url.toString();
  history.pushState({}, "Shared Code URL", url.toString());
}

function getThemeCSS() {
  return Array.from(document.styleSheets)
    .flatMap((sheet) => {
      try {
        return Array.from(sheet.cssRules);
      } catch (e) {
        return [];
      }
    })
    .filter(
      (rule) =>
        (rule instanceof CSSStyleRule && rule.selectorText === ":root") ||
        (rule instanceof CSSMediaRule &&
          rule.media.mediaText.includes("prefers-color-scheme")),
    )
    .map((rule) => rule.cssText)
    .join("\n");
}

function main() {
  // the editor is created immediately, but other things are deferred to when the iframe finishes loading, in onReady
  setupEditor();
  setupDragAndDrop();
  storyFrame.onReady(onReady);
  storyFrame.onStatus((s) => {
    lastStatus = s;
    if (s.divergedAt != null) {
      console.error("story diverged at", s.divergedAt);
    }
  });
}

// https://developer.mozilla.org/en-US/docs/Web/API/Window/btoa
/** @param {string} base64 */
function base64ToString(base64) {
  const binString = atob(base64);
  return new TextDecoder().decode(
    Uint8Array.from(binString, (m) => m.codePointAt(0) ?? 0),
  );
}

/** @param {string} str */
function stringToBase64(str) {
  const binString = Array.from(new TextEncoder().encode(str), (byte) =>
    String.fromCodePoint(byte),
  ).join("");
  return btoa(binString);
}
