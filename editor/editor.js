let editor;
const iframe = document.querySelector("iframe");
const fastReload = document.querySelector("#fastreload");
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
  // see https://ace.c9.io/build/kitchen-sink.html for theme list,
  // https://cdnjs.com/libraries/ace for theme name
  // editor.setTheme("ace/theme/xcode");
  editor.setTheme("ace/theme/one_dark");
  editor.setShowPrintMargin(false);
  editor.renderer.setShowGutter(false);
  editor.setHighlightActiveLine(false);
  editor.setOption("displayIndentGuides", false);
  editor.commands.bindKey("Cmd-L", null);
  editor.session.setUseWorker(false);
  editor.session.setUseWrapMode(true);
  editor.setOptions({
    mode: "ace/mode/markdown",
    tabSize: 4,
    useSoftTabs: true,
    scrollPastEnd: 0.8,
  });
  editor.setFontSize("12px");
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
    module.Vim.map("j", "gj", "normal");
    module.Vim.map("k", "gk", "normal");
  });
  disableVim();

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

function disableVim() {
  editor.setKeyboardHandler("");
}

function vim() {
  editor.setKeyboardHandler("ace/keyboard/vim");
}

// function usingFastReload() {
//   return fastReload.checked;
// }

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
  refreshEditor();
}, 250);

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
  } else {
    throw `unknown message ${e.data.type}`;
  }
});

function onPageLoad() {
  try {
    iframe.contentWindow.postMessage(
      { type: "EDITED", md: editorGet(), history: choice_history },
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
  choice_history = [];
  editorSet(current_example_text());
}

function restart() {
  choice_history = [];
  refreshEditor();
}

function reload() {
  choice_history = [];
  fullReload();
}

window.onbeforeunload = function () {
  return "prevent closing without saving";
};

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

function share() {
  const url = new URL(window.location);
  url.search = new URLSearchParams({ story: window.btoa(editorGet()) });
  // this navigates away
  // window.location = url.toString();
  history.pushState({}, "Shared Code URL", url.toString());
}

setupEditor();
