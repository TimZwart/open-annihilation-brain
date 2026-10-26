-- Keeps state.units, state.roles, state.commander and state.factories in
-- step with our own units.

local state = require("state")
local util = require("util")

local roster = {}

local function add(unit)
    local role = util.role(unit.type)
    state.units[unit.id] = unit
    state.roles[unit.id] = role
    if role == "commander" then state.commander = unit end
end

local function finish(unit)
    if state.roles[unit.id] == "factory" then state.factories[unit.id] = unit end
end

local function remove(id)
    if state.commander ~= nil and state.commander.id == id then state.commander = nil end
    state.units[id], state.roles[id], state.factories[id] = nil, nil, nil
    state.army[id], state.sent[id] = nil, nil
end

function roster.onUnitCreated(unit)
    add(unit)
end

function roster.onUnitFinished(unit)
    if state.units[unit.id] == nil then add(unit) end
    finish(unit)
end

-- This hook also fires for allies' and seen enemies' deaths.
function roster.onUnitDestroyed(unit)
    if state.units[unit.id] ~= nil then remove(unit.id) end
end

function roster.onUnitGiven(unit, old, from, to)
    if from == me.player then
        remove(unit.id)
        if old ~= nil then remove(old.id) end
    end
    if to == me.player then
        add(unit)
        if unit.finished == true then finish(unit) end
    end
end

-- A safety net for deaths we were not told about.
function roster.think()
    for id, unit in pairs(state.units) do
        if unit.alive ~= true then remove(id) end
    end
end

function roster.report()
    local counts = {}
    for _, role in pairs(state.roles) do counts[role] = (counts[role] or 0) + 1 end
    local parts = {}
    for role, count in pairs(counts) do parts[#parts + 1] = role .. "=" .. count end
    table.sort(parts)
    return { "units: " .. table.concat(parts, " ") }
end

return roster
