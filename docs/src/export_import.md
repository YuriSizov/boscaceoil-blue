---
title: Export and Import
---

# Export and Import

What's the point of writing music, if you cannot share it? Or perhaps you want to mix it up with another audio editor? Whatever the case, _Bosca Ceoil Blue_ lets you turn your composition into one of more widely recognized formats by the means of exporting.

And, experimentally, it also supports importing existing MIDI files. Both of these options are accessible via the `FILE` menu.


## Exporting to external formats

_Bosca Ceoil Blue_ supports the following external formats:

- Waveform, `.wav`
- Standard MIDI, `.mid`
- FastTracker 2 XM, `.xm`
- SiON MML, `.mml`

Regardless of the format, during the export process you can configure a number of settings to fit your needs.

- **Export bars** allows you to define the range, in arrangement bars, that is going to be exported. By default the entire song is exported, but you might need to only export a part of it, which is where this option becomes helpful.

![](images/io-export.png)

### Limitations

Since external formats follow their own conventions and serve their specific purposes, not every feature available in _Bosca Ceoil Blue_ can be supported when exporting. But we try our best to offer as much compatibility as we can!

#### Waveform file

An uncompressed audio format containing a rendered out song.

- Universally supported by media players, music and video production software, game engines, etc.
- What you hear is what you get.

#### Standard MIDI file

A program file with instructions for MIDI players to reproduce the song.

- Supports only 15 unique instruments + 1 drumkit.
- Non-MIDI Bosca instruments are converted to their closest MIDI approximation.
- Low-pass filter and instrument recording are not supported.

#### FastTracker 2 XM file

A FastTracker-compatible format with uncompressed samples and instructions to reproduce the song.

- Supports up to 256 bars in the arrangement.
- Only one sample per instrument is rendered, which may affect the playback.
- Low-pass filter and instrument recording are not supported.

#### SiON MML file

A music macro language file with a program for a synthesizer written in a SiON flavor of MML.

- Requires SiON/GDSiON-based software to play.
- Volume is normalized, which may result in minimal precision loss.


## Importing from external formats

If you're a daring soul, you might want to try importing a MIDI file into _Bosca Ceoil Blue_ to continue working on it with our little app. We try our best to convert a MIDI composition into a _Bosca_ song, but the reality here is that Standard MIDI format is made to support a vast variety of composition approaches, and _Bosca Ceoil_ is only a step sequencer.

This means that we cannot support multiple time signatures and tempos, as well as any command that doesn't perfectly map to metronome ticks. Within these limitations, you should have decent luck importing songs into the app this way. And on the plus side, _Bosca Ceoil Blue_ supports all standard MIDI instruments, including drumkits.

![](images/io-import.png)

Several configuration options are available for you when importing songs:

- **Pattern size**. When importing a song, we will try to figure out the pattern size based on the timing information that we can find in the MIDI file. However, you might want to adjust the pattern size manually to better fit your composition.

<p class="warning">
Note that exporting and importing using MIDI files should not be used as a replacement for saving and loading <em>Bosca</em> songs normally. Songs exported to MIDI will be converted to be compatible with the format, as outlined above, and any incompatible information (such as non-MIDI instruments) will be forever lost during the process.
</p>
