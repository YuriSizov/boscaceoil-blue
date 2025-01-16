---
title: Arrangements
---

# Arrangements

Now that you've mastered working with notes, the next step is making more patterns and arranging them into a song. Conveniently, you can find the necessary tools in the `ARRANGEMENT` view!

![](/images/overview-arrangement-view.png)

This panel has 3 major parts: the pattern dock, the arrangement grid, and the timeline. Let's take on them in order.


## Pattern dock

On the right side of the arrangement view is a panel where you will immediately find one blue rectangle with a number and perhaps some dots. Below it, at the bottom of the panel, is the `ADD NEW` button. This is the pattern dock, a list of all patterns that you currently have made for your song. Clicking on the button will, predictably, add a new pattern, and once there are too many of them, buttons for scrolling the list will appear. You can also scroll with your <kbd>Mouse Wheel</kbd>.

![](/images/arrangements-dock.png)

To delete a pattern completely, simply <kbd>Left Click</kbd> and start dragging it. Shortly after, a new label will appear beneath the dock that reads `DELETE?`. Drop the pattern on that label, and it will be deleted. If this pattern is used by the song, it will disappear from the arrangement, replaced by emptiness.

![](/images/arrangements-dock-delete.png)

With the basics of pattern management out of the way, it's time to start composing. Once again, <kbd>Left Click</kbd> and drag the pattern, but this time move it to the left side where the arrangement grid is visible. At this point you can see a similar blue rectangle occupying the top-left cell. Drop the pattern into the next cell to add it to the song.

![](/images/arrangements-drag-n-drop.png)

There can be only 4096 unique patterns in a song.


## Arrangement grid

Just like notes in patterns conform to a metronome, ticking away at regular intervals, the entire song conforms to the same metronome as well. The arrangement grid in front of you represents the chronological order of patterns in your song, with each column corresponding to a pattern-sized unit of time called _a bar_. Bars are further split into 8 rows, called channels or tracks. This gives you the means to play up to 8 unique patterns at the same time.

_Bosca Ceoil Blue_ automatically keeps track of every bar that you fill with patterns, and when the time comes to [export your song](/export_import.html), everything that you've added up to that moment will be included. Keep in mind, that the maximum length of any song is 1000 bars.

To add a pattern to the arrangement, drag and drop it from the pattern dock, or <kbd>Left Click</kbd> and drag one of the existing patterns on the grid onto another cell, making a copy. Hold <kbd>Alt</kbd> as you do this, and instead of a copy a new variant of the original pattern will be created. You can also simply <kbd>Alt + Left Click</kbd> on a pattern to turn it into a variant.

<kbd>Right Click</kbd> removes the clicked pattern from the grid. This doesn't delete the pattern, however, and you can still use it later.

![](/images/arrangements-patterns.png)

A pattern that has a reddish frame around it is selected for editing. This is the pattern that you see below, in the [pattern editor](/notes_and_patterns.html). Any time you <kbd>Left Click</kbd> a pattern or create a new pattern by any means, that pattern gets selected.

The grid can be scrolled through with <kbd>Mouse Wheel</kbd> or a [keyboard shortcut](/shortcuts.html). On top of that, you can change the scale of the grid, making it more compact or more spacious, by holding <kbd>Ctrl</kbd> as you scroll.


## Timeline

Below the arrangement grid you can find an extra row with numbers, and a white line crossing through some of the cells. This is the arrangement timeline, a tool that lets you control the parts of the song that are being played. With a <kbd>Left Click</kbd> on any of the cell, you can select the corresponding bar for playback. Hold the mouse button and drag across several cells to select a whole range, or <kbd>Double Click</kbd> on a cell to select every bar from this to the very end.

![](/images/arrangements-timeline-select.png)

The bars selected this way do not affect the export. This is purely a tool for you to preview portions of your song. But the timeline itself can do more than that.

<kbd>Middle Click</kbd> (or <kbd>Shift + Left Click</kbd>) on any bar to insert an empty bar before it. With <kbd>Right Click</kbd> remove the clicked bar completely, shifting every following bar to the left. With any number of bars selected, hover over the arrangement grid and press <kbd>Ctrl + C</kbd> to copy selected bars, then hover over a bar and press <kbd>Ctrl + V</kbd> to paste copied bars before that bar.


## Managing instruments

The next step is all about building and tuning your instrument set. Onto the [Instruments](/instruments.html)!
