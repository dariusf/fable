Hello! Fable is a narrative scripting language which makes it easy to publish your interaction fiction on the web.

Try it out on this page --- edit this text on the left and see your changes live on the right!

You can get started writing immediately: _regular prose_ is valid Fable.

To give the reader some choices, list them with dashes.

- Here is a choice
- Here is another

Often you will want to _jump_ to different sections of your story depending on what the reader chooses.
You can do this with the _jump_, written like this:

<pre style="margin: 0 0">`->name_of_section`</pre>

- Turn to page 10 `->page10`
- Attempt a Persuasion check `->persuasion`

# persuasion

Success!

`->end`

# page10

You turned to page 10!

`->end`

# end

"Meta" things are usually quoted using backticks, to distinguish them from your prose.
Think of them as a means for you to silently tell Fable what to do next, behind the scenes, without readers knowing!

That's all you need to get started!
Check out the tutorial in the dropdown on the right for more.
There are other examples you can look at too.