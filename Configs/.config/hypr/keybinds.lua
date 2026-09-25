-- ============================================================================
-- Keybindings: the ones this setup adds or changes on top of HyDE's defaults
-- ============================================================================
-- This file only holds data; HyDE's lua/morphing_island.lua reads it and creates the binds.
-- It is yours: HyDE updates never overwrite it.
-- After editing, run `hyprctl reload` (then `hyprctl configerrors` must print nothing).
-- Super+/ (or Super+\) lists every active keybinding, including HyDE's own.
--
-- Writing keys
--   "$mod + SHIFT + T"   $mod is HyDE's main modifier (SUPER). Modifiers: SUPER, SHIFT, CTRL, ALT.
--   Key names are xkb names: A…Z, 1…9, Return, TAB, Delete, comma, period, backslash, Up, Left…
--   Some layouts (e.g. Portuguese) need Shift for "/", so keys on "/" also have a "\" twin.
--
-- Where HyDE's default binds come from
--   Workspaces, window management, media keys, screenshots… are defined by HyDE in
--   ~/.local/share/hypr/key_binds.lua (HyDE's file: overwritten on HyDE updates, don't edit it).
--   To change or remove one of those, list its keys in `unbind` below and, to reassign the
--   action, add it to `binds`.

local M = {}

-- ----------------------------------------------------------------------------
-- Shell binds: the same keys work in both desktop shells
-- ----------------------------------------------------------------------------
-- `island on|off|toggle` (or $mod+ALT+I) chooses the shell. When a key is pressed, its action
-- goes to whichever shell is running:
--   island   arguments for `qs -p ~/.config/morphing-island ipc call island …`
--            (see ~/.config/morphing-island/README.md, "IPC"). nil = the key does nothing there.
--   hyde     a shell command for the HyDE Quickshell shell (`qs ipc call …`). nil = nothing.
--   desc     "[Category] what it does": the category groups it in the keybindings list.
M.shell = {
	-- Launcher and its modes.
	{ keys = "$mod + A", island = "open launcher", hyde = "qs ipc call launcher toggle", desc = "[Launcher] application finder" },
	{ keys = "$mod + V", island = "launcher ':'", hyde = "qs ipc call launcher clipboard", desc = "[Launcher] clipboard" },
	{ keys = "$mod + SHIFT + K", island = "launcher '='", hyde = "qs ipc call launcher calc", desc = "[Launcher] calculator" },
	{ keys = "$mod + slash", island = "launcher '?'", hyde = "qs ipc call launcher keys", desc = "[Launcher] keybindings" },
	{ keys = "$mod + backslash", island = "launcher '?'", hyde = "qs ipc call launcher keys", desc = "[Launcher] keybindings" },

	-- Control center, notifications, island settings.
	{ keys = "$mod + ALT + C", island = "open controlcenter", hyde = "qs ipc call controlcenter toggle", desc = "[Launcher] control center" },
	{ keys = "$mod + N", island = "open controlcenter", hyde = "qs ipc call notifications toggle", desc = "[Utilities] notification center" },
	{ keys = "$mod + ALT + comma", island = "open settings", hyde = nil, desc = "[Morphing Island] settings" },

	-- Theme and wallpaper.
	{ keys = "$mod + SHIFT + T", island = "open theme", hyde = "qs ipc call launcher pick themes", desc = "[Theming and Wallpaper] select a theme" },
	{ keys = "$mod + SHIFT + W", island = "open wallpaper", hyde = "qs ipc call launcher pick wallpapers", desc = "[Theming and Wallpaper] select a global wallpaper" },

	-- HyDE's rofi menus, ported to both shells: launcher pickers (`pick <name>`; the island's are in
	-- ~/.config/morphing-island/services/Pickers.qml, the HyDE shell's in ~/.config/quickshell/pickers/).
	{ keys = "$mod + TAB", island = "pick windows", hyde = "qs ipc call launcher pick windows", desc = "[Launcher|Pickers] window switcher" },
	{ keys = "$mod + SHIFT + E", island = "pick files", hyde = "qs ipc call launcher pick files", desc = "[Launcher|Pickers] file finder" },
	{ keys = "$mod + period", island = "pick glyph", hyde = "qs ipc call launcher pick glyph", desc = "[Launcher|Pickers] glyph picker" },
	{ keys = "$mod + SHIFT + comma", island = "pick emoji", hyde = "qs ipc call launcher pick emoji", desc = "[Launcher|Pickers] emoji picker" },
	{ keys = "$mod + SHIFT + slash", island = "pick web", hyde = "qs ipc call launcher pick web", desc = "[Launcher|Pickers] web search" },
	{ keys = "$mod + SHIFT + backslash", island = "pick web", hyde = "qs ipc call launcher pick web", desc = "[Launcher|Pickers] web search" },
	{ keys = "$mod + SHIFT + R", island = "pick wallbash", hyde = "qs ipc call launcher pick wallbash", desc = "[Theming and Wallpaper] wallbash mode selector" },
	{ keys = "$mod + SHIFT + Y", island = "pick animations", hyde = "qs ipc call launcher pick animations", desc = "[Theming and Wallpaper] select animations" },
	{ keys = "$mod + SHIFT + U", island = "pick hyprlock", hyde = "qs ipc call launcher pick hyprlock", desc = "[Theming and Wallpaper] select Hyprlock layout" },
	{ keys = "$mod + SHIFT + G", island = "pick games", hyde = "qs ipc call launcher pick games", desc = "[Utilities] game launcher" },
	-- Every picker in one list (workflows, shaders, layouts, HyDE themes… have no key of their own).
	{ keys = "$mod + SHIFT + A", island = "pick menu", hyde = "qs ipc call launcher pick menu", desc = "[Launcher] HyDE menus" },

	-- Bar.
	{ keys = "$mod + comma", island = "hide", hyde = "qs ipc call bar toggle", desc = "[Window Management] hide or show the bar" },
	{ keys = "$mod + CTRL + B", island = "hide", hyde = "qs ipc call bar toggle", desc = "[Window Management] hide or show the bar" },
	-- Bar layouts only exist in the HyDE shell.
	{ keys = "$mod + ALT + Up", island = nil, hyde = "qs ipc call bar next", desc = "[Theming and Wallpaper] next bar layout" },
	{ keys = "$mod + ALT + Down", island = nil, hyde = "qs ipc call bar prev", desc = "[Theming and Wallpaper] previous bar layout" },

	-- Session: the power menu asks before logging out, rebooting or powering off.
	-- ($mod+Delete used to exit Hyprland instantly; it now opens the same menu.)
	{ keys = "CTRL + ALT + DELETE", island = "open power", hyde = "qs ipc call powermenu toggle", desc = "[Window Management] logout menu" },
	{ keys = "$mod + Delete", island = "open power", hyde = "qs ipc call powermenu toggle", desc = "[Window Management] logout menu" },
}

-- ----------------------------------------------------------------------------
-- Plain binds: one command, whatever the shell
-- ----------------------------------------------------------------------------
--   cmd    shell command to run.   desc   as above.
M.binds = {
	-- Switch shells live: Morphing Island ⇄ HyDE Quickshell shell.
	{ keys = "$mod + ALT + I", cmd = "$HOME/.local/bin/island toggle", desc = "[Morphing Island] switch between the island and the HyDE shell" },

	-- Lock through loginctl, so hypridle runs the active shell's lock screen. Without hypridle, lock
	-- directly: HyDE shell, then the island, then HyDE's hyprlock.
	{
		keys = "$mod + L",
		cmd = "sh -c 'pgrep -x hypridle >/dev/null && exec loginctl lock-session; qs ipc call lock lock || "
			.. "qs -p $HOME/.config/morphing-island ipc call lock lock || hyde-shell lockscreen.sh'",
		desc = "[Window Management] lock session",
	},

	-- Apps ($mod+T also opens the terminal: HyDE's default).
	{ keys = "$mod + Return", cmd = hyde.config.app.terminal, desc = "[Launcher|Apps] terminal emulator" },

	-- Game mode: the "gaming" workflow (back to normal with the Workflows picker, in $mod+SHIFT+A).
	-- Replaces HyDE's gamemode script, which sources a config the Lua setup doesn't have.
	{ keys = "$mod + ALT + G", cmd = "hyde-shell workflows --set gaming", desc = "[Utilities] game mode (gaming workflow)" },
}

-- ----------------------------------------------------------------------------
-- Removed HyDE binds
-- ----------------------------------------------------------------------------
-- Removed before the binds above are added, so a key listed in both is reassigned.
M.unbind = {
	"$mod + ALT + T", -- dropdown terminal: needs pyprland, not installed (the key would install it)
	"$mod + ALT + G", -- HyDE's game mode: reassigned above
}

return M
