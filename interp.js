let scenes = {};
let content = document.querySelector("#content");

function main() {
  for (const scene of data) {
    scenes[scene.name] = scene.cmds;
  }
  interpret(data[0].cmds, content);
}

function interpret(instrs, parent) {
  for (const instr of instrs) {
    // console.log("interpret", instr[0], parent);
    switch (instr[0]) {
      case "Run":
        // console.log("run", instr[1]);
        try {
          // Function(instr[1])();
          eval?.(instr[1]);
        } catch (e) {
          print(e);
        }
        break;
      // case "Break":
      //   {
      //     let d = document.createElement("br");
      //     parent.appendChild(d);
      //   }
      //   break;
      case "Para":
        {
          let d = document.createElement("div");
          interpret(instr[1], d);
          parent.appendChild(d);
        }
        break;
      case "Text":
        {
          let d = document.createElement("span");
          d.textContent = instr[1];
          parent.appendChild(d);
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
            v = "(" + e + ")";
          }
          d.textContent = v + "";
          parent.appendChild(d);
        }
        break;
      case "Choices":
        {
          let alts = instr[1];
          let ul = document.createElement("ul");
          let items = [];
          for (const item of alts) {
            let li = document.createElement("li");
            li.textContent = item.initial;
            items.push(li);
          }
          parent.appendChild(ul);
        }
        break;
      default:
        throw `unknown kind ${instr[0]}`;
    }
  }
}
