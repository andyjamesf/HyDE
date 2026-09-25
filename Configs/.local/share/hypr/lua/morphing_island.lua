-- ============================================================================
-- Desktop shell: HyDE Quickshell shell or Morphing Island
-- ============================================================================
-- Two Quickshell shells are installed and exactly one runs at a time:
--   * the HyDE Quickshell shell  (~/.config/quickshell, started as hyde-*-qsbar.service)
--   * the Morphing Island        (~/.config/morphing-island, started as morphing-island.service)
-- `island on|off|toggle` (~/.local/bin/island, or Super+Alt+I) switches between them and writes the
-- state file ~/.local/state/morphing-island/active. Every shell bind reads that file when the key is
-- pressed and sends the action to whichever shell is running, so the same keys work in both.
--
-- The keys themselves live in ~/.config/hypr/keybinds.lua (user file, documented there). This
-- module only applies them. Loaded by hyde.lua after key_binds.lua, so these binds replace HyDE's.

MorphingIsland = {}

local home = os.getenv("HOME")
local state = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/morphing-island/active"
local ipc = "qs -p " .. home .. "/.config/morphing-island ipc call island "
local mod = hyde.config.modifiers.main

-- True while the Morphing Island is the active shell.
function MorphingIsland.active()
	local f = io.open(state, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- Called by `island on|off`; the binds decide at key-press time, so nothing to do here.
function MorphingIsland.set(_) end

-- A bind action that runs `island_cmd` when the island is active and `hyde_cmd` otherwise
-- (nil = do nothing in that shell).
local function route(island_cmd, hyde_cmd)
	return function()
		local cmd = MorphingIsland.active() and island_cmd or hyde_cmd
		if cmd then
			hl.exec_cmd(cmd)
		end
	end
end

-- Keybindings from ~/.config/hypr/keybinds.lua ($mod = HyDE's main modifier).
local file = home .. "/.config/hypr/keybinds.lua"
local ok, keys = pcall(dofile, file)
if not ok or type(keys) ~= "table" then
	if io.open(file, "r") then
		print("morphing_island: " .. file .. " failed to load: " .. tostring(keys))
	end
	keys = {}
end
local function k(spec)
	return (spec:gsub("%$mod", mod))
end
for _, spec in ipairs(keys.unbind or {}) do
	hl.unbind(k(spec))
end
for _, b in ipairs(keys.shell or {}) do
	hl.bind(k(b.keys), route(b.island and (ipc .. b.island), b.hyde), { description = b.desc })
end
for _, b in ipairs(keys.binds or {}) do
	hl.bind(k(b.keys), hl.dsp.exec_cmd(b.cmd), { description = b.desc })
end

-- At login: start the island instead of the HyDE shell, and let it be the polkit agent.
if MorphingIsland.active() then
	hyde.config.start.bar = "hyde-shell app -u morphing-island.service -t service -- qs -p "
		.. home .. "/.config/morphing-island"
	hyde.config.start.auth_dialogue = ""
end

-- Hyprland's own "what's new" and donation windows don't match the desktop's design.
hl.config({ ecosystem = { no_update_news = true, no_donation_nag = true } })
-- HyDE's Alt+Tab switcher sends a notification for every step; the shells show enough already.
hyde.env("ALTAB_NOTIFY", "0")
