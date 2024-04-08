let scenes = {};
let content = document.querySelector("#content");

// function Goto(scene) {
//   this.scene = scene;
// }
// function jump(scene) {
//   // throw new Goto(scene);
//   interpret(scenes[scene], content, () => {});
// }

function main() {
  for (const scene of data) {
    scenes[scene.name] = scene.cmds;
  }
  let scene = data[0].name;
  // while (true) {
  // try {
  interpret(scenes[scene], content, () => {});
  // break;
  // } catch (e) {
  //   if (e instanceof Goto) {
  //     scene = e.scene;
  //   } else {
  //     throw e;
  //   }
  // }
  // }
}

function interpret(instrs, parent, k) {
  loop: for (var i = 0; i < instrs.length; i++) {
    const instr = instrs[i];
    // console.log("interpret", instr, parent);
    switch (instr[0]) {
      case "Meta":
        try {
          let s = eval?.(instr[1]);
          let instrs = scripture_parse(s)[0].cmds;
          console.log("meta produced", instrs);
          interpret(instrs, parent, () => {});
        } catch (e) {
          // TODO surface errors
          console.log(e);
        }
        break;
      case "Run":
        try {
          eval?.(instr[1]);
        } catch (e) {
          console.log(e);
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
      case "LinkCode":
      case "LinkJump":
        {
          let e = document.createElement("a");
          e.href = "#";
          let kind = instr[0] === "LinkCode" ? "Run" : "Jump";
          let target = instr[0] === "LinkCode" ? instr[2] + "()" : instr[2];
          e.onclick = () => {
            interpret([[kind, target]], parent, () => {});
          };
          e.textContent = instr[1];
          parent.appendChild(e);
        }
        break;
      case "Interpolate":
        {
          let d = document.createElement("span");
          // console.log("eval", instr[1]);
          let v;
          try {
            // v = Function(instr[1])();
            v = eval?.(instr[1]);
          } catch (e) {
            // if (e instanceof Goto) {
            //   throw e;
            // }
            v = "(" + e + ")";
          }
          d.textContent = v + "";
          parent.appendChild(d);
        }
        break;
      // case "Break":
      //   {
      //     let d = document.createElement("br");
      //     parent.appendChild(d);
      //   }
      //   break;

      // These have recursion

      // case "Para":
      // {
      //   let d = document.createElement("div");
      //   interpret(instr[1], d);
      //   parent.appendChild(d);
      // }
      // break loop;
      // case "Choices":
      // {
      //   let alts = instr[1];
      //   let ul = document.createElement("ul");
      //   let items = [];
      //   for (const item of alts) {
      //     let li = document.createElement("li");
      //     li.textContent = item.initial;
      //     items.push(li);
      //   }
      //   parent.appendChild(ul);
      // }
      default:
        break loop;
      // throw `unknown kind ${instr[0]}`;
    }
  }

  // i is the index of a recursive instr, or the end of the instr list
  if (i >= instrs.length) {
    return k();
  }
  let current = instrs[i];
  let rest = instrs.slice(i + 1);

  switch (current[0]) {
    case "Jump":
      {
        return interpret(scenes[current[1]], content, () => {});
        // abandon current k and instructions, go back to top element
      }
      break;
    case "Para":
      {
        if (current[1].length > 0) {
          let d = document.createElement("div");
          parent.appendChild(d);
          interpret(current[1], d, () => {
            interpret(rest, parent, k);
          });
        } else {
          interpret(rest, parent, k);
        }
      }
      break;
    case "Choices":
      {
        let alts = current[1];
        let ul = document.createElement("ul");
        parent.appendChild(ul);
        let links = [];
        let indicate_clicked = (clicked) => {
          links.forEach((a) => {
            if (a !== clicked) {
              a.removeAttribute("href");
            }
            a.onclick = null;
          });
        };
        // let after = document.createElement("div");
        // parent.appendChild(after);
        for (const item of alts) {
          let li = document.createElement("li");
          ul.appendChild(li);
          let a = document.createElement("a");
          a.href = "#";
          links.push(a);
          li.appendChild(a);
          a.onclick = () => {
            indicate_clicked(a);
            interpret(item.code, document.createElement("div"), () => {
              interpret([item.rest], parent, () => {
                interpret(rest, parent, k);
              });
            });
          };
          interpret(item.initial, a, (x) => x);
        }
      }
      break;
    default:
      throw `unknown kind ${current[0]}`;
  }
}
