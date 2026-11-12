# kuumo-shell

Quickshell config for the Kuumo desktop.

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

`IpcRouter` is the IPC manager. Quickshell already ships a type named `IpcHandler`, so this shell does not reuse that name. `ThemeManager` syncs the wallpaper only; color presets stay in `styles/`.

Run it with:

```bash
quickshell -p /path/to/kuumo-shell
```
"# kuumo-shell" 
