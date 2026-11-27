<p align="center">
  <img src="assets/logo.png" width="180" alt="kuumo-shell logo">
</p>

<h1 align="center">kuumo-shell</h1>

<p align="center">A minimal floating island shell for Quickshell on Hyprland.</p>

---

## About

kuumo-shell is one small pill at the top of your screen that morphs into everything else: a clock, a music player, a control center, a launcher, a clipboard, a power menu and more. The pill grows and shrinks with a spring animation inspired by the iPhone's Dynamic Island, and the look follows a moon-and-cloud theme.

It is only a shell. It needs Hyprland, and it is its own notification daemon and polkit agent.

## Features

- **Island**: an idle clock pill with rolling digits, an extended panel (clock, date, now-playing, workspace dots) and a Caps Lock indicator
- **Control center**: Wi-Fi (with network list), Night Light with temperature and dimming sliders, KDE Connect, Focus, volume and brightness sliders, and a notifications list
- **OSD**: volume and brightness popups inside the island
- **Notifications**: the shell receives them itself and shows toasts; Focus silences the toasts while the list keeps collecting
- **Launcher**: one search box for apps, settings, files, the web, `>` commands, a calculator, a unit/currency converter with live rates and an emoji picker. Results are grouped, and every source can be switched off
- **Clipboard**: searchable history with pins and image thumbnails. Choose an item and it is copied and pasted into the window you came from
- **Power menu**: lock, sleep, log out, restart and shut down, with hold-to-confirm
- **Authentication prompt**: when a program asks for your password, the island opens by itself with who is asking and a password field with the Authenticate button inside. A wrong password shakes the field, Caps Lock shows an icon, and closing the island cancels the request
- **Theme and wallpaper switchers**: live preview, static and animated wallpapers, and each theme remembers its last wallpaper. Drop image files on the island to add them as wallpapers
- **Settings window**: appearance (including your own custom theme colors), animations and the options of each feature
- **Motion**: typewriter text effects, a rolling clock, spring animations with adjustable speed and bounce, and a reduce-motion switch
- **Keyboard first**: `Esc` closes any panel; the launcher, clipboard, switchers and authentication prompt take the keyboard while open; sliders move with the arrow keys (`Page Up`/`Page Down` or `Shift`+arrows for bigger steps)

## Requirements

`install.sh` installs all of this on Arch Linux. On another distro, install it yourself.

- [Quickshell](https://quickshell.org) and [Hyprland](https://hypr.land), with systemd (power menu) and polkit
- PipeWire for volume, and any MPRIS media player for the music panel
- NetworkManager (`nmcli`) for Wi-Fi
- `brightnessctl` for brightness
- `hyprsunset` for Night Light
- `cliphist` and `wl-clipboard` for the clipboard, and `wtype` to paste from it
- `awww` for wallpapers and `ffmpeg` for animated-wallpaper thumbnails
- `fd` for file search in the launcher, and `xdg-utils` to open files and links
- KDE Connect (`kdeconnect-cli`) for the phone button
- Fonts: Inter, JetBrains Mono Nerd Font and Material Symbols Rounded

Run only one polkit agent and one notification daemon. If you have another one (`hyprpolkitagent`, `polkit-gnome`, `mako`, `dunst` and so on), take it out of your autostart.

## Install

On Arch Linux:

```bash
git clone https://github.com/Ryukabe/kuumo-shell.git
cd kuumo-shell
./install.sh
```

The installer:

- installs the dependencies with pacman, and with your AUR helper (yay or paru) for anything not in the official repositories. If you have neither, it offers to build yay
- links the folder to `~/.config/quickshell`, after asking and backing up whatever is there. If the folder already is `~/.config/quickshell`, it leaves it alone
- warns if another polkit agent or notification daemon is running
- never edits your Hyprland config. That part is yours, see below

It is safe to run again. On another distro, install the requirements yourself and put the folder at `~/.config/quickshell`.

## Hyprland setup

Add this to your Hyprland Lua config (`~/.config/hypr/hyprland.lua`, the default since Hyprland 0.55).

### Autostart

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon") -- skip this line if you already start it elsewhere
  hl.exec_cmd("qs")
end)
```

### Keybinds

The keys are suggestions. Change them to whatever you like.

```lua
local mainMod = "SUPER"
local ipc = "qs ipc call "

hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. "island launcher"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(ipc .. "island control"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(ipc .. "island clipboard"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(ipc .. "island power"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(ipc .. "island theme"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(ipc .. "island wallpaper"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings toggle"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "osd volumeUp"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "osd volumeDown"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "osd volumeMute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "osd brightnessUp"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "osd brightnessDown"), { locked = true, repeating = true })
```

`qs ipc call` talks to the default Quickshell instance. If you start the shell with `-p /path/to/kuumo-shell`, add the same `-p` to every call.

### Layer rules

Hyprland's own layer animations run on top of the island's and cause glitches, so turn them off for the shell:

```lua
hl.layer_rule({
  name = "kuumo-no-anim",
  match = { namespace = "^kuumo-shell$" },
  no_anim = true,
})
```

Optional, blur behind the island:

```lua
hl.layer_rule({
  name = "kuumo-blur",
  match = { namespace = "^kuumo-shell$" },
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
```

### Permissions

If you turn on Hyprland's permission system (`ecosystem.enforce_permissions`), allow `wtype`'s virtual keyboard, or pasting from the clipboard will not work. See the [permissions page](https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/) of the Hyprland wiki.

<details>
<summary>Classic <code>hyprland.conf</code></summary>

```ini
exec-once = awww-daemon
exec-once = qs

bind = SUPER, Space, exec, qs ipc call island launcher
bind = SUPER, A, exec, qs ipc call island control
bind = SUPER SHIFT, V, exec, qs ipc call island clipboard
bind = SUPER, X, exec, qs ipc call island power
bind = SUPER, T, exec, qs ipc call island theme
bind = SUPER, W, exec, qs ipc call island wallpaper
bind = SUPER, comma, exec, qs ipc call settings toggle

bindel = , XF86AudioRaiseVolume, exec, qs ipc call osd volumeUp
bindel = , XF86AudioLowerVolume, exec, qs ipc call osd volumeDown
bindl = , XF86AudioMute, exec, qs ipc call osd volumeMute
bindel = , XF86MonBrightnessUp, exec, qs ipc call osd brightnessUp
bindel = , XF86MonBrightnessDown, exec, qs ipc call osd brightnessDown
```

For the layer rules, see the Hyprland wiki.

</details>

## Usage

Everything is driven over IPC, so you can bind these commands to any keys you like.

| Command | Action |
| --- | --- |
| `qs ipc call island toggle` | Switch between the pill and the extended panel |
| `qs ipc call island expand` | Open the extended panel |
| `qs ipc call island collapse` | Back to the pill |
| `qs ipc call island control` | Control center |
| `qs ipc call island launcher` | App launcher |
| `qs ipc call island commands` | Launcher on its command list |
| `qs ipc call island command <id>` | Open one command straight away, for example `emoji` |
| `qs ipc call island clipboard` | Clipboard history |
| `qs ipc call island power` | Power menu |
| `qs ipc call island theme` | Theme switcher |
| `qs ipc call island wallpaper` | Wallpaper switcher |
| `qs ipc call island close` | Close whatever is open |
| `qs ipc call osd volumeUp` / `volumeDown` / `volumeMute` | Volume with the on-screen popup |
| `qs ipc call osd brightnessUp` / `brightnessDown` | Brightness with the on-screen popup |
| `qs ipc call settings toggle` | Open the Settings window, or close it |
| `qs ipc call settings openPage <id>` | Open Settings on one page |

Run `qs ipc show` to list every target and function.

## Updating

```bash
cd kuumo-shell      # the folder you cloned
git pull
./kuumo-shell.sh restart
```

`kuumo-shell.sh` is a small helper with `start`, `stop`, `restart` and `log`.

## Configuration

Every option is documented with a comment in `Config.qml`.

## Structure

```
kuumo-shell/
├── shell.qml                 # entry
├── Config.qml                # user settings
├── qmldir
├── install.sh                # installs the dependencies and links the shell
├── kuumo-shell.sh            # start / stop / restart / log helper
├── state/                    # global reactive singletons
├── core/                     # shell-wide managers, no UI (IpcRouter, ipc/)
├── styles/                   # theme, motion, presets, wallpapers
├── components/               # reusable pieces, no system logic
├── modules/                  # each feature owns its view, service, and qmldir
└── assets/
```

`modules/` holds one folder per feature: `clipboard`, `control`, `display`, `island`, `launcher`, `media`, `network`, `notifications`, `osd`, `phone`, `polkit`, `power`, `system`, `theme`, `wallpaper` and `workspaces`.

`IpcRouter` is the IPC manager, with one handler file per target in `core/ipc/`. Quickshell already ships a type named `IpcHandler`, so this shell does not reuse that name. `ThemeManager` syncs the wallpaper only; color presets stay in `styles/`.

## Theming

Presets live in `styles/presets/`: Kuumo Dark, Everblush, Tokyo Night, Rose Pine and Ayu Dark. You can also build your own colors in Settings, Appearance. Each preset lists its own wallpapers, which are looked up in `styles/wallpapers/`.

Every theme has seven surface and text colors and eight status colors. The default palette (Kuumo Dark):

| Name | Hex | Role |
| --- | --- | --- |
| Void Night | `#0a0a0a` | Base background |
| Moonlit Slate | `#131417` | Island surface |
| Cloud Shadow | `#1b1d22` | Sub / elevated background |
| Horizon Mist | `#272a30` | Borders |
| Dim Starlight | `#8a909c` | Muted text |
| Cloud Moon | `#f4f6f9` | Foreground |
| Full Moon | `#e0ddd8` | Accent |

| Status | Hex |
| --- | --- |
| Red | `#e06c75` |
| Orange | `#e49567` |
| Yellow | `#e5c07b` |
| Green | `#98c379` |
| Cyan | `#56b6c2` |
| Blue | `#61afef` |
| Purple | `#c678dd` |
| Pink | `#e387b1` |

## Roadmap

- Quickshell lock screen
- Shade (hyprshade) tile in the control center
- Theme colors generated from the wallpaper
- An update command inside the shell

## Credits

- [Quickshell](https://quickshell.org), [Hyprland](https://hypr.land), [awww](https://codeberg.org/LGFae/awww), [cliphist](https://github.com/sentriz/cliphist) and [wtype](https://github.com/atx/wtype)
- [Material Symbols](https://fonts.google.com/icons) by Google (Apache-2.0), [Inter](https://rsms.me/inter/) and [JetBrains Mono](https://www.jetbrains.com/lp/mono/) (SIL OFL)
- Island motion inspired by the iPhone Dynamic Island; the rolling clock digits by [NumberFlow](https://number-flow.barvian.me)
- Exchange rates from [Exchange Rate API](https://www.exchangerate-api.com) (open.er-api.com)

## License

See [LICENSE](LICENSE).