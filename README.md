<p align="center">
  <img src="assets/logo.png" width="180" alt="kuumo-shell logo">
</p>

<h1 align="center">kuumo-shell</h1>

<p align="center">A minimal floating island shell for Quickshell on Hyprland.</p>

---

## About

kuumo-shell is one small pill at the top of your screen that morphs into everything else: a clock, a music player, a control center, a launcher, a clipboard, a power menu and more. The pill grows and shrinks with a spring animation inspired by the iPhone's Dynamic Island, and the look follows a moon-and-cloud theme.

## Features

- **Island**: an idle clock pill with rolling digits, an extended panel (clock, date, now-playing, workspace dots) and a Caps Lock indicator
- **Control center**: Wi-Fi (with network list), Night Light, KDE Connect, Focus, volume and brightness sliders, and a notifications list
- **OSD**: volume and brightness popups inside the island
- **Notifications**: the shell receives them itself and shows toasts; Focus silences the toasts while the list keeps collecting
- **Launcher**: app search, calculator and unit/currency converter with live rates, `>` command mode and an emoji picker
- **Clipboard**: searchable history with pins and image thumbnails
- **Power menu**: lock, sleep, log out, restart and shut down, with hold-to-confirm
- **Theme and wallpaper switchers**: live preview, static and animated wallpapers, and each theme remembers its last wallpaper

## Requirements

- [Quickshell](https://quickshell.org) and [Hyprland](https://hypr.land)
- PipeWire for volume, and any MPRIS media player for the music panel
- NetworkManager (`nmcli`) for Wi-Fi
- `brightnessctl` for brightness
- `hyprsunset` for Night Light
- `cliphist` and `wl-clipboard` for the clipboard
- `awww` and `ffmpeg` for wallpapers and animated-wallpaper thumbnails
- KDE Connect (`kdeconnect-cli`) for the phone button
- Material Symbols font (icons)

## Install

```bash
git clone https://github.com/Ryukabe/kuumo-shell.git ~/.config/quickshell
quickshell
```

If you already have a `~/.config/quickshell`, back it up first, or clone somewhere else and run `quickshell -p /path/to/kuumo-shell`.

Start it from your Hyprland autostart. `kuumo-shell.sh` is a helper script (`start`, `stop`, `restart`, `log`).

## Usage

Everything is driven over IPC, so you can bind these commands to any keys you like.

| Command | Action |
| --- | --- |
| `qs ipc call island toggle` | Switch between the pill and the extended panel |
| `qs ipc call island expand` | Open the extended panel |
| `qs ipc call island collapse` | Back to the pill |
| `qs ipc call island control` | Control center |
| `qs ipc call island launcher` | App launcher |
| `qs ipc call island clipboard` | Clipboard history |
| `qs ipc call island power` | Power menu |
| `qs ipc call island theme` | Theme switcher |
| `qs ipc call island wallpaper` | Wallpaper switcher |
| `qs ipc call island close` | Close whatever is open |
| `qs ipc call osd volumeUp` / `volumeDown` / `volumeMute` | Volume with the on-screen popup |
| `qs ipc call osd brightnessUp` / `brightnessDown` | Brightness with the on-screen popup |

Run `qs ipc show` to list every target and function.

## Structure

```
kuumo-shell/
├── shell.qml                 # entry
├── Config.qml                # user settings
├── qmldir
├── state/                    # global reactive singletons
├── core/                     # shell-wide managers, no UI
├── styles/                   # theme, motion, presets, wallpapers
├── components/               # reusable pieces, no system logic
├── modules/                  # each feature owns its view, service, and qmldir
└── assets/
```

`modules/` holds one folder per feature: `clipboard`, `control`, `display`, `island`, `launcher`, `media`, `network`, `notifications`, `osd`, `phone`, `polkit`, `power`, `system`, `theme`, `wallpaper` and `workspaces`.

`IpcRouter` is the IPC manager. Quickshell already ships a type named `IpcHandler`, so this shell does not reuse that name. `ThemeManager` syncs the wallpaper only; color presets stay in `styles/`.

## Theming

Presets live in `styles/presets/` (KuumoDark and Everblush so far). Each preset lists its own wallpapers, which are looked up in `styles/wallpapers/`. The default palette:

| Name | Hex | Role |
| --- | --- | --- |
| Void Night | `#0a0a0a` | Base background |
| Moonlit Slate | `#131417` | Island surface |
| Cloud Shadow | `#1b1d22` | Sub / elevated background |
| Horizon Mist | `#272a30` | Borders |
| Dim Starlight | `#7e8490` | Muted text |
| Cloud Moon | `#f4f6f9` | Foreground |
| Full Moon | `#ffffff` | Accent |

## Roadmap

- Polkit authentication prompt (in progress)
- Quickshell lock screen
- Shade (hyprshade) tile in the control center
- Theme colors generated from the wallpaper

## Credits

- [Quickshell](https://quickshell.org), [Hyprland](https://hypr.land), [awww](https://codeberg.org/LGFae/awww) and [cliphist](https://github.com/sentriz/cliphist)
- [Material Symbols](https://fonts.google.com/icons) by Google (Apache-2.0)
- Island motion inspired by the iPhone Dynamic Island; the rolling clock digits by [NumberFlow](https://number-flow.barvian.me)
- Exchange rates from [Exchange Rate API](https://www.exchangerate-api.com) (open.er-api.com)

## License

See [LICENSE](LICENSE).