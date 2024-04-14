
# beginning

```js
var turn_reaching = 0;

var inventory = new Set();

var dark_under = false;

var bedroom_light = {seen: false, on: false, loc: 'desk'}; // desk, floor, bed

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

The bedroom. This is where it happened. Now to look for clues. `->murder_scene`

# murder_scene

```js
go_back_to = 'murder_scene'
```

- `?bedroom_light.seen` `more seen_light`
- `more compare_prints`
- The bed... `1` The bed was low to the ground, but not so low something might not roll underneath. It was still neatly made. `->prebed`
- `?dark_under && bedroom_light.loc === 'floor' && bedroom_light.on`
    Look under the bed `1`
    I peered under the bed. Something glinted back at me.
    `turn_reaching = turns`

    - Reach for it `1` I fished with one arm under the bed, but whatever it was, it had been kicked far enough back that I couldn't get my fingers on it.  `->reaching`
    - `?inventory.has('cane')` Knock it with the cane `->knock_with_cane`
    - `?(turns-turn_reaching)>1` Stand up `1` I stood up once more, and brushed my coat down. `->murder_scene`

- `?turn_reaching && (turns-turn_reaching) >= 4 && inventory.has('cane')` `more knock_with_cane`

- `?knife_loc == 'floor'`
    Pick up the knife `1`
    Careful not to touch the handle, I lifted the blade from the carpet.
    `inventory.add('knife')`

- `?inventory.has('knife')`
    Look at the knife `1`
    The blood was dry enough. Dry enough to show up partial prints on the hilt!
    `reach(knife_knowledge, 'prints_on_knife')`

- The desk... `1`

    I turned my attention to the desk. A lamp sat in one corner, a neat, empty in-tray in the other. There was nothing else out.

    Leaning against the desk was a wooden cane.

    `bedroom_light.seen = true`

    `->predesk`

- `?inventory.has('cane') && turns_since('desk') <= 2` Swoosh the cane `1`
    I was still holding the cane: I gave it an experimental swoosh. It was heavy indeed, though not heavy enough to be used as a bludgeon.
    But it might have been useful in self-defence. Why hadn't the victim reached for it? Knocked it over?

- The window... `1` I went over to the window and peered out. A dismal view of the little brook that ran down beside the house.
    `->prewindow`

- `?seen('murder_scene')>=5` Leave the room `1`
    I'd seen enough. I `$bedroom_light.on ? ' switched off the lamp, then ' : ''` turned and left the room.
    `->joe_in_hall`

`->murder_scene`

# prebed

```js
var turn_entered_room = turns;
reach(bed_knowledge, 'neatly_made');
var bed_state = 'made_up'; // made_up, covers_shifted, covers_off, bloodstain_visible
```

`->bed`

# bed

- Lift the bedcover `reach(bed_knowledge, 'crumpled_duvet'); bed_state = 'covers_shifted'` I lifted back the bedcover. The duvet underneath was crumpled.

- `?reached(bed_knowledge, 'crumpled_duvet')` Remove the cover `reach(bed_knowledge, 'hastily_remade'); bed_state = 'covers_off'` Careful not to disturb anything beneath, I removed the cover entirely. The duvet below was rumpled.

    Not the work of the maid, who was conscientious to a point. Clearly this had been thrown on in a hurry.

- `?bed_state == 'covers_off'` Pull back the duvet `reach(bed_knowledge, 'body_on_bed'); bed_state = 'bloodstain_visible'` I pulled back the duvet. Beneath it was a sheet, sticky with blood.

    Either the body had been moved here before being dragged to the floor - or this is was where the murder had taken place.

- `?bed_state != 'made_up'` Remake the bed `bed_state = 'made_up'` Carefully, I pulled the bedsheets back into place, trying to make it seem undisturbed.
  <!-- seems like there's a bug here, shouldn't be able to pull back duvet after making -->

- Test the bed `1`  I pushed the bed with spread fingers. It creaked a little, but not so much as to be obnoxious.

- Look under the bed `dark_under = true;` Lying down, I peered under the bed, but could make nothing out.

- `?(turns-turn_entered_room)>1` Something else? `1` I took a step back from the bed and looked around. `->murder_scene`

`->bed`

# predesk

```js
var drawers_opened = 0;
```

`->desk`

# desk

- `?!inventory.has('cane')` Pick up the cane `inventory.add('cane')` I picked up the wooden cane. It was heavy, and unmarked.

- `?!bedroom_light.on` Turn on the lamp `1` `>->operate_lamp`

- Look at the in-tray `1`

  I regarded the in-tray, but there was nothing to be seen. Either the victim's papers were taken, or his line of work had seriously dried up. Or the in-tray was all for show.

- `sticky` `?drawers_opened<3` Open a drawer `1`

    I tried `$' ' + ['a drawer at random', 'another drawer', 'a third drawer'][drawers_opened]`. `$' ' + ['Locked', 'Also locked', 'Unsurprisingly, locked as well'][drawers_opened]`.

    `drawers_opened++`

- `?seen('desk') >= 2` Something else? `1` I took a step away from the desk once more. `->murder_scene`

`->desk`

# prewindow

```js
var window_state = 'none'; // none, steamed, steam_gone
```

`->window`

# window

```js
go_back_to = 'window';
```

- `more compare_prints`
- Look down at the brook `1` `>->downy`
- Look at the glass `see('greasy')`
    ```js ~
    if (window_state === 'steamed') {
      '`->downy`'
    } else {
      'The glass in the window was greasy. No one had cleaned it in a while, inside or out.'
    }
    ```
- `?window_state == 'steamed' && !seen('see_prints_on_glass') && seen('downy') && seen('greasy')`
    Look at the steam `1`
    A cold day outside. Natural my breath should steam. `>->see_prints_on_glass`
- `sticky`  `?window_state == 'steam_gone'` Breathe on the glass `1`
    I breathed gently on the glass once more.
    ```js
    if (reached(window_knowledge, 'fingerprints_on_glass')) {
      render('The fingerprints reappeared.');
    }
    window_state = 'steamed';
    ```

- `sticky` Something else? `1`
    ```js ~
    let acc = '';
    if (seen('window') < 2 || reached(window_knowledge, 'fingerprints_on_glass') || window_state == 'steamed') {
      acc += 'I looked away from the dreary glass.\n\n';
      //render('I looked away from the dreary glass.');
      if (window_state == 'steamed') {
        window_state = 'steam_gone';
        //render('The steam from my breath faded.');
        acc += 'The steam from my breath faded.\n\n';
      }
      //render('`->murder_scene`');
      acc += '`->murder_scene`';
    }
    acc
    ```
    I leant back from the glass. My breath had steamed up the pane a little.
    `window_state = 'steamed'`

`->window`

# downy

```js ~
if (window_state == 'steamed') {
  // TODO higher-level helper
  "Through the steamed glass I couldn't see the brook. `>->see_prints_on_glass` `->window`"
}
```
I watched the little stream rush past for a while. The house probably had damp but otherwise, it told me nothing.

# knock_with_cane

- Use the cane to reach under the bed `1`

    Positioning the cane above the carpet, I gave the glinting thing a sharp tap. It slid out from the under the foot of the bed.
    `knife_loc = 'floor'`

    - Stand up `1`
    - Look under the bed once more `1` Moving the cane aside, I looked under the bed once more, but there was nothing more there.

    Satisfied, I stood up, and saw I had knocked free a bloodied knife. `->murder_scene`

# seen_light

- `?!bedroom_light.on` Turn on lamp `1` `>->operate_lamp`

- `?bedroom_light.loc === 'bed'  && bed_state == 'bloodstain_visible'`
    Move the light to the bed `bedroom_light.loc = 'bed'`

    I moved the light over to the bloodstain and peered closely at it. It had soaked deeply into the fibres of the cotton sheet.
    There was no doubt about it. This was where the blow had been struck. `reach(bed_knowledge, 'murdered_in_bed')`

- `?bedroom_light.loc != 'desk' && (turns-turn_moved_light_to_floor) >= 2`
    Move the light back to the desk
    `bedroom_light.loc = 'desk'`
    I moved the light back to the desk, setting it down where it had originally been.

- `?bedroom_light.loc != 'floor' && dark_under`
    Move the light to the floor
    `bedroom_light.loc = 'floor'`
    I picked the light up and set it down on the floor.
    `var turn_moved_light_to_floor = turns;`

<!-- `->murder_scene` -->

# compare_prints

- `?reached(window_knowledge, 'fingerprints_on_glass') && reached(knife_knowledge, 'prints_on_knife') && !reached(window_knowledge, 'fingerprints_on_glass_match_knife')`
    Compare the prints on the knife and the window `1`
    Holding the bloodied knife near the window, I breathed to bring out the prints once more, and compared them as best I could.
    Hardly scientific, but they seemed very similar - very similiar indeed.
    `reach(window_knowledge, 'fingerprints_on_glass_match_knife')`
    `->$go_back_to`

# see_prints_on_glass

`reach(window_knowledge, 'fingerprints_on_glass')`
`$['But I could see a few fingerprints, as though someone hadpressed their palm against it.', 'The fingerprints were quite clear and well-formed.'][0]`
They faded as I watched.

`window_state= 'steam_gone'`

# operate_lamp

I flicked the light switch.

```js
if (bedroom_light.on) {
  render('The bulb fell dark');
  bedroom_light.on = false;
} else {
  if (bedroom_light.loc === 'floor') {
    render('A little light spilled under the bed.');
  } else if (bedroom_light.loc === 'desk') {
    render('The light gleamed on the polished tabletop.');
  }
  bedroom_light.on = true;
}
```

# joe_in_hall

My police contact, Joe, was waiting in the hall. 'So?' he demanded. 'Did you find anything interesting?'

`->joe_in_hall1`

# joe_in_hall1

- `?seen('joe_in_hall1') == 1` 'Nothing.' `1`
    He shrugged. 'Shame.'
    `->done`

- `?inventory.has('knife')` 'I found the murder weapon.' `1`
    'Good going!' Joe replied with a grin. 'We thought the murderer had gotten rid of it. I'll bag that for you now.'
    `knife_loc = 'joe'`

- `?reached(knife_knowledge, 'prints_on_knife') && knife_loc == 'joe'`
    'There are prints on the blade.' `1`
    'There are prints on the blade,' I told him.
    He regarded them carefully.
    'Hrm. Not very complete. It'll be hard to get a match from these.'
    `reach(knife_knowledge, 'joe_seen_prints_on_knife')`

- `?reached(window_knowledge, 'fingerprints_on_glass_match_knife') && reached(knife_knowledge, 'joe_seen_prints_on_knife') `
    'They match a set of prints on the window, too.' `1`
    'Anyone could have touched the window,' Joe replied thoughtfully. 'But if they're more complete, they should help us get a decent match!'
    `reach(knife_knowledge, 'joe_wants_better_prints')`

- `?reached(bed_knowledge, 'body_on_bed') && !reached(bed_knowledge, 'murdered_in_bed')`
    'The body was moved to the bed at some point.' `1`
    'The body was moved to the bed at some point,' I told him. 'And then moved back to the floor.'
    'Why?'
    - 'I don't know.' `1`
        Joe nods. 'All right.'
    - 'Perhaps to get something from the floor?' `1`
        'You wouldn't move a whole body for that.'
    - 'Perhaps he was killed in bed.' `1`
        'It's just speculation at this point,' Joe remarks.

- `?reached(bed_knowledge, 'murdered_in_bed')`
    'The victim was murdered in bed, and then the body was moved to the floor.' `1`
    'Why?'
    - 'I don't know.' `1`
        Joe nods. 'All right, then.'
    - 'Perhaps the murderer wanted to mislead us.' `1`
        'How so?'

        - 'They wanted us to think the victim was awake.' `1`
            'They wanted us to think the victim was awake[.'], I replied thoughtfully.
            'That they were meeting their attacker, rather than being stabbed in their sleep.'

        - 'They wanted us to think there was some kind of struggle.' `1`
            'They wanted us to think there was some kind of struggle,' I replied.
            'That the victim wasn't simply stabbed in their sleep.'

        'But if they were killed in bed, that's most likely what happened. Stabbed, while sleeping.'
        `reach(bed_knowledge, 'murdered_while_asleep')`
    - 'Perhaps the murderer hoped to clean up the scene.' `1`
        'But they were disturbed? It's possible.'

  - `?seen('joe_in_hall1') > 1` 'That's it.' `1`
      'All right. It's a start,' Joe replied.
      `->done`

`->joe_in_hall1`

# done
<!-- this is also a fallback option... -->

```js
if (reached(knife_knowledge, 'joe_wants_better_prints') && !reached(knife_knowledge, 'joe_got_better_prints')) {
  reach(knife_knowledge, 'joe_got_better_prints');
  render("I'll get those prints from the window now.");
} else if (reached(knife_knowledge, 'joe_seen_prints_on_knife')) {
  render("I'll run those prints as best I can.");
} else {
  render("'Not much to go on.'");
}
```
THE END


<!--

make_choices([
    "The bed...",
    "Lift the bedcover",
    "Remove the cover",
    "Pull back the duvet",
    "Remake the bed",
    "Test the bed",
    "Look under the bed",
    "Something else?",
    "The desk...",
    "Pick up the cane",
    "Turn on the lamp",
    "Look at the in-tray",
    "Open a drawer",
    "Open a drawer",
    "Open a drawer",
    "Something else?",
    "Swoosh the cane",
    "The window...",
    "Look down at the brook",
    "Look at the glass",
    "Something else?",
    " Look at the steam",
    "Breathe on the glass",
    "Something else?",
    " Move the light to the floor ",
    " Look under the bed",
    "Knock it with the cane",
    "Use the cane to reach under the bed",
    "Look under the bed once more",
    " Pick up the knife",
    " Look at the knife",
    " Compare the prints on the knife and the window",
    " Move the light back to the desk ",
    " Move the light to the floor ",
    "Leave the room"
])

-->