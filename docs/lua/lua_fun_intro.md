# Lua Functional Libraries

Updated 2017-12-05

[< Lua][0]

This is a quick introduction to the Lua Fun library and how to write code using it. If you're completely unfamiliar with functional programming, you might want to start by reading [this](https://maryrosecook.com/blog/post/a-practical-introduction-to-functional-programming).

## Lua Fun

## Intro
Lua Fun is a library that provides several functions useful for writing Lua code in a functional style, such as the common `map` and `reduce`. For example, using Lua Fun, you would find the sum of the numbers 1 to 5 like this:
```Lua
sum_1_to_5 = reduce(operator.add, 0, range(5))
```
`range(5)` returns a table with the numbers 1 to 5, `{1, 2, 3, 4, 5}` (technically it returns an iterator for those values, but iterators will be explained later). `operator.add` is simply a functional version of the `+` operator, i.e. it takes two arguments and returns the addition of those two arguments. `reduce` then repeatedly calls `operator.add` with the return value of the last call and the current value being iterated over, with 0 as the initial value for the first call. `reduce` stops and returns the return value of the final call once it has iterated over all the items given to it. Lua Fun also has a few shortcut functions for common useages of `reduce`. For example, the earlier summing code can also be written as `sum_1_to_5 = sum(range(5))`. A list of those shortcut function can be found [here](https://luafun.github.io/reducing.html#id4).

A reference for the functions available in Lua Fun can be found [here](https://luafun.github.io/index.html).

## Tips
- Try not to use anonymous functions inside calls to `map`, `reduce`, and `filter` because Lua, unfortunately, doesn't have very concise anonymous function syntax. Named local functions will usually be easier to read.
- If you find yourself writing a long chain of functions like `reduce(... map(... map(... filter(...))))`, try to break it up into smaller units and write functions for those units. The functions can then simply call each other to compose the chain. You can look at [this](https://github.com/OpenAngelArena/oaa/blob/master/game/scripts/vscripts/components/filters/filtermanager.lua) for an example.

## Special Notes

### Iterators
Lua Fun functions don't technically take or return tables, they return iterators instead, which are actually a set of 3 values. Details can be found [here](https://luafun.github.io/under_the_hood.html) if you're interested. All you really need to know though, is that because of this detail:

1. Tables will automatically be handled when passed into Lua Fun functions **but**, keep in mind that if your table has non-contiguous numeric keys and key `1` is defined, Lua Fun will assume the table is an array and will only iterate through keys 1 up to the value that would be returned by Lua's length operator (read [this](https://www.lua.org/manual/5.1/manual.html#2.5.5) for more info on the length operator). In order for that to happen, you have to explicitly do `pairs(table)`. e.g. `map(func, pairs(table))`.

2. If you need to produce an actual table to interop with code not using Lua Fun, or for some other reason, you can use the `totable` or `tomap` functions. Documentation for those functions is available [here](https://luafun.github.io/reducing.html).

3. Iterators can be used in for ... in ... loops if you prefer that syntax to Lua Fun's `foreach` function. For example, you can do `for i in range(5) do ...`

### Parameter Order
If you've not dealt much with functional programming before, you might have gotten used to having callback functions as the last parameter of functions. Keep in mind that pretty much all Lua Fun functions that take functions as parameters have it as the *first* parameter. The reason for this is that it's convention, and makes more sense for functions like `map`, `reduce`, and `filter`, particularly when chaining them together. In particular though, keep in mind that even `foreach` takes the function as the first parameter rather than the data.

### Reduce
If you've used other languages with functional primitives before, you may be used to `reduce` starting by calling the given function with the first 2 items in the given list. Keep in mind that Lua Fun's `reduce` has an initial value as a parameter instead. You can replicate the above mentioned behaviour of `reduce` by doing `reduce(func, head(list), tail(list))` if necessary, though this causes an error if `list` is empty. Alternatively, `reduce(func, nth(1, list), tail(list))` returns `nil` when `list` is empty.

### Partial
While Lua Fun doesn't have `partial`, the OAA project has an implemetation that can be found in `game/scripts/vscripts/libraries/functional.lua` ([file on GitHub](https://github.com/OpenAngelArena/oaa/blob/master/game/scripts/vscripts/libraries/functional.lua)). Usage should be similar to `partial` in other languages. The first parameter is the function to curry, followed by the parameters to pass to the curried function.

[0]: README.md
