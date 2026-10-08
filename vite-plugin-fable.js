import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import {
  createReadStream,
  existsSync,
  statSync,
  readFileSync,
  readdirSync,
  realpathSync,
} from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { styleText } from "node:util";

// wraps an async fn so that calls made while it is running are merged into a single follow-up call once it finishes.
// e.g. a rebuild occurs, fable runs. subsequent rebuilds set pending. then when the first rebuild is done, a second run (only one) is started for all the pending ones.
function coalesce(fn, merge) {
  let running = false;
  let pending = null;
  return async function run(arg) {
    if (running) {
      pending = pending === null ? arg : merge(pending, arg);
      return;
    }
    running = true;
    try {
      await fn(arg);
    } finally {
      running = false;
      if (pending !== null) {
        const next = pending;
        pending = null;
        run(next);
      }
    }
  };
}

export default function markdownCompilerPlugin(options = {}) {
  const {
    input,
    outDir,
    command, // debounce: debounceMs = 120
    // extensions of files that should also trigger a rebuild.
    // this is not tied to what the story actually references: any file
    // under the watched directories with one of these extensions counts
    watchExtensions = [".js", ".css", ".mp3"],
    // files to include in the production bundle which vite can't discover from index.html, e.g. audio only referenced from scripts
    assets = [],
  } = options;

  if (!input) throw new Error("[fable] `input` (source .md file) is required.");
  if (!outDir)
    throw new Error(
      "[fable] `outDir` (compiler output directory) is required.",
    );
  if (!command) throw new Error("[fable] `command` (CLI command) is required.");

  const srcFile = path.resolve(input);
  const buildDir = path.resolve(outDir);
  const projectRoot = process.cwd();

  function log(msg) {
    console.log(styleText("blue", `[fable] ${msg}`));
  }

  function warn(msg) {
    console.log(styleText("yellow", `[fable] ${msg}`));
  }

  const fableCmd = Array.isArray(command) ? command : command.split(/\s+/);
  const [fableBin, ...fableArgs] = fableCmd;

  function runFable() {
    if (!existsSync(srcFile)) {
      throw new Error(`[fable] Source file not found: ${srcFile}`);
    }
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

  // resolves a relative path to a project file, turning it into either a build dir file, or a file in the project root
  function findFile(rel) {
    const root = findRoot(rel);
    if (!root) return null;
    const p = path.join(root, rel);
    return statSync(p).isDirectory() ? null : p;
  }

  // outputs the directory (build or project root) of a file referred to by a relative path, or null if the file can't be found
  function findRoot(rel) {
    for (const dir of [buildDir, projectRoot]) {
      if (existsSync(path.join(dir, rel))) return dir;
    }
    return null;
  }

  return [devPlugin(), buildPlugin()];

  /* The dev plugin
    - In short, it makes vite watch the input markdown file for changes, running Fable and reloading the page.
    - Any js/css/mp3 files under (not just in) the project root or the input file's directory are also watched for changes.
    - Fable is run once on starting.
    - The plugin registers middleware which intercepts requests and serves them from Fable's build directory. This is different from how Vite works by default: Vite serves requests from the project root, where it expects to find an index.html, and lazily transforms and serves referenced files. Vite's default behaviour is a fallback for files which can't be found, e.g. js and css in the project root.
    - If only the markdown changes, the editor's fast hot reload path is used. */
  function devPlugin() {
    let server = null;
    // let debounceTimer = null;

    const MIME = {
      // ".html": "text/html; charset=utf-8", // never read
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
        return next(); // falls back to vite's static file server for the project root
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
        html = await server.transformIndexHtml(req.url, html);
        res.setHeader("Content-Type", "text/html; charset=utf-8");
        res.end(html);
      } else {
        res.setHeader("Content-Type", mimeType);
        createReadStream(filePath)
          .on("error", () => next())
          .pipe(res);
      }
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
          server.ws.send({
            type: "custom",
            event: "fable:edit",
            data: { md: readFileSync(srcFile, "utf-8") },
          });
        } else {
          // it wasn't the src md that changed, or it was and also other files were added
          server.ws.send({ type: "full-reload" });
        }
      } catch {
        // error already printed by runFable
      }
    }

    // running fable may take time. if more events arrive then, we should re-run fable and merge the results
    const rebuildCoalesced = coalesce(rebuild, (a, b) => a && b);

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

    return {
      name: "fable:dev",
      apply: "serve",

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
        // log("Initial build...");
        await runFable();
      },

      configureServer(s) {
        server = s;

        // vite only watches its root by default, so also watch the story and its directory in case referenced files live outside the root. this is still a heuristic
        server.watcher.add([srcFile, path.dirname(srcFile)]);

        server.watcher.on("change", (changedPath) => {
          const resolved = path.resolve(changedPath);

          // never react to files Fable writes, otherwise we loop forever
          if (resolved === buildDir || resolved.startsWith(buildDir + path.sep))
            return;

          // rebuild on the source markdown, or on any file whose
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

          // with coalesce (which guarantees no overlapping builds), we don't need debounce for correctness, only to avoid double builds for when multiple file events arrive at once

          rebuildCoalesced(isSrc);

          // }, debounceMs);
        });

        // https://vite.dev/guide/api-plugin#configureserver
        // Register middleware here, so it runs before Vite's internal middleware
        server.middlewares.use(serveFromBuildDir);
      },
    };
  }

  /* The build plugin
    - In short, it runs Fable, then has Vite bundle and minify the result for deployment, in a self-contained dist directory.
    - The build directory is made Vite's root, so that Fable's index.html is the entry point.
    - Fable itself is run on starting, as in dev.
    - Takes every file referenced from index.html, concatenates them in order into one script and minified, then emitted as story.bundle.js, then rewrites the html to point to this. */
  function buildPlugin() {
    let bundledSource = null;
    const bundledScript = "story.bundle.js";

    async function loadVite() {
      try {
        // works if vite is an npm dep
        return await import("vite");
      } catch {
        // resolve from global install...
        const cli = realpathSync(process.argv[1]);
        return await import(createRequire(cli).resolve("vite"));
      }
    }

    return {
      name: "fable:build",
      apply: "build",

      // make vite use the build dir as root (and the index.html there as entry point)
      // output to dist
      config() {
        return {
          root: buildDir,
          build: {
            outDir: path.resolve(projectRoot, "dist"),
            emptyOutDir: true,
          },
        };
      },

      // run fable before everything starts
      async buildStart() {
        await runFable();
      },

      // turns imports into paths
      resolveId(id, importer) {
        // returning undefined continues vite's resolution process.
        // check if referenced by index.html
        if (importer !== path.join(buildDir, "index.html")) return;
        // look in build dir
        if (existsSync(path.join(buildDir, id))) return;
        // otherwise, look outside the build dir
        return findFile(id) ?? undefined;
      },

      // rewriting html
      transformIndexHtml: {
        // run before vite's processing, so script tags are still present
        order: "pre",

        async handler(html) {
          // collect classic scripts without type="module", find them in either build dir or project root, and read their text, in source order
          const classic =
            /<script\b(?![^>]*type="module")[^>]*\bsrc="([^"]+)"[^>]*><\/script>\s*/g;
          const sources = [];
          for (const [, src] of html.matchAll(classic)) {
            const file = findFile(src);
            if (!file) throw new Error(`[fable] script not found: ${src}`);
            sources.push(readFileSync(file, "utf-8"));
          }

          // bundle, then minify them.
          // minify is the oxc minifier in vite 8. it's still technically experimental. we use it because it keeps top-level names.
          const { minify } = await loadVite();
          // store here for generateBundle to output
          bundledSource = (await minify(bundledScript, sources.join(";\n")))
            .code;

          // rewrite html, replacing the last script tag and removing the test
          let remaining = sources.length;
          return html.replace(classic, () =>
            --remaining === 0
              ? `<script src="${bundledScript}"></script>\n`
              : "",
          );
        },
      },

      // called just before files are written to dist
      generateBundle() {
        // copy all files referenced in assets
        for (const rel of assets) {
          const root = findRoot(rel);
          if (!root) throw new Error(`[fable] asset not found: ${rel}`);
          const abs = path.join(root, rel);
          const files = statSync(abs).isDirectory()
            ? readdirSync(abs, { recursive: true }).map((f) =>
                path.join(rel, f),
              )
            : [rel];
          for (const f of files) {
            const file = path.join(root, f);
            if (!statSync(file).isFile()) continue;
            this.emitFile({
              type: "asset",
              fileName: f.split(path.sep).join("/"),
              source: readFileSync(file),
            });
          }
        }

        // write the script
        this.emitFile({
          fileName: bundledScript,
          source: bundledSource,
        });
      },
    };
  }
}
