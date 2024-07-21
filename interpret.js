// API

function jump(s) {
  return "`->" + s + "`";
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

function seen(scene) {
  // truthiness supported for this, 0 is false, nonzero is true
  return internal.seen_scenes[scene];
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

const choices_disappear = true;

// INTERNALS

const content = document.querySelector("#content");
const container = document.querySelector("#scroll-container");

let internal = defaultInternal();

function defaultInternal() {
  return {
    debug: false,
    // callbacks
    bug_detectors: [],
    // on_choice: [], // TODO unused?
    on_scene_visit: [
      (s) => {
        see(s);
        internal.last_visited_turn[s] = internal.turns;
      },
    ],
    on_interact: [
      () => {
        internal.turns++;
      },
    ],
    // story state
    turns: 0,
    seen_scenes: {},
    last_visited_turn: {},
    // this shouldn't be accessed directly by users as on_scene_visit won't fire
    scenes: {},
    // sticky choices
    fresh: 0,
    choice_state: {},
    // choices taken by the user
    choice_history: [],
    // choices to immediately take when hot reloading
    immediately_take: [],
    // whether or not to send parent events. for internal use
    silent_choice: false,
  };
}

function resetInternals() {
  internal = defaultInternal();
}

function start(story) {
  if (story.length === 0) {
    return;
  }
  internal.choice_history = [];
  for (const scene of story) {
    internal.scenes[scene.name] = scene.cmds;
  }
  let scene = story[0].name;
  internal.on_scene_visit.forEach((f) => f(scene));
  interpret(internal.scenes[scene], content, () => {});
}

// default standalone entry point: the content of the global `story` (expected to be the JSON output of the CLI) is interpreted into the div #content
function main() {
  if (isStandalone()) {
    start(story);
  }
}

window.onload = function () {
  window.parent.postMessage({ type: "PAGE_LOADED" }, "*");
};

function resetStory(s) {
  resetInternals();
  content.textContent = "";
  let s1 = s ? Fable.parse(s) : story;
  start(s1);
}

window.addEventListener("message", function (e) {
  if (e.data.type === "EDITED") {
    content.textContent = "";
    internal.immediately_take = e.data.history;
    story = Fable.parse(e.data.md);
    start(story);
  } else if (e.data.type === "RESET") {
    resetStory(e.data.md);
  }
});

function informParentChoice(choice) {
  if (!internal.silent_choice) {
    window.parent.postMessage({ type: "CHOICE_MADE", choice }, "*");
  }
}

function informParentDiverged(which) {
  window.parent.postMessage({ type: "DIVERGED", which }, "*");
}

function surfaceError(...args) {
  console.error(args);
  let elt = createPara();
  elt.classList.add("error");
  elt.style.color = "red";
  elt.textContent = args.join(" ");
  content.append(elt);
  throw "failure";
}

function createPara() {
  let d = document.createElement("div");
  d.classList.add("para");
  if (isStandalone()) {
    d.classList.add("fadein");
  }
  return d;
}

function spacer() {
  let e = document.createElement("span");
  e.textContent = " ";
  return e;
}

// Inserts elt into parent, deciding whether or not to put a space before elt
function addInline(parent, elt) {
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
  // !noSpaceSucceedingPunctuation &&

  if (addSpace) {
    parent.appendChild(spacer());
  }
  parent.appendChild(elt);

  // If we added any text at all, default to needing space before the next element.
  if (!eltHasNoText) {
    let noSpaceSucceedingPunctuation = elt.innerText.match(/["']$/);
    if (noSpaceSucceedingPunctuation) {
      parent.needsSpace = false;
    } else {
      parent.needsSpace = true;
    }
  } else {
    // Otherwise, keep the state unchanged.
  }
}

function addBlock(parent, elt) {
  parent.appendChild(elt);
}

function interpret(instrs, parent, k) {
  loop: for (var i = 0; i < instrs.length; i++) {
    const instr = instrs[i];
    if (internal.debug) {
      console.log("interpret", instr, parent);
    }
    switch (instr[0]) {
      case "Run":
        try {
          eval?.(instr[1]);
        } catch (e) {
          surfaceError("run", instr[1], e);
        }
        break;
      case "Verbatim":
        {
          // this is a span that must appear inside a Para
          let s = document.createElement("span");
          s.innerHTML = instr[1];
          // parent.appendChild(instr[1]);
          // parent.insertAdjacentHTML("beforeend", instr[1]);
          addInline(parent, s);
        }
        break;
      case "VerbatimBlock":
        {
          let d = createPara();
          d.innerHTML = instr[1];
          addBlock(parent, d);
        }
        break;
      case "Text":
        {
          // this is inline
          let s = document.createElement("span");
          s.textContent = instr[1];
          addInline(parent, s);
        }
        break;
      case "Break":
        {
          // parent.appendChild(document.createElement("br"));
          // addInline(parent, spacer());
          // do nothing, as space insertion will take care of this?
        }
        break;
      case "LinkCode":
      case "LinkJump":
        {
          let e = document.createElement("a");
          e.href = "#";
          let kind = instr[0] === "LinkCode" ? "Run" : "Jump";
          let target = instr[0] === "LinkCode" ? instr[2] + "()" : instr[2];
          e.onclick = (ev) => {
            ev.preventDefault();
            internal.on_interact.forEach((f) => f());
            if (kind === "Jump") {
              // ensure that it is not used
              interpret([[kind, target]], parent, null);
            } else {
              interpret([[kind, target]], parent, () => {});
            }
          };
          e.textContent = instr[1];
          // parent.appendChild(e);
          addInline(parent, e);
        }
        break;
      case "Interpolate":
        {
          let s = document.createElement("span");
          let v;
          try {
            v = eval?.(instr[1]);
          } catch (e) {
            surfaceError("interpolate", instr[1], e);
          }
          s.textContent = v + "";
          // parent.appendChild(d);
          addInline(parent, s);
          // parent.appendChild(d);
        }
        break;

      default:
        break loop;
    }
  }

  // i is the index of a recursive instr, or the end of the instr list
  if (i >= instrs.length) {
    k();
    container.scrollTo({
      top: container.scrollHeight,
      // window.scrollTo({
      // top: document.body.scrollHeight,
      behavior: "smooth",
    });
    return;
  }
  let current = instrs[i];
  let rest = instrs.slice(i + 1);

  // things which go below:
  // recursive things which can be aborted (Para),
  // things which need access to (Meta, Tunnel) or ignore the continuation (Jump),

  // corollary: from the placement of Run above, it cannot access the continuation

  switch (current[0]) {
    case "Tunnel": {
      // keep current k
      let scene = current[1];
      internal.on_scene_visit.forEach((f) => f(scene));
      interpret(internal.scenes[scene], content, k);
      // handling the rest is not needed because a tunnel is usually inside a para
      return;
    }
    case "Jump": {
      // abandon current k and instructions, go back to top element
      let scene = current[1];
      internal.on_scene_visit.forEach((f) => f(scene));
      interpret(internal.scenes[scene], content, () => {});
      return;
    }
    case "JumpDynamic": {
      let scene;
      try {
        scene = eval?.(current[1]);
      } catch (e) {
        surfaceError("JumpDynamic", current[1], e);
      }
      internal.on_scene_visit.forEach((f) => f(scene));
      interpret(internal.scenes[scene], content, () => {});
      return;
    }
    case "Meta":
    case "MetaBlock":
      let [kind, metaText] = current;
      let s;
      let instrs;
      try {
        s = eval?.(metaText);
        if (s === undefined) {
          s = "";
        }
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
            if (into.innerText.length > 0) {
              // TODO more granular condition, reuse the one above
              // console.log("retroactively fixed spaces");
              into.parentNode.insertBefore(spacer(), into);
            }
          }
        } else {
          interpret(rest, parent, k);
        }
      } catch (e) {
        surfaceError("meta", metaText, s, instrs, e);
      }
      break;
    case "Para":
      {
        if (current[0].length > 0) {
          let d;
          if (Fable.mayHaveText(current)) {
            // removes unneccessary divs
            d = createPara();
            addBlock(parent, d);
          } else {
            d = parent;
          }
          interpret(current[1], d, () => {
            interpret(rest, parent, k);
          });
        } else {
          // optimization
          interpret(rest, parent, k);
        }
      }
      break;
    case "Choices":
      {
        let [_, more, alts] = current;
        let ul = document.createElement("ul");
        ul.classList.add("choice");
        if (isStandalone()) {
          ul.classList.add("fadein");
        }
        addBlock(parent, ul);
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
        // add more alternatives
        let extra = Fable.recursivelyAddChoices(
          (s) => internal.scenes[s],
          more
        );

        // generate choices
        for (const item of alts.concat(extra)) {
          if (!item.sticky) {
            let id = `c${internal.fresh++}`;
            internal.choice_state[id] = false;
            item.code.push(["Run", `internal.choice_state.${id} = true;`]);
            item.guard.unshift(`!internal.choice_state.${id}`);
          }
          let generate = true;
          for (const g of item.guard) {
            try {
              generate &&= !!eval?.(g);
            } catch (e) {
              surfaceError("guard", g, e);
              continue;
            }
          }
          if (!generate) {
            continue;
          }
          let li = document.createElement("li");
          ul.appendChild(li);
          let a = document.createElement("a");
          a.href = "#";
          a.classList.add("choice");
          a.draggable = false;
          links.push(a);
          li.appendChild(a);
          a.onclick = (ev) => {
            ev.preventDefault();
            for (const old of document.querySelectorAll(
              "#content > div:not(.old)"
            )) {
              old.classList.add("old");
            }
            internal.choice_history.push(a.textContent);
            informParentChoice(a.textContent);
            internal.on_interact.forEach((f) => f());
            if (choices_disappear) {
              parent.removeChild(ul);
            } else {
              indicate_clicked(a);
            }
            // if (item.code.length > 0) {
            // we want to separate code and rest because we don't want to create an empty div for a code instr that doesn't have any output
            interpret(item.code, createPara(), () => {
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
        }

        // possibly take choices for hot reloading
        if (internal.immediately_take.length > 0) {
          let something_taken = false;
          for (const a of links) {
            if (a.textContent === internal.immediately_take[0]) {
              let elt = internal.immediately_take.shift();
              internal.silent_choice = true;
              a.click();
              internal.silent_choice = false;
              something_taken = a;
              break;
            }
          }
          if (!something_taken) {
            // there were choices we could have immediately taken, but nothing was chosen - we've diverged
            informParentDiverged(internal.immediately_take[0]);
            internal.immediately_take = [];
          }
        }
      }
      break;
    default:
      throw `unknown kind ${current[0]}`;
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

const testing_freq = 30;
function click_links() {
  let bug = bug_found();
  if (window.location.hash !== "#testing" || bug) {
    if (bug) {
      console.log(internal.choice_history);
    }
    return;
  }
  let elts = document.querySelectorAll(".choice");
  if (elts.length === 0) {
    return location.reload();
  }
  let elt = elts[Math.floor(Math.random() * elts.length)];
  // console.log(elt.textContent);
  elt.click();
  setTimeout(click_links, testing_freq);
}
setTimeout(click_links, testing_freq);

// UTILITY

function xpath(xpath) {
  let nodes = document.evaluate(
    xpath,
    document,
    null,
    XPathResult.ORDERED_NODE_ITERATOR_TYPE,
    null
  );
  let res = [];
  try {
    let node = nodes.iterateNext();
    while (node) {
      res.push(node);
      node = nodes.iterateNext();
    }
  } catch (e) {
    console.error(`Document tree modified during iteration: ${e}`);
  }
  return res;
}

function findContainingText(c) {
  return xpath(`//*[contains(child::text(), "${c}")]`);
}

// true if we are running in a html page or on itch
// false if we are running in the editor
function isStandalone() {
  return !inIFrame() || location.host.indexOf("itch") > -1;
}

function inIFrame() {
  try {
    return window.self !== window.top;
  } catch (e) {
    return true;
  }
}

// https://stackoverflow.com/a/52693392
function user_globals() {
  return Object.keys(window)
    .filter((x) => typeof window[x] !== "function")
    .filter(
      (x) => Object.getOwnPropertyDescriptor(window, x).value !== undefined
    )
    .filter(
      (a) =>
        ![
          // builtin
          "chrome",
          // jsoo
          "jsoo_runtime",
          "caml_fs_tmp",
          // ours
          "story",
          "Fable",
        ].includes(a)
    );
}
