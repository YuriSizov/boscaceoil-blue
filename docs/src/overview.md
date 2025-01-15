---
title: Overview
---

# Application overview

In the following article we give an overview for every part of the user interface of _Bosca Ceoil Blue_, and how it relates to making music.

If you want to jump right into compositing, check [Notes and Patterns](/notes_and_patterns.html) next!

If you'd rather learn with practice, _Bosca Ceoil Blue_ features an interactive guide built right into the app itself! Go to `FILE > HELP` and press `BASIC GUIDE` to get started.

![](/images/overview-builtin-guide.png)


## Bosca Ceoil, a step sequencer

At its core, _Bosca Ceoil Blue_ is a simple musical sequencer. You compose music that is laid out perfectly on a fixed grid. Each cell on this grid represents a unit in time, the minimum length that the played sound can be. We call this _a note_, a 1-unit-long note to be precise. A number of these unit notes in a row form the length of _a pattern_.

Patterns is what your overall song consists of. You arrange patterns across _the timeline_, the timeline that is also split into cells, fitting exactly one pattern. Chain enough patterns together, and you have _a composition_! Every pattern has _an instrument_ assigned to it, and there are 8 _tracks_ for patterns to be played at the same time — giving you flexibility to build up layers to your compositions.

That's the basic principle of making songs with _Bosca Ceoil_. Don't worry if it's too much to grasp at this point, we'll go through each part in this and follow-up articles. Now, let's take a look at the user interface to assign these ideas to the tools at your disposal!


## Your first look

Every time you open _Bosca Ceoil Blue_, this is what you immediately see:

![](/images/introduction-welcome.png)

The whole user interface can be split into two main areas, the upper _tool view_ and the lower _pattern view_.

- The _tool view_ has changeable panels, accessible with the menu at the very top of the application window. Each panel gives you access to a different set of tools and configuration options.
    - The [file view](#file-view).
    - The [arrangement view](#arrangement-view).
    - The [instrument view](#instrument-view).
    - The [advanced view](#advanced-view).
- The [pattern view](#pattern-editor) is always visible and allows you to edit the current pattern at any time.


### File view

The file view is the first upper panel that you see when you open _Bosca Ceoil_. You can also access it at any time by pressing `FILE` in the top menu.

![](/images/overview-file-view.png)

The file view provides access to basic file operations (creating new songs, saving and loading, exporting and importing), key song settings (BPM/tempo, pattern and bar sizes), and playback controls. It also let's you view the built-in help and the credits list.

Most of these features are self-explanatory. You can learn more about song settings in [Notes and Patterns](/notes_and_patterns.html) and [Arrangements](/arrangements.html). Read more about exporting and importing in [Export and Import](/export_import.html).


### Pattern editor

The pattern editor is a permanent part of the user interface. No matter which tool view is currently open, the last selected pattern is always editable via the pattern editor in the lower part of the application window. To change the edited pattern, use the [arrangement view](#arrangement-view).

![](/images/overview-pattern-editor.png)

The pattern editor consists of a note grid and additional editing tools below it. The rows in the grid represent notes at different pitches, starting with low pitches at the bottom and going up. The rows are visually grouped into octaves, giving a number to a set of 12 notes from C (Do) to B (Si). You can scroll the grid using the buttons on the right side of it, or with a [shortcut](/shortcuts.html).

The columns in the grid represent units of time as the pattern progresses. By default, there are 16 units in one pattern. That number can be configured in the [file view](#file-view). Notes can be placed on this grid taking any number of whole cells. Notes can also extend beyond the pattern view, but must always start on one of the pattern cells.

Below the grid are configuration options for the edited pattern: the assigned instrument, the key, the scale. There are also buttons to shift all the notes higher or lower. Finally, you can enable instrument recording, an advanced tuning technique, from the bottom panel (read more in [Instruments](/instruments.html)).

![](/images/overview-pattern-editor-drums.png)

When editing a pattern that uses a drumkit, notes are replaced with drumkit's instruments and some configuration options are disabled.

Continue reading in [Notes and Patterns](/notes_and_patterns.html).


### Arrangement view

The arrangement view can be accessed at any time by pressing `ARRANGEMENT` in the top menu. This is the view you will probably spend the most time in.

![](/images/overview-arrangement-view.png)

The arrangement view consists of a arrangement grid and a pattern dock. The pattern dock contains a list of all available patterns and can be used to create and remove patterns. Patterns can be added to the arrangement by dragging them from the dock.

The arrangement itself is displayed as a grid. There are always 8 rows, which represent 8 tracks that can be played at the same time. The columns represent the so-called bars — units of time fitting exactly one pattern. In other words, one bar is a space equal to the length of a pattern (16 by default) which can be assigned a pattern or left empty.

Above the grid there is a time row, giving you an indication of the real time length for your composition. This row is automatically calculated based on the pattern length and the current BPM/tempo, which can be configured in the [file view](#file-view).

Below the grid there is a timeline row that allows you to select bars for playback, and also manipulate bars (insert a new bar, remove a bar, copy and paste bars).

You can scroll both the dock and the grid using the on-screen buttons, or with a [shortcut](/shortcuts.html).

Continue reading in [Arrangements](/arrangements.html).


### Instrument view

The instrument view can be accessed at any time by pressing `INSTRUMENT` in the top menu.

![](/images/overview-instrument-view.png)

The instrument view consists of an instrument dock and an instrument configuration panel. The instrument dock contains a list of all available instruments and can be used to add or remove instruments. Selecting an instrument in the list makes it available for editing and also makes it the default instrument for the next created pattern.

In the configuration panel you can select the instrument preset for the edited instrument. Presets are available in a number of different categories. There is also a button to select a random instrument preset.

Below the preset selector there are tuning pads for the low-pass filter and the volume of the instrument. The low-pass filter can be adjusted on two axes, configuring the resonance and cutoff values. Tuning the instrument affects all patterns that use that instrument, unless the currently edited pattern has instrument recording enabled.

Continue reading in [Instruments](/instruments.html).


### Advanced view

The advanced view can be accessed at any time by pressing `ADVANCED` in the top menu.

![](/images/overview-advanced-view.png)

The advanced view contains several extra settings for the song and the app overall. For the song you can adjust the swing effect, which affects the timing of upcoming notes, as well as add a global audio effect, which is applied to the entire composition. Only one global effect can be active at a time.

The application settings include the scale of the graphical user interface, the note format, and the size of the internal buffer for the synthesizer. The application settings persist on application restarts and affect all songs. They are not saved with the song, though.


## Making music

Continue on with the basics of creating and editing patterns in [Notes and Patterns](/notes_and_patterns.html)!
