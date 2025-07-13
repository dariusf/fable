
```js
var items = ['Apple', 'Banana', 'Carrot'];
```

text from Scene 1


```js meta
items.map(i => `- ${i}`).join('\n') + `

<details>
  <summary>Click me</summary>
  This was hidden
</details>`
```
