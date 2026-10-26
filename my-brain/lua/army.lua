-- Gathers combat units into waves and sends them at the enemy.

local state = require("state")
local util = require("util")
local intel = require("intel")

local army = {}

local WAVES = { small = 4, medium = 8, large = 12 }

local function wave_size()
    return WAVES[me.options.wave] or WAVES.medium
end

-- Attack a unit handle, or move to a position.
-- TODO: a move walks past enemies; patrol or attack_ground may suit better.
local function send(unit, target)
    if target.id ~= nil then return unit:attack(target) end
    return unit:move(target)
end

function army.onUnitFinished(unit)
    if state.units[unit.id] ~= nil and state.sent[unit.id] == nil and util.land_combat(unit.type) then
        state.army[unit.id] = unit
        -- TODO: move fresh units to a rally point in front of the base.
    end
end

-- A sent unit that runs out of orders looks for the next target.
function army.onUnitIdle(unit)
    if state.sent[unit.id] == nil then return end
    local target = intel.target(unit)
    if target ~= nil then send(unit, target) end
end

function army.think()
    for id, unit in pairs(state.army) do
        if unit.alive ~= true then state.army[id] = nil end
    end
    if util.size(state.army) < wave_size() then return end

    local origin = state.commander
    if not util.alive(origin) then
        local _, first = next(state.army)
        origin = first
    end
    local target = origin ~= nil and intel.target(origin) or nil
    if target == nil then return end

    for id, unit in pairs(state.army) do
        send(unit, target)
        state.sent[id] = true
    end
    state.army = {}
    state.persist.waves = state.persist.waves + 1
    util.log("wave %d sent", state.persist.waves)
end

function army.report()
    return { string.format("army: %d waiting (wave of %d), %d waves sent",
        util.size(state.army), wave_size(), state.persist.waves) }
end

return army
