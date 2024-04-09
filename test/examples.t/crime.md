
# beginning

```js
var turns = 0;
function on_interact() {
  turns++;
}
```

The bedroom. This is where it happened. Now to look for clues. `jump murder_scene`

# murder_scene

- The bed... `1` The bed was low to the ground, but not so low something might not roll underneath. It was still neatly made. `jump bed`
- The desk...
- The window...

`jump murder_scene`

---

# bed

```js
var crumpled_duvet = false;
var bed_state = null;
```

- Lift the bedcover `1` I lifted back the bedcover. The duvet underneath was crumpled. `crumpled_duvet = true; bed_state = 'covers_shifted'`
- Test the bed `1`  I pushed the bed with spread fingers. It creaked a little, but not so much as to be obnoxious.
- Look under the bed `1` Lying down, I peered under the bed, but could make nothing out.

`jump bed`