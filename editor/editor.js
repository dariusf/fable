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

let editor;
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

let iframe = document.querySelector("iframe");
function refreshEditor() {
  try {
    iframe.src += ""; // reload
    return true;
  } catch (e) {
    console.error(e);
    return false;
  }
}

let onEdit = debounce((_eventData) => {
  // eventData.command.name
  refreshEditor();
}, 250);

window.addEventListener("message", onPageLoad);

function onPageLoad(e) {
  if (e.data === "page loaded") {
    let txt = editorGet();
    try {
      iframe.contentWindow.postMessage(Fable.parse(txt), "*");
    } catch (e) {}
  }
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
  refreshEditor();
}

setupEditor();
