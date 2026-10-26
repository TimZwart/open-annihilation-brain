-- Keeps every finished factory busy with land combat units.

local state = require("state")
local util = require("util")

local production = {}

local MENU_SIZE = 3       -- how many of the cheapest combat types to cycle

local menus = {}          -- factory type index -> list of records it makes
local turn = {}           -- factory id -> next menu index

function production.start()
    menus, turn = {}, {}
end

-- TODO: add constructors, scouts, and anti-air once enemies fly.
local function menu(factory)
    local key = factory.type_index
    if menus[key] == nil then
        local built, combat = game.build_list(factory.type), {}
        if type(built) == "table" then
            for slot = 1, #built do
                if util.land_combat(built[slot]) then combat[#combat + 1] = built[slot] end
            end
        end
        table.sort(combat, function(a, b)
            return util.num(a, "buildcostmetal") < util.num(b, "buildcostmetal")
        end)
        for index = #combat, MENU_SIZE + 1, -1 do combat[index] = nil end
        menus[key] = combat
    end
    return menus[key]
end

local function feed(factory)
    if not util.alive(factory) or factory.finished ~= true or not util.free(factory) then return end
    local list = menu(factory)
    if #list == 0 then return end
    local index = turn[factory.id] or 1
    if factory:queue(list[index]) == true then
        turn[factory.id] = index % #list + 1
    end
end

function production.onUnitFinished(unit)
    if state.factories[unit.id] ~= nil then feed(unit) end
end

function production.onUnitIdle(unit)
    if state.factories[unit.id] ~= nil then feed(unit) end
end

function production.think()
    for _, factory in pairs(state.factories) do feed(factory) end
end

function production.report()
    return { string.format("production: %d factories", util.size(state.factories)) }
end

return production
