
# Two

```js
let items = ['Apple', 'Banana', 'Carrot'];
var a = items[Math.floor(Math.random()*items.length)];
```

Hello `$a`!

```js
function runMe() {
  console.log('hi');
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

---

# Three

text from Scene 3

This can't be interpreted as markdown

```
[1, 2, 3].map(n => `- ${n}`).join('\n')
```
