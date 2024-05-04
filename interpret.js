// API

window.on_interact = [];
window.on_scene_visit = [];
window.on_choice = [];
window.bug_detectors = [];

var turns = 0;
on_interact.push(() => {
  turns++;
});

var last_visited_turn = {};
function turns_since(scene) {
  return turns - (last_visited_turn[scene] || 0);
}

var seen_scenes = {};

function see(scene) {
  if (seen_scenes.hasOwnProperty(scene)) {
    seen_scenes[scene]++;
  } else {
    seen_scenes[scene] = 1;
  }
}

function seen(scene) {
  // truthiness supported for this, 0 is false, nonzero is true
  return seen_scenes[scene];
}

on_scene_visit.push((s) => {
  see(s);
  last_visited_turn[s] = turns;
});

function make_choices(cs) {
  if (cs.length) {
    let c = cs[0].trim();
    let [elt] = xpath(`//*[contains(child::text(), "${c}")]/..`);
    elt.click();
    setTimeout(() => make_choices(cs.slice(1)), 30);
  }
}

// CONFIG

let choices_disappear = true;

// INTERNALS

// this shouldn't be accessed directly by users as on_scene_visit won't fire
let _scenes = {};
let content = document.querySelector("#content");

// sticky choices
let fresh = 0;
window.choice_state = {};

const internal = {
  choice_history: [],
  // choices to immediately take when hot reloading
  immediately_take: [],
  // whether or not to send parent events. for internal use
  silent_choice: false,
};

function start(story) {
  if (!story.length) {
    return;
  }
  internal.choice_history = [];
  for (const scene of story) {
    _scenes[scene.name] = scene.cmds;
  }
  let scene = story[0].name;
  on_scene_visit.forEach((f) => f(scene));
  interpret(_scenes[scene], content, () => {});
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

window.addEventListener("message", function (e) {
  if (e.data.type === "EDITED") {
    content.textContent = "";
    let ast = Fable.parse(e.data.md);
    internal.immediately_take = e.data.history;
    start(ast);
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

function maybeTakeChoice(a) {
  if (!internal.immediately_take.length) {
    return;
  }
  let next = internal.immediately_take.shift();
  if (a.textContent === next) {
    internal.silent_choice = true;
    a.click();
    internal.silent_choice = false;
  } else {
    // we've diverged
    internal.immediately_take = [];
    informParentDiverged(a.textContent);
  }
}

function surfaceError(...args) {
  console.error(args);
  let elt = document.createElement("div");
  elt.classList.add("error");
  elt.style.color = "red";
  elt.textContent = args.join(" ");
  content.append(elt);
  throw "failure";
}

function interpret(instrs, parent, k) {
  loop: for (var i = 0; i < instrs.length; i++) {
    const instr = instrs[i];
    // console.log("interpret", instr, parent);
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
          // comments go in here too
          // this is on the same level as Para, i.e. block
          let d = document.createElement("div");
          d.innerHTML = instr[1];
          parent.appendChild(d);
        }
        break;
      case "Text":
        {
          // this is inline
          let d = document.createElement("span");
          d.textContent = instr[1];
          parent.appendChild(d);
        }
        break;
      case "Break":
        {
          // parent.appendChild(document.createElement("br"));
          let e = document.createElement("span");
          e.textContent = " ";
          parent.appendChild(e);
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
            window.on_interact.forEach((f) => f());
            if (kind === "Jump") {
              // ensure that it is not used
              interpret([[kind, target]], parent, null);
            } else {
              interpret([[kind, target]], parent, () => {});
            }
          };
          e.textContent = instr[1];
          parent.appendChild(e);
        }
        break;
      case "Interpolate":
        {
          let d = document.createElement("span");
          let v;
          try {
            v = eval?.(instr[1]);
          } catch (e) {
            surfaceError("interpolate", instr[1], e);
          }
          d.textContent = v + "";
          parent.appendChild(d);
        }
        break;

      default:
        break loop;
    }
  }

  // i is the index of a recursive instr, or the end of the instr list
  if (i >= instrs.length) {
    k();
    window.scrollTo({
      top: document.body.scrollHeight,
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
      on_scene_visit.forEach((f) => f(scene));
      return interpret(_scenes[scene], content, k);
    }
    case "Jump": {
      // abandon current k and instructions, go back to top element
      let scene = current[1];
      on_scene_visit.forEach((f) => f(scene));
      return interpret(_scenes[scene], content, () => {});
    }
    case "JumpDynamic": {
      let scene;
      try {
        scene = eval?.(current[1]);
      } catch (e) {
        surfaceError("JumpDynamic", current[1], e);
      }
      on_scene_visit.forEach((f) => f(scene));
      return interpret(_scenes[scene], content, () => {});
    }
    case "Meta":
      let s;
      let instrs;
      try {
        s = eval?.(current[1]);
        if (s === undefined) {
          s = "";
        }
        // console.log("meta result", s);
        instrs = Fable.parse(s);
        if (instrs.length) {
          instrs = instrs[0].cmds;
          // console.log("meta produced", instrs);
          interpret(instrs, parent, () => {
            interpret(rest, parent, k);
          });
        } else {
          interpret(rest, parent, k);
        }
      } catch (e) {
        surfaceError("meta", current[1], s, instrs, e);
      }
      break;
    case "Para":
      {
        if (current[0].length) {
          let d;
          if (Fable.mayHaveText(current)) {
            // removes unneccessary divs
            d = document.createElement("div");
            parent.appendChild(d);
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
        parent.appendChild(ul);
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
        let extra = Fable.recursivelyAddChoices((s) => _scenes[s], more);

        for (const item of alts.concat(extra)) {
          if (!item.sticky) {
            let id = `c${fresh++}`;
            window.choice_state[id] = false;
            item.code.push(["Run", `window.choice_state.${id} = true;`]);
            item.guard.unshift(`!window.choice_state.${id}`);
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
          // console.log("choice generated from", item);
          let li = document.createElement("li");
          ul.appendChild(li);
          let a = document.createElement("a");
          a.href = "#";
          a.classList.add("choice");
          links.push(a);
          li.appendChild(a);
          a.onclick = (ev) => {
            ev.preventDefault();
            internal.choice_history.push(a.textContent);
            informParentChoice(a.textContent);
            window.on_interact.forEach((f) => f());
            if (choices_disappear) {
              parent.removeChild(ul);
            } else {
              indicate_clicked(a);
            }
            // if (item.code.length > 0) {
            // we want to separate code and rest because we don't want to create an empty div for a code instr that doesn't have any output
            interpret(item.code, document.createElement("div"), () => {
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
          maybeTakeChoice(a);
        }
      }
      break;
    default:
      throw `unknown kind ${current[0]}`;
  }
}

function render(s) {
  let cmds;
  if (typeof s === "string") {
    cmds = Fable.parse(s);
    if (!cmds.length) {
      return;
    }
    cmds = cmds[0].cmds;
  } else {
    // take it as a scene (a list of commands)
    cmds = s;
  }
  if (Fable.containsControlChange(cmds)) {
    surfaceError("render cannot be used to jump", cmds);
  } else {
    interpret(cmds, content, () => {});
  }
}

function render_scene(s) {
  on_scene_visit.forEach((f) => f(s));
  render(_scenes[s]);
}

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
  let runtime_error = !!document.querySelectorAll(".error").length;
  let user_defined_error = bug_detectors.some((b) => b());
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
  if (!elts.length) {
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

function isStandalone() {
  return !inIFrame();
}

function inIFrame() {
  try {
    return window.self !== window.top;
  } catch (e) {
    return true;
  }
}
