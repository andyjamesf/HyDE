# HyDE — Quickshell Edition

A fork of [HyDE](https://github.com/HyDE-Project/HyDE) (the Hyprland desktop environment) in which
the bar, notifications, OSD, launcher, control center, power menu and lock screen are a single
desktop shell written from scratch in [Quickshell](https://quickshell.org) (QML). Everything else is
still HyDE: the installer, themes, wallbash, wallpapers, scripts and Hyprland configuration.

It installs exactly like the original HyDE:

```sh
git clone --depth 1 https://github.com/andyjamesf/HyDE ~/HyDE
cd ~/HyDE/Scripts && ./install.sh
```

> The original HyDE README (features, themes, community, credits) is in
> [`README.HyDE.md`](README.HyDE.md).

---

## Origin

| | |
|---|---|
| Upstream | [`HyDE-Project/HyDE`](https://github.com/HyDE-Project/HyDE), `master` |
| Forked at | `aceb94ee` (2026-09-20), the Lua configuration era (Hyprland 0.56, `hyprland.lua`) |
| This fork | [`andyjamesf/HyDE`](https://github.com/andyjamesf/HyDE) |
| Shell code | [`Configs/.config/quickshell/`](Configs/.config/quickshell/) |

The edition lives in a small number of self-contained commits on top of upstream, so it can follow
HyDE with a rebase:

```sh
git remote add upstream https://github.com/HyDE-Project/HyDE   # once
git fetch upstream && git rebase upstream/master
```

## What changes compared to HyDE

| Part | HyDE | Quickshell Edition |
|---|---|---|
| Bar | Waybar | Quickshell bar (7 layouts, per-theme colors) |
| Notifications | dunst (or swaync) | shell notification server + popups + history |
| Volume/brightness OSD | notify-send popups | shell OSD |
| App launcher, clipboard, calculator | rofi | shell launcher (4 modes) |
| Keybindings hint | rofi | launcher **Keys** mode |
| Logout menu | wlogout | shell power menu |
| Lock screen | hyprlock | shell lock screen (hyprlock stays as fallback) |
| Control center | — | new |
| Theme/wallpaper/animation pickers, emoji, glyphs, window switcher | rofi | still rofi, restyled with the shell colors |

The installer (`Scripts/dots/quickshell.toml` in the `core` group) installs the shell and its
dependencies and no longer installs `waybar`, `dunst` or `wlogout`. The shell's code is updated by
HyDE updates; your settings in `config/` are only copied when missing and are never overwritten.

Dependencies: `quickshell`, `inter-font`, `upower`, `power-profiles-daemon`, `wl-clipboard`,
`python` and `ttf-material-symbols-variable-git` (AUR).

## Features

### Bar

- **7 layouts**: Islands (default), Minimal, Compact, Floating (a single dock-like island),
  Productivity (CPU/memory/temperature), Media (music in the center with a visualizer) and Bottom.
  Presets live in `config/layouts.json`; you can add your own.
- **Island styles**: theme background, accent tint, raised, accent color, glass, outline only, or a
  fixed `#rrggbb`; **opacity** 50–100 %.
- **Adjustable height** (19–32 px or ±2 px steps). Text, icons and corner radius follow it.
- A layout can be tied to a HyDE theme (`themeLayouts`), and the island corners follow Hyprland's
  `decoration:rounding`, so the bar matches each theme.
- **Widgets**: HyDE menu, workspaces (with app icons), active window, clock, media (with cava),
  AI tools usage, tray, audio, microphone, brightness, network, Bluetooth, battery, system stats,
  caffeine (idle inhibit), night light, notifications, control center and session.
- Each widget has a tooltip, and most open a **popout**: sound (outputs and per-app volume),
  network (Wi-Fi list, connect with password), Bluetooth (pair/connect), display (brightness and
  night light), battery (power profiles), calendar (Google Calendar events via iCal) and media.
- The **HyDE menu** (palette icon) has bar layout, island style and opacity, bar height, shell
  colors, and all of HyDE's actions (theme, wallpaper, animations, workflows, lock screen layout,
  shaders, …).

### Control center (`Super+Alt+C`)

A compact Material 3 panel: user header with settings, lock and session buttons; quick toggles in a
4-column grid (Wi-Fi, Bluetooth, Silent, Night light, Power profile, Caffeine, Microphone, Wallpaper
colors). Right click, long press or the small badge opens the details. Below the grid: volume,
microphone and brightness sliders, a media strip, the latest notifications, and one row of HyDE
shortcuts. It fits a 800 px tall screen without scrolling. Detail pages cover Wi-Fi, Bluetooth,
sound and the full notification history.

### Notifications

A built-in notification server (no dunst/swaync):

- popups for 5 s (paused on hover; critical ones stay), with actions, images and links;
- history in the control center, and Do Not Disturb;
- a new notification with the same app and title replaces the visible one instead of stacking;
- HyDE's own volume/brightness notifications are dropped, because the OSD shows them.

### OSD

Volume, microphone and brightness indicator. It ignores the brightness changes made by hypridle's
screen dimming.

### Launcher (`Super+A`)

One window with four modes (Tab switches mode):

- **Apps**: fuzzy search, favorites (Ctrl+F) and frecency. Typing a calculation shows the result.
- **Clipboard** (`Super+V`): cliphist history with images; Delete removes an entry.
- **Calculator** (`Super+Shift+K`): functions, constants, percentages; Enter copies the result.
- **Keys** (`Super+/`): every Hyprland keybinding with its description, category and readable keys
  (`Super` `/`, `Volume +`, `Left click`), alternative combos on one row, searchable. Enter runs it.

### Power menu (`Ctrl+Alt+Delete`) and lock screen (`Super+L`)

The power menu has lock, suspend, hibernate, log out, restart and shut down; destructive actions
ask for a second press. The lock screen uses `ext-session-lock` with PAM (the same
`/etc/pam.d/hyprlock` configuration, so the same password works). It is driven by hypridle and
`loginctl lock-session`, and it survives a shell reload while locked.

### Colors and theming

- Colors follow HyDE and change with a smooth transition when you switch theme or wallpaper.
  There are three sources: the **HyDE theme's bar colors** (default), the **theme palette
  (wallbash)**, or the **current wallpaper**.
- Every text and icon color is checked for WCAG contrast against what is behind it, so light
  themes and every island style stay readable.
- HyDE's **rofi** menus get the shell's panel colors, opacity and subtle outline. The shell writes
  `~/.config/rofi/theme.rasi` and rewrites it when HyDE replaces it on a theme switch.
- A single design system (`services/Theme.qml`) defines spacing (4 px grid), a Material 3 type
  scale, shapes, surfaces and motion, and every surface uses it.

## Fixes to HyDE itself

- **wallbash**: templates no longer replace symlinked configs (kitty, swaync) with regular files.
  The Waybar color template writes to `~/.cache/hyde/wallbash/bar.css`.
- **Keybindings**:
  - nine workspaces, without the `0` key and the numpad binds for workspaces 10–20;
  - bare `F10`/`F11`/`F12` no longer steal those keys from apps;
  - no duplicate binds;
  - fixed descriptions.
- **Running a bind from the keybindings list**: with the Lua configuration,
  `hyprctl dispatch __lua N` no longer works, so the Keys mode calls the bind's function directly.
- **Shaders**: `custom.frag` used `#define COLOR_VISION_ENABLED true`, which GLES rejects; it is
  now `0`.
- **Blur**: blur for the shell's layers and for the bar popouts (`blur_popups`).

## Keybindings

The shell's own binds (all others are HyDE's; press `Super+/` for the full list):

| Keys | Action |
|---|---|
| `Super+A` | launcher (apps; type a calculation to compute it) |
| `Super+V` | clipboard |
| `Super+Shift+K` | calculator |
| `Super+/` | keybindings |
| `Super+Alt+C` | control center |
| `Super+N` | notification history |
| `Super+Alt+↑` / `↓` | next / previous bar layout |
| `Super+Ctrl+B` | hide / show the bar |
| `Super+L` | lock |
| `Ctrl+Alt+Delete` | power menu |

## Configuration

`~/.config/quickshell/config/config.json` holds only what you change. Defaults are in
`services/Config.qml`, and changes apply live:

```jsonc
{
  "bar": {
    "layout": "islands",           // a name from config/layouts.json
    "position": "top",             // "top" | "bottom"
    "opacity": 0.92,
    "pillStyle": "tint",           // surface | tint | container | accent | glass | outline | "#rrggbb"
    "themeLayouts": { "Catppuccin-Latte": "minimal" }
  },
  "appearance": { "locale": "en_GB", "font": "Inter", "fontSize": 12, "animationScale": 1 },
  "widgets": {
    "workspaces": { "shown": 5, "appIcons": true },
    "clock": { "format": "HH:mm", "showDate": false },
    "notifications": { "timeout": 5000, "maxPopups": 4, "historySize": 100 },
    "osd": { "enabled": true, "timeout": 1500 },
    "lock": { "enabled": true }    // false: lock with HyDE's hyprlock
  }
}
```

What you pick in the menus (layout, island style, opacity, height, color source, Do Not Disturb)
is stored in `~/.local/state/quickshell/` and takes priority over `config.json`.

**Google Calendar**: create `~/.local/share/quickshell/calendars.json` with each calendar's secret
iCal address. It stays out of any repository, because the address gives read access:

```json
{ "calendars": [ { "name": "Personal", "url": "https://calendar.google.com/calendar/ical/…/basic.ics", "color": "#8ab4f8" } ] }
```

## IPC

Everything can be driven from scripts or binds (`qs ipc show` lists it all):

```
qs ipc call bar            toggle | show | hide | layout <name> | next | prev | pill <style>
                           opacity <0..1> | height <px> | taller | shorter | agents
                           popout <name> | menu <name[:submenu]> | tooltip <name>
qs ipc call controlcenter  toggle | open | close | page wifi|bluetooth|audio|notifications
qs ipc call launcher       toggle | clipboard | calc | keys | close | openOn <screen>
qs ipc call notifications  toggle | open | toggleDnd | clear
qs ipc call colors         source hyde|wallbash|wallpaper | toggle
qs ipc call lock           lock | unlock | isLocked
qs ipc call idle           toggle | isInhibited
qs ipc call brightness     up | down | set <percent>
qs ipc call powermenu      toggle
qs ipc call shell          reload
```

## Going back to HyDE's original pieces

In `~/.config/hypr/hyprland.lua` (HyDE's user override layer):

- **Waybar**: `hyde.config.start.bar = "hyde-shell app -u hyde-" .. os.getenv("XDG_SESSION_DESKTOP") .. "-bar.scope -t scope -- waybar.py --watch"`
  (and install `waybar`).
- **dunst**: `hyde.config.start.notifications = "hyde-shell app -u hyde-" .. os.getenv("XDG_SESSION_DESKTOP") .. "-notifications.service -t service -- dunst"`
  (and install `dunst`).
- **hyprlock**: set `"lock": { "enabled": false }` in `config.json`. hypridle also falls back to
  hyprlock whenever the shell is not running.

**Locked out?** Switch to a TTY (`Ctrl+Alt+F3`), log in and run `qs ipc call lock unlock`. If
Hyprland shows "the lockscreen app died", run
`hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'` instead.

## Project layout

| Path | Contents |
|---|---|
| `Configs/.config/quickshell/shell.qml` | entry point: per-screen windows and IPC targets |
| `…/services/` | singletons with the logic: colors, audio, network, Bluetooth, notifications, launcher, keybindings, lock, rofi colors… |
| `…/components/` | reusable visual pieces (buttons, sliders, cards, popouts, menus, tooltips) |
| `…/modules/` | bar, control center, notifications, OSD, launcher, power menu, lock screen |
| `…/config/` | `config.json` and `layouts.json` (user settings; never overwritten) |
| `Scripts/dots/quickshell.toml` | installer entry (packages and files) |
| `Configs/.local/share/hypr/lua/` | HyDE's Lua config: shell autostart, binds, layer rules |
| `Configs/.local/share/hyde/wallbash/` | wallbash templates (shell palette, bar colors) |

## Credits

- [HyDE](https://github.com/HyDE-Project/HyDE) and its contributors, for everything this builds on.
- [Quickshell](https://quickshell.org), the QML toolkit the shell runs on.
- Ideas were drawn from [Noctalia](https://github.com/noctalia-dev/noctalia-shell),
  [Caelestia](https://github.com/caelestia-dots/shell),
  [end-4's dots](https://github.com/end-4/dots-hyprland) and
  [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell). The code here is original.

Licensed under the same license as HyDE ([GPL-3.0](LICENSE)).
