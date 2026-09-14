---
head: |
    <script src="main.js"></script>
---

```js
FableAudio.set([]);
```

`->start`

# start

- `sticky` Play some audio `->stinger`
- `sticky` Loop 1 `->loop1`
- `sticky` Loop 2 `->loop2`

<!-- - Clear saved data `->clear` -->

<!-- # clear -->

<!-- `clearSaveData(); window.location.reload()` -->

# stinger

```js
FableAudio.set({stinger: { loop: false }});
```

Stinger played

`->start`

# loop1

Short loop

```js
FableAudio.set(["loop"]);
```

`->start`

# loop2

Long loop

```js
FableAudio.set(["loop_large"]);
```

`->start`