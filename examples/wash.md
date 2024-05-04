```js
var outlet_closed = false;
```

`->start`

# start

The outlet is `$' ' + (outlet_closed ? 'closed' : 'open')`.

`->hub`

# hub

- `sticky` Turn the dial `->dial`
- `sticky` Set the temperature `->temp`
- `sticky` Set the spin `->spin`
- `sticky` Adjust the time `->time`
- Add detergent `1` You added some detergent.
- `?!outlet_closed` Close the outlet `outlet_closed = true` You closed the outlet.
- `?outlet_closed` Start the machine `->wait`
- `?!outlet_closed` Start the machine `->water`

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

`->hub`

# temp

- `sticky` 90
- `sticky` 60
- `sticky` 50
- `sticky` 40
- `sticky` 30
- `$'*'` `sticky`

`->hub`

# spin

- `sticky` 1000
- `sticky` 800
- `sticky` 600
- `sticky` Swirl
- `sticky` Box

`->hub`

# time

- `sticky` 115
- `sticky` 55

`->hub`

# water

You left the machine and came back to find the clothes unwashed and the floor covered with water.

THE END

# wait

Time to wait.

THE END