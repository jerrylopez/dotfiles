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

local things = {
  bundleID = "com.culturedcode.ThingsMac",
  width = 0.4, -- fraction of the screen
  duration = 0.2,
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

local function slideIn(app, win)
  local screen = hs.screen.mainScreen()

  local workspace = hs.execute(aerospace .. " list-workspaces --focused"):gsub("%s+$", "")
  hs.execute(string.format("%s move-node-to-workspace --window-id %d %s", aerospace, win:id(), workspace))

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
  hs.timer.doAfter(things.duration, function() app:hide() end)
end

local function toggleThings()
  local app = hs.application.get(things.bundleID)

  -- Not running yet: launch it, then slide in once it has a window.
  if not app then
    hs.application.launchOrFocusByBundleID(things.bundleID)
    hs.timer.waitUntil(function()
      app = hs.application.get(things.bundleID)
      return app and thingsWindow(app) ~= nil
    end, function() slideIn(app, thingsWindow(app)) end, 0.1)
    return
  end

  if app:isHidden() then app:unhide() end
  local win = thingsWindow(app)
  if not win then
    -- Running with its window closed; reopening Things brings one back.
    hs.application.launchOrFocusByBundleID(things.bundleID)
    hs.timer.waitUntil(function() return thingsWindow(app) ~= nil end,
      function() slideIn(app, thingsWindow(app)) end, 0.1)
    return
  end

  -- Focused means it is on screen in front of you: put it away. Anything
  -- else — hidden, on another workspace, or just behind the window you
  -- clicked into — brings it here.
  if hs.window.focusedWindow() == win then
    slideOut(app, win)
  else
    slideIn(app, win)
  end
end

hs.hotkey.bind(hyper, "t", toggleThings)
