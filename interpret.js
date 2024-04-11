let scenes = {};
let content = document.querySelector("#content");
window.on_interact = () => {};
window.choice_state = {};
let fresh = 0;
let choices_disappear = true;

function main() {
  for (const scene of data) {
    scenes[scene.name] = scene.cmds;
  }
  let scene = data[0].name;
  interpret(scenes[scene], content, () => {});
}

function interpret(instrs, parent, k) {
  loop: for (var i = 0; i < instrs.length; i++) {
    const instr = instrs[i];
    // console.log("interpret", instr, parent);
    switch (instr[0]) {
      case "Meta":
        try {
          let s = eval?.(instr[1]);
          let instrs = Scripture.parse(s)[0].cmds;
          // console.log("meta produced", instrs);
          interpret(instrs, parent, () => {});
        } catch (e) {
          // TODO surface errors
          console.error("failure", instr[1], e);
        }
        break;
      case "Run":
        try {
          eval?.(instr[1]);
        } catch (e) {
          console.error("failure", instr[1], e);
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
          parent.appendChild(document.createElement("br"));
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
            window.on_interact();
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
            v = "(" + e + ")";
            console.error("failure", instr[1], e);
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

  switch (current[0]) {
    case "Jump": {
      // abandon current k and instructions, go back to top element
      return interpret(scenes[current[1]], content, () => {});
    }
    case "Para":
      {
        if (current[0].length > 0) {
          let d;
          if (Scripture.mayHaveText(current)) {
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
        let extra = Scripture.recursivelyAddChoices((s) => scenes[s], more);
        extra.forEach((c) => alts.push(c));

        for (const item of alts) {
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
              console.error(e);
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
          links.push(a);
          li.appendChild(a);
          a.onclick = (ev) => {
            ev.preventDefault();
            window.on_interact();
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
          interpret(item.initial, a, (x) => x);
        }
      }
      break;
    default:
      throw `unknown kind ${current[0]}`;
  }
}

function render(s) {
  interpret(s, content, () => {});
}
