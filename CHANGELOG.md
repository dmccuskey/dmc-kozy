# Changelog

## 1.1.1 (2026-10-01)

### Changed

- Lines get the 0-255 `setStrokeColor()`. Solar2D ignores setting a line's color methods the usual way, so lines kept Solar2D's own 0-1 method; the module now stores its methods with `rawset()`.

## 1.1.0 (2026-09-29)

### Changed

- Gray with alpha, `setFillColor( 128, 0.5 )`, uses the alpha; it used the gray value as the alpha.
- A gradient is translated as a copy: your table is left as it is, so using it twice gives the same colors.
- A color that isn't one raises an error naming dmc_kozy, at your line: a color name (dmc-kozy has none; it printed `ERROR dmc_kolor: named color not found` and gave white), a short or malformed hex string, a string among the numbers.
- Other paints, such as `{ type='image', filename='wood.png' }`, go to Solar2D unchanged; they raised an error.
- `newPolygon()` gets the 0-255 `setFillColor()` too.
- `native.newTextField()` and `newTextBox()` get a 0-255 `setTextColor()` instead of a `setFillColor()` that raised an error; `newWebView()` gets no color method.
- `display.newImage()`, `newImageRect()` and the other constructors return `nil` when Solar2D's does; they raised an error.
- `setReferencePoint()` takes Solar2D's own `display.CenterReferencePoint` (and the others), which it ignored, and raises an error for anything that isn't a reference point. `setAnchor()` raises an error for a value that isn't a number.
- Settings without the `:BOOL` type work: `MAKE_GLOBAL = false` was the string `"false"`, which counted as true.
- The module returns a table you call instead of a function; `require( 'dmc_corona.dmc_kozy' )()` works as before.
- Rebuilt with dmc-corona-boot 1.6.0.

### Added

- `VERSION`, `display` and `native` in the table the module returns.
- Unit tests: `tests/run_unit.sh`, plain Lua 5.1.

### Removed

- The `PRINT_WARNINGS` setting, which did nothing.
- The globals `_extend`, `createClosure` and `t` it left behind, and the copy of `extend()`.

## 1.0.2

- `setAnchor()` with one value no longer crashes the Simulator; the wrapper for `native.newText()`, which Solar2D doesn't have, is dropped.
