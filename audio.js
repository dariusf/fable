(function () {
  "use strict";

  // https://developer.mozilla.org/en-US/docs/Web/API/AudioContext
  let ctx;

  // https://developer.mozilla.org/en-US/docs/Web/API/GainNode
  let master;

  let tracks = {};
  let playbacks = [];

  const MUTED = 0.0001; // -80 dB: exp ramps can't target exactly 0
  const FADE_FLOOR = 0.01; // -40 dB: higher so we don't spend most of an exponential ramp in silence

  // A playback is an instance of a playing track. It starts muted.
  function play(name, loop, at) {
    const buffer = tracks[name];
    if (!buffer) {
      throw new Error(`unknown track ${name}`);
    }

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(MUTED, at);
    gain.connect(master);

    const src = ctx.createBufferSource();
    src.buffer = buffer;
    src.loop = loop;
    src.connect(gain);

    const p = {
      name,
      src,
      gain,
      startTime: at,
      endTime: loop ? null : at + buffer.duration,
      muted: true, // last intent expressed, different from gain at this moment, which may be changing
      volume: MUTED,
    };
    src.onended = () => {
      src.disconnect();
      gain.disconnect();
      removePlayback(p);
    };
    src.start(at);
    playbacks.push(p);
    return p;
  }

  function fadeTo(p, from, to, over, at) {
    const g = p.gain.gain;
    g.cancelScheduledValues(at);
    g.setValueAtTime(from, at);
    g.exponentialRampToValueAtTime(to, at + over);
    p.muted = to <= MUTED;
    p.volume = to;
  }

  function fadeIn(p, to, over, at) {
    fadeTo(p, FADE_FLOOR, to, over, at);
  }

  function fadeOut(p, over, at) {
    fadeTo(p, Math.max(p.gain.gain.value, MUTED), MUTED, over, at);
  }

  // A playback that has begun to fade out is considered gone. Returns when it will be silent.
  function stop(p, over) {
    removePlayback(p);
    const now = ctx.currentTime;
    if (p.startTime >= now) {
      // not audible yet. cancel outright rather than fading silence
      p.src.stop(p.startTime);
      return now;
    }
    fadeOut(p, over, now);
    p.src.stop(now + over);
    return now + over;
  }

  async function initialize(manifest = {}) {
    if (ctx) {
      throw new Error(`loadManifest(${manifest}): can only be called once`);
    }
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    master = ctx.createGain();
    master.connect(ctx.destination);
    await loadManifest(manifest);
  }

  async function loadManifest(manifest) {
    await Promise.all(
      Object.entries(manifest).map(async ([name, url]) => {
        const ATTEMPTS = 3;
        for (let i = 0; ; i++) {
          try {
            const res = await fetch(url);
            // fetch may throw or have a non-ok result
            if (!res.ok) {
              throw new Error(`${url}: ${res.status}`);
            }
            const ab = await res.arrayBuffer();
            tracks[name] = await ctx.decodeAudioData(ab);
            return;
          } catch (e) {
            if (i >= ATTEMPTS) throw e;
            await new Promise((r) => setTimeout(r, 500 * 2 ** i));
          }
        }
      }),
    );
  }

  // Returns first playback of the named track or undefined
  function livePlayback(name) {
    return playbacks.find((p) => p.name === name);
  }

  // Remove a specific playback
  function removePlayback(p) {
    playbacks = playbacks.filter((x) => x !== p);
  }

  /*

    Declarative API

    The declarative API allows stories to play sound effects (e.g. stingers) and music in a way that supports hot reloading. It supports the batching of changes that occurs when fast-forwarding through the story, e.g. many set calls, then a single reconcile.

    Mental model

    - set says what the state should be at a given point in time. reconcile then turns whatever the state is into what it should be.
    - add/remove/mute/unmute are "additive" versions of set (in that they act the state given by the last set)
    - For simplicity, transitions (fade out/in time) are associated with the action, rather than a track. This means that at a particular action, all tracks fade in/out in the same way.

    Reconciliation behaviours

    - If a track is already playing, playing it again is a no-op
    - Newly-absent/present tracks will be stopped/started, while muting/unmuting tracks will change their state
    - If a track hasn't started yet, it's cancelled and rescheduled
    - reconcile is called frequently (e.g. on user input), but not so fast that fades won't have time to complete.
    - A track is considered stopped as soon as it starts to fade out. A second reconcile during this time won't re-fade, but might restart it.

  */

  // desired state for the next reconcile.
  // maps track name to spec: { muted = false, loop = true, volume = 1 }
  // a falsy spec is treated as absent.
  let scene = {};

  // fade settings for the next reconcile
  // { fadeOut = 0, fadeIn = 0 }
  let transition = {};

  // the last scene that reconcile acted on, for not replaying one-shot tracks
  let applied = {};

  // Diffs the live playbacks against the desired state and makes all the changes
  function reconcile() {
    if (ctx.state === "suspended") ctx.resume();

    const prev = applied;
    applied = scene;
    const { fadeOut: fadeOutDur = 0, fadeIn: fadeInDur = 0 } = transition;

    // filter out falsy (absent) tracks
    const desired = {};
    for (const [name, spec] of Object.entries(scene)) {
      if (spec) desired[name] = spec;
    }

    const now = ctx.currentTime;

    // stop tracks which aren't present
    let fadeStart = now;
    const toBeStopped = playbacks.filter((p) => !desired[p.name]);
    for (const p of toBeStopped) {
      const endTime = stop(p, fadeOutDur);
      if (endTime > now) {
        fadeStart = Math.max(fadeStart, endTime);
      }
    }

    // start new ones
    for (const [name, spec] of Object.entries(desired)) {
      const { muted = false, loop = true, volume = 1 } = spec;

      let p = livePlayback(name);
      let startTime = fadeStart;
      if (p && p.startTime >= now) {
        // not started yet. replace with this instance
        startTime = Math.max(fadeStart, p.startTime);
        stop(p, 0);
        p = null;
      }

      if (!p) {
        // p is not live and may be started
        if (!loop && prev[name]) {
          // finished one-shot, skip
          delete scene[name];
          continue;
        }
        try {
          p = play(name, loop, startTime);
        } catch (e) {
          console.error(`failed to play ${name}; may not have loaded.`, e);
          continue;
        }
        if (!muted) {
          fadeIn(p, volume, fadeInDur, startTime);
        }
      } else {
        // already live, has started.
        // cases handle muted flag differing; if same, no-op
        if (p.muted && !muted) {
          fadeIn(p, volume, fadeInDur, now);
        } else if (!p.muted && muted) {
          fadeOut(p, fadeOutDur, now);
        } else if (!muted && p.volume !== volume) {
          fadeTo(p, Math.max(p.gain.gain.value, MUTED), volume, fadeInDur, now);
        }
      }
    }
  }

  function set(next, { fadeOut = 0.4, fadeIn = 0 } = {}) {
    scene = { ...normaliseNameArray(next) };
    transition = { fadeOut, fadeIn };
  }

  function add(partial, t = transition) {
    set({ ...scene, ...normaliseNameArray(partial) }, t);
  }

  function remove(names, t = transition) {
    const next = { ...scene };
    for (const name of names) delete next[name];
    set(next, t);
  }

  function withMuted(names, muted, t) {
    const next = { ...scene };
    for (const name of names) {
      if (next[name]) next[name] = { ...next[name], muted };
    }
    set(next, t);
  }

  function mute(names, t = transition) {
    withMuted(names, true, t);
  }

  function unmute(names, t = transition) {
    withMuted(names, false, t);
  }

  window.FableAudio = {
    loadManifest,
    initialize,
    set,
    add,
    remove,
    mute,
    unmute,
    reconcile,
  };

  function normaliseNameArray(ns) {
    if (Array.isArray(ns)) {
      const r = {};
      for (const n of ns) {
        r[n] = {};
      }
      return r;
    }
    return ns;
  }
})();
