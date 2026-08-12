# Log viewer

`LogViewer` renders the job build log and the server log tail. Both can run to
tens of thousands of lines, and the job log grows *while* it is on screen, so
the design goal is that the cost of an update is proportional to what changed
— not to how much log has accumulated.

Files:

- `lib/shared/widgets/log_viewer.dart` — the widget, the scrolling, the tree
- `lib/shared/widgets/log_viewer_metrics.dart` — `_LogMetrics`, every
  measurement and the cache in front of it
- `lib/shared/widgets/log_viewer_gutter.dart` — `_PinnedGutter`
- `lib/shared/widgets/log_viewer_row.dart` — the rows and the per-build style
  bundle they share with the gutter
- `lib/shared/widgets/log_viewer_pan.dart` — the touch-drag shim
- `lib/features/builds/application/job_log_controller.dart` — the producer

The last four are `part of` the first.

## The append-only contract

`JobLogState.lines` is **one list, mutated in place** for the whole lifetime of
a job, and `LogViewer.lines` is documented to expect that.

This is the load-bearing decision, so it is worth being explicit about why a
mutable list crosses a layer boundary in an otherwise immutable-state app. A
chatty build emits hundreds of SSE chunks. Rebuilding the line list per chunk
(`[...state.lines, ...parts]`) copies every line received so far each time,
which makes one build O(lines × chunks) in list copies — for a result that is
only ever a few lines longer than the previous one. The same applied to
materializing `lines + pendingLine` for rendering.

What the contract buys, and what it costs:

- Consumers still rebuild, because `copyWith` hands out a new `JobLogState`.
- **Never** `select` on `lines` or compare it for equality: it is `identical`
  to the previous state's list. Nothing outside the controller may mutate it.
- `refresh()` installs a *new* list rather than clearing the old one, because
  a change of identity is what tells the viewer to throw its measurements away.

The half-arrived last line stays out of `lines` (a build tool can flush
mid-line) and travels as `pendingLine`, which the viewer draws as one extra
trailing row. That keeps every committed line final and costs no copy.

## Measuring, once

`build` runs on every chunk, so anything O(lines) in it is O(lines × chunks)
over a build. `_LogMetrics` keeps all of it out of that budget:

| Quantity | How it is obtained |
| --- | --- |
| Row height | Measured once per resolved `TextStyle` + `TextScaler`, cached. |
| Character advance | Measured once, from a ten-character run — one glyph rounds badly once multiplied across a 200-column line. |
| Width of a plain-ASCII line | `length × advance`, so the line is never laid out at all. Sound because the layout already assumes a monospace font. |
| Width of any other line | Laid out for real. A tab has no predictable advance, and a CJK ideograph or an emoji is typically *double* width, so estimating from the character count leaves the tail of such a line clipped and unreachable. |
| Widest line | Tracked incrementally: an append-only list can only push the maximum up, so each build measures the lines it just gained. |

Measurement uses `MediaQuery.textScalerOf`, because a `TextPainter` does no
scaling of its own — leaving it out under-measures every column as soon as the
reader zooms.

Two consequences of caching widths in pixels rather than characters: a style
or text-scale change throws the cache away and rescans (a rare, one-off O(N)
pass), and the pending line is measured fresh each build instead of being
cached, since it is still growing.

Every row is forced to the same height by a `forceStrutHeight` strut, which is
what lets `itemExtent` hand that height to `ListView.builder`: scroll offsets
come from the index instead of from laying out every preceding row.

## Emissions are coalesced

SSE chunks arrive faster than the screen paints, and each emission rebuilds the
whole job detail screen. The controller therefore publishes appended output on
a 50 ms timer (`_flushInterval`) instead of per chunk, and flushes immediately
at the points where no further chunk is coming — the log finished, or was
fetched in one shot — so the last lines are never left waiting.

One consequence: `_flush` is the only writer of `lines`/`pendingLine`, so an
unrelated emission in between (a job or mode change) carries the last
*published* pending line rather than the newest one. That is a difference of
one partial line, corrected by the flush already queued.

## The gutter is pinned

Line numbers stay at the pane's left edge no matter how far right the text is
scrolled, the way a code editor keeps them in view.

`_PinnedGutter` is a fixed-width column **outside** the horizontal scroll view,
and the log text scrolls in its own viewport starting where that column ends.
So there is no overlap to manage: nothing can ever be drawn over the numbers.

The first attempt did it the other way round — gutter inside each row, pushed
right by the scroll offset to compensate — and that is worth recording because
it looks right and is not. A gutter is a divider with no fill behind it, so
text scrolling *underneath* it showed straight through and swallowed the
numbers, which are deliberately faded to 45% alpha. Fixing that by giving the
column an opaque background means hardcoding a colour that has to keep matching
whatever the pane sits on. Moving it out of the scroll view removes the problem
instead of papering over it.

The cost is that the column has to place the numbers itself instead of letting
a viewport do it: row `i` goes at `i * rowHeight - scrollOffset`, rebuilt from
an `AnimatedBuilder` on the vertical controller, and only for the rows within
the visible height. That is exact rather than approximate — it is the same
arithmetic the list's own viewport does, and it is only available because
`itemExtent` fixes every row's height. `test/log_viewer_test.dart` pins it down
at offsets that are not a whole number of rows, and checks that the numbers
land in the *same frame* as the scroll rather than one behind.

Two consequences of being outside the list:

- The numbers cannot be selected or copied at all, which is what a real
  editor's gutter does. No `SelectionContainer.disabled` needed.
- The list's own gestures don't reach the column, so it forwards a wheel over
  itself to the vertical position — to a reader it is still part of the log.

## Scrolling

Four things here are not obvious, and each one was a bug:

1. **Both scrollbars sit outside the horizontal scroll view.** A scrollbar
   paints along the edge of its own box. The vertical one used to be nested
   *inside* the horizontally scrolling content, so its box was as wide as the
   widest line in the log and its thumb was drawn off-screen — invisible for
   exactly the wide logs that most need it. Out there, the list's
   notifications have already bubbled through the horizontal `Scrollable`, so
   their `depth` is 1 and the default `depth == 0` predicate drops every one of
   them; the vertical scrollbar matches on axis instead.

2. **The auto-scroll target is computed, not read.** In a post-frame callback
   `position.maxScrollExtent` is still the *previous* frame's value — the grown
   viewport has not published its new content dimensions yet. Jumping to it
   left the newest line one row below the fold on every append. Because
   `itemExtent` fixes the row height, `rows × height − viewport` is the exact
   extent; if it ever lands a hair past the end, `ScrollPosition` pulls an
   out-of-range offset back in-bounds on the next layout, which is the bottom
   anyway.

3. **A touch drag pans sideways.** `SelectionArea` claims horizontal drags,
   which is right for a mouse — dragging across text is how you select it —
   but on a touchscreen it left the log with no way to scroll sideways at all,
   because Material's scrollbar is not interactive on mobile platforms either.
   `_HorizontalTouchPan` sits below the selection region so it wins the arena,
   accepts `PointerDeviceKind.touch` only so mouse selection is untouched, and
   hands the drag to `ScrollPosition.drag` so the pan gets real physics.

4. **The row area is at least as wide as the pane.** At its content width, the
   area to the right of a narrow log was inert — a wheel or a drag over most
   of the pane did nothing.

Following the tail also stops when the reader scrolls away, and resumes when
they scroll back to the bottom, rather than yanking them down on every chunk.

Two layout traps worth remembering:

- A `Container`'s decoration border is *layout*, not just paint. It contributes
  its own thickness as padding around the child, so the gutter's 1px divider
  has to be counted in the column's declared width — it silently cost a pixel
  of misalignment when it was not.
- A `Stack` of nothing but positioned children has no opinion about its own
  size and collapses to nothing under loose constraints, which is why the
  gutter column is given an explicit width.

## Tests

`test/log_viewer_test.dart` covers all four scrolling bugs, the pinned gutter
(alignment at fractional offsets, same-frame placement, text never reaching it,
a wheel over it scrolling the log), the pending-line row, incremental widening,
and remeasurement on a text-scale change. Per repo policy `test/` is gitignored
and never committed; the file is expected to exist locally only.

Note that the double-width-glyph case cannot be asserted under the test font,
where every glyph is the same square. The test that guards the non-ASCII path
uses a surrogate pair instead — two UTF-16 code units rendering as one glyph,
where the character-count estimate would reserve twice the room it needs.
