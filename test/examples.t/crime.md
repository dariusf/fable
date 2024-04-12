
# beginning

```js
var turns = 0;
function on_interact() {
  turns++;
}

var bedroom_light_seen = false;
var bedroom_light_on = false;
var bedroom_light_loc = 'desk'; // desk, floor, bed

var knife_loc = 'under_bed'; // under_bed, floor, joe

var go_back_to = null; // for compare_prints

// knowledge subsystem
bed_knowledge = {meta: ['neatly_made', 'crumpled_duvet', 'hastily_remade', 'body_on_bed', 'murdered_in_bed', 'murdered_while_asleep']};
knife_knowledge = {meta: ['prints_on_knife', 'joe_seen_prints_on_knife', 'joe_wants_better_prints', 'joe_got_better_prints']};
window_knowledge = {meta: ['steam_on_glass', 'fingerprints_on_glass', 'fingerprints_on_glass_match_knife']};

for (let k of [bed_knowledge, knife_knowledge, window_knowledge]) {
  for (let i of k.meta) {
    k[i] = false;
  }
}

function reached(st, which) {
  return st[which];
}

function reach(st, which) {
  let i = st.meta.indexOf(which);
  if (i < 0) {
    throw 'fail';
  }
  for (let e of st.meta.slice(0, i+1)) {
    st[e] = true;
  }
}
```

The bedroom. This is where it happened. Now to look for clues. `jump murder_scene`

# murder_scene

```js
go_back_to = 'murder_scene'
```

- `?bedroom_light_seen` `more seen_light`
- `more compare_prints`
- The bed... `1` The bed was low to the ground, but not so low something might not roll underneath. It was still neatly made. `jump prebed`
- The desk...
- The window...

`jump murder_scene`

# prebed

```js
var turn_entered_room = turns;
reach(bed_knowledge, 'neatly_made');
var bed_state = 'made_up'; // made_up, covers_shifted, covers_off, bloodstain_visible
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

# seen_light

- `?!bedroom_light_on` Turn on lamp `1` `>->operate_lamp`

- `? bedroom_light_loc === 'bed'  && bed_state == 'bloodstain_visible'`
    Move the light to the bed `bedroom_light_loc = 'bed'`

    I moved the light over to the bloodstain and peered closely at it. It had soaked deeply into the fibres of the cotton sheet.
    There was no doubt about it. This was where the blow had been struck. `reach(bed_knowledge, murdered_in_bed)`

- `? bedroom_light_loc != 'desk' && (turn-turn_moved_light_to_floor) >= 2`
    Move the light back to the desk
    `bedroom_light_loc = 'desk'`
    I moved the light back to the desk, setting it down where it had originally been.
- `? bedroom_light_loc != 'floor' && darkunder`
    Move the light to the floor
    `bedroom_light_loc != 'floor'`
    I picked the light up and set it down on the floor.
    `var turn_moved_light_to_floor = turns;`

`->murder_scene`

# compare_prints

- `? reached(window_knowledge, 'fingerprints_on_glass') && reached(knife_knowledge, 'prints_on_knife') && !reached(window_knowledge, 'fingerprints_on_glass_match_knife'))`
    Compare the prints on the knife and the window `1`
    Holding the bloodied knife near the window, I breathed to bring out the prints once more, and compared them as best I could.
    Hardly scientific, but they seemed very similar - very similiar indeed.
    `reach(window_knowledge, 'fingerprints_on_glass_match_knife')`
    `->$go_back_to`

# operate_lamp

I flicked the light switch.

```
if (bedroom_light_on) {
  render([['Text', 'The bulb fell dark']]);
  bedroom_light_on = false;
} else {
  if (bedroom_light_loc === 'floor') {
    render([['Text', 'A little light spilled under the bed.']]);
  } else if (bedroom_light_loc === 'desk') {
    render([['Text', 'The light gleamed on the polished tabletop.']]);
  }
  bedroom_light_on = true;
}
```