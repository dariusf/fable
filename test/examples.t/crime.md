
# beginning

```js
var turns = 0;
function on_interact() {
  turns++;
}

// knowledge subsystem
bed_knowledge = {meta: ['neatly_made', 'crumpled_duvet', 'hastily_remade', 'body_on_bed', 'murdered_in_bed', 'murdered_while_asleep']};
for (let i of bed_knowledge.meta) {
  bed_knowledge[i] = false;
}
function reached(st, which) {
  return st[which];
}
function reach(st, which) {
  let i = st.meta.indexOf(which);
  if (i < 0) {
    throw 'fail';
  }
  console.log('slice',which,i,st.meta.slice(0, i+1));
  for (let e of st.meta.slice(0, i+1)) {
    st[e] = true;
  }
}
```

The bedroom. This is where it happened. Now to look for clues. `jump murder_scene`

# murder_scene

- The bed... `1` The bed was low to the ground, but not so low something might not roll underneath. It was still neatly made. `jump prebed`
- The desk...
- The window...

`jump murder_scene`

# prebed

```js
var turn_entered_room = turns;
reach(bed_knowledge, 'neatly_made');
var bed_state = 'made_up';
```

`jump bed`

# bed

- Lift the bedcover `reach(bed_knowledge, 'crumpled_duvet'); bed_state = 'covers_shifted'` I lifted back the bedcover. The duvet underneath was crumpled.

- `guard reached(bed_knowledge, 'crumpled_duvet')` Remove the cover `reach(bed_knowledge, 'hastily_remade'); bed_state = 'covers_off'` Careful not to disturb anything beneath, I removed the cover entirely. The duvet below was rumpled.

    Not the work of the maid, who was conscientious to a point. Clearly this had been thrown on in a hurry.

- `guard bed_state == 'covers_off'` Pull back the duvet `reach(bed_knowledge, 'body_on_bed'); bed_state = 'bloodstain_visible'` I pulled back the duvet. Beneath it was a sheet, sticky with blood.

    Either the body had been moved here before being dragged to the floor - or this is was where the murder had taken place.

- `guard bed_state != 'made_up'` Remake the bed `bed_state = 'made_up'` Carefully, I pulled the bedsheets back into place, trying to make it seem undisturbed.
  <!-- seems like there's a bug here, shouldn't be able to pull back duvet after making -->

- Test the bed `1`  I pushed the bed with spread fingers. It creaked a little, but not so much as to be obnoxious.

- Look under the bed `1` Lying down, I peered under the bed, but could make nothing out.

- `guard (turns-turn_entered_room)>1` Something else? `1` I took a step back from the bed and looked around. `jump murder_scene`

`jump bed`