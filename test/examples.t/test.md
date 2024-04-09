
# Two

```js
var turns = 0;
function on_interact() {
  turns++;
}
var items = ['Apple', 'Banana', 'Carrot'];
var a = items[Math.floor(Math.random()*items.length)];
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

after all

---

# One

text from Scene 1

```js meta
items.map(i => `- ${i}`).join('\n') + `

<details>
  <summary>Click me</summary>
  This was hidden
</details>`
```

---

# Three

text from Scene 3

Turns: `$turns`

---

# Nested

<!-- - Choice 1 `1`
    - Did you choose choice 1? `1`
    - Or not? `1`
- Choice 2 `1` -->