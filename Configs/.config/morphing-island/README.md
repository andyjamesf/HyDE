# Morphing Island

A Quickshell (QML) desktop shell built around **one floating island** at the top of each screen. The
same surface morphs between a small clock pill, an expanded bar, volume/microphone/brightness OSDs,
notifications, a launcher, a control center, theme and wallpaper pickers, settings, a power menu,
a polkit prompt and the lock screen. Geometry is driven by a critically damped spring: it moves
fast, arrives cleanly and never bounces.

It is independent from the HyDE Quickshell shell (`~/.config/quickshell`), which is never modified.
Only one of the two runs at a time.

## Switching

```sh
island on       # stop the HyDE shell and its polkit agent, start the island
island off      # back to the HyDE shell (bar, notifications, polkit agent)
island toggle
island status   # "island" or "hyde"
island ipc <function> [args]    # e.g. island ipc open launcher
```

The choice is stored in `~/.local/state/morphing-island/active`, so it survives logins and
`hyprctl reload`. `Super+Alt+I` toggles it too. On login HyDE's `lua/morphing_island.lua` starts
whichever shell is active.

Run by hand: `qs -p ~/.config/morphing-island` (a named config via `qs -c` is not possible while
`~/.config/quickshell/shell.qml` exists: Quickshell then ignores its subfolders).

## What it does

| Mode | How to get there | Notes |
|---|---|---|
| Clock | default | time; equalizer bars while music plays |
| Expanded | hover, or click empty space to pin | media controls · time and date · volume, Bluetooth, Wi‑Fi signal, battery |
| Volume / microphone / brightness OSD | changing volume, mic volume/mute or brightness | icon reacts to the level; 1.5 s; ignores hypridle's dimming |
| Notification | a notification arrives | countdown pauses on hover; click dismisses; critical ones are red and stay 12 s; queued behind open surfaces |
| Launcher | `Super+A` | fuzzy apps with favorites (`Ctrl+F`) and frecency; animated results |
| Calculator | `Super+Shift+K`, or type `=` | live result; Enter copies |
| Keybindings | `Super+\`, or type `?` | every Hyprland bind with readable keys, searchable; Enter runs it |
| Clipboard | `Super+V`, or type `:` | cliphist history (text and images); Enter pastes into the previous window; Delete removes |
| HyDE menus | `Super+Shift+A` | every picker below in one list (incl. those without a bind) |
| Windows | `Super+Tab` | open windows; Enter focuses |
| Files | `Super+Shift+E` | files in your home; Enter opens |
| Web search | `Super+Shift+/` | HyDE's search engines; Enter opens the browser |
| Emoji / Glyphs | `Super+Shift+,` / `Super+.` | grid; Enter copies and types it (HyDE's lists) |
| Bookmarks, Quick apps, Games | HyDE menus | browser bookmarks, HyDE quickapps, Steam/Lutris |
| Wallbash mode, Animations, Lock layout | `Super+Shift+R` / `Y` / `U` | current option first, badge "Current"; applied through HyDE |
| Workflows, Shaders, Layouts | HyDE menus | same, applied through HyDE |
| Control center | `Super+Alt+C`, `Super+N` | tiles (Wi‑Fi, Bluetooth, Sound, Peace Mode, Night Light, Caffeine): icon toggles, the rest opens the page; volume/brightness sliders; media; notification history with Clear All |
| Wi‑Fi / Bluetooth / Sound / Media pages | from the control center | slide in while the island resizes; Esc goes back |
| Themes | `Super+Shift+T` | 18 schemes (dark, light, e‑ink) + "Wallpaper" (wallbash palette) + "HyDE" (theme's bar colors) |
| Wallpapers | `Super+Shift+W` | HyDE thumbnails, accent ring on the active one; set through HyDE (palette follows) |
| Settings | `Super+Alt+,` | bar height 30–51 and font size live; hover, Peace Mode, animations, speed |
| Power | `Ctrl+Alt+Delete` | Lock, Suspend immediate; Log out, Restart, Power off need a second click |
| Polkit | an app asks for privileges | password goes only to polkit; Esc or outside click cancels; a failure closes safely |
| Lock | `Super+L`, idle | the clock pill morphs into the lock card; same PAM config as hyprlock; survives a reload |

**Peace Mode** hides notification popups (critical ones still show); everything still lands in the
history. **Caffeine** keeps the session awake (an idle inhibitor on the island: no dimming, lock or
suspend by hypridle) until turned off; it survives restarts.

Keyboard: every surface takes focus when it opens; arrows/Enter work in lists and grids; Esc goes
back or closes; clicking outside closes. The mouse only selects after it really moves.

## Keybindings

The same `Super` binds serve both shells: each one goes to whichever is active. They are configured in
**`~/.config/hypr/keybinds.lua`** (documented there: add, move or remove a bind, or override one of
HyDE's defaults); HyDE's `lua/morphing_island.lua` only reads that file. Run `hyprctl reload` after editing it.

| Keys | Island | HyDE shell |
|---|---|---|
| `Super+A` | launcher | launcher |
| `Super+V` | clipboard | clipboard |
| `Super+Shift+K` | calculator | calculator |
| `Super+Alt+C`, `Super+N` | control center | control center / notifications |
| `Super+Shift+T` / `Super+Shift+W` | theme / wallpaper pickers | HyDE's pickers |
| `Super+/`, `Super+\` | keybindings list | keybindings list |
| `Super+Tab`, `Super+Shift+E`, `Super+.`, `Super+Shift+,`, `Super+Shift+/` or `Super+Shift+\`, `Super+Shift+R/Y/U/G` | island pickers | HyDE's rofi menus |
| `Super+Shift+A` | HyDE menus (all pickers) | HyDE's rofi selector |
| `Super+Alt+I` | switch to the HyDE shell | switch to the island |
| `Super+,`, `Super+Ctrl+B` | hide/show the pill | hide/show the bar |
| `Super+Alt+↑/↓` | — | next/previous bar layout |
| `Super+Enter` | terminal | terminal |
| `Super+Alt+,` | settings | — |
| `Ctrl+Alt+Delete`, `Super+Delete` | power menu | power menu |
| `Super+L` | lock (island) | lock (HyDE shell) |

## Configuration

Every tunable lives in `config/`, one documented file per area (pill, expanded island, clock,
OSD, notifications, control center, media, theme, wallpapers, lock screen, power menu, polkit,
animations, behaviour, settings screen). See **[config/README.md](config/README.md)** for the full
list. Files reload live on save.

The Settings surface (bar height, font size, theme, hover, Peace Mode, animations, speed) and a few
toggles (hidden pill, Caffeine) store **overrides** in `~/.local/state/morphing-island/prefs.json`;
they win over the config file defaults, and "Reset to defaults" removes them. Palettes live in
`theme/Palettes.qml` (the only place with hex colors). Launcher favorites and usage:
`~/.local/state/morphing-island/launcher.json`.

If `wallust` is installed and writes `~/.cache/wallust/colors.json`, the "Wallpaper" theme uses it
instead of HyDE's wallbash palette.

## Layout

```
shell.qml       one IslandWindow per screen, LockScreen, IPC ("island", "island-debug", "lock")
config/         every tunable, split by concern (see config/README.md)
core/           state machine (IslandController, IslandState), Spring, IslandSurface (the shared
                look: background, border, shadow, springs), Island, ModeSlot, IslandWindow,
                LockScreen/LockSurface, MouseGuard, FocusRetry
components/     the content of every mode (views, pages, cards, sliders, Osd, PasswordField…)
icons/          vector icons drawn with QtQuick.Shapes (tintable, state-driven)
services/       audio, brightness, network, Bluetooth, battery, media, notifications, apps,
                calculator, clipboard, night light, caffeine, wallpapers, lock (PAM), polkit,
                Prefs (user overrides), Paths (XDG directories)
theme/          Theme (roles, contrast, transitions) and Palettes
```

## IPC (for scripts and tests)

```
island ipc open <mode>          launcher | controlcenter | wifi | bluetooth | audio | media |
                                theme | wallpaper | settings | power
island ipc close | pin | mode
island ipc launcher "<query>"   e.g. "=2+2", ":"
island ipc pick <name>           windows | files | web | emoji | glyph | bookmarks | quickapps | games |
                                wallbash | animations | hyprlock | workflows | shaders | layouts | menu
island ipc hide | peace | caffeine | nightlight | notifications | clearNotifications
qs -p ~/.config/morphing-island ipc call lock lock | unlock | isLocked
```

Test and diagnostic hooks live in a separate target, `island-debug`:

```
qs -p ~/.config/morphing-island ipc call island-debug <function>
  hover <true|false>     pretend the pointer is over the island (tests without a mouse)
  polkit                 "registered" if the island is the session's polkit agent
  recentNotifications    the last 10 history entries (app · title · icon)
  ccState                control center summary (page, counts), or "closed"
  launcherState          launcher/picker summary ("apps 3 Firefox", "pick:windows 4 ~"), or "closed"
  prefs                  the current prefs.json overrides as JSON
  pickRefresh <name>     reload a picker's data, as opening it does (asynchronous)
  pickItems <name> <q>   a picker's entries for query <q>: "<index>\t<key>\t<title>\t<badge>"
  pickActivate <name> <q> <i>
                         activate entry <i> of pickItems, as Enter would (changes real state)
```

**Locked out?** From a TTY: `qs -p ~/.config/morphing-island ipc call lock unlock`.

## Known limits

- Bluetooth devices that need a PIN or confirmation only pair while another pairing agent (e.g.
  blueman-applet) runs; "just works" devices pair directly.
- Night light talks to HyDE's hyprsunset daemon but does not update HyDE's own state file.
- Only one shell can own notifications and polkit, hence the exclusive switch.
- The animations and layouts pickers call `hyde-shell animations|layouts --set`, exactly like HyDE's
  rofi menus. With Hyprland 0.56 HyDE writes the choice but Hyprland does not apply it live (nor on
  `hyprctl reload`); the other pickers (shaders, workflows, wallbash, hyprlock, themes) apply live.
