-- Entry script. It must return one table of hooks.
--
-- The work lives in modules under lua/ (require "economy" reads
-- lua/economy.lua). Each module may define any engine hook name
-- (onUnitFinished, onUnitIdle, ...) plus these scaffold hooks:
--
--   start(saved)  called from the engine's start, after state.reset
--   think(tick)   called every THINK_EVERY ticks by a timer
--   report()      returns lines for the AI-weights console report
--
-- brain.lua forwards every engine event to each module that defines it,
-- in the order listed in MODULES.
--
-- Do not call the hooks table `brain`: that would shadow the global
-- `brain` API table the profile installs.

local state = require("state")
local util = require("util")

local MODULES = {
    require("roster"),      -- first, so the others see an up-to-date state
    require("intel"),
    require("economy"),
    require("production"),
    require("army"),
}

-- 30 ticks is one second. The play budget is 2,000,000 instructions a
-- tick, banked up to 30 ticks, so a think every half second is cheap.
local THINK_EVERY = 15

local EVENTS = {
    "onUnitCreated", "onUnitFinished", "onUnitDamaged", "onUnitDestroyed",
    "onUnitGiven", "onUnitIdle", "onCommandDone", "onUnitLoaded",
    "onUnitUnloaded", "onUnitSeen", "onUnitLost", "onPathFailed",
    "onRadarLost", "onRadarContact", "onAllianceChanged", "onPlayerDefeated",
    "onChat", "onTick",
}

local hooks = {}

local function dispatch(name, ...)
    for index = 1, #MODULES do
        local fn = MODULES[index][name]
        if fn ~= nil then fn(...) end
    end
end

-- Install an engine hook only when some module wants it, so the engine
-- skips events nobody listens to.
for _, name in ipairs(EVENTS) do
    for index = 1, #MODULES do
        if MODULES[index][name] ~= nil then
            hooks[name] = function(...) dispatch(name, ...) end
            break
        end
    end
end

local function think()
    dispatch("think", me.tick)
end

-- Timers survive a profile reload (start runs again in the same sandbox),
-- but not a saved game, which opens a fresh sandbox.
local armed = false

-- Return true, or a string the player sees as the reason the brain
-- does not fit this game.
-- `units` is the match's unit records after mods and mutators.
function hooks.fits(game)
    -- e.g. if not game:has_expansion("core-contingency") then return "needs Core Contingency" end
    return true
end

function hooks.start(_, seat, saved)
    state.reset(saved)
    dispatch("start", saved)
    -- Adopt what is already on the map: the commander at match start, or
    -- every unit after a saved game loads.
    seat:each_unit(function(unit)
        if unit.alive == true then
            dispatch("onUnitCreated", unit, nil)
            if unit.finished == true then dispatch("onUnitFinished", unit, nil) end
        end
    end)
    if not armed then
        brain.every(THINK_EVERY, think)
        armed = true
    end
    util.log("started as %s, level %s, seat %d", me.name or "?", me.level, me.player)
end

-- Plain data only: no unit handles, functions or metatables.
function hooks.save()
    return state.save()
end

function hooks.report()
    local lines = { string.format("tick %d", me.tick) }
    for index = 1, #MODULES do
        local fn = MODULES[index].report
        if fn ~= nil then
            for _, line in ipairs(fn()) do lines[#lines + 1] = line end
        end
    end
    return table.concat(lines, "\n")
end

return hooks
