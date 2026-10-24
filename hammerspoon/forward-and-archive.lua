-- Forward and Archive: Hammerspoon launcher
-- https://github.com/sbecker11/mail-forward-and-archive
--
-- Binds a global hotkey that runs forward-and-archive.applescript
-- (installed next to this file in ~/.hammerspoon/) against Mail's selection.
--
-- Load it from ~/.hammerspoon/init.lua with:
--     require("forward-and-archive")

local M = {}

-- ===== CONFIGURATION =====
M.mods = { "ctrl", "alt", "cmd" }   -- hotkey modifiers
M.key  = "F"                        -- hotkey key  (default: Ctrl-Option-Cmd-F)
-- ==========================

M.scriptPath = hs.configdir .. "/forward-and-archive.applescript"
M.task = nil   -- kept here so the running task isn't garbage-collected

function M.run()
  local front = hs.application.frontmostApplication()
  if not front or front:name() ~= "Mail" then
    hs.alert.show("Forward and Archive: switch to Mail and select messages first")
    return
  end
  if not hs.fs.attributes(M.scriptPath) then
    hs.alert.show("Forward and Archive: script not found at " .. M.scriptPath)
    return
  end
  if M.task and M.task:isRunning() then
    hs.alert.show("Forward and Archive is already running")
    return
  end

  hs.alert.show("Forward and Archive…")
  -- The script's run handler is `on run {input, parameters}`, so pass two
  -- empty arguments to match it (the same shape Shortcuts provides).
  M.task = hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      hs.alert.show("Forward and Archive failed — see Hammerspoon Console")
      print("[forward-and-archive] exit " .. tostring(exitCode) .. ": " .. tostring(stdErr))
    end
  end, { M.scriptPath, "", "" })
  M.task:start()
end

M.hotkey = hs.hotkey.bind(M.mods, M.key, M.run)

return M
