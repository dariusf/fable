let editor;
let iframe = document.querySelector("iframe");
let choice_history = [];

// https://www.joshwcomeau.com/snippets/javascript/debounce/
const debounce = (callback, wait) => {
  let timeoutId = null;
  return (...args) => {
    window.clearTimeout(timeoutId);
    timeoutId = window.setTimeout(() => {
      callback(...args);
    }, wait);
  };
};

function setupEditor() {
  // https://ace.c9.io/tool/mode_creator.html

  editor = ace.edit("editor");
  editor.setTheme("ace/theme/xcode");
  editor.setShowPrintMargin(false);
  editor.renderer.setShowGutter(false);
  editor.setHighlightActiveLine(false);
  editor.setOption("displayIndentGuides", false);
  editor.commands.bindKey("Cmd-L", null);
  editor.session.setUseWorker(false);
  editor.session.setUseWrapMode(true);
  editor.session.setOptions({
    mode: "ace/mode/markdown",
    tabSize: 4,
    useSoftTabs: true,
  });
  editor.setFontSize("12px");
  editor.commands.addCommand({
    name: "Run",
    bindKey: { win: "Ctrl-Enter", mac: "Command-Enter" },
    exec: function (_editor) {
      run();
    },
    // scrollIntoView: "cursor",
  });
  editor.commands.on("afterExec", onEdit);
  editor.focus();
}

function editorSet(s) {
  // inp.value = s;
  editor.setValue(s, -1);
}

function editorGet() {
  // return inp.value;
  return editor.getValue();
}

function vim() {
  editor.setKeyboardHandler("ace/keyboard/vim");
}

function refreshEditor() {
  try {
    iframe.src += ""; // reload
    return true;
  } catch (e) {
    console.error(e);
    return false;
  }
}

const whitelistedActions = Object.fromEntries(
  ["insertstring", "backspace", "undo", "redo", "paste"].map((e) => [e, true])
);
let onEdit = debounce((eventData) => {
  // console.log(eventData.command.name);
  if (whitelistedActions[eventData.command.name]) {
    refreshEditor();
  }
}, 250);

window.addEventListener("message", (e) => {
  if (e.data.type === "PAGE_LOADED") {
    onPageLoad();
  } else if (e.data.type === "CHOICE_MADE") {
    choice_history.push(e.data.choice);
  } else if (e.data.type === "DIVERGED") {
    console.log(e.data);
    let at = e.data.which;
    let idx = choice_history.indexOf(at);
    if (idx === -1) {
      // what's going on
      console.error("story reported divergence at", at, idx, choice_history);
      choice_history = [];
    } else {
      choice_history = choice_history.slice(idx);
    }
  } else {
    throw `unknown message ${e.data.type}`;
  }
});

function onPageLoad() {
  let txt = editorGet();
  try {
    iframe.contentWindow.postMessage(
      { type: "EDITED", md: txt, history: choice_history },
      "*"
    );
  } catch (e) {}
}

const examples = document.querySelector("#examples");
function current_example_name() {
  return examples[examples.selectedIndex].value;
}
function current_example_text() {
  return examples[examples.selectedIndex].dataset.text.trim();
}

function load_selected_example() {
  editorSet(current_example_text());
  choice_history = [];
  refreshEditor();
}

// https://www.stefanjudis.com/snippets/how-trigger-file-downloads-with-javascript/
function downloadFile(file) {
  // Create a link and set the URL using `createObjectURL`
  const link = document.createElement("a");
  link.style.display = "none";
  link.href = URL.createObjectURL(file);
  link.download = file.name;

  // It needs to be added to the DOM so it can be clicked
  document.body.appendChild(link);
  link.click();

  // To make this work on Firefox we need to wait
  // a little while before removing it.
  setTimeout(() => {
    URL.revokeObjectURL(link.href);
    link.parentNode.removeChild(link);
  }, 0);
}

function saveFile() {
  downloadFile(new File([editorGet()], "story.md"));
}

// function loadFile(e) {
//   const selectedFile = e.target.files[0];
//   const reader = new FileReader();
//   new Promise((resolve, reject) => {
//     reader.onload = (event) => resolve(event.target.result);
//     reader.onerror = (error) => reject(error);
//     reader.readAsText(selectedFile);
//   })
//     .then((content) => {
//       editorSet(content);
//       refreshEditor();
//     })
//     .catch((error) => console.log(error));
// }

setupEditor();
