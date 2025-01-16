---
title: Notes and Patterns
---

# Notes and patterns

The moment you start _Bosca Ceoil Blue_ up you can already begin placing notes!

Give it a try, and <kbd>Left Click</kbd> anywhere on the big empty grid. You should hear the sound of a `MIDI Grand Piano` when the vertical line reaches the note that you've just placed.

![](images/patterns-placing-notes.png)

Keep adding more notes! If it gets too noisy, <kbd>Right Click</kbd> on any existing note to remove it.

![](images/patterns-removing-notes.png)

You can also hold <kbd>Ctrl</kbd> and scroll your <kbd>Mouse Wheel</kbd> to adjust the size of the cursor, allowing you to place longer or shorter notes.

It's that simple, and you can probably pick some notes by ear to arrange a favorite childhood song already. But let's talk about patterns a bit.


## Note patterns

_Bosca Ceoil Blue_ is a step sequencer, which means it plays notes at equal intervals. You can think of it as clicks of _a metronome_. _Tick, tick, tick, tick_. Each _tick_ representing the time when a note can be potentially played.

When you were previously clicking on the big empty grid, you were telling _Bosca Ceoil_ to play a note at a specific tick of the metronome. You were kind of programming it! And as a result, as the big vertical line (called the player head) moves from left to right, tick after tick, placed notes get executed.

Take note that there are only 16 cells in any given row of the grid, and once the player head reaches the far right side, the sequence starts all over again, looping.

![](images/patterns-length.png)

The grid that you see before you represents a note pattern, where all placed notes belong to. You are immediately given one when you create a new song, and you will likely create many more as you work on your composition. Each note pattern has a fixed length, which is exactly 16 notes by default. You can change that size in the [file view](overview.html#file-view), but keep in mind that this affects every pattern of the song at the same time.

We will talk more about patterns in [Arrangements](arrangements.html), for now let's focus on the relationship between patterns and notes.


## Placing notes

When you place a note on the grid, you add it to the currently edited pattern. You can place up to 128 unique notes in the same pattern, and you are given a free roam over where to put them. We've established before that each column of the grid represents a tick of the metronome. Each row, in turn, represents a different pitch of a note.

A pitch is how high or how low the note sounds, and quite literally the lowest pitches can be found at the bottom of the grid, while the highest are located at the top. The rows of pitches are grouped into octaves and labeled according to the current musical key (seen in the bottom right). By default the grid is opened around 4-5 octaves, which is a good starting point for any instrument.

### Basics

To place a note, <kbd>Left Click</kbd> on any empty cell of the grid. You cannot place a note into a cell that is already occupied. To remove the note, <kbd>Right Click</kbd> on it. Hold <kbd>Ctrl</kbd> and use your <kbd>Mouse Wheel</kbd> to change the size of the placed note. Hold <kbd>Ctrl</kbd> and <kbd>Left Click</kbd> on any existing note to copy its size; click on an empty space instead to reset the size back to 1.

![](images/patterns-drawing.png)

Notes longer than 1 cell in size can overlap, when placed into the same row, but cannot start where another note starts. Notes can be as long as 128 ticks, although patterns can only go up to 32 ticks. Notes can also be placed in a way that their tail exceeds the bounds of the edited pattern, but they must start within the bounds. This is safe to do, and may even be desirable for some instruments. When [exporting](export_import.html) these notes are accounted for correctly.

### Previewing

You can test the way the note sounds before committing to it. Click on the note label on the left side of the pattern editor, and you'll be able to hear it with the currently selected pitch, key, and length without placing it into the pattern.

To help you further, notes that are placed when the playback is stopped or paused are played immediately.

### Selecting and stamping

If you hold <kbd>Shift</kbd> and then <kbd>Left Click</kbd> and drag across the grid, you can select notes. Pressing <kbd>Ctrl + C</kbd> when notes are selected copies them. Copied notes can be inserted into the same or a different pattern with <kbd>Ctrl + V</kbd>. Inserted notes are placed relative to the cursor, to the top-right of it.

![](images/patterns-stamping.png)

### Transposing

Using the plus and minus buttons below the grid the entire pattern of notes can be shifted higher or lower at the same time. As notes cannot overlap each other, shifting them close to the top and bottom limits may result in notes piling up, like Tetris pieces.

### Action history

You can always undo any recent change. The application remembers the last 40 actions that you performed, and allows you to step back and forth through these actions. Press <kbd>Ctrl + Z</kbd> to undo an action, and <kbd>Shift + Ctrl + Z</kbd> to redo the last undone action. This applies to everything you do in _Bosca Ceoil Blue_, not just placing notes.


## Key and scale

By default, the pattern is configured to be in the _C-key_ (or _Do_), with the _C_ (_Do_) note being at the start of each octave and _B_ (_Si_) being at the end. You can change the key for the edited pattern at the bottom right of the pattern editor. If you don't know why you would want to do that, it's safe to keep it as _C_ (_Do_).

What you actually might want to change as you experiment with the produced sounds is the scale. For the purposes of _Bosca Ceoil_ the scale allows you to limit yourself to a subset of pitches that sound good together. It's a neat trick that helps you compose better music even if you're just a beginner!

![](images/patterns-scale-key.png)

Try experimenting with available options. Scales and chords are commonly associated with different moods that you might want to convey. You can look up the names online to get an idea which scale option would be good for you.


## Instrument

The instrument that the edited pattern uses is displayed in the bottom left corner. There you can also change the instrument to another, out of those available for the song. New instruments can be added in the [instrument view](overview.html#instrument-view) before they can be selected here.

The instrument is associated by its number. This means that if, for example, you change the instrument preset for the instrument number 3, all patterns that use the instrument number 3 will now use the new preset. If you delete an instrument, patterns that use it are updated to another available option.

![](images/patterns-instrument.png)

### Drumkits

By and large, patterns that use drumkits can be edited in the same way as any other pattern. However, there are some differences. Drumkits represent a set of instruments (a kit, if you will) grouped together by association. Each instrument in a drumkit is tuned to a certain pitch and cannot be changed.

For these reasons, instead of pitches and octaves you have a grid where each row represents a drumkit item. On top of that, the key and scale selectors are hidden when working with drumkits.

![](images/patterns-drumkits.png)


## Arranging patterns

Continue to [Arrangements](arrangements.html) to learn about managing and arranging patterns, and song composition!
