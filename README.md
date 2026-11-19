<p align="center">
  <img src="docs/icon.png" width="84" alt="App Folder" />
</p>

<h1 align="center">App Folder</h1>

<p align="center">
  An app folder on the Plasma desktop.
  The widget composes a live icon from the folder contents and opens a popup with your apps on click.
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT" /></a>
  <img src="https://img.shields.io/badge/Plasma-6-1d99f3" alt="KDE Plasma 6" />
  <img src="https://img.shields.io/badge/lang-en%20%7C%20ru-inactive" alt="Interface: English and Russian" />
</p>

<p align="center">
  English | <a href="README_RU.md">Русский</a>
</p>

<p align="center">
  <img width="675" height="450" alt="demo.webp" src="https://github.com/user-attachments/assets/ee0d1ff6-b962-4dfd-b18d-59a13fac47d3" />
</p>

## Features

- **Live icon** — composed of the app icons in the folder, so the contents are visible before you open it
- **Zero setup** — a new widget gets its folder created on the spot, drop launchers right away
- **Everything by drag and drop** — drop a `.desktop` file on the widget, drag an icon out of the popup; the file just moves
- **A plain folder** — just `.desktop` files: edit them in Dolphin or a terminal, sync however you like — changes are picked up automatically
- **Smart popup** — picks its side of the screen and never spills past the edges; sorting, scrolling, click or hover to open

## Installation

### From the store

Right-click the desktop → “Add Widgets…” → “Get New Widgets…”, search for “App Folder”.

### From releases

Download `plasma-appfolder.plasmoid` from the [releases page](https://github.com/ttempaa/plasma-appfolder/releases):

```sh
kpackagetool6 --type Plasma/Applet --install plasma-appfolder.plasmoid
```

### From source

Requires `make` and `msgfmt` (gettext):

```sh
git clone https://github.com/ttempaa/plasma-appfolder
cd plasma-appfolder
make && kpackagetool6 --type Plasma/Applet --install .
```

Upgrade with `--upgrade` instead of `--install`; remove with `--remove com.github.ttempaa.plasma.appfolder`.
Widget data (folders and the shared config) lives in `~/.local/share/plasma-appfolder/`.

## Compatibility

Plasma 6 (developed and tested on 6.8, Wayland).

## License

Code is [MIT](LICENSE). Icon glyphs are from [Lucide](https://lucide.dev), ISC license.
