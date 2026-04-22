// API

function capitalize(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

const { useRandomSeed, random, randomIncl, randomExcl, coin } = Fable;
function randomFrom(xs) {
  return xs[randomExcl(0, xs.length)];
}

function jump(label) {
  return `\`->${label}\``;
}

function tunnel(label) {
  return `\`>->${label}\``;
}

function clear() {
  content.innerHTML = "";
}

function turns_since(scene) {
  return internal.turns - (internal.last_visited_turn[scene] || 0);
}

function visit(scene) {
  internal.last_visited_turn[scene] = internal.turns;
}

function see(scene) {
  if (internal.seen_scenes.hasOwnProperty(scene)) {
    internal.seen_scenes[scene]++;
  } else {
    internal.seen_scenes[scene] = 1;
  }
}

function make_choices(cs) {
  if (cs.length > 0) {
    let c = cs[0].trim();
    let [elt] = xpath(`//*[contains(child::text(), "${c}")]/..`);
    elt.click();
    setTimeout(() => make_choices(cs.slice(1)), 30);
  }
}

function last_choice() {
  return internal.choice_history[internal.choice_history.length - 1];
}

// CONFIG

var choices_disappear = true;
var tweet_style_choices = false;

// INTERNALS

if (!isDeterministic()) {
  useRandomSeed(+new Date());
}
const content = document.querySelector("#content");
const container = document.querySelector("#scroll-container");

let internal = defaultInternal();

function defaultInternal() {
  return {
    debug: false, // meant to be togged here
    // callbacks
    bug_detectors: [],
    // on_choice: [], // TODO unused?
    on_scene_visit: [
      (s) => {
        see(s);
        internal.current_scene = s;
        internal.section_state[s] ||= {};
        internal.last_visited_turn[s] = internal.turns;
      },
    ],
    on_quiescent: [],
    on_interact: [
      () => {
        internal.turns++;
      },
    ],
    history_interpretations: [],
    pre_push_history: [],
    // story state
    turns: 0,
    seen_scenes: {},
    last_visited_turn: {},
    // section state
    current_scene: null,
    section_state: {},
    // this shouldn't be accessed directly by users as on_scene_visit won't fire
    scenes: {},
    // sticky choices
    choice_state: {},
    // choices taken by the user
    choice_history: [],
    // choices to immediately take when hot reloading
    immediately_take: [],
    // whether or not to send parent events. for internal use
    system_made_choice: false,
    // saving and loading
    local_storage_key: "fable",
    local_storage_version: 1,
    on_game_load: [],
    on_game_save: () => null,
    is_replaying: false,
  };
}

function resetInternals() {
  internal = defaultInternal();
}

window.seen = internal.seen_scenes;

async function start(story) {
  // this occurs before the story is interpreted,
  // and can be used to re-run side effects
  window.beforeGameLoad?.();

  if (story.length === 0) {
    return;
  }
  internal.choice_history = [];
  for (const scene of story) {
    internal.scenes[scene.name] = scene.cmds;
  }
  let scene = story[0].name;
  internal.on_scene_visit.forEach((f) => f(scene));

  loadInitialData();

  internal.is_replaying = true;
  doubleBuffer(async () => {
    content.textContent = ""; // in case this is called to restart
    interpret(internal.scenes[scene], content, () => {
      // we can't rely on this continuation being taken as a jump will abandon it
    });
    await immediatelyTakeChoices();
    internal.is_replaying = false;
    scrollToLastOld("auto");
  });
}

// "double buffer", so the work that has to be done before a hot reload is completed before we show anything
async function doubleBuffer(f) {
  // content.style.display = "none";
  content.style.opacity = 0;

  await f();

  // setTimeout(() => {
  //   // content.style.display = "block";
  //   content.style.opacity = 1;
  // }, 100);

  content.style.opacity = 1;

  // content.animate([{ opacity: 0 }, { opacity: 1 }], {
  //   duration: 500,
  //   fill: "forwards",
  // });
}

// default standalone entry point: the content of the global `story` (expected to be the JSON output of the CLI) is interpreted into the div #content
async function main() {
  if (isStandalone()) {
    await start(story);
  }
}

window.onload = function () {
  window.parent.postMessage({ type: "PAGE_LOADED" }, "*");
};

function resetStory(s) {
  resetInternals();
  content.textContent = "";
  container.scrollTo(0, 0);
  let s1 = s ? Fable.parse(s) : story;
  start(s1);
}

window.addEventListener("message", function (e) {
  if (e.data.type === "EDITED") {
    internal.immediately_take = e.data.history;
    story = Fable.parse(e.data.md);
    start(story); // no await
  } else if (e.data.type === "RESET") {
    resetStory(e.data.md);
  } else if (e.data.type === "CHOICE_SHORTCUT") {
    handleChoiceShortcutKey(e.data.key);
  } else if (e.data.type === "GET_GRAPH") {
    try {
      const source = Fable.graph(e.data.md);
      window.parent.postMessage({ type: "GRAPH_RESPONSE", source }, "*");
    } catch (err) {
      window.parent.postMessage(
        { type: "GRAPH_ERROR", error: err.toString() },
        "*",
      );
    }
  } else if (e.data.type === "GET_STORY_JSON") {
    window.parent.postMessage(
      { type: "STORY_JSON_RESPONSE", json: story },
      "*",
    );
  }
});

function informEditorOfChoice(choice) {
  if (!internal.system_made_choice) {
    window.parent.postMessage({ type: "CHOICE_MADE", choice }, "*");
  }
}

function informParentDiverged(which) {
  window.parent.postMessage({ type: "DIVERGED", which }, "*");
}

function triggerOneShotCallback(name) {
  internal[name] = internal[name].filter((f) => !f());
}

function surfaceError(message, ...args) {
  console.error(message, args);
  let elt = createPara();
  elt.classList.add("error");
  elt.style.color = "red";
  elt.textContent = message;
  content.append(elt);
  throw new Error(message);
}

function createPara() {
  let d = document.createElement("div");
  d.classList.add("para");
  return d;
}

function spacer() {
  let e = document.createElement("span");
  e.textContent = " ";
  return e;
}

function addBlock(parent, elt) {
  parent.appendChild(elt);
}

// Inserts elt into parent, deciding whether or not to put a space before elt
function addInline(parent, elt) {
  let addSpace = inlinePrecedingSpaceCondition(parent, elt);
  let eltHasNoText = elt.innerText.length === 0;

  if (addSpace) {
    parent.appendChild(spacer());
  }
  parent.appendChild(elt);

  if (!eltHasNoText) {
    if (inlineSucceedingSpaceCondition(elt)) {
      parent.needsSpace = false;
    } else {
      parent.needsSpace = true;
    }
  } else {
    // Otherwise, keep the state unchanged.
  }
}

function inlineSucceedingSpaceCondition(elt) {
  // If we added any text at all, default to needing space before the next element.
  return elt.innerText.match(/["']$/);
}

function inlinePrecedingSpaceCondition(parent, elt) {
  // Initially (when parent is empty), there is no need for a space.
  // This is local state of the parent element.
  let needsSpace = parent.needsSpace || false;
  // A space is needed after an element with any text is added...
  let eltHasNoText = elt.innerText.length === 0;
  // ... except if we're inserting certain kinds of punctuation.
  let noSpacePrecedingPunctuation = elt.innerText.match(/^[.,!:'"]/);
  // let leadingAlpha = !!elt.innerText.match(/^[a-zA-Z0-9]/);

  // quotes are rather intricate.
  // currently we will add a space before an opening quote, which is correct,
  // but also before a closing quote.
  // fortunately, closing quotes are typically preceded by spaceless punctuation,
  // so this should do the right thing.
  // another workaround is to keeps quotes inside interpolations / metas.
  let addSpace = !noSpacePrecedingPunctuation && needsSpace && !eltHasNoText;

  return addSpace;
}

function execute(s) {
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/eval#direct_and_indirect_eval
  // indirect eval, which runs in the global scope
  https: window.local = internal.section_state[internal.current_scene];
  return eval?.(s);

  // function constructor also runs in the global scope
  // can access this, but cannot see previous definitions
  // return new Function(s).call(internal.section_state[internal.current_scene]);
}

function interpret_Run(code) {
  try {
    execute(code);
  } catch (e) {
    surfaceError(`Run: error when executing ${code}: ${e.toString()}`, e);
  }
}

function interpret_Verbatim(parent, text) {
  // this is a span that must appear inside a Para
  let s = document.createElement("span");
  s.innerHTML = text;
  // parent.appendChild(text);
  // parent.insertAdjacentHTML("beforeend", text);
  addInline(parent, s);
}

function interpret_VerbatimBlock(parent, text) {
  let d = createPara();
  d.innerHTML = text;
  addBlock(parent, d);
}

function interpret_Text(parent, text) {
  // this is inline
  let s = document.createElement("span");
  s.textContent = text;
  addInline(parent, s);
}

function interpret_Break() {
  // parent.appendChild(document.createElement("br"));
  // addInline(parent, spacer());
  // do nothing, as space insertion will take care of this?
}

function interpret_LinkCodeJump(parent, kind0, text, dest) {
  let e = document.createElement("a");
  e.href = "#";
  let kind = kind0 === "LinkCode" ? "Run" : "Jump";
  let target = kind0 === "LinkCode" ? dest + "()" : dest;
  e.onclick = (ev) => {
    ev.preventDefault();
    triggerOneShotCallback("on_interact");
    if (kind === "Jump") {
      // ensure that it is not used
      interpret([[kind, target]], parent, null);
    } else {
      interpret([[kind, target]], parent, () => {});
    }
  };
  e.textContent = text;
  // parent.appendChild(e);
  addInline(parent, e);
}

function interpret_Interpolate(parent, code) {
  let s = document.createElement("span");
  let v;
  try {
    v = execute(code);
  } catch (e) {
    surfaceError(
      `Interpolate: error when executing ${code}: ${e.toString()}`,
      e,
    );
  }
  // if (typeof v !== "string") {
  //   surfaceError(`Interpolate: ${code} evaluated to ${v}, not a string`);
  // }
  s.textContent = v + "";
  // parent.appendChild(d);
  addInline(parent, s);
  // parent.appendChild(d);
}

function interpret_Tunnel(parent, k, scene, rest) {
  // keep current k
  internal.on_scene_visit.forEach((f) => f(scene));
  interpret(internal.scenes[scene], content, () => {
    interpret(rest, parent, k);
  });
}

function interpret_Jump(scene_name) {
  internal.on_scene_visit.forEach((f) => f(scene_name));
  const scene = internal.scenes[scene_name];
  if (scene === undefined) {
    surfaceError(`Jump: scene ${scene_name} not found`);
  }
  // go back to top element
  interpret(scene, content, () => {});
}

function interpret_JumpDynamic(scene_name) {
  let scene;
  try {
    scene = execute(scene_name);
  } catch (e) {
    surfaceError(
      `JumpDynamic: error when executing ${code}: ${e.toString()}`,
      e,
    );
  }
  internal.on_scene_visit.forEach((f) => f(scene));
  interpret(internal.scenes[scene], content, () => {});
}

function interpret_MetaMetaBlock(parent, k, current, rest) {
  let [kind, metaText] = current;
  let s;
  let instrs;
  try {
    s = execute(metaText);
    if (s === undefined) {
      s = "";
    }
    // else if (typeof s !== "string") {
    //   surfaceError(`Meta: ${metaText} evaluated to ${s}, not a string`);
    // }
    if (Array.isArray(s)) {
      // fake a list of scenes, assuming internal.scenes[name] is used
      instrs = [{ cmds: s }];
    } else {
      // console.log(kind, "result", s);
      instrs = Fable.parse(s + "");
    }
    if (instrs.length > 0) {
      let into;
      if (kind === "Meta") {
        into = document.createElement("span");
        // assume there is a single para
        // extract its contents as inline instrs
        instrs = instrs[0].cmds[0][1];
      } else {
        // the result of evaluating the MetaBlock is a Para,
        // so add it directly
        into = parent;
        instrs = instrs[0].cmds;
      }

      // console.log(kind, "produced", instrs);

      if (kind === "Meta") {
        // Always add the inline meta's span, but retroactively
        // fix spaces after it's rendered.
        addInline(parent, into);
      }
      // We don't have to do anything for blocks

      interpret(instrs, into, () => {
        interpret(rest, parent, k);
      });

      /*
            This fixes the edge case of a jump in a meta causing the entire meta to disappear.
            The problem is there is no ideal place to put the addInline.
            We need it to happen after some text is rendered in order to add preceding space, so we can't have it before.
            If we put it in the continuation, a jump might interrupt it and cause it to disappear (the original problem).
            If we put it after, the ordering of into and whatever else instrs renders is reversed in parent.
            We can't do the last one, but render into a temp element to preserve the order, because that last part is hard - it's unpredictable when a call to interpret returns.
            We also can't speculatively run it in order to determine if we should add a space because of potential side effects.
            The solution is to retroactively fix the spaces after.
          */
      if (kind === "Meta") {
        if (inlinePrecedingSpaceCondition(into.parentNode, into)) {
          // console.log("retroactively fixed spaces");
          into.parentNode.insertBefore(spacer(), into);
        }
      }
    } else {
      interpret(rest, parent, k);
    }
  } catch (e) {
    surfaceError(
      `${kind}: error when executing ${metaText}: ${e.toString()}`,
      e,
    );
  }
}

function interpret_Para(parent, k, current, rest) {
  const [_, para] = current;
  if (para.length === 0) {
    // optimization
    return interpret(rest, parent, k);
  }

  let d;
  if (Fable.mayHaveText(current)) {
    // removes unneccessary divs
    d = createPara();
    addBlock(parent, d);
  } else {
    d = parent;
  }
  interpret(para, d, () => {
    interpret(rest, parent, k);
  });
}

function interpret_Emph(parent, k, current, rest) {
  let [_, children] = current;
  let s = document.createElement("i");
  interpret(children, s, () => {
    addInline(parent, s);
    interpret(rest, parent, k);
  });
}

function interpret_Choice(parent, k, current, rest) {
  let [_, { more, items, fallthrough }] = current;
  let ul = document.createElement("ul");
  ul.classList.add("choice");
  if (isStandalone()) {
    ul.classList.add("fadein");
  }
  let links = [];
  let indicate_clicked = (clicked) => {
    links.forEach((a) => {
      if (a !== clicked) {
        a.removeAttribute("href");
      }
      a.onclick = (ev) => {
        ev.preventDefault();
      };
    });
  };

  // add more alternatives.
  // even though this is here, dynamic more use is quite limited; see tests
  let extra = Fable.recursivelyAddChoices((s) => internal.scenes[s], more);

  function generateChoice(item, idk) {
    let extra_code = [];
    let extra_guard = [];
    switch (item.kind[0]) {
      case "Sticky":
        break;
      case "Consumable":
        let id = item.kind[1];
        extra_code.push(["Run", `internal.choice_state.${id} = true;`]);
        extra_guard.push(`!internal.choice_state.${id}`);
        break;
      default:
        throw `unknown kind ${current[0]}`;
    }
    let generate = true;
    for (const g of extra_guard.concat(item.guard)) {
      try {
        generate &&= !!execute(g);
      } catch (e) {
        surfaceError(`guard: error when executing ${g}: ${e.toString()}`, e);
        continue;
      }
    }
    if (!generate) {
      return false;
    }
    let li = document.createElement("li");
    ul.appendChild(li);
    let a = document.createElement("a");
    a.setAttribute("idx", idx);
    a.href = "#";
    a.classList.add("choice");
    a.draggable = false;
    links.push(a);
    li.appendChild(a);
    a.onclick = (ev) => {
      ev.preventDefault();
      for (const old of document.querySelectorAll("#content > div:not(.old)")) {
        old.classList.add("old");
      }
      triggerOneShotCallback("pre_push_history");
      internal.choice_history.push(a.textContent);
      triggerOneShotCallback("on_interact");
      informEditorOfChoice(a.textContent);
      saveGameOnInteract(); // only do this after triggering interactions
      if (choices_disappear) {
        parent.removeChild(ul);
      } else {
        indicate_clicked(a);
      }
      if (tweet_style_choices) {
        clear();
      }
      // if (item.code.length > 0) {
      // we want to separate code and rest because we don't want to create an empty div for a code instr that doesn't have any output
      interpret(extra_code.concat(item.code), createPara(), () => {
        interpret(item.rest, parent, () => {
          interpret(rest, parent, k);
        });
      });
      // } else {
      //   interpret(item.rest, parent, () => {
      //     interpret(rest, parent, k);
      //   });
      // }
    };
    interpret(item.initial, a, () => {});
    return true;
  }

  // generate choices
  let idx = 1;
  let choicesGenerated = 0;
  const allChoiceItems = items.concat(extra);
  for (const item of allChoiceItems.filter((i) => !i.otherwise)) {
    if (generateChoice(item, idx)) {
      choicesGenerated++;
      idx++;
    }
  }
  let otherwisesGenerated = 0;
  if (choicesGenerated === 0) {
    const otherwises = allChoiceItems.filter((i) => i.otherwise);
    console.assert(otherwises.length <= 1); // TODO compile time check
    for (const item of otherwises) {
      if (generateChoice(item, idx)) {
        otherwisesGenerated++;
        idx++;
      }
    }
  }
  if (choicesGenerated + otherwisesGenerated === 0) {
    if (fallthrough) {
      return interpret(rest, parent, k);
    } else {
      // get stuck intentionally, for now
      // surfaceError("empty choice");
    }
  } else {
    addBlock(parent, ul);
    triggerOneShotCallback("on_quiescent");
  }
}

// scroll the last .old paragraph to the top of the screen
function scrollToLastOld(behavior = "smooth") {
  const old = document.querySelectorAll(".old");
  if (old.length > 0) {
    const lastOld = old[old.length - 1];
    container.scrollTo({
      top: lastOld.offsetTop,
      behavior: behavior,
    });
  } else {
    // there is no greyed-out text, which only happens right at the beginning,
    // so scroll to the top, assuming that it fits within the viewport
    container.scrollTo(0, 0);
    // previous scrolling logic: go unconditionally to the bottom
    // container.scrollTo({
    //   top: container.scrollHeight,
    //   // window.scrollTo({
    //   // top: document.body.scrollHeight,
    //   behavior: "smooth",
    // });
  }
}

function interpret(instrs, parent, k) {
  loop: for (var i = 0; i < instrs.length; i++) {
    const instr = instrs[i];
    if (internal.debug) {
      console.log("interpret", instr, parent);
    }
    switch (instr[0]) {
      case "Run":
        interpret_Run(instr[1]);
        break;
      case "Verbatim":
        interpret_Verbatim(parent, instr[1]);
        break;
      case "VerbatimBlock":
        interpret_VerbatimBlock(parent, instr[1]);
        break;
      case "Text":
        interpret_Text(parent, instr[1]);
        break;
      case "Break":
        interpret_Break();
        break;
      case "LinkCode":
      case "LinkJump":
        interpret_LinkCodeJump(parent, instr[0], instr[1], instr[2]);
        break;
      case "Interpolate":
        interpret_Interpolate(parent, instr[1]);
        break;

      default:
        break loop;
    }
  }

  // i is the index of a recursive instr, or the end of the instr list
  if (i >= instrs.length) {
    k();
    // an interaction has concluded

    triggerOneShotCallback("on_quiescent");

    if (!internal.is_replaying) {
      scrollToLastOld("smooth");
    }
    return;
  }
  let current = instrs[i];
  let rest = instrs.slice(i + 1);

  // things which go below:
  // recursive things which can be aborted (Para),
  // things which need access to (Meta, Tunnel) or ignore the continuation (Jump),

  // corollary: from the placement of Run above, it cannot access the continuation

  switch (current[0]) {
    case "Tunnel":
      interpret_Tunnel(parent, k, current[1], rest);
      return;
    case "Jump":
      // abandon current k and instructions
      interpret_Jump(current[1]);
      return;
    case "JumpDynamic":
      interpret_JumpDynamic(current[1]);
      return;
    case "Meta":
    case "MetaBlock":
      interpret_MetaMetaBlock(parent, k, current, rest);
      break;
    case "Para":
      interpret_Para(parent, k, current, rest);
      break;
    case "Emph":
      interpret_Emph(parent, k, current, rest);
      break;
    case "Choice":
      interpret_Choice(parent, k, current, rest);
      break;
    default:
      throw `unknown kind of instruction ${current[0]}`;
  }
}

// function render(s) {
//   let cmds;
//   if (typeof s === "string") {
//     cmds = Fable.parse(s);
//     if (cmds.length === 0) {
//       return;
//     }
//     cmds = cmds[0].cmds;
//   } else {
//     // take it as a scene (a list of commands)
//     cmds = s;
//   }
//   if (Fable.containsControlChange(cmds)) {
//     surfaceError("render cannot be used to jump", cmds);
//   } else {
//     interpret(cmds, content, () => {});
//   }
// }

// preventing this from jumping seems unnecessarily restrictive
// function render_scene(s) {
//   internal.on_scene_visit.forEach((f) => f(s));
//   render(internal.scenes[s]);
// }

// TESTING

function isTesting() {
  return window.location.hash === "#testing";
}

function randomly_test() {
  window.location.hash = "testing";
  click_links();
}

function stop_testing() {
  // const p = new URLSearchParams(window.location.search);
  // p.set("testing", "1");
  // window.location.search = p;
  // this doesn't cause a redirect
  window.location.hash = "";
}

function bug_found() {
  let runtime_error = document.querySelectorAll(".error").length > 0;
  let user_defined_error = internal.bug_detectors.some((b) => b());
  if (user_defined_error) {
    console.error("a user-defined error occurred");
  }
  return runtime_error || user_defined_error;
}

window.onerror = () => {
  stop_testing();
};

document.onkeydown = (e) => {
  if (e.key === "Escape") {
    stop_testing();
  }
};

const TESTING_FREQ = 30;
function click_links() {
  let bug = bug_found();
  if (!isTesting()) {
    // console.log("stopped testing");
    return;
  }
  if (bug) {
    console.log("bug found", internal.choice_history);
    return;
  }
  let elts = document.querySelectorAll(".choice");
  if (elts.length === 0) {
    console.log("no links left");
    // testing reloads on every edit, to find semantic non-closure issues,
    // while the editor restarts for speed.
    // testing could also restart, to be faster.
    location.reload();
    return;
  }
  let elt = elts[randomExcl(0, elts.length)];
  console.log("choice taken:", elt.textContent);
  elt.click();
  setTimeout(click_links, TESTING_FREQ);
}
setTimeout(click_links, TESTING_FREQ);

function clickByText(text, timeout = 100, interval = 10) {
  return new Promise((resolve, _reject) => {
    const startTime = Date.now();
    let done = false;
    function poll() {
      const elements = choicesContainingText(text);
      let targetElement = elements[0];
      if (targetElement) {
        internal.on_quiescent.push(() => {
          if (!done) {
            done = true;
            resolve(true);
          }
          return true;
        });
        targetElement.click();
        return;
      }
      if (Date.now() - startTime > timeout) {
        if (!done) {
          done = true;
          resolve(false);
        }
        return;
      }
      setTimeout(poll, interval);
    }
    poll();
  });
}

async function clickAll(...items) {
  for (const item of items) {
    // ignores return value?
    await clickByText(item);
  }
}

function putValueInSelect(id, val) {
  const selectElt = document.getElementById(id);
  if (selectElt) {
    selectElt.value = val;
  }
}

function interpretHistoryItem(text) {
  for (const hi of internal.history_interpretations) {
    if (hi(text)) {
      return true;
    }
  }
  return false;
}

// possibly take choices for hot reloading
async function immediatelyTakeChoices() {
  while (internal.immediately_take.length > 0) {
    const to_take = internal.immediately_take.shift();
    if (interpretHistoryItem(to_take)) {
      continue;
    }

    internal.system_made_choice = true;
    const clicked = await clickByText(to_take);
    internal.system_made_choice = false;

    if (clicked) {
      // console.log("taking choice", to_take);
    } else {
      console.log(
        "diverged at",
        to_take,
        document.querySelectorAll("a.choice"),
      );
      // there were choices we could have immediately taken, but nothing was chosen - we've diverged
      informParentDiverged(to_take);
      internal.immediately_take = [];
      break;
    }
  }

  // console.log("done immediately taking choices", internal.choice_history);
}

// UTILITY

function choicesContainingText(text) {
  return Array.from(document.querySelectorAll("a.choice")).filter(
    (c) => c.innerText.trim() === text,
  );
}

// true if we are running in a html page or on itch
// false if we are running in the editor
function isStandalone() {
  return !inIFrame() || location.host.indexOf("itch") > -1;
}

function isInDev() {
  return (
    location.host.indexOf("localhost") > -1 ||
    location.host.indexOf("127.0.0.1") > -1
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
  return navigator.webdriver || !!p.get("det");
}

// https://stackoverflow.com/a/52693392
function user_globals() {
  return Object.keys(window)
    .filter((x) => typeof window[x] !== "function")
    .filter(
      (x) => Object.getOwnPropertyDescriptor(window, x).value !== undefined,
    )
    .filter(
      (a) =>
        ![
          // builtin
          "chrome",
          // jsoo
          "jsoo_runtime",
          "jsoo_fs_tmp",
          // ours
          "story",
          "Fable",
        ].includes(a),
    );
}

function handleChoiceShortcutKey(key) {
  if (key >= 1 && key <= 9) {
    document.querySelector(`a[idx="${+key}"]`)?.click();
  }
}

document.body.onkeydown = function (e) {
  handleChoiceShortcutKey(e.key);
};

// back button
// note that we have to push dummy entries to history to enable this
window.onpopstate = function (_) {
  if (!isInDev()) return;
  if (!isStandalone()) return;

  // persist a modified history
  internal.choice_history.pop();
  saveGameToLocalStorage();

  // rerun the game from the start
  resetInternals();
  content.textContent = "";
  start(story);

  // it's also possible to reload the page
  // window.location.reload();
};

function debounce(fn, delay) {
  let timeoutId;
  return (...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

// const pushUrlToHistory = // debounce(
//   (url) => {
//     window.history.pushState({}, "", url);
//     // navigation.navigate(url); // no await
//   }; // }, 100);

function loadGameFromUrl() {
  function inspectChoiceUrl() {
    const p = new URLSearchParams(window.location.search);
    return decodeChoices(p.get("choices"));
  }

  let to_load;
  try {
    to_load = inspectChoiceUrl();
    // console.log("reloading", to_load);
  } catch (e) {
    console.error("an error occurred loading choices, so starting over", e);
    // restart the state, which seems better than crashing and the game being unplayable
    to_load = [];
  }
  // const url = new URL(window.location);
  // url.searchParams.delete("choices");
  // pushUrlToHistory(url);
  return to_load;
}

function saveGameOnInteract() {
  // editor cannot use local storage
  if (!isStandalone()) return;

  // saveGameToUrl();
  // pushUrlToHistory(url);
  saveGameToLocalStorage();

  if (!isInDev()) return;

  // push something, so we can press back
  window.history.pushState({}, "");
}

// function saveGameToUrl() {
//   if (!isInDev()) return;
//   if (!isStandalone()) return;
//   if (internal.system_made_choice) return;
//   const s = encodeChoices(internal.choice_history);
//   const url = new URL(window.location);
//   url.searchParams.set("choices", s);
//   // pushUrlToHistory(url);
// }

function decodeChoices(str) {
  // return JSON.parse(base64ToJsonString(str));
  return str.split("|");
}

// function encodeChoices(hist) {
//   // return jsonStringToBase64(JSON.stringify(hist));
//   return hist.join("|");
// }

// // https://developer.mozilla.org/en-US/docs/Web/API/Window/btoa
// function base64ToJsonString(base64) {
//   const binString = atob(base64);
//   return new TextDecoder().decode(
//     Uint8Array.from(binString, (m) => m.codePointAt(0)),
//   );
// }

// function jsonStringToBase64(str) {
//   const binString = Array.from(new TextEncoder().encode(str), (byte) =>
//     String.fromCodePoint(byte),
//   ).join("");
//   return btoa(binString);
// }

// function automaticallyMakeChoicesUntil(text) {
//   if (document.body.innerText.includes(text)) {
//     return;
//   }
//   document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "1" }));
//   setTimeout(automaticallyMakeChoicesUntil, 1, text);
// }

async function automaticallyMakeChoicesUntil(text) {
  function found(s) {
    // return document.body.innerText.includes(s);
    const notOld = Array.from(document.querySelectorAll(".para:not(.old)"));
    return notOld.some((e) => e.innerText.includes(s));
  }
  while (!found(text)) {
    await new Promise(
      (resolve) => {
        internal.on_quiescent.push(() => {
          resolve(true);
          return true;
        });
        document.body.dispatchEvent(new KeyboardEvent("keydown", { key: "1" }));
      },
      // setTimeout(resolve, 1)
    );
  }
}

function removeUrlParam() {
  const url = new URL(window.location);
  url.searchParams.delete("reset");
  window.history.replaceState({}, "", url);
}

function clearLocalStorage() {
  localStorage.removeItem(internal.local_storage_key);
}

function hasLocalStorageSave() {
  // editor does not allow use of local storage
  if (!isStandalone()) return false;

  return !!localStorage.getItem(internal.local_storage_key);
}

function saveToLocalStorage(data) {
  const save = {
    version: internal.local_storage_version,
    choices: internal.choice_history,
    data, // choice state is persisted independently of user data
  };
  localStorage.setItem(internal.local_storage_key, JSON.stringify(save));
}

function loadFromLocalStorage() {
  try {
    const save = JSON.parse(localStorage.getItem(internal.local_storage_key));
    internal.immediately_take = save.choices;
    internal.on_game_load.forEach((f) => f(save.data, save.version));
    return save;
  } catch (e) {
    console.error("error loading game", e);
    return null;
  }
}

function saveGameToLocalStorage() {
  saveToLocalStorage(internal.on_game_save());
}

function loadInitialData() {
  const params = new URLSearchParams(window.location.search);

  if (params.get("reset") === "1") {
    clearLocalStorage();
    removeUrlParam("reset");
  } else if (!!params.get("choices")) {
    internal.immediately_take = loadGameFromUrl();
    // note that the url is only a means of input (for testing).
    // also, we don't save anything to local storage, as we don't have the user data at this point.
    // the url is a lossy means of persisting game state in any case.
    removeUrlParam("choices");
  } else if (hasLocalStorageSave()) {
    loadFromLocalStorage();
  }
}

function enableResetDetector(element) {
  const REQUIRED_TAPS = 5;
  const TIME_WINDOW_MS = 2000;

  let taps = [];

  element.addEventListener("click", () => {
    const now = performance.now();
    taps.push(now);
    taps = taps.filter((t) => now - t < TIME_WINDOW_MS);
    if (taps.length >= REQUIRED_TAPS) {
      taps = [];
      if (confirm("Start over?")) {
        clearLocalStorage();
        window.location.reload();
      }
    }
  });
}
