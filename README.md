<p align="center">
	<img src="assets/logos/logo_blue.png">
</p>

# Bosca Ceoil: The Blue Album

**Bosca Ceoil: The Blue Album** (or _Bosca Ceoil Blue_, for short) is a simple and beginner-friendly music making app. Using a step sequencer you can create anything from a simple beat to a complex melodic piece — with huge selection of synthesized instruments!

_Bosca Ceoil Blue_ is a modern port of **Terry Cavanagh's [Bosca Ceoil](https://github.com/TerryCavanagh/boscaceoil)**, and attempts to preserve everything that made the original so approachable and intuitive. And just like the original, _Bosca Ceoil Blue_ is absolutely free and provided under a permissive open source license, should you need to modify it.

[![patreon-link](https://img.shields.io/badge/Patreon-orange?label=support%20the%20project&color=%23F2614B&style=for-the-badge)](https://patreon.com/YuriSizov)
[![discord-link](https://img.shields.io/badge/Discord-purple?label=get%20in%20touch&color=%235865F2&style=for-the-badge)](https://discord.gg/S657Y9KPF9)

## Features

**An intuitive piano roll sequencer.** Write music by playfully clicking on note blocks and experimenting with note arrangement.

**A pattern-based compositor.** Build patterns using the sequencer, and then drag and rearrange them on the timeline to compose a rich and complex melody.

**300+ synthesized instruments.** A variety of percussion, string, wind, MIDI, and synthwave instruments at your disposal.

**Export WAV and MID files.** Render out music that you've produced to share or to use in your game.

## Why _Bosca Ceoil_ needs a port?

Original _Bosca Ceoil_ is a great tool for budding musicians and game developers. It's almost perfect, but can still benefit from some UX enhancements and improvements to its composing features. It's also using an outdated technology stack which makes it hard to impossible to run it on modern systems, namely macOS and web.

The goal of the _Bosca Ceoil Blue_ project is to make _Bosca Ceoil_ more accessible to today's users and also to new contributors. We achieve this by reimplementing the entire application with a more modern set of tools, as a [Godot engine](https://godotengine.org/) project.

A general-purpose game engine like Godot gives the project means to run on Linux, macOS, and Windows, as well as on web and even mobile phones — almost hassle-free. It's also a popular tool among many game developers, which should make _Bosca Ceoil Blue_ an inviting project for new collaborators.

## State of the port

_Bosca Ceoil Blue_ is still in active development, with several major features implemented, and several more still being worked on.

- [x] Pattern editing, scale and key adjustments.
- [x] Instrument management and tuning.
- [x] Composition and arrangement editing.
- [x] Advanced settings (swing, effects, filters).
- [x] App settings configuration and persistence.
- [x] Advanced instrument tuning.
- [x] Saving and loading.
- [x] Export to WAV, MIDI, SiON MML, and XM.
- [ ] Import from MIDI.
- [x] Keyboard shortcuts.
- [x] Interactive help and on-boarding guide.

A significant part of the port involves recreation of the [SiON software synthesizer](https://github.com/keim/SiON), which the original _Bosca Ceoil_ is based on, as a GDExtension. The progress on that is tracked in a separate project, [GDSiON](https://github.com/YuriSizov/gdsion). This includes platform support, specifically for the Web platform.

## Contributing

Your participation is welcome!

Whether you can test the project and report bugs, or you can work on improvements and missing features, please don't hesitate to reach out.

- For bugs, please consider creating a bug report in the [Issues](https://github.com/YuriSizov/boscaceoil-blue/issues) section of this repository.
- For features, please start a thread in the [Discussion](https://github.com/YuriSizov/boscaceoil-blue/discussions) section of this repository.
- For work coordination, and just to chat about the project, please join our [Discord server](https://discord.gg/S657Y9KPF9).

The project is being developed using the latest available build of **Godot 4.3**. As this version of the engine is still unstable, some bugs unrelated to this project must be expected.

To test and develop _Bosca Ceoil Blue_ you need to:

- Check out this repository, or download it as a ZIP archive.
- Get the [latest release of GDSiON](https://github.com/YuriSizov/gdsion/releases) and extract it into the `bin` folder in the project root.

## License

This project is provided under an [MIT license](LICENSE). Original Bosca Ceoil application is provided under a [BSD-2-Clause-Views license](https://github.com/TerryCavanagh/boscaceoil/blob/da4cedf00c766101f4c7d3a48f1608fc8fd44659/README.md).

## Support

You can support the project financially by donating via [Patreon](https://www.patreon.com/YuriSizov)! Every dollar helps, so please consider donating even if it's a little. Thank you very much <3
