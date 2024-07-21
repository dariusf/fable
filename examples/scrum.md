
```js
var seen_review = 0;
```

`->start`

# start

Let's begin today's standup.

<!-- This records energy level -->
How are you feeling today?

- Green
- Amber
- Red

`->do`

# do

What would you like to do next?

- Review `1` `->review`
- `sticky` Add a story `1` `>->add` `->start`

# add

How many points is this story worth?

- 2 points
- 3 points
- 5 points

How much creative energy do you think you'll need to finish this?

- A bit
- A lot

Okay, I've added it to the backlog.

`->do`

# review

```js
seen_review++;
```

Reviewing...

<!--Debug {saw_review} {review} {TURNS_SINCE(->review)}-->

- `?seen_review > 1 && !seen('exceeded')` Energy exceeded `->exceeded`
- Pick a ticket `1` So how are we doing on this next story?
    - It's done `1` Great! `->review`
    - It's not yet done `1` Is it still something you want to do today?
        - Yes `1` Do you think you'll be able to finish it today?
            - Yes `1` Great, let's move on. `->review`
            - No `1` Maybe we should break it down into smaller stories.
                - Yes `>->add` `->review`
                - No `1` Okay, I'll leave it. `->review`
        - No `1` I'll move it to the backlog, then. `->review`
- No tickets `1` Great!
    Would you like to take some things out of the backlog?
    - Yes `->take_from_backlog`
    - No `->enjoy_your_day`
- All tickets seen `1` Great! Here's your schedule for today. `->enjoy_your_day`

# exceeded

Are you sure you'll be able to complete everything?

- Yes `1` Great, let's move on. `-> review`
- No `1` We should reassess. What can or can't you do? `-> prune_aggressively`

# prune_aggressively

- Not done `1` Still pruning. `-> prune_aggressively`
- Done and under limit `1` Great, let's move on. `-> review`

# take_from_backlog

Pick a random story. Does this look ok?

+ Yes `-> review`
+ No `-> take_from_backlog`

# enjoy_your_day

Enjoy the rest of your day!
