-- The commander's build plan: extractors on metal spots, energy, and
-- factories near home.

local state = require("state")
local util = require("util")

local economy = {}

-- What the commander builds, in order. The plan walks the list and builds
-- the first role we own fewer of than the list has asked for so far, so a
-- lost building is rebuilt. Roles are util.role names.
local PLANS = {
    easy   = { "extractor", "energy", "factory", "extractor", "energy" },
    medium = { "extractor", "extractor", "energy", "factory", "extractor", "energy", "energy" },
    hard   = { "extractor", "extractor", "energy", "extractor", "factory", "energy",
               "extractor", "energy", "factory" },
}

local BASE_RADIUS = 320   -- how far from home a building may go, world units
local BASE_JITTER = 96    -- spread for the search's starting point
local SPOT_RADIUS = 48    -- how far from a metal spot an extractor may sit
local SPOT_CLAIM = 96     -- spots this close to a new extractor are taken
local MAX_SPOTS = 2000    -- more deposits than this is a metal map: build anywhere
local SPOTS_TRIED = 24    -- nearest spots tried per attempt

local picks = nil         -- role -> unit record the commander builds for it
local spots = nil         -- metal spots as {x =, z =}, or false to build anywhere
local taken = {}          -- spot index -> true when built on or refused
local pending = nil       -- spot index of the extractor we last ordered

function economy.start()
    picks, spots, taken, pending = nil, nil, {}, nil
end

local function choose_picks(commander)
    local list = game.build_list(commander.type)
    if type(list) ~= "table" or #list == 0 then return nil end
    local by_role = {}
    for index = 1, #list do
        local record = list[index]
        if util.land(record) then
            local role = util.role(record)
            by_role[role] = by_role[role] or {}
            by_role[role][#by_role[role] + 1] = record
        end
    end
    -- A factory only counts when it can make land combat units.
    local plants = {}
    for _, record in ipairs(by_role.factory or {}) do
        local built = game.build_list(record)
        if type(built) == "table" then
            for slot = 1, #built do
                if util.land_combat(built[slot]) then plants[#plants + 1] = record break end
            end
        end
    end
    -- TODO: cheapest is a weak rule; e.g. prefer solar over wind when
    -- game.map.wind_max is low.
    return {
        extractor = util.cheapest(by_role.extractor or {}),
        energy = util.cheapest(by_role.energy or {}),
        factory = util.cheapest(plants),
    }
end

-- Metal spot cells in world units. Assumes cells count from 0; brain.place
-- searches around the point, so an off-by-one cell still lands.
local function load_spots()
    local map = game.map
    if map == nil then return false end
    local list = map:metal_spots()
    if type(list) ~= "table" or #list == 0 or #list > MAX_SPOTS then return false end
    local cell = util.num(map, "world_width") / util.num(map, "width")
    local result = {}
    for index = 1, #list do
        result[index] = util.pos((list[index].cx + 0.5) * cell, (list[index].cz + 0.5) * cell)
    end
    return result
end

local function claim_near(position)
    if not spots then return end
    -- brain.place may hand back fixed values; square plain numbers so the
    -- product cannot pass fixed's range.
    local px, pz = util.number(position.x), util.number(position.z)
    for index = 1, #spots do
        local dx, dz = spots[index].x - px, spots[index].z - pz
        if dx * dx + dz * dz <= SPOT_CLAIM * SPOT_CLAIM then taken[index] = true end
    end
end

local function next_role()
    local plan = PLANS[me.difficulty] or PLANS.medium
    local asked = {}
    for index = 1, #plan do
        local role = plan[index]
        asked[role] = (asked[role] or 0) + 1
        if picks[role] ~= nil and state.count(role) < asked[role] then return role end
    end
    return nil
end

-- Where to put an extractor: a site near the nearest open metal spot.
local function extractor_site(commander, record)
    if not spots then return nil end
    local cx, cz = util.num(commander, "x"), util.num(commander, "z")
    local open = {}
    for index = 1, #spots do
        if not taken[index] then
            local dx, dz = spots[index].x - cx, spots[index].z - cz
            open[#open + 1] = { index = index, d = dx * dx + dz * dz }
        end
    end
    table.sort(open, function(a, b) return a.d < b.d end)
    for n = 1, math.min(#open, SPOTS_TRIED) do
        local index = open[n].index
        local _, _, x, z = brain.place(record, spots[index], SPOT_RADIUS, 0)
        if x ~= nil then return { x = x, z = z }, index end
        taken[index] = true
    end
    return nil
end

-- Where to put anything else: the first clear site near home.
local function base_site(commander, record, facing)
    local home = state.home or util.pos(commander.x, commander.z)
    local near = {
        x = home.x + brain.random(2 * BASE_JITTER + 1) - BASE_JITTER - 1,
        z = home.z + brain.random(2 * BASE_JITTER + 1) - BASE_JITTER - 1,
    }
    local _, _, x, z = brain.place(record, near, BASE_RADIUS, facing)
    if x == nil then return nil end
    return { x = x, z = z }
end

local function build_next()
    local commander = state.commander
    if not util.alive(commander) or commander.type == nil then return end
    if picks == nil then picks = choose_picks(commander) end
    if picks == nil or not util.free(commander) then return end
    if spots == nil then spots = load_spots() end

    local role = next_role()
    if role == nil then return end -- TODO: the plan is done; keep expanding
    local record = picks[role]
    -- TODO: facing for factories should point the exit away from the base.
    local facing = role == "factory" and (brain.random(4) - 1) or 0
    local site, spot
    if role == "extractor" then site, spot = extractor_site(commander, record) end
    if site == nil then site = base_site(commander, record, facing) end
    if site == nil then
        util.log("no site for %s", role)
        return
    end
    if commander:build(record, site, facing) == true then
        pending = spot
        if role == "extractor" then claim_near(site) end
        util.log("commander builds %s at %s,%s", role, site.x, site.z)
    end
end

economy.think = build_next

function economy.onUnitIdle(unit)
    if state.commander ~= nil and unit.id == state.commander.id then build_next() end
end

-- A refused build (blocked site, enemy extractor) marks that spot taken so
-- the next attempt goes elsewhere.
function economy.onCommandDone(unit, _, result)
    if state.commander ~= nil and unit.id == state.commander.id and result == "failed"
        and pending ~= nil then
        taken[pending] = true
        pending = nil
    end
end

-- TODO: when the commander dies, hand the plan to constructors.

function economy.report()
    local function name(role) return picks and picks[role] and picks[role].name or "-" end
    return {
        string.format("economy: extractor=%s energy=%s factory=%s",
            name("extractor"), name("energy"), name("factory")),
        string.format("economy: metal %.0f/%.0f energy %.0f/%.0f",
            util.number(me.metal), util.number(me.metal_storage),
            util.number(me.energy), util.number(me.energy_storage)),
    }
end

return economy
