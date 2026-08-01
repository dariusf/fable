/// <reference path="./fable.d.ts" />

// * Environment predicates

// true if we are running in a html page or on itch
// false if we are running in the editor
function isStandalone() {
  return !inIFrame() || location.host.indexOf("itch") > -1;
}

function isInDev() {
  return (
    location.host.indexOf("localhost") > -1 ||
    location.host.indexOf("127.0.0.1") > -1 ||
    location.protocol === "file:"
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

/** @param {string} s */
function smartypants(s) {
  // the order matters
  return s
    .replace(/---/g, "—")
    .replace(/--/g, "–")
    .replace(/\.\.\./g, "…")
    .replace(/'([st])/g, "’$1")
    .replace(/(^|[ \t\n(])'/g, "$1‘")
    .replace(/'/g, "’")
    .replace(/(^|[ \t\n(])"/g, "$1“")
    .replace(/"/g, "”");
}

/**
 * smartypants for raw HTML, so only the text between tags is transformed
 * @param {string} html */
function smartypantsHtml(html) {
  return html
    .split(/(<[^>]*>)/)
    .map((part) => (part.startsWith("<") ? part : smartypants(part)))
    .join("");
}

/** @param {string} string */
function capitalize(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

/** @param {string} label */
function jump(label) {
  return `\`->${label}\``;
}

/** @param {string} label */
function tunnel(label) {
  return `\`>->${label}\``;
}

/** @template T @param {T[]} xs @returns {T} */
function randomFrom(xs) {
  return xs[randomExcl(0, xs.length)];
}

/**
 * @template {unknown[]} A
 * @param {(...args: A) => void} fn
 * @param {number} delay
 * @returns {(...args: A) => void}
 */
function debounce(fn, delay) {
  /** @type {ReturnType<typeof setTimeout>} */
  let timeoutId;
  return (...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

/**
 * @param {string} id
 * @param {string} val */
function putValueInSelect(id, val) {
  const selectElt = /** @type {HTMLSelectElement | null} */ (
    document.getElementById(id)
  );
  if (selectElt) {
    selectElt.value = val;
  }
}

// tap an element 5 times in 2 seconds to offer a game reset
/** @param {HTMLElement} element @param {() => void} reset */
function enableResetDetector(element, reset) {
  const REQUIRED_TAPS = 5;
  const TIME_WINDOW_MS = 2000;

  /** @type {number[]} */
  let taps = [];

  element.addEventListener("click", () => {
    const now = performance.now();
    taps.push(now);
    taps = taps.filter((t) => now - t < TIME_WINDOW_MS);
    if (taps.length >= REQUIRED_TAPS) {
      taps = [];
      if (confirm("Start over?")) {
        reset();
      }
    }
  });
}
