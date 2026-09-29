-- Hammerspoon — https://www.hammerspoon.org/docs/
--
-- Linked to ~/.hammerspoon/init.lua by install.macos.conf.yaml.

hs.autoLaunch(true)
hs.window.animationDuration = 0

-- Hyperkey sends ctrl+alt+shift+cmd together, same chord AeroSpace binds.
local hyper = { "ctrl", "alt", "shift", "cmd" }

local aerospace = "/opt/homebrew/bin/aerospace"

-- |----------------------------------------------------------------
-- | Things drawer
-- |----------------------------------------------------------------
--
-- hyper+t slides Things in from the right edge of whichever workspace is
-- focused, and slides it back out again. AeroSpace floats Things rather than
-- tiling it (see config/aerospace), and its workspaces are emulated: a window
-- belongs to one, and focusing it switches there. So before sliding in, the
-- window is moved onto the focused workspace — that is what makes it reachable
-- from all of them.
--
-- Put away, it is parked on a workspace of its own rather than hidden with
-- macOS's Hide. AeroSpace takes a hidden app's windows out of its layout, and
-- a window moved to a workspace while still hidden gets tiled there until the
-- unhide registers, squeezing the workspace's windows for a moment. Parked
-- on a workspace, it stays floating throughout.

local things = {
  bundleID = "com.culturedcode.ThingsMac",
  width = 0.4, -- fraction of the screen
  duration = 0.2,
  parking = "scratchpad", -- the workspace it waits on while put away
}

-- AeroSpace's outer gaps, read from whichever config ~/.aerospace.toml points
-- at right now (hyper+` swaps it). `aerospace config --get` can't return
-- gaps, hence reading the file. A side the config leaves out falls back to 0,
-- AeroSpace's own default.
local function aerospaceOuterGaps()
  local gaps = { top = 0, right = 0, bottom = 0 }
  local file = io.open(os.getenv("HOME") .. "/.aerospace.toml")
  if not file then return gaps end
  for line in file:lines() do
    local side, value = line:match("^%s*outer%.(%a+)%s*=%s*(%d+)")
    if side and gaps[side] then gaps[side] = tonumber(value) end
  end
  file:close()
  return gaps
end

-- The drawer's resting frame, and the same frame pushed just off the right
-- edge. `width` is what the window actually is, when that is known: Things has
-- a minimum width (590pt), and on a narrow screen the fraction asks for less,
-- so anchoring the fraction to the edge would push the window past it.
local function thingsFrames(screen, width)
  local s = screen:frame()
  local gap = aerospaceOuterGaps()
  local w = width or math.floor(s.w * things.width)
  local shown = hs.geometry.rect(s.x2 - w - gap.right, s.y + gap.top, w, s.h - gap.top - gap.bottom)
  local hidden = hs.geometry.rect(s.x2, shown.y, w, shown.h)
  return shown, hidden
end

local function thingsWindow(app)
  return app:mainWindow() or app:allWindows()[1]
end

local function aerospaceRun(args)
  return (hs.execute(aerospace .. " " .. args .. " 2>/dev/null"):gsub("%s+$", ""))
end

-- One of AeroSpace's fields for the window, e.g. "window-layout" or "workspace".
local function aerospaceWindow(win, field)
  return aerospaceRun(string.format(
    "list-windows --all --format '%%{window-id} %%{%s}' | awk '$1 == %d { print $2 }'", field, win:id()))
end

-- AeroSpace's layout for the window, e.g. "floating", or
-- "macos_native_window_of_hidden_app" while its app is hidden.
local function aerospaceLayout(win)
  return aerospaceWindow(win, "window-layout")
end

local function slideIn(app, win)
  local screen = hs.screen.mainScreen()
  local workspace = aerospaceRun("list-workspaces --focused")
  aerospaceRun(string.format("move-node-to-workspace --window-id %d %s", win:id(), workspace))
  things.parked = false

  -- Size it off screen first, then place it by the width Things accepted.
  local _, hidden = thingsFrames(screen)
  win:setFrame(hidden, 0)
  local shown, parked = thingsFrames(screen, win:frame().w)
  win:setFrame(parked, 0)
  win:setFrame(shown, things.duration)
  win:focus()
end

local function slideOut(app, win)
  local _, hidden = thingsFrames(win:screen(), win:frame().w)
  win:setFrame(hidden, things.duration)
  hs.timer.doAfter(things.duration, function()
    aerospaceRun(string.format("move-node-to-workspace --window-id %d %s", win:id(), things.parking))
    things.parked = true
  end)
end

-- Once Things has a window AeroSpace no longer counts as hidden, slide it in.
local function slideInWhenReady(app)
  hs.timer.waitUntil(function()
    local win = thingsWindow(app)
    return win ~= nil and aerospaceLayout(win) ~= "macos_native_window_of_hidden_app"
  end, function() slideIn(app, thingsWindow(app)) end, 0.05)
end

local function toggleThings()
  local app = hs.application.get(things.bundleID)

  -- Not running yet: launch it, then slide in once it has a window.
  if not app then
    hs.application.launchOrFocusByBundleID(things.bundleID)
    hs.timer.waitUntil(function()
      app = hs.application.get(things.bundleID)
      return app ~= nil
    end, function() slideInWhenReady(app) end, 0.1)
    return
  end

  -- Hidden with cmd-h, or its window closed: bring it back, and wait for
  -- AeroSpace to see it before moving it, for the reason at the top.
  if app:isHidden() or not thingsWindow(app) then
    app:unhide()
    if not thingsWindow(app) then hs.application.launchOrFocusByBundleID(things.bundleID) end
    slideInWhenReady(app)
    return
  end

  -- Focused means it is on screen in front of you: put it away. Anything
  -- else — parked, on another workspace, or just behind the window you
  -- clicked into — brings it here.
  local win = thingsWindow(app)
  if hs.window.focusedWindow() == win then
    slideOut(app, win)
  else
    slideIn(app, win)
  end
end

hs.hotkey.bind(hyper, "t", toggleThings)

-- Whether Things is waiting on the parking workspace. Tracked here rather than
-- asked of AeroSpace when it matters, because the watcher below is racing
-- AeroSpace and every CLI call costs it ~35ms. A reload starts from the truth.
do
  local app = hs.application.get(things.bundleID)
  local win = app and thingsWindow(app)
  things.parked = win ~= nil and aerospaceWindow(win, "workspace") == things.parking
end

-- cmd-tab and the Dock slide it in too. Either one focuses the parked window,
-- and AeroSpace answers that by switching to the parking workspace, a moment
-- later. Moved onto the focused workspace before then, there is nowhere to
-- switch to; if AeroSpace got there first, it is sent back where it came from.
-- Only a parked Things is pulled over: one left open on another workspace is
-- where you left it, and switching there is what focusing it should do.
things.watcher = hs.application.watcher.new(function(_, event, app)
  if event ~= hs.application.watcher.activated or app:bundleID() ~= things.bundleID then return end

  local win = thingsWindow(app)
  if not win or not things.parked then return end

  if aerospaceRun("list-workspaces --focused") == things.parking then
    aerospaceRun("workspace-back-and-forth")
  end
  slideIn(app, win)
end)
things.watcher:start()
