---
title: Instruments
---

# Instruments

The second most important tool after the arrangement view is the `INSTRUMENT` view.

In _Bosca Ceoil Blue_ you can find hundreds of instrument presets, but instead of using them directly you first must create a song instrument out of one of them. This allows you to quickly find the instrument that you need when editing patterns, and to use the same preset multiple times with different tuning configurations.

![](/images/overview-instrument-view.png)


## Instrument management

The instrument view is split into two parts: the instrument dock and the instrument configuration panel. Similarly to how you can create and delete patterns from the dock in the [arrangement view](/arrangements.html), you can create and delete instruments from the instrument dock. Pressing `ADD NEW INSTRUMENT` adds a random instrument to the list, while dragging and dropping one of the existing instruments onto the `DELETE?` label deletes it.

![](/images/instruments-dock-delete.png)

You can only create up to 16 unique instruments.

The newly added instrument is random, so you can discover something fresh every time! But you have full control over what you will use in the end. To the right of the dock is the configuration panel, where you can select a specific instrument, or roll the dice again and find another random one.

Instruments are grouped into several categories, with the MIDI set being split even further due to its sheer size. The complete list of instrument categories is as follows:

- MIDI
- Chiptune
- Bass
- Brass
- Bell
- Guitar
- Lead
- Piano
- Special
- Strings
- Wind
- World
- Drumkit

![](/images/instruments-categories.png)

And the following are sub-categories of MIDI instruments:

- Piano
- Bells
- Organ
- Guitar
- Bass
- Strings
- Ensemble
- Brass
- Reed
- Pipe
- Lead
- Pads
- Synth
- World
- Drums
- Effects

Instruments are loosely color-coded, which not only makes _Bosca Ceoil BLue_ look fun and appealing, but also helps you to distinguish them. The instrument used also defines the color of the pattern, as you might've noticed already.

Once created, the instrument can be selected for any pattern using the list in the bottom-left corner of the [pattern editor](/notes_and_patterns.html).

![](/images/instruments-pattern-picker.png)


## Tuning

One way to further define the voice of the instrument that you've selected is to tweak and tune it. Each instrument allows you to adjust two settings: the low-pass filter and the volume. The volume should be self-explanatory, and it gives you means to make the instrument quieter.

The low-pass filter may require a bit of an explanation. Controlled with a pad rather than a 1-dimensional slider, this filter has two parameters, resonance and cutoff. Moving the pad head left and right adjusts the cutoff point, while moving it up and down changes the resonance.

![](/images/instruments-tuning-pads.png)

The low-pass filter, as the name suggests, allows audio frequencies below the cutoff threshold to pass freely, while damping those that go beyond that limit. In other words, the further left you move the pad head, the less high-frequency sounds will be allowed by the instrument.

Resonance, in turn, allows to additionally amplify the sound around the cutoff point. This makes the sounds close to the cutoff frequency to be more pronounced, peaking. A use case for this would heavily depend on each particular instrument, so feel free to experiment!

<p class="warning">
Some sounds produced this way may be unpleasant, especially at extreme values. Please take care and try lowering the volume first, or avoid using headphones until you understand what you can expect here.
</p>


## Instrument recording

You can push instrument tuning even further than that! At the bottom of the [pattern editor](/notes_and_patterns.html) there is a mysterious `REC` button with a round icon. When clicked, the icon turns red and the instrument view opens — on the instrument that the edited pattern uses. A pinkish label `! RECORDING: PATTERN N !` also appears, as the tuning pads get a similarly pinkish frame.

![](/images/instruments-recording.png)

This feature is called instrument recording, and what it allows you to do is to set specific values for the low-pass filter and volume of the instrument for each individual tick of the pattern.

While the recoding mode is enabled and the pattern is being played through, start changing the values using the tuning pads. As you move a pad head, you should notice a colorful trail that is left by it. Those are the values recorded for each note of the pattern, color-coded from red to green.

![](/images/instruments-recording-values.png)

If you disable the recording mode on the pattern, it reverts to using the default configuration of the instrument. But the recorded values are still stored, and you can re-enable the recording mode later.

<p class="warning">
Due to a bug in an older version of <em>Bosca Ceoil</em>, only the first 16 notes can retain their recorded values when the file is saved. <em>Bosca Ceoil Blue</em> aims to maintain compatibility with that version, so it maintains this bug as well. This will be addressed in a future major version of the app.
</p>

This is a fancy tool which can be very powerful, but it may take some time to master and find the use case for. Once again, try it and see if it gives you any inspiration!


## Adding audio effects

Continue on to [Effects](/effects.html), and you will learn about the final piece of the puzzle — global effects and filters.
