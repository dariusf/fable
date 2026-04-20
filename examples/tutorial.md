Welcome to Fable's tutorial!
It is itself a Fable story.

It may help to read the source in the left panel as you play along on the right, to see how something is done.

These topics are best read in order, but feel free jump around as you please. `->topics`

# topics

- Is Fable for me? `->fable_for_me`
- Sections, jumps, and choices `->sections_jumps_choices`
- Publishing your story `->publishing`
- Exploring the editor `->editor`
- Saving the game `->saving`
- Ever-changing prose `->dynamic`
- Guarded choices `->guarded_choices`
- Dialogue loops `->dialogue_loops`
- Keeping score `->score`
- Taking inventory `->inventory`

# fable_for_me

<h1>Is Fable for me?</h1>

Let's see... which of these best describes you?

- I am new to writing interactive fiction
  <b>New to writing IF</b>

  Fable is a great way to get started with interactive fiction --- all you have to do is start writing, here, in the editor!

  When done, click the Publish button on the right, and you'll get your game in a file you can upload to itch.

  Check out the rest of this tutorial first, to see what Fable is capable of and how it does things.

  If you'd prefer to create IF more graphically, check out Twine.

- I am a writer first
  <b>Writer</b>

  Fable is more minimalistic than other IF systems:
  your writing is front and centre, and everything can be done in a single file.

  Like Twine, it targets the web and publishes to a single HTML file you can directly upload to itch.

  Its design is loosely inspired by Ink, though a Fable story _is_ the game, and isn't to be embedded in a larger engine (which streamlines things).

  Fable also has a pleasant, minimal, and consistent language design, with a clear delineation between prose and code.

  This editor doesn't send your work anywhere: you are completely in control of your writing.

- I am a programmer first
  <b>Programmer</b>

  Fable is web-first: it is a Markdown dialect, uses JavaScript natively, and publishes to a single HTML file.
  It is appropriate for quickly writing IF without having to worry about the engine --- there is almost no scaffolding, and you can write the entire game in a single text file, directly interacting with the web page using native browser APIs.
  All the tools you know will work.

  (If you looking for a narrative scripting language to embedded within a larger game engine, you will probably be better served by Ink.)

  Fable also has a pleasant, minimal, and consistent language design --- there is a clear delineation between prose and code, and the usual IF programming needs are met using metaprogramming rather than bespoke syntax. It has a well-defined semantics, and tools for (automatically) testing your stories and finding bugs in them.

  This editor is entirely client-side and has vim keybindings, which you can enable by opening the settings using <kbd>Cmd</kbd> + <kbd>,</kbd>.
  A command-line workflow with hot reloading is also supported.
  The whole system is open source and well-documented.

  Check out the language reference for more.

<!-- this is a divider -->

- Back

`->topics`

# sections_jumps_choices

<h1>Sections, jumps, and choices</h1>

To get started with Fable, all you need are three fundamental concepts: _sections_, _jumps_, and _choices_.

- Sections

Sections are written like this.

<pre># my_section</pre>

The unnamed section before the first one is called _prelude_, and is shown automatically.

- Jumps

Sections don't automatically flow into one another. For that, you need a _jump_, written like this, with backticks.

<pre>`->my_section`</pre>

NB: _Meta_ things are usually quoted with backticks, to distinguish them from prose.
Think of them as a way for you to tell Fable what to do next behind the scenes.

You can see the effect of a jump here...

`->my_section`

# my_section

Tada! The transition is seamless, so the reader doesn't have to know it happened.

- Choices

Finally, give the reader some choices with a bulleted list.

<pre>
- Roll some dice
- Flip a coin
</pre>

- Roll some dice
- Flip a coin

The story continues after a choice.
Put jumps in the list items to have readers' choices take them to different sections.

<pre>
- I like apples `->apples`
- I like oranges `->oranges`
</pre>

- I like apples `->apples`
- I like oranges `->oranges`

# apples

You picked apples!

`->converge`

# oranges

I like oranges too!

`->converge`

# converge

You now know enough Fable to be dangerous!

- Back

`->topics`

# dynamic

<h1>Ever-changing prose</h1>

The prose you write in Fable doesn't have to be static; it can change across playthroughs!
We'll demonstrate this using a classic example: the <a href="https://www.scholastic.com/content/dam/teachers/articles/migrated-files-in-body/shakespeare_insult_kit.pdf">Shakespeare Insult Kit</a>.

This requires some light programming.
First, we'll need some word lists.
We'll define them using a _block_ of JavaScript, indicated by three backticks.
<code>var</code> declares a _variable_, which is used here to name a collection of words.

<pre>
```
var adjective1 = ["your", "words", "here"];
```
</pre>

```
var adjective1 = ["artless", "bawdy", "beslubbering", "bootless", "churlish", "cockered", "clouted", "craven", "currish", "dankish", "dissembling", "droning", "errant", "fawning", "fobbing", "froward", "frothy", "gleeking", "goatish", "gorbellied", "impertinent", "infectious", "jarring", "loggerheaded", "lumpish", "mammering", "mangled", "mewling", "paunchy", "pribbling", "puking", "puny", "qualling", "rank", "reeky", "roguish", "ruttish", "saucy", "spleeny", "spongy", "surly", "tottering", "unmuzzled", "vain", "venomed", "villainous", "warped", "wayward", "weedy", "yeasty"]

var adjective2 = ["base-court", "bat-fowling", "beef-witted", "beetle-headed", "boil-brained", "clapper-clawed", "clay-brained", "common-kissing", "crook-pated", "dismal-dreaming", "dizzy-eyed", "doghearted", "dread-bolted", "earth-vexing", "elf-skinned", "fat-kidneyed", "fen-sucked", "flap-mouthed", "fly-bitten", "folly-fallen", "fool-born", "full-gorged", "guts-griping", "half-faced", "hasty-witted", "hedge-born", "hell-hated", "idle-headed", "ill-breeding", "ill-nurtured", "knotty-pated", "milk-livered", "motley-minded", "onion-eyed", "plume-plucked", "pottle-deep", "pox-marked", "reeling-ripe", "rough-hewn", "rude-growing", "rump-fed", "shard-borne", "sheep-biting", "spur-galled", "swag-bellied", "tardy-gaited", "tickle-brained", "toad-spotted", "unchin-snouted", "weather-bitten"];

var noun = ["apple-john", "baggage", "barnacle", "bladder", "boar-pig", "bugbear", "bum-bailey", "canker-blossom", "clack-dish", "clotpole", "coxcomb", "codpiece", "death-token", "dewberry", "flap-dragon", "flax-wench", "flirt-gill", "foot-licker", "fustilarian", "giglet", "gudgeon", "haggard", "harpy", "hedge-pig", "horn-beast", "hugger-mugger", "joithead", "lewdster", "lout", "maggot-pie", "malt-worm", "mammet", "measle", "minnow", "miscreant", "moldwarp", "mumble-news", "nut-hook", "pigeon-egg", "pignut", "puttock", "pumpion", "ratsbane", "scut", "skainsmate", "strumpet", "varlot", "vassal", "whey-face", "wagtail"];
```

- Okay, what next?

The idea is to then _interpolate_ words from the word list into your sentence.

<pre>
Thou `~randomFrom(adjective1)`, `~randomFrom(adjective2)` `~randomFrom(noun)`!
</pre>

We use backticks again to signal that we're doing something _meta_, outside the prose.
The tilde <code>~</code> tells Fable to evaluate some code and have the result be part of the surrounding prose.
Here, the code uses the JavaScript function <code>randomFrom</code>, which samples words from our word lists.

Now you'll then get fresh insults every time you play!

- Get some fresh insults `->insult`

# insult

Thou `~randomFrom(adjective1)`, `~randomFrom(adjective2)` `~randomFrom(noun)`!

Thou `~randomFrom(adjective1)`, `~randomFrom(adjective2)` `~randomFrom(noun)`!

Thou `~randomFrom(adjective1)`, `~randomFrom(adjective2)` `~randomFrom(noun)`!

- `sticky` More fresh insults `->`
- Back

`->topics`

# score

<h1>Keeping score</h1>

It is sometimes useful to keep track of the reader's score over the course of the game.
For example, you might want to count the number of clues they have encountered in a mystery game.

We use some JavaScript to say where we want to keep track of the score.

First, we say that the score is initially 0.

<pre>
```
var score = 0;
```
</pre>

```
var score = 0
```

- Okay

We then annotate our choices with backticked snippets of code to increment (<code>++</code>) the score. For example,

<pre>
- My choice `score++` `->jump_somewhere`
</pre>

Let's try this out. Search the room, and we'll track how many clues you found.

`->clues`

# clues

- Look under the bed
  You peer under the bed and see a strange metallic object. `score++` `->`
- Look behind the table
  There is nothing under the table. `->`
- Look under the lampshade
  There is something stuck inside the lampshade. `score++` `->`
- Check inside the drawers
  You open the drawers and find an old key. `score++`
- Stop exploring

Number of clues found: `~score`

- Back

`->topics`

# inventory

<h1>Taking inventory</h1>

Sometimes we need to track more than just a score.
For example, you might want to track what the reader has in their pockets at a certain point in the story.

We need some light programming.
First, we declare that the <code>inventory</code> is where we track this, and it is initially empty.

<pre>
```
var inventory = [];
```
</pre>

```
var inventory = []
```

- Okay

We then annotate our choices with backticked snippets of code to track the items the reader acquires. For example,

<pre>
- Pick up the sword `inventory.push("sword")` `->jump_somewhere`
</pre>

Let's try this out. Open the chest and grab all the treasure you can!

`->treasure`

# treasure

- Grab the diamond
  You got the diamond. `inventory.push("diamond")` `->`
- Pick up the sapphire
  You got the sapphire. `inventory.push("sapphire")` `->`
- Grab the emerald
  You got the emerald. `inventory.push("emerald")` `->`
- Leave the rest

You got: `~inventory.join(", ")`

- Back

`->topics`

# publishing

<h1>Publishing your story</h1>

Once you've written your piece, itch is the simplest way to publish it.

Click the Publish button on the right, then <a href="https://itch.io/game/new">create a new project</a> there and upload the file.
Some recommended settings:

<ul>
<li>Kind of project: HTML</li>
<li>How should your project be run in your page? Click to launch in fullscreen</li>
<li>Mobile friendly, portrait</li>
</ul>

And you're done!

- Back

`->topics`

# editor

<h1>Exploring the editor</h1>

You've already been using the editor to both read and play through this tutorial, but it offers a lot more for developing stories.

`->editor0`

# editor0

- Back and forth
  The Back and Restart buttons help you conveniently navigate your work.

  The Back button is disabled in published stories, so your readers' choices matter. `->`
- Graph
  The Graph button visualises your story.
  It's great for understanding its structure and spotting what Ink calls _loose ends_: dangling narrative threads.
  Click it now to try visualising this one! `->`
- Docs
  For the details on Fable, the language reference is available at the Docs link. `->`
- Open and Save
  The Open and Save buttons allow you to save your work and resume a writing session another day.
  You can also drag and drop a markdown file into the editor to open it.

  Always click the Save button after a long writing section!
  A best-effort attempt is made to preserve your writing across reloads of the tab, but it's best not to rely on it. `->`
- Publish and Share
  The Publish button will download your story as a HTML file, ready for publishing.

  The Share button will create a link you can send to a friend to share your work.
  For longer stories, the link can get very long and may not work, so it is better to Publish and send them the file. `->`
- Privacy
  The editor runs entirely on your computer and it doesn't send your story anywhere.
  For that reason, some things like saving are a little less convenient than in a normal app.
  The tradeoff is that you get to stay in control of your work. `->`
- Back

`->topics`

# saving

<h1>Saving the game</h1>

In published stories, Fable automatically saves readers' choices, so if they refresh the page, they won't have to start over.
You will have to clear the save data manually.
To see how and to add to what is saved, see the language reference.

- Back

`->topics`

# guarded_choices

<h1>Conditional choices</h1>

Some choices are dependent on others having been taken. For example, the reader might have to get a key before they can unlock a door.

You can model this using a _precondition_ on a choice. This is a backticked bit of code with <code>?</code> in front.

First, declare that there is a key to be acquired.

<pre>
```
var has_key = false;
```
</pre>

```
var has_key = false;
```

- Okay

After that, set up a situation where a choice somewhere records that the player has a key, while another choice is guarded by it.

<pre>
# loot

- Open the chest `has_key=true`
- `?has_key` Unlock the door `->`
</pre>

- Try this

`->loot`

# loot

- Open the chest `has_key=true` `->`
- `?has_key` Unlock the door

You unlocked the door!

- Back

`->topics`

# dialogue_loops

<h1>Dialogue loops</h1>

When writing the flow of a conversation, one sometimes wants a _dialogue loop_, where there is a list of outstanding talking points, some of which unlock new ones, and the conversation goes on until the reader decides to leave it or runs out of options.

Here's an example dialogue loop, which is explained right after.

You stare into her eyes. `->loop_example`

# loop_example

```
local.dog ||= 0
```

- Ask about her dog `local.dog=true`
  "How's your dog?" you ask.

  "Fine. He loves his kibbles." `->`
- `?local.dog` Ask about the kibbles
  "What's in the kibbles?"

  "I have no idea. Some dried meat, maybe." `->`
- Talk about the weather
  "It's been really hot recently, huh?"

  "Yeah, it has." `->`
- Leave

"I'll see you around."

This uses several features of Fable simultaneously.

<ul>
<li><code>`->`</code> is shorthand for a jump back to the current section.</li>
<li><code>local.dog ||= 0</code> sets a section-local variable. This is useful to track the state of conversations, without having to worry about reusing the same variable name elsewhere.</li>
<li>A conditional choice blocks access to the kibbles talking point until the dog is brought up.</li>
</ul>

- Two more things

In the conversation before, the reader was allowed to leave at any time.
Two more variations are useful.

Marking a choice as <code>otherwise</code> makes it so it only appears when all other choices are exhausted.
This makes the reader have to finish the conversation before they can move on.

<pre>
- A choice
- `otherwise` An otherwise choice
</pre>

- What's the second thing?

Having a choice marked as <code>fallthrough</code> is similar, but instead of the choice appearing, the story instead continues seamlessly with whatever is after the choice.

<pre>
- A choice
- Another choice
- `fallthrough`
</pre>

This has a similar effect as <code>otherwise</code>, except that the reader automatically leaves the conversation.

- Back

`->topics`
