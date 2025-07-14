```js
var outlet_closed = false;
```

`->start`

# start

You stand before the washing machine.

The outlet is `$' ' + (outlet_closed ? 'closed' : 'open')`.

`->hub`

# hub

```js
function done_everything() {
  return ['dial', 'temp', 'spin', 'time'].map(i => !!seen[i]).reduce((a, b) => a && b, true);
}
```

- `sticky` Turn the dial `->dial`
- `sticky` Set the temperature `->temp`
- `sticky` Set the spin `->spin`
- `sticky` Adjust the time `->time`
- Add detergent
    You added some detergent. `see('detergent')`
- `?!outlet_closed` Close the outlet `outlet_closed = true` You closed the outlet.
- `?done_everything()` Start the machine
    ```js ~
    !outlet_closed ? '`->water`' : !seen.detergent ? '`->unwashed`' : '`->wait`'
    ```

`->hub`

# dial

- `sticky` Cottons
- `sticky` Mixed
- `sticky` Delicates
- `sticky` Quick 18
- `sticky` Spin
- `sticky` Rinse
- `sticky` Energy Saver
- `sticky` Bedding
- `sticky` Wool
- `sticky` Jeans
- `sticky` Sensitive Plus

You turned the dial to `$' ' + last_choice()`.

`->hub`

# temp

- `sticky` 90
- `sticky` 60
- `sticky` 50
- `sticky` 40
- `sticky` 30
- `$'*'` `sticky`

You set the temperature to `$' ' + last_choice()`.

`->hub`

# spin

- `sticky` 1000
- `sticky` 800
- `sticky` 600
- `sticky` Swirl
- `sticky` Box

You set the spin to `$' ' + last_choice()`.

`->hub`

# time

- `sticky` 115
- `sticky` 55

You set the time to `$' ' + last_choice()`.

`->hub`

# water

You left the machine and came back to find the clothes unwashed and the floor covered with water.

THE END

# unwashed

You came back to find the clothes wet but unwashed, because you had forgotten to add detergent.

THE END

# wait

Time to wait.

THE END