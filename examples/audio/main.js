// https://cdn.jsdelivr.net/gh/Subsussp/THE@gh-pages/music/Farfromanyroad.mp3
// https://cdn.jsdelivr.net/gh/sh20raj/AudiPlay/Ark.mp3
// https://cdn.jsdelivr.net/gh/chillsocial/ChillApps@main/Roblox/audio.mp3

const stinger =
  "https://cdn.jsdelivr.net/npm/sample-audio-files@1.0.7/media/Lee_Smolin_Physics_Envy_and_Economic_Theory-cWn86ESze6M_mono_1st_few_seconds.wav";

const loop =
  "https://cdn.jsdelivr.net/gh/Subsussp/THE@gh-pages/music/sample1.mp3";

const loop_large =
  "https://cdn.jsdelivr.net/npm/sample-audio-files@1.0.7/media/Justice_Genesis_8bit_mono-y6iHYTjEyKU.wav";

async function init() {
  await FableAudio.initialize({
    stinger,
    loop,
  });

  // defer loading this
  FableAudio.loadManifest({
    loop_large,
  });

  window.afterRender = () => {
    FableAudio.reconcile();
  };
}
