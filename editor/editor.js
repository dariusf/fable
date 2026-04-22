let editor;
const iframe = document.querySelector("iframe");
let choice_history = [];

const Completion = (function () {
  let headingCache = [];

  function collectHeadings(session) {
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

  function findBoundaryStart(text, boundaryRegex) {
    for (let i = text.length - 1; i >= 0; i--) {
      if (boundaryRegex.test(text[i])) {
        return i + 1;
      }
    }

    return 0;
  }

  function findBoundaryEnd(text, boundaryRegex) {
    for (let i = 0; i < text.length; i++) {
      if (boundaryRegex.test(text[i])) {
        return i;
      }
    }

    return text.length;
  }

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

  function isHeadingAnchorContext(session, pos, prefix) {
    const { chunkBeforeCursor, chunkAfterCursor } = getCursorBoundedText(
      session,
      pos,
    );

    return chunkBeforeCursor.startsWith("`->"); //&& chunkAfterCursor === "`";
  }

  const headingCompleter = {
    getCompletions(editor, session, pos, prefix, callback) {
      if (!isHeadingAnchorContext(session, pos, prefix)) {
        callback(null, []);
        return;
      }

      callback(null, headingCache);
    },
  };

  function setupTriggerOnIntentToJump(editor) {
    editor.commands.on("afterExec", (e) => {
      if (e.command.name !== "insertstring" || e.args !== ">") {
        return;
      }
      const pos = editor.getCursorPosition();
      if (isHeadingAnchorContext(editor.session, pos, "")) {
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
function debounce(callback, wait) {
  let timeoutId = null;
  return (...args) => {
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
    document.getElementById("editor").style.visibility = "visible";
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
  editor.commands.bindKey("Cmd-L", null);
  editor.session.setUseWorker(false);
  editor.session.setUseWrapMode(true);
  editor.setOptions({
    mode: "ace/mode/markdown",
    tabSize: 4,
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

  editor.setFontSize("14px");
  // editor.commands.addCommand({
  //   name: "Run",
  //   bindKey: { win: "Ctrl-Enter", mac: "Command-Enter" },
  //   exec: function (_editor) {
  //     run();
  //   },
  //   // scrollIntoView: "cursor",
  // });
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

function setupDragAndDrop() {
  const editorDiv = document.getElementById("editor");
  editorDiv.addEventListener("dragover", (e) => {
    e.preventDefault();
  });
  editorDiv.addEventListener("drop", async (e) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (!file) return;

    if (file.name.endsWith(".md")) {
      const text = await file.text();
      choice_history = [];
      editorSet(text);
    } else if (file.name.endsWith(".html")) {
      alert(
        "This is a published story file. Open the original .md file to edit.",
      );
    }
  });
}

function editorSet(s) {
  // inp.value = s;
  editor.setValue(s, -1);
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

function refreshEditor() {
  // if (true || usingFastReload()) {
  iframe.contentWindow.postMessage({ type: "RESET", md: editorGet() }, "*");
  // } else {
  // fullReload();
  // }
}

function fullReload() {
  iframe.src += ""; // reload
}

let onEdit = debounce(() => {
  const currentText = editorGet();
  const examplesSelect = document.querySelector("#examples");
  const selectedOption = examplesSelect.options[examplesSelect.selectedIndex];

  if (
    selectedOption.value !== "custom" &&
    selectedOption.dataset.text?.trim() !== currentText.trim()
  ) {
    examplesSelect.value = "custom";
    setDirty(true);
  }

  // refreshEditor();
  triggerEdited();
}, 250);

let pendingGraphWindow = null;

window.addEventListener("message", (e) => {
  if (e.data.type === "PAGE_LOADED") {
    onPageLoad();
  } else if (e.data.type === "CHOICE_MADE") {
    choice_history.push(e.data.choice);
  } else if (e.data.type === "DIVERGED") {
    let at = e.data.which;
    let idx = choice_history.indexOf(at);
    if (idx === -1) {
      // what's going on
      console.error("story reported divergence at", at, idx, choice_history);
      choice_history = [];
    } else {
      choice_history = choice_history.slice(0, idx);
    }
    onPageLoad();
  } else if (e.data.type === "GRAPH_RESPONSE") {
    if (pendingGraphWindow) {
      populateGraphWindow(pendingGraphWindow, e.data.source);
      pendingGraphWindow = null;
    }
  } else if (e.data.type === "GRAPH_ERROR") {
    if (pendingGraphWindow) {
      pendingGraphWindow.close();
      pendingGraphWindow = null;
    }
    alert("Error generating graph: " + e.data.error);
  } else if (e.data.type === "STORY_JSON_RESPONSE") {
    if (pendingPublishResolve) {
      pendingPublishResolve(e.data.json);
      pendingPublishResolve = null;
    }
  } else {
    throw `unknown message ${e.data.type}`;
  }
});

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
  pendingGraphWindow = window.open();
  pendingGraphWindow.document.write("Loading graph...");
  iframe.contentWindow.postMessage({ type: "GET_GRAPH", md: editorGet() }, "*");
}

function triggerEdited() {
  try {
    iframe.contentWindow.postMessage(
      { type: "EDITED", md: editorGet(), history: choice_history },
      "*",
    );
  } catch (e) {}
}

let isInitialized = false;
// this is called multiple times, so this state prevents repeated initialization
function onPageLoad() {
  if (!isInitialized) {
    isInitialized = true;
    const queryParams = new URLSearchParams(window.location.search);
    if (queryParams.get("story") !== null) {
      editorSet(base64ToString(queryParams.get("story")));
    } else {
      editorSet(current_example_text());
    }
    // The editorSet above triggers onEdit, which will call triggerEdited
    // after its 250ms debounce. We don't call it here to avoid a double-send.
    return;
  }
  triggerEdited();
}

const examples = document.querySelector("#examples");
function current_example_name() {
  return examples[examples.selectedIndex].value;
}
function current_example_text() {
  return examples[examples.selectedIndex].dataset.text.trim();
}

function load_selected_example() {
  choice_history = [];
  fileHandle = null;
  setDirty(false);
  editorSet(current_example_text());
}

function back() {
  if (choice_history.length > 0) {
    choice_history.pop();
    triggerEdited();
  }
}

function restart() {
  choice_history = [];
  refreshEditor();
}

function reload() {
  choice_history = [];
  fullReload();
}

let isDirty = false;

function setDirty(dirty) {
  isDirty = dirty;
}

window.onbeforeunload = function () {
  if (isDirty) {
    return "You have unsaved changes. Are you sure you want to leave?";
  }
};

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
      choice_history = [];
      setDirty(true);
      editorSet(text);
    } catch (e) {
      console.error(e);
    }
  } else {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".md";
    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (file) {
        const text = await file.text();
        choice_history = [];
        setDirty(true);
        editorSet(text);
      }
    };
    input.click();
  }
}

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
    setDirty(false);
  } catch (e) {
    console.error(e);
  }
}

function downloadBlob(blob, filename) {
  const link = document.createElement("a");
  link.style.display = "none";
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  setTimeout(() => {
    URL.revokeObjectURL(link.href);
    link.parentNode.removeChild(link);
  }, 0);
}

function saveFileFallback(markdown) {
  const file = new File([markdown], "story.md", { type: "text/markdown" });
  downloadBlob(file, file.name);
  setDirty(false);
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
  interpret: fetch("interpret.js").then((r) => r.text()),
  css: fetch("default.css").then((r) => r.text()),
};

let pendingPublishResolve = null;

async function publish() {
  const [runtime, interpret, css] = await Promise.all([
    assetPromises.runtime,
    assetPromises.interpret,
    assetPromises.css,
  ]);

  const storyJson = await new Promise((resolve) => {
    pendingPublishResolve = resolve;
    iframe.contentWindow.postMessage({ type: "GET_STORY_JSON" }, "*");
  });

  const storyJs = "var story = " + JSON.stringify(storyJson) + ";";

  const html = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Fable Story</title>
    <style>${css}</style>
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
    <script>${interpret}</script>
    <script>main();</script>
  </body>
</html>`;

  const file = new File([html], "index.html", { type: "text/html" });
  downloadBlob(file, file.name);
}

function share() {
  const url = new URL(window.location);
  url.search = new URLSearchParams({ story: stringToBase64(editorGet()) });
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
        rule.selectorText === ":root" ||
        (rule.media && rule.media.mediaText.includes("prefers-color-scheme")),
    )
    .map((rule) => rule.cssText)
    .join("\n");
}

function main() {
  // the editor is created immediately, but other things are deferred to when the iframe finishes loading, in onPageLoad
  setupEditor();
  setupDragAndDrop();
}

// https://developer.mozilla.org/en-US/docs/Web/API/Window/btoa
function base64ToString(base64) {
  const binString = atob(base64);
  return new TextDecoder().decode(
    Uint8Array.from(binString, (m) => m.codePointAt(0)),
  );
}

function stringToBase64(str) {
  const binString = Array.from(new TextEncoder().encode(str), (byte) =>
    String.fromCodePoint(byte),
  ).join("");
  return btoa(binString);
}
