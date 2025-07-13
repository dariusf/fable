a: asd
b: |
  hi
  there
c: lol
extra: hi there
---

# Two

```js
tweet_style_choices = false;
var items = ['Apple', 'Banana', 'Carrot'];
// This makes testing tough
// var a = items[Math.floor(Math.random()*items.length)];
var a = items[2-3+1];
```

Hello `$a`!

```js
function runMe() {
  console.log('hi');
  interpret([['Para', [['Text', 'Hi!']]]], content,()=>{});
}
```

<!-- block comments don't appear -->

inline comments <i>don't</i> appear <!-- comment -->

[jump](#One)

[code](!runMe)

Make a choice:

- Go to Scene 1 `jump One` should not show
- Say something, then to Scene 1 `1` should show. `jump One`
- Go to Scene 3 `jump Three`
- Continue
- Nested lists `jump Nested`
- Copy `jump Copy`
- More `->More`
- Jump dynamic `->$items[0]`
- Tunnel! `>->Tunnel`
- Tunnels followed by jumps `->tunnel_test`
- Spaces `->Spaces`
- Inline and block meta `->InlineBlockMeta`
- Inline meta jump `->InlineMetaJump`
- Block meta jump `->BlockMetaJump`
- Choice break delimiters `->ChoiceBreakDelimiters`

End of first scene

# One

text from Scene 1

```js meta
items.map(i => `- ${i}`).join('\n') + `

<details>
  <summary>Click me</summary>
  This was hidden
</details>`
```

# Three

text from Scene 3

Turns: `$internal.turns`

# Nested

- Choice 1 `1`
    - Nested choice. Did you choose choice 1? `1`
    - Or not? `1`
- Choice 2 `1` after
    break
- Choice 3 `1`

    A paragraph
- Choice 4 `1`

    ```js
    console.log('you chose choice 4');
    ```

Right before going back to Nested

`jump Nested`

# Copy

```js ~
internal.scenes['One']
```

# Some choices

- a
- b

# More

- Hi
- `more Some choices`

# Apple

```js
clear()
```

Apple scene

# Tunnel

```js
clear()
```

Tunnel

# Spaces

```js
clear()
```

- `?a` choice text `1` code after

"Hi, `$'A'`," he said.

"`$'Edge case'`" here

`$'A'`'s thing

# tunnel_test

```js
clear()
```

before

`>->tunnel_test_a`

after

# tunnel_test_a

a

`->tunnel_test_b`

# tunnel_test_b

- b

# InlineBlockMeta

```js
clear()
```

interpolation `$'1'`

inline meta `~'1'`

```js ~
'block meta'
```

# InlineMetaJump

```js
clear()
```

hi `~ 'there' + jump('Some choices')`!

<!-- edge case: instructions before the jump disappear -->

# BlockMetaJump

```js
clear()
```

```js ~
'1'
```

```js ~
if (true) {
  '2 `->BlockMetaJump1`'
}
```

should not show

# BlockMetaJump1

3

# ChoiceBreakDelimiters

```js
clear()
```

- asd
    selected