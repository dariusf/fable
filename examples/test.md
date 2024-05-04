
# Two

```js
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

[jump](#One)

[code](!runMe)

Make a choice:

- Go to Scene 1 `jump One` should not show
- Say something, then go to Scene 1 `1` should show. `jump One`
- Go to Scene 3 `jump Three`
- Continue
- Nested lists `jump Nested`
- Copy `jump Copy`
- More `->More`
- Jump dynamic `->$items[0]`
- Tunnel `>->Tunnel`

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

```js
render_scene('One');
```

# Some choices

- a
- b

# More

- Hi
- `more Some choices`

# Apple

Apple scene

# Tunnel

Tunnel

# Spaces

- `?a` choice text `1` code after