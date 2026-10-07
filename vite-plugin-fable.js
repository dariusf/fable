import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import {
  createReadStream,
  existsSync,
  statSync,
  readFileSync,
  readdirSync,
} from "node:fs";
import path from "node:path";
import { styleText } from "node:util";

/*

  How the plugin works:

  - It makes vite watch the input markdown file. When it changes, the plugin runs Fable and reloads the page.
  - It registers middleware which intercepts requests and serves them from Fable's build directory. This is different from how Vite works by default: Vite serves requests from the project root, where it expects to find an index.html, and lazily transforms and serves referenced files.
  - If only the markdown changes, the editor's fast hot reload path is used.

*/

export default function markdownCompilerPlugin(options = {}) {
  const {
    input,
    outDir,
    command, // debounce: debounceMs = 120
    // extensions of referenced files that should also trigger a rebuild
    watchExtensions = [".js", ".css", ".mp3"],
  } = options;

  if (!input) throw new Error("[fable] `input` (source .md file) is required.");
  if (!outDir)
    throw new Error(
      "[fable] `outDir` (compiler output directory) is required.",
    );
  if (!command) throw new Error("[fable] `command` (CLI command) is required.");

  const srcFile = path.resolve(input);
  const buildDir = path.resolve(outDir);

  let viteServer = null;
  // let debounceTimer = null;

  function log(msg) {
    console.log(styleText("blue", `[fable] ${msg}`));
  }

  function warn(msg) {
    console.log(styleText("yellow", `[fable] ${msg}`));
  }

  const MIME = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".json": "application/json",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".ttf": "font/ttf",
    ".mp3": "audio/mpeg",
  };

  async function serveFromBuildDir(req, res, next) {
    let urlPath = req.url.split("?")[0];
    if (urlPath === "/") urlPath = "/index.html";

    const filePath = path.join(buildDir, urlPath);
    // log(`served: ${urlPath}`);

    // if not found, pass through.
    // things like vite's internal /@ files go in here
    if (!existsSync(filePath) || statSync(filePath).isDirectory()) {
      // log(`not handled: ${urlPath}`);
      return next();
    }

    const ext = path.extname(filePath).toLowerCase();
    const mimeType = MIME[ext] ?? "application/octet-stream";

    res.setHeader("Cache-Control", "no-store");

    // inject vite's HMR client into index.html
    if (ext === ".html") {
      let html = readFileSync(filePath, "utf-8");
      // html = html.replace(
      //   "<head>",
      //   `<head><script type="module" src="/@vite/client"></script>`,
      // );
      html = await viteServer.transformIndexHtml(req.url, html);
      res.setHeader("Content-Type", "text/html; charset=utf-8");
      res.end(html);
    } else {
      res.setHeader("Content-Type", mimeType);
      createReadStream(filePath)
        .on("error", () => next())
        .pipe(res);
    }
  }

  const fableCmd = Array.isArray(command) ? command : command.split(/\s+/);
  const fableBin = fableCmd[0];
  const fableArgs = fableCmd.slice(1);

  function runFable() {
    return new Promise((resolve, reject) => {
      log(`${fableBin} ${fableArgs.join(" ")} -o ${outDir} ${input}`);

      const proc = spawn(fableBin, [...fableArgs, "-o", buildDir, srcFile], {
        stdio: "inherit",
        shell: process.platform === "win32",
      });

      proc.on("error", (err) => {
        warn(`Failed to start compiler: ${err.message}`);
        reject(err);
      });

      proc.on("close", (code) => {
        if (code === 0) resolve();
        else {
          warn(`Compiler exited with code ${code}`);
          reject(new Error(`Compiler exited ${code}`));
        }
      });
    });
  }

  const storyOutputs = ["story.js", "graph.dot", "graph.mmd"];
  function fingerprintBuildDir() {
    const hash = createHash("sha1");
    if (!existsSync(buildDir)) return hash.digest("hex");
    for (const name of readdirSync(buildDir).sort()) {
      // ignore outputs in the fingerprint, because we only want to detect if the inputs have changed
      if (storyOutputs.includes(name)) continue;
      const file = path.join(buildDir, name);
      if (!statSync(file).isFile()) continue;
      hash.update(name).update(readFileSync(file));
    }
    return hash.digest("hex");
  }

  // isSrc is true if the main story.md changed
  async function rebuild(isSrc) {
    try {
      const before = fingerprintBuildDir();
      await runFable();
      // log("build succeeded, triggering reload");
      if (isSrc && before === fingerprintBuildDir()) {
        // only src md changed, so take the fast path
        viteServer.ws.send({
          type: "custom",
          event: "fable:edit",
          data: { md: readFileSync(srcFile, "utf-8") },
        });
      } else {
        // it wasn't the src md that changed, or it was and also other files were added
        viteServer.ws.send({ type: "full-reload" });
      }
    } catch {
      // error already printed by runCompiler
    }
  }

  const hmrId = "virtual:fable-hmr";
  const resolvedHmrId = "\0" + hmrId;
  // import.meta.hot exists only in a page with vite's dev client.
  const hmrClient = `
if (import.meta.hot) {
  import.meta.hot.on("fable:edit", ({ md }) => {
    try {
      postStatus(applyEdit(Fable.parse(md)));
    } catch (e) {
      console.error("fable:edit", e);
    }
  });
}
`;

  // plugin object
  return {
    name: "fable",

    // runs when something is imported
    resolveId(id) {
      if (id === hmrId) return resolvedHmrId;
    },

    // runs when vite needs the source code for an unresolved id
    load(id) {
      if (id === resolvedHmrId) return hmrClient;
    },

    // called when vite processes a html page.
    // see other call to transformIndexHtml
    transformIndexHtml() {
      // injects our module into the page.
      // __x00__ is vite's URL-safe encoding of the \0 prefix
      return [
        {
          tag: "script",
          attrs: { type: "module", src: "/@id/__x00__" + hmrId },
          injectTo: "head",
        },
      ];
    },

    async buildStart() {
      if (!existsSync(srcFile)) {
        throw new Error(`[fable] Source file not found: ${srcFile}`);
      }
      // log("Initial build…");
      await runFable();
    },

    configureServer(server) {
      viteServer = server;

      server.watcher.add(srcFile);

      server.watcher.on("change", (changedPath) => {
        const resolved = path.resolve(changedPath);

        // never react to files Fable writes, otherwise we loop forever
        if (resolved === buildDir || resolved.startsWith(buildDir + path.sep))
          return;

        // rebuild on the source markdown, or on any referenced file whose
        // extension we watch (js/css/mp3 by default)
        const isSrc = resolved === srcFile;
        const isWatchedRef = watchExtensions.includes(
          path.extname(resolved).toLowerCase(),
        );
        if (!isSrc && !isWatchedRef) return;

        // debounce not strictly needed, unless we get more events than we want
        // clearTimeout(debounceTimer);
        // debounceTimer = setTimeout(() => {
        // log(`"${input}" changed — rebuilding…`);

        // it's possible this triggers again before the compiler finishes.
        // it seems too rare to matter though, and it seems like it should converge eventually.
        // debounce lowers the chance of this.
        rebuild(isSrc);

        // }, debounceMs);
      });

      // https://vite.dev/guide/api-plugin#configureserver
      // Register middleware here, so it runs before Vite's internal middleware
      server.middlewares.use(serveFromBuildDir);
    },
  };
}
