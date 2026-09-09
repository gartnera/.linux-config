-- Hyprland Lua config, ported from the sway config in this repo via hyprland.conf.
-- Structured to mirror those files' ordering so all three can be diffed by eye.
-- Migration plan + rationale: ~/.config/hypr/MIGRATION-PLAN.md
--
-- Hyprland 0.56 looks for hyprland.lua first and only falls back to hyprland.conf, which
-- is why this file exists. hyprland.conf is kept beside it as a reference/fallback: rename
-- or delete THIS file and the .conf takes over again.
--
-- NOTE: a Lua error here is far less forgiving than a .conf typo. A .conf parse error skips
-- the bad line; a Lua error aborts the script and trips emergency mode, leaving only
-- SUPER + Q bound. Validate with `Hyprland --verify-config -c <path>` after editing.

------------------
---- PLUGINS -----
------------------

-- hy3 provides the i3/sway layout (splits, tabs, container tree).
-- Installed from aur/hyprland-plugin-hy3, built against this exact Hyprland commit.
hl.plugin.load("/usr/lib/libhy3.so")

-- IMPORTANT: hl.plugin.load only *registers* the plugin; it is loaded after this script
-- finishes, and Hyprland then re-runs the config (CConfigManager::handlePluginLoads calls
-- reload() when the plugin set changed). So on the FIRST pass hl.plugin.hy3 is nil, and on
-- the second it exists. Everything below therefore goes through the helpers further down,
-- which fall back to the native dispatcher when hy3 is not there yet. Indexing hl.plugin.hy3
-- unguarded would error on the first pass and trip emergency mode.
local hy3 = hl.plugin and hl.plugin.hy3

-------------------
---- VARIABLES ----
-------------------

local mod   = "SUPER"
local left, down, up, right = "h", "j", "k", "l"

local term  = "systemd-run -p MemoryMax=75% -p CPUWeight=50 -p Nice=5 --user alacritty"
-- Launching goes through `uwsm app`, not `hyprctl dispatch`, for two reasons.
-- 1. rofi does not run -run-command through a shell, so any quoting in it is passed
--    through literally. The previous `hyprctl dispatch "hl.dsp.exec_cmd([[{cmd}]])"`
--    therefore reached hyprctl with the quotes still attached and died as a Lua syntax
--    error -- invisibly, because that error goes to rofi's stdout, not the compositor log.
--    This form needs no quoting at all, so it survives either execution model.
-- 2. `uwsm app` is the uwsm-native way: it starts each app in its own unit under
--    app-graphical.slice instead of as a child of rofi.
-- (The sway config routed through swaymsg so windows opened on the originating workspace;
-- Hyprland assigns the workspace at map time, so that indirection is not needed here.)
local menu  = "rofi -show run -run-command 'uwsm app -- {cmd}'"

local lock  = "systemd-cat -t swaylock swaylock -c 000000 --indicator-idle-visible -f"
local sleep = "systemctl suspend"

-- release = true, so the key isn't still held down when the lock screen appears
hl.bind(mod .. " + SHIFT + s", hl.dsp.exec_cmd(lock .. ";" .. sleep), { release = true })
hl.bind(mod .. " + CTRL + l", hl.dsp.exec_cmd(lock), { release = true })

-----------------
---- LOGGING ----
-----------------

-- Hyprland logs NOTHING by default: disable_logs defaults true and gates all logging,
-- enable_stdout_logs defaults false. Both must be flipped for the journal to see anything.
-- uwsm runs the compositor as wayland-wm@<instance>.service, so stdout lands in journald:
--   journalctl --user -u 'wayland-wm@*' -f
hl.config({
    debug = {
        disable_logs        = false,
        enable_stdout_logs  = true,
        colored_stdout_logs = false, -- ANSI escapes render as garbage in journalctl
        disable_time        = true,  -- journald timestamps already
    },

    render = {
        cm_enabled        = true,
        cm_auto_hdr       = 2,
        send_content_type = true,
    },
})

---------------------
---- ENVIRONMENT ----
---------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
-- NOTE: PATH and QT_QPA_PLATFORMTHEME come from ~/.profile, which uwsm sources when
-- building the session environment (and which ~/.zshenv sources for shells). WLR_RENDERER
-- was wlroots-only; Hyprland uses aquamarine, so it is intentionally not carried over.

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- hl.config takes nested tables that map onto config keys: general.col.active_border here
-- is the `general:col.active_border` option. Names are normalised, so a hyphenated option
-- like input:touchpad:tap-to-click is written tap_to_click below.
hl.config({
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 1,
        col = {
            active_border   = "rgba(33ccffee)",
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "hy3",
    },

    decoration = {
        rounding              = 0,
        rounding_power        = 2,
        active_opacity        = 1.0,
        inactive_opacity      = 1.0,
        border_part_of_window = false,
        shadow = { enabled = false },
        blur   = { enabled = false },
    },

    animations = { enabled = false },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },

    cursor = {
        -- sway: mouse_warping container
        no_warps = false,
    },

    -- X11 apps render at the display's real pixel size instead of being drawn at the
    -- logical size and upscaled by the compositor -- which is what makes them blurry on a
    -- scaled output (the TV below is scale 2). XWayland is handed the monitor's native
    -- resolution, so its windows are 1:1 with the panel: crisp, but physically half-size on
    -- a 2x output until the app scales itself (Xft.dpi / GDK_SCALE / QT_SCALE_FACTOR --
    -- deliberately not set here, since that would put the scaling back).
    xwayland = {
        force_zero_scaling = true,

        -- Xwayland's listening socket also gets an *abstract* one (@/tmp/.X11-unix/X0)
        -- rather than only the on-disk /tmp/.X11-unix/X0. wlroots did this unconditionally,
        -- so sway got it for free; Hyprland made it opt-in and defaults to off.
        -- ~/bin/steam runs Steam under `systemd-run -p PrivateTmp=true`, which gives it a
        -- private /tmp where the on-disk socket does not exist -- so XOpenDisplay fails and
        -- Steam dies at startup. An abstract socket lives in the network namespace, not the
        -- mount namespace, so it reaches through PrivateTmp. Takes effect at next login:
        -- the socket is bound once when the Xwayland server starts, not on reload.
        create_abstract_socket = true,
    },

    input = {
        kb_layout          = "us",
        kb_options         = "caps:escape,altwin:swap_lalt_lwin",
        numlock_by_default = true,
        follow_mouse       = 1,
        sensitivity        = 0,
        touchpad = {
            -- sway had this per-device on "1267:32:Elan_Touchpad"; global is equivalent in
            -- effect here. Per-device form would use hl.device{} with `hyprctl devices` name.
            tap_to_click   = true,
            natural_scroll = false,
        },
    },
})

-- hy3's own options, i.e. the plugin:hy3:* keys. Guarded because these keys only exist
-- once the plugin is loaded: applying them on the first (plugin-less) pass would raise
-- "unknown config key" errors and put an error overlay on screen at every login.
if hy3 then
    hl.config({
        plugin = {
            hy3 = {
                -- sway: workspace_layout tabbed -- first window on a workspace opens a tab group
                tab_first_window     = true,
                node_collapse_policy = 2,
                tabs = {
                    height      = 22,
                    text_font   = "Noto Sans Mono", -- sway: font "Noto Sans Mono 10"
                    text_height = 10,
                    render_text = true,
                },
                autotile = { enable = false },
            },
        },
    })
end

-- NOTE: no gestures. 0.56 reworked them onto hl.gesture{} and gestures:workspace_swipe no
-- longer exists. sway configured none, so none are set here.

---------------------------
---- DISPATCHER SHIMS -----
---------------------------

-- These pick the hy3 dispatcher when the plugin is loaded and the closest native
-- equivalent otherwise, so the first (plugin-less) pass still registers usable binds
-- rather than erroring.
local function focus_dir(d)
    if hy3 then return hy3.move_focus(d) end
    return hl.dsp.focus({ direction = d })
end

local function move_dir(d)
    if hy3 then return hy3.move_window(d) end
    return hl.dsp.window.move({ direction = d })
end

local function move_to_ws(ws)
    if hy3 then return hy3.move_to_workspace(tostring(ws)) end
    return hl.dsp.window.move({ workspace = ws })
end

local function kill_active()
    -- hy3:killactive matches sway's `kill`, which closes the focused *container*
    if hy3 then return hy3.kill_active() end
    return hl.dsp.window.close()
end

----------------------
---- KEYBINDINGS -----
----------------------

-- Basics
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(term))
hl.bind(mod .. " + SHIFT + q", kill_active())
hl.bind(mod .. " + d", hl.dsp.exec_cmd(menu))
-- NOTE: sway's $mod+Shift+d ran wldash, which is no longer installed. Bind dropped.

-- sway: floating_modifier $mod normal. Mouse buttons are raw evdev codes:
-- 272 = left, 273 = right, 274 = middle, 275 = back/side, 276 = forward/extra.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mod .. " + SHIFT + c", hl.dsp.exec_cmd("hyprctl reload"))
-- swaynag is layer-shell, so it still works here; only the command it runs changes
hl.bind(mod .. " + SHIFT + e", hl.dsp.exec_cmd(
    "swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit " ..
    "Hyprland? This will end your Wayland session.' -b 'Yes, exit Hyprland' " ..
    "'hyprctl dispatch \"hl.dsp.exit()\"'"))

-- Moving around
for key, dir in pairs({ [left] = "l", [down] = "d", [up] = "u", [right] = "r" }) do
    hl.bind(mod .. " + " .. key, focus_dir(dir))
    hl.bind(mod .. " + SHIFT + " .. key, move_dir(dir))
end
for key, dir in pairs({ left = "l", down = "d", up = "u", right = "r" }) do
    hl.bind(mod .. " + " .. key, focus_dir(dir))
    hl.bind(mod .. " + SHIFT + " .. key, move_dir(dir))
end

-- Workspaces. 10 maps to key 0, as in the sway config.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, move_to_ws(i))
end

-- Layout
if hy3 then
    hl.bind(mod .. " + b", hy3.make_group("h"))                    -- sway: splith
    hl.bind(mod .. " + v", hy3.make_group("v"))                    -- sway: splitv
    -- sway: layout tabbed. changegroup, NOT makegroup: makegroup wraps the focused node in
    -- a NEW group, which on a split workspace tabs only the active window. changegroup
    -- changes the layout of the group the node already belongs to, which is what sway's
    -- `layout tabbed` does -- its siblings become tabs too.
    -- ("toggletab" instead of "tab" would untab on a second press, if you prefer that.)
    hl.bind(mod .. " + w", hy3.change_group("tab"))
    hl.bind(mod .. " + e", hy3.change_group("opposite"))           -- sway: layout toggle split
    hl.bind(mod .. " + space", hy3.toggle_focus_layer())           -- sway: focus mode_toggle
    hl.bind(mod .. " + p", hy3.change_focus("raise"))              -- sway: focus parent
    hl.bind(mod .. " + c", hy3.change_focus("lower"))              -- sway: focus child
end
-- NOTE: sway's $mod+s (layout stacking) has no hy3 equivalent -- hy3 does tabs only.
-- Accepted loss; native groups have groupbar:stacked but can't mix with hy3.

hl.bind(mod .. " + f", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))

-- Scratchpad. special:<name> overlays the current workspace; follow = false is the
-- equivalent of sway's `move scratchpad` not following the window.
-- NOTE: sway's scratchpad cycles its windows one at a time; a special workspace shows all.
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
hl.bind(mod .. " + minus", hl.dsp.workspace.toggle_special("scratchpad"))

-- Resizing. hl.define_submap(name, fn) scopes every bind made inside fn to that mode
-- (sway: mode "resize"); hl.dsp.submap("reset") returns to the normal binds.
hl.bind(mod .. " + r", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local step = {
        [left] = { -10, 0 }, [down] = { 0, 10 }, [up] = { 0, -10 }, [right] = { 10, 0 },
        left   = { -10, 0 }, down   = { 0, 10 }, up   = { 0, -10 }, right   = { 10, 0 },
    }
    for key, d in pairs(step) do
        -- repeating = true so held keys keep resizing, as in sway's resize mode
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    end
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- gamescope submap has limited keybindings so you don't accidentally do stuff while playing
-- games. Also mutes the chromium input (for discord) when an in-game button is pressed.
--
-- NOTE: under sway this was entered/left automatically by gamescope-mode-manager, which is
-- still i3ipc-based and NOT yet ported. Until it is, toggle manually with the bind below.
-- The fps-limit half of that service is therefore also inactive.
hl.bind(mod .. " + SHIFT + g", hl.dsp.submap("gamescope"))
hl.define_submap("gamescope", function()
    for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, move_to_ws(i))
    end

    hl.bind(mod .. " + f", hl.dsp.window.fullscreen({ action = "toggle" }))
    hl.bind(mod .. " + SHIFT + q", kill_active())
    hl.bind(mod .. " + SHIFT + g", hl.dsp.submap("reset"))

    local vol = { repeating = true, locked = true }
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), vol)
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), vol)
    hl.bind("SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"), vol)
    hl.bind("SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"), vol)

    -- --mangoapp option on gamescope does not handle keybindings,
    -- it can be configured via mangohudctl commands
    hl.bind("SHIFT + F12", hl.dsp.exec_cmd("mangohudctl toggle no_display"))

    -- non_consuming: the key is handled here AND still passed to the game. This is native,
    -- and is exactly what the local sway fork was patched to do (bindsym --passthrough) --
    -- so that fork is no longer needed for this.
    hl.bind("t", hl.dsp.exec_cmd("chrome-input-mute 1"), { non_consuming = true })
    hl.bind("t", hl.dsp.exec_cmd("chrome-input-mute 0"), { non_consuming = true, release = true })
    hl.bind("mouse:275", hl.dsp.exec_cmd("chrome-input-mute 1"), { non_consuming = true })
    hl.bind("mouse:275", hl.dsp.exec_cmd("chrome-input-mute 0"), { non_consuming = true, release = true })
end)

-- Workspace switching on the current output. m+1/m-1 = next/previous workspace on the
-- current monitor (sway: next_on_output). e+1 would include empty workspaces.
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("CTRL + ALT + left", hl.dsp.focus({ workspace = "m-1" }))

-- Side mouse buttons: sway's button8/back = 275, button9/forward = 276
hl.bind(mod .. " + mouse:276", focus_dir("l"))
hl.bind(mod .. " + mouse:275", focus_dir("r"))

hl.bind(mod .. " + SHIFT + bracketleft", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + bracketright", hl.dsp.workspace.move({ monitor = "r" }))

-- Media keys (pactl, matching the sway config rather than switching to wpctl).
-- repeating + locked: volume keys autorepeat when held and still work on the lock screen.
local vol = { repeating = true, locked = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), vol)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), vol)
hl.bind("SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"), vol)
hl.bind("SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"), vol)
-- macos compatible shortcuts
hl.bind("ALT + SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"), vol)
hl.bind("ALT + SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"), vol)

-- locked only (no repeat) for toggles and transport controls
local lockedOnly = { locked = true }
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), lockedOnly)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), lockedOnly)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), vol)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), vol)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), lockedOnly)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), lockedOnly)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), lockedOnly)

----------------------
---- WINDOW RULES ----
----------------------

-- sway: for_window [app_id="^chrome-.*-.*$"] shortcuts_inhibitor disable
hl.window_rule({
    name  = "chrome-no-shortcuts-inhibit",
    match = { class = "^chrome-.*-.*$" },
    no_shortcuts_inhibit = true,
})

-- sway: border none. There is no "noborder" effect; per-window border_size 0 is it.
hl.window_rule({ name = "chromium-no-border", match = { title = ".* - Chromium" }, border_size = 0 })
hl.window_rule({ name = "firefox-no-border",  match = { title = ".*Firefox" },     border_size = 0 })

-- sway: floating enable
hl.window_rule({ name = "zeal-float", match = { title = "^Zeal.*" }, float = true })

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

------------------------------------
---- MONITORS AND WORKSPACES -------
------------------------------------

-- desc: is a PREFIX match against "make model serial" -- the same strings the sway config
-- used in its `workspace N output ...` lines.
--
-- NOTE: kanshi still owns modes/positions/scale for now (it speaks zwlr_output_manager_v1,
-- which Hyprland implements). Migrating those to native monitor rules is deferred.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", cm = "auto" })

-- sway: output "LG Electronics LG TV SSCR2 0x01010101" render_bit_depth 10
--
-- The mode is stated explicitly rather than "preferred" ON PURPOSE. This panel's preferred
-- mode is 3840x2160@60, but kanshi's `tv` profile asks for @120. With "preferred" here,
-- every login did two modesets back to back -- Hyprland to 60Hz, then kanshi to 120Hz --
-- which is a black screen flash for a second or so. Matching kanshi's value makes its
-- apply a no-op. If you change this, change the kanshi profile to match, or vice versa.
hl.monitor({
    output   = "desc:LG Electronics LG TV SSCR2 0x01010101",
    mode     = "3840x2160@120",
    position = "auto",
    scale    = "2",
    bitdepth = 10,
    cm       = "auto",
})

-- The two desk monitors, matching kanshi's `new-desk-3` profile exactly (2560x1440@144,
-- scale 1.25, side by side). Same reason as the TV above: if Hyprland and kanshi disagree
-- on mode/scale/position, every login does two modesets and the screen flashes black.
-- 2048 is 2560/1.25, i.e. the first monitor's logical width, so they sit flush.
-- Keep these in step with ~/.config/kanshi/config.
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAGEAR 010NTEPJQ724",
    mode     = "2560x1440@144",
    position = "0x0",
    scale    = "1.25",
    cm       = "auto",
})
hl.monitor({
    output   = "desc:LG Electronics LG ULTRAGEAR 010NTBKJQ757",
    mode     = "2560x1440@144",
    position = "2048x0",
    scale    = "1.25",
    cm       = "auto",
})

-- sway: workspace N output '...'
local wsOutputs = {
    ["1"] = "desc:LG Electronics LG ULTRAGEAR 010NTEPJQ724",
    ["2"] = "desc:LG Electronics LG ULTRAGEAR 010NTEPJQ724",
    ["3"] = "desc:LG Electronics LG ULTRAGEAR 010NTBKJQ757",
    ["4"] = "desc:LG Electronics LG ULTRAGEAR 010NTBKJQ757",
}
for ws, output in pairs(wsOutputs) do
    hl.workspace_rule({ workspace = ws, monitor = output })
end

-------------------
---- AUTOSTART ----
-------------------

-- NOTE: nothing here, unlike the sway config's dbus-update-activation-environment /
-- session-target line. Hyprland does `systemctl --user import-environment`,
-- `dbus-update-activation-environment` and sd_notify(READY=1) natively at startup, and uwsm
-- owns graphical-session.target.
